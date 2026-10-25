"""Architecture read-only verification; never creates keys, signs, or prints secrets."""
from pathlib import Path
import datetime as dt
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
AUTHOR = ROOT / 'docs/development/evidence/beta-readiness/BR05'
META = json.loads((AUTHOR / 'signed-candidate.json').read_text())
PUBLIC = json.loads((AUTHOR / 'upload-key-public.json').read_text())
SIGNED = Path(META['artifact'])
ORIGINAL = Path(META['derivation']['original_unsigned'])
JAVA = Path('/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home/bin')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def check(condition, label):
    if not condition:
        raise RuntimeError(label)

def run(label, args):
    result = subprocess.run(args, capture_output=True, stdin=subprocess.DEVNULL,
                            text=True, errors='replace', timeout=120)
    check(result.returncode == 0, label + '_failed_output_suppressed')
    commands.append({'operation': label, 'exit_code': result.returncode})
    return result.stdout

commands = []
check(sha(SIGNED) == '5016d22d030414dfbf3c9a84f59327badddb3d82cac1719df36c967e97593caa', 'signed_hash')
check(sha(ORIGINAL) == 'ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90', 'original_hash')
check(sha(SIGNED.parent / 'app-release-unsigned.aab') == sha(ORIGINAL), 'copied_unsigned')
check(sha(SIGNED.parent / 'sources.json') == META['derivation']['original_source_manifest_sha256'], 'original_sources')
for name, expected in META['derivation']['signing_tools_sha256'].items():
    check(sha(ROOT / name) == expected, 'signing_tool_changed')
ipa = ROOT / 'build/beta-candidates/0.5.0-5/ios-br01-3/Pourlune-0.5.0-5.ipa'
check(sha(ipa) == '0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5', 'old_ipa')

key, password = Path(PUBLIC['key_path']), Path(PUBLIC['password_file_path'])
recovery = Path(PUBLIC['recovery_directory'])
for path in [key.parent, recovery.parent, recovery]:
    info = path.lstat()
    check(stat.S_ISDIR(info.st_mode) and stat.S_IMODE(info.st_mode) == 0o700 and info.st_uid == os.getuid(), 'directory_permissions')
for path in [key, password, recovery / key.name, recovery / password.name]:
    info = path.lstat()
    check(stat.S_ISREG(info.st_mode) and stat.S_IMODE(info.st_mode) == 0o600 and info.st_uid == os.getuid(), 'file_permissions')
    check(not path.resolve().is_relative_to(ROOT), 'secret_in_repository')
# Compare privately, report booleans only, never serialize bytes or password digests.
check(key.read_bytes() == (recovery / key.name).read_bytes(), 'key_recovery_mismatch')
secret = password.read_bytes().strip()
check(len(secret) >= 32 and password.read_bytes() == (recovery / password.name).read_bytes(), 'password_recovery_mismatch')
public_files = [p for p in AUTHOR.rglob('*') if p.is_file()]
public_files += [ROOT / 'docs/development/deliveries/beta-readiness-BR05.md']
public_files += [p for p in SIGNED.parent.iterdir() if p.suffix in ('.json', '.log')]
for path in public_files:
    data = path.read_bytes()
    check(secret not in data and b'BEGIN PRIVATE KEY' not in data and b'BEGIN ENCRYPTED PRIVATE KEY' not in data, 'secret_in_public_evidence')
del secret

with zipfile.ZipFile(ORIGINAL) as before, zipfile.ZipFile(SIGNED) as after:
    names = after.namelist()
    check(len(names) == len(set(names)) and after.testzip() is None, 'zip_integrity')
    def payload(z):
        return {n: hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if not n.upper().startswith('META-INF/')}
    original_payload, signed_payload = payload(before), payload(after)
    check(original_payload == signed_payload, 'payload_changed')
    check(any(n.upper().endswith('.SF') for n in names) and any(n.upper().endswith('.RSA') for n in names), 'signature_entries')
    assets = {urllib.parse.unquote(n[len('base/assets/flutter_assets/'):]): hashlib.sha256(after.read(n)).hexdigest()
              for n in names if n.startswith('base/assets/flutter_assets/assets/') and not n.endswith('/')}
    expected = {str(p.relative_to(ROOT / 'app')): sha(p) for p in (ROOT / 'app/assets').rglob('*') if p.is_file()}
    check(assets == expected, 'assets_changed')
    symbols = [n for n in signed_payload if n.startswith('BUNDLE-METADATA/') and ('debugsymbols/' in n or n.endswith('proguard.map'))]
    check(len(symbols) == 10, 'symbol_count')

