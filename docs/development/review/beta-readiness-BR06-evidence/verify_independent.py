"""Read-only BR06 candidate verification. Does not build, sign, run or upload."""
from pathlib import Path
import datetime as dt
import hashlib
import json
import plistlib
import re
import subprocess
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
BASE = ROOT / 'build/beta-candidates/0.5.0-6'
AUTHOR = ROOT / 'docs/development/evidence/beta-readiness/BR06'
JAVA = Path('/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home/bin')
PIN = 'E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2'
URL = 'https://wangyule0379-max.github.io/pourlune-support/'
DEST = [URL, URL + 'privacy.html', 'wangyule0379@gmail.com']
commands = []

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def check(value, label):
    if not value:
        raise RuntimeError(label)

def run(label, args):
    p = subprocess.run(args, capture_output=True, stdin=subprocess.DEVNULL,
                       timeout=120)
    commands.append({'operation': label, 'exit_code': p.returncode})
    check(p.returncode == 0, label + ': failed; output not published')
    return p.stdout

def load(p):
    return json.loads(p.read_text())

report = {'checked_at': dt.datetime.now(dt.timezone.utc).isoformat(),
          'no_build_sign_device_run_upload_or_key_creation': True}
scope = load(AUTHOR / 'scope-manifest.json')['files']
for item in scope:
    check(sha(ROOT / item['path']) == item['sha256'], 'scope hash ' + item['path'])
report['author_scope_hashes_matched'] = len(scope)
source_maps = []
for platform in ['ios', 'android']:
    folder = BASE / (platform + '-br06-1')
    sources = load(folder / 'sources.json')
    for name, digest in sources.items():
        check(sha(ROOT / name) == digest, 'source drift ' + name)
    source_maps.append(sources)
check(source_maps[0] == source_maps[1], 'platform source mismatch')
report['sources_matched_each'] = len(source_maps[0])
report['source_manifest_sha256'] = sha(BASE / 'ios-br06-1/sources.json')

artifacts = {
    'ios': ('ios-br06-1/Pourlune-0.5.0-6.ipa', 'c7d5c5428da62644179abbd29d95e6fe5ab1270026dbfb054ac2aa6bde6c1ce4'),
    'android': ('android-br06-1/Pourlune-0.5.0-6-upload-signed.aab', '57118f03b57d6c75264a2dd310740ff486336b19d0acfe6597804f63461a74d8')}
expected_assets = {str(p.relative_to(ROOT / 'app')): sha(p) for p in (ROOT / 'app/assets').rglob('*') if p.is_file()}
report['candidates'] = {}
for platform, (relative, digest) in artifacts.items():
    file = BASE / relative
    check(sha(file) == digest, 'candidate hash ' + platform)
    with zipfile.ZipFile(file) as z:
        names = z.namelist()
        check(len(names) == len(set(names)) and z.testzip() is None, 'zip integrity')
        if platform == 'ios':
            prefix = 'Payload/Runner.app/Frameworks/App.framework/flutter_assets/'
            binaries = ['Payload/Runner.app/Frameworks/App.framework/App']
            info = plistlib.loads(z.read('Payload/Runner.app/Info.plist'))
            check(info['CFBundleIdentifier'] == 'com.pourlune.app' and info['CFBundleVersion'] == '6'
                  and info['CFBundleShortVersionString'] == '0.5.0' and info['CFBundleDisplayName'] == 'Pourlune', 'ios identity')
            report['ios_minimum'] = info['MinimumOSVersion']
            report['ios_privacy_manifests'] = sum(n.endswith('PrivacyInfo.xcprivacy') for n in names)
            # Verify every IPA file against the extracted inspection tree before codesign.
            inspected = BASE / 'ios-br06-1/ipa-inspection'
            for name in names:
                if not name.endswith('/'):
                    check((inspected / name).read_bytes() == z.read(name), 'inspection mismatch ' + name)
            report['ipa_inspection_files_match'] = sum(not n.endswith('/') for n in names)
        else:
            prefix = 'base/assets/flutter_assets/'
            binaries = [n for n in names if n.startswith('base/lib/') and n.endswith('/libapp.so')]
            report['android_symbols'] = {n: hashlib.sha256(z.read(n)).hexdigest() for n in names if 'debugsymbols/' in n or n.endswith('proguard.map')}
        assets = {urllib.parse.unquote(n[len(prefix):]): hashlib.sha256(z.read(n)).hexdigest() for n in names if n.startswith(prefix + 'assets/') and not n.endswith('/')}
        check(assets == expected_assets, 'asset mismatch ' + platform)
        for binary in binaries:
            data = z.read(binary)
            check(all(v.encode() in data for v in DEST), 'missing compiled destination ' + binary)
        report['candidates'][platform] = {'sha256': digest, 'assets': len(assets), 'puzzles': sum(n.startswith('assets/puzzles/') for n in assets), 'destination_binaries_checked': binaries}

signed = BASE / artifacts['android'][0]
with zipfile.ZipFile(signed) as a, zipfile.ZipFile(BASE / 'android-br06-1/app-release-unsigned.aab') as b:
    def payload(z):
        return {n: hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if not n.upper().startswith('META-INF/') and not n.endswith('/')}
    check(payload(a) == payload(b), 'signed payload changed')
    report['signed_payload_entries_equal'] = len(payload(a))