result = {'checked_at': dt.datetime.now(dt.timezone.utc).isoformat(), 'signed_sha256': sha(SIGNED),
          'old_ipa_unsigned_and_source_manifest_unchanged': True, 'private_permissions_verified': True,
          'local_recovery_equal': True, 'off_device_backup_verified': False,
          'secret_not_in_scanned_public_files': True, 'public_files_scanned': len(public_files),
          'payload_equal_entries': len(signed_payload), 'assets': len(expected),
          'puzzles': sum(n.startswith('assets/puzzles/') for n in expected), 'symbol_files_equal': len(symbols),
          'native_rebuild_or_sign_or_install_or_upload_performed': False}
if '--java' in sys.argv:
    common = ['-J-Duser.language=en', '-J-Duser.country=US', '-J-Duser.timezone=UTC']
    args = ['-keystore', str(key), '-storepass:file', str(password)]
    listing = run('inspect_existing_alias', [str(JAVA / 'keytool'), *common, '-list', '-v', *args, '-alias', PUBLIC['alias']])
    pin = re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', listing)
    period = re.search(r'Valid from: (.*?) until: ([^\r\n]+)', listing)
    check(pin and pin[1].replace(':', '').upper() == PUBLIC['certificate_sha256'], 'key_pin')
    check('PrivateKeyEntry' in listing and '3072-bit RSA' in listing and 'SHA256withRSA' in listing and 'CN=Android Debug' not in listing, 'key_metadata')
    check(period is not None, 'period_missing')
    start, end = [dt.datetime.strptime(v.strip(), '%a %b %d %H:%M:%S %Z %Y').replace(tzinfo=dt.timezone.utc) for v in period.groups()]
    check(start <= dt.datetime.now(dt.timezone.utc) < end, 'certificate_expired')
    verified = run('jarsigner_strict_verify', [str(JAVA / 'jarsigner'), *common, '-verify', '-strict', *args, str(SIGNED), PUBLIC['alias']])
    check('jar verified.' in verified.lower(), 'strict_not_verified')
    cert = run('read_aab_public_certificate', [str(JAVA / 'keytool'), *common, '-printcert', '-v', '-jarfile', str(SIGNED)])
    pins = re.findall(r'SHA256:\s*([A-Fa-f0-9:]+)', cert)
    check(len(pins) == 1 and pins[0].replace(':', '').upper() == PUBLIC['certificate_sha256'], 'aab_pin')
    jar = Path('/Users/wangyule/.cache/pourlune-tools/bundletool-all-1.18.3.jar')
    check(sha(jar) == json.loads((AUTHOR.parent / 'BR01/bundletool-download.json').read_text())['sha256'], 'bundletool_hash')
    run('bundletool_validate', [str(JAVA / 'java'), '-jar', str(jar), 'validate', f'--bundle={SIGNED}'])
    xml = run('bundletool_manifest', [str(JAVA / 'java'), '-jar', str(jar), 'dump', 'manifest', f'--bundle={SIGNED}'])
    root = ET.fromstring(xml); ns = '{http://schemas.android.com/apk/res/android}'
    check(root.get('package') == 'com.pourlune.app' and root.get(ns+'versionName') == '0.5.0' and root.get(ns+'versionCode') == '5', 'identity_version')
    check(root.find('uses-sdk').get(ns+'targetSdkVersion') == '36' and root.find('application').get(ns+'label') == 'Pourlune', 'sdk_label')
    result.update(real_java_commands=commands, certificate_sha256=PUBLIC['certificate_sha256'], certificate_expires_utc=end.isoformat(), identity='com.pourlune.app', version='0.5.0+5', strict_signature_verified=True)
(OUT / ('independent-final.json' if '--java' in sys.argv else 'independent-static.json')).write_text(json.dumps(result, indent=2)+'\n')
print(json.dumps(result, indent=2))