# Existing key is only passed to Java for strict verification. No secret is printed.
private = Path('/Users/wangyule/.local/share/pourlune-signing')
common = ['-J-Duser.language=en', '-J-Duser.country=US']
text = run('android_jarsigner_strict', [str(JAVA / 'jarsigner'), *common, '-verify', '-strict', '-keystore', str(private / 'pourlune-upload.p12'), '-storepass:file', str(private / 'store-password'), str(signed), 'pourlune-upload']).decode()
check('jar verified.' in text.lower(), 'strict no success')
cert = run('android_public_certificate', [str(JAVA / 'keytool'), *common, '-printcert', '-v', '-jarfile', str(signed)]).decode()
pins = re.findall(r'SHA256:\s*([A-Fa-f0-9:]+)', cert)
check(len(pins) == 1 and pins[0].replace(':', '').upper() == PIN, 'certificate mismatch')
report['upload_certificate_sha256'] = PIN
jar = Path('/Users/wangyule/.cache/pourlune-tools/bundletool-all-1.18.3.jar')
check(sha(jar) == load(AUTHOR.parent / 'BR01/bundletool-download.json')['sha256'], 'bundletool changed')
run('bundletool_validate', [str(JAVA / 'java'), '-jar', str(jar), 'validate', '--bundle=' + str(signed)])
xml = run('bundletool_manifest', [str(JAVA / 'java'), '-jar', str(jar), 'dump', 'manifest', '--bundle=' + str(signed)])
root = ET.fromstring(xml); ns = '{http://schemas.android.com/apk/res/android}'
check(root.get('package') == 'com.pourlune.app' and root.get(ns + 'versionCode') == '6' and root.get(ns + 'versionName') == '0.5.0', 'android identity')
sdk = root.find('uses-sdk')
check(sdk.get(ns+'minSdkVersion') == '24' and sdk.get(ns+'targetSdkVersion') == '36', 'sdk versions')
check(root.find('application').get(ns+'label') == 'Pourlune', 'android label')
report['android_identity'] = {'package': root.get('package'), 'build': 6, 'min': 24, 'target': 36}

app = BASE / 'ios-br06-1/ipa-inspection/Payload/Runner.app'
run('ios_codesign_deep_strict', ['codesign', '--verify', '--deep', '--strict', str(app)])
ent = plistlib.loads(run('ios_entitlements', ['codesign', '-d', '--entitlements', ':-', str(app)]))
profile = plistlib.loads(run('ios_embedded_profile', ['security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')]))
check(ent['application-identifier'] == 'T7U878Z8H6.com.pourlune.app' and not ent.get('get-task-allow', True), 'ios entitlements')
check(profile['Entitlements']['application-identifier'] == ent['application-identifier'] and profile['ExpirationDate'] > dt.datetime.now(dt.timezone.utc).replace(tzinfo=None), 'profile identity or expiry')
check(not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices'), 'not store profile')
report['ios_profile'] = {'application_identifier': ent['application-identifier'], 'debuggable': False, 'expires': profile['ExpirationDate'].isoformat(), 'distribution': 'App Store'}
dsym_dir = BASE / 'ios-br06-1/ios-export/Runner.xcarchive/dSYMs'
uuids = {}
for dwarf in sorted(dsym_dir.glob('*.dSYM/Contents/Resources/DWARF/*')):
    text = run('dsym_uuid_' + dwarf.name, ['xcrun', 'dwarfdump', '--uuid', str(dwarf)]).decode()
    pairs = set(re.findall(r'UUID: ([A-Fa-f0-9-]+) \(([^)]+)\)', text))
    executable = app / 'Runner' if dwarf.name == 'Runner' else app / 'Frameworks' / (dwarf.name + '.framework') / dwarf.name
    if executable.exists():
        actual = run('binary_uuid_' + dwarf.name, ['xcrun', 'dwarfdump', '--uuid', str(executable)]).decode()
        check(pairs == set(re.findall(r'UUID: ([A-Fa-f0-9-]+) \(([^)]+)\)', actual)), 'symbol uuid mismatch ' + dwarf.name)
        uuids[dwarf.name] = sorted(pairs)
    else:
        uuids[dwarf.name] = {'not_embedded_executable': True, 'uuid': sorted(pairs)}
report['ios_symbol_uuid_checks'] = uuids

http = []
for relative in ['', 'privacy.html']:
    with urllib.request.urlopen(URL + relative, timeout=30) as response:
        body = response.read()
        local = ROOT / 'docs/support/pages-site' / (relative or 'index.html')
        check(response.status == 200 and body == local.read_bytes(), 'live page mismatch')
        http.append({'url': response.url, 'status': response.status, 'sha256': hashlib.sha256(body).hexdigest()})
report['public_http'] = http
report['commands'] = commands
(OUT / 'independent-final.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'result': 'PASS', 'scope': len(scope), 'sources_each': len(source_maps[0]), 'assets_each': len(expected_assets), 'commands': len(commands), 'http_pages': len(http)}, indent=2))
