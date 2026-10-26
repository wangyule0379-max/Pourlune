"""Parent read-only package inspection. No author verification modules or SDK execution."""
from pathlib import Path
from datetime import datetime, timezone
import base64
import hashlib
import json
import plistlib
import re
import stat
import subprocess
import tempfile
import urllib.parse
import zipfile

ROOT = Path('/Volumes/data/App Development/Pourlune')
PACKAGE = ROOT / 'build/package-review/0.5.0-15/ios-gameplay-polish-2'
OUT = ROOT / 'docs/development/evidence/gameplay-polish-testflight-20261026'
HEAD = '70d9b5909e6a1d8c158df349f59fd4cfb043b99e'
ACCEPTED = 'c3de374'
IPA_SHA = 'fde95b02f7bd0e8c00245f893c9a4a89403ba88d983ebc148410c2c2f5660513'
TEAM = 'T7U878Z8H6'
SIGNER = '13362E4AF31A860FA6B705DB5192AF78613F7A58'
checks = {}
details = {}


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def filehash(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def check(name, value):
    checks[name] = bool(value)


def run(*args):
    return subprocess.run(args, cwd=ROOT, capture_output=True, check=True).stdout


def git_bytes(rev, path):
    return run('git', 'show', f'{rev}:{path}')


candidate = json.loads((PACKAGE / 'candidate.json').read_text())
sources = json.loads((PACKAGE / 'sources.json').read_text())
mirror = json.loads((OUT / 'review-copy.json').read_text())
actual_files = {str(f.relative_to(PACKAGE)): filehash(f)
                for f in PACKAGE.rglob('*') if f.is_file()}
check('readonly_mirror_exact_all_files', actual_files == mirror['files'])
check('readonly_permissions', all((f.stat().st_mode & 0o222) == 0
                                 for f in [PACKAGE, *PACKAGE.rglob('*')]))
check('candidate_554_hashes', all(actual_files.get(p) == h
                                for p, h in candidate['files_sha256'].items()))
check('source_manifest_hash', filehash(PACKAGE / 'sources.json') == candidate['source_manifest_sha256'])
check('candidate_head', candidate['git_head'] == HEAD)
source_errors = [p for p, h in sources.items()
                 if filehash(ROOT / p) != h or digest(git_bytes(HEAD, p)) != h]
check('508_sources_equal_exact_git_and_current', not source_errors and len(sources) == 508)
details['source_mismatches'] = source_errors
locks = [p for p in sources if p.endswith(('pubspec.lock', 'Package.resolved')) or p == '.flutter-version']
check('sdk_and_locks_equal_accepted', all(digest(git_bytes(ACCEPTED, p)) == sources[p] for p in locks))
details['locks'] = locks

ipa = PACKAGE / 'Pourlune-0.5.0-15.ipa'
check('ipa_sha_and_size', actual_files[ipa.name] == IPA_SHA and ipa.stat().st_size == 80311850)
with zipfile.ZipFile(ipa) as z:
    members = [i for i in z.infolist() if not i.is_dir()]
    check('ipa_has_no_duplicate_paths', len(members) == len(set(i.filename for i in members)))
    zip_hashes = {i.filename: digest(z.read(i)) for i in members}
    extracted = {str(f.relative_to(PACKAGE / 'ipa-inspection')): filehash(f)
                 for f in (PACKAGE / 'ipa-inspection').rglob('*') if f.is_file()}
    check('actual_zip_exact_extracted_all_files', zip_hashes == extracted)
details['zip_members'] = len(zip_hashes)

app = PACKAGE / 'ipa-inspection/Payload/Runner.app'
archive = PACKAGE / 'ios-export/Runner.xcarchive'
archive_app = archive / 'Products/Applications/Runner.app'
info = plistlib.loads((app / 'Info.plist').read_bytes())
identity = {'CFBundleIdentifier': 'com.pourlune.app', 'CFBundleDisplayName': 'Pourlune',
            'CFBundleShortVersionString': '0.5.0', 'CFBundleVersion': '15', 'MinimumOSVersion': '15.0'}
check('actual_ipa_identity', all(info.get(k) == v for k, v in identity.items()))
archive_info = plistlib.loads((archive_app / 'Info.plist').read_bytes())
check('archive_identity', all(archive_info.get(k) == v for k, v in identity.items()))
check('collection_defaults_off', info.get('FIREBASE_ANALYTICS_COLLECTION_ENABLED') is False
      and info.get('FirebaseCrashlyticsCollectionEnabled') is False)
check('no_tracking_usage_prompt', 'NSUserTrackingUsageDescription' not in info)
details['identity'] = identity

asset_root = app / 'Frameworks/App.framework/flutter_assets'
assets = {p: h for p, h in sources.items() if p.startswith('app/assets/')}
packaged = {urllib.parse.unquote(str(p.relative_to(asset_root))): p
            for p in asset_root.rglob('*') if p.is_file()}
check('146_assets_exact_source', len(assets) == 146 and all(
    p[4:] in packaged and filehash(packaged[p[4:]]) == h for p, h in assets.items()))
main_files = sorted((asset_root / 'assets/puzzles/main').glob('*.json'))
daily_files = sorted((asset_root / 'assets/puzzles/daily').glob('*.json'))
check('60_main_30_daily', len(main_files) == 60 and len(daily_files) == 30)
levels = [json.loads(p.read_text()) for p in main_files]
check('21_to_60_five_colors_seven_bottles', all(
    len(x['initial_bottom_to_top']) == 7 and set(x['target_labels']) == {'O', 'G', 'P', 'B', 'R', None}
    and sum(t is None for t in x['target_labels']) == 2 for x in levels[20:]))
check('all_puzzles_equal_accepted_source', all(filehash(p) == digest(git_bytes(ACCEPTED,
    'app/' + str(p.relative_to(asset_root)))) for p in main_files + daily_files))
protected = [p for p in assets if '/puzzles/daily/' in p or p == 'app/assets/catalog/daily.json']
check('31_daily_catalog_equal_accepted', len(protected) == 31 and all(
    sources[p] == digest(git_bytes(ACCEPTED, p)) for p in protected))
details['content'] = {'main': len(main_files), 'daily': len(daily_files), 'five_color_main': 40,
                      'assets_exact': len(assets), 'protected_daily_catalog': len(protected)}

log = (PACKAGE / 'build.log').read_text(errors='replace')
lines = [line.replace('\\', '').strip() for line in log.splitlines()]
defs_lines = [line.split('=', 1)[1] for line in lines if line.startswith('export DART_DEFINES=')]
decoded = []
for line in defs_lines:
    decoded.append(dict(base64.b64decode(x, validate=True).decode().split('=', 1)
                        for x in line.split(',') if not x.startswith('[CLIENT_CONFIG_')))
complete = [d for d in decoded if 'POURLUNE_FIREBASE_OPTIONS' in d]
check('frozen_definitions_consistent', bool(complete) and all(
    all(complete[0].get(k) == v for k, v in d.items()) for d in decoded))
defs = complete[0]
expect = {'POURLUNE_FIREBASE_ENV': 'prod', 'POURLUNE_FIREBASE_NATIVE_READY': 'true',
          'POURLUNE_AD_MODE': 'disabled', 'POURLUNE_AD_PLATFORM': 'ios',
          'POURLUNE_AD_NATIVE_ID': 'com.pourlune.app',
          'POURLUNE_AD_APP_ID': 'ca-app-pub-3940256099942544~1458002511',
          'POURLUNE_SUPPORT_URL': 'https://wangyule0379-max.github.io/pourlune-support/',
          'POURLUNE_PRIVACY_URL': 'https://wangyule0379-max.github.io/pourlune-support/privacy.html',
          'POURLUNE_FEEDBACK_EMAIL': 'wangyule0379@gmail.com'}
check('frozen_release_mode_and_destinations', all(defs.get(k) == v for k, v in expect.items()))
check('no_scenario_database_override', 'POURLUNE_SCENARIO' not in defs and 'POURLUNE_DATABASE' not in defs)
targets = [line.split('=', 1)[1] for line in lines if line.startswith('export FLUTTER_TARGET=')]
check('normal_main_entrypoint', targets and set(targets) == {'lib/main.dart'})
check('archive_noadid_environment', 'export FIREBASE_ANALYTICS_WITHOUT_ADID=1' in lines)
graph = set(re.findall(r"^\s*Target '([^']+)' in project '([^']+)'\s*$", log, re.M))
check('actual_noadid_core_graph', {('FirebaseAnalyticsCore', 'Firebase'),
    ('FirebaseAnalyticsCoreWrapper', 'Firebase'), ('GoogleAppMeasurementCore', 'GoogleAppMeasurement')} <= graph)
check('full_identity_measurement_graph_absent', not any(t in {'FirebaseAnalytics',
    'FirebaseAnalyticsWrapper', 'GoogleAppMeasurement', 'GoogleAppMeasurementIdentitySupport'} for t, _ in graph))
native = plistlib.loads((app / 'GoogleService-Info.plist').read_bytes())
options = json.loads(defs['POURLUNE_FIREBASE_OPTIONS'])
mapping = {'apiKey': 'API_KEY', 'appId': 'GOOGLE_APP_ID', 'messagingSenderId': 'GCM_SENDER_ID',
           'projectId': 'PROJECT_ID', 'storageBucket': 'STORAGE_BUCKET', 'iosBundleId': 'BUNDLE_ID'}
check('compiled_firebase_matches_native', all(options.get(k) == native.get(v) for k, v in mapping.items()))
check('sample_app_id_matches_native', info.get('GADApplicationIdentifier') == expect['POURLUNE_AD_APP_ID'])
details['build_config'] = {'entrypoint': 'lib/main.dart', 'ads': 'disabled', 'firebase': 'prod',
                         'no_adid_core': True, 'options_compared_without_persisting': True}

signature_results = []
for label, bundle in [('ipa', app), ('archive', archive_app)]:
    result = subprocess.run(['codesign', '--verify', '--deep', '--strict', str(bundle)], capture_output=True)
    check(label + '_deep_strict_signature', result.returncode == 0)
    profile = plistlib.loads(run('security', 'cms', '-D', '-i', str(bundle / 'embedded.mobileprovision')))
    entitlements = plistlib.loads(run('codesign', '-d', '--entitlements', ':-', str(bundle)))
    check(label + '_profile', profile['UUID'] == '74a202b2-3b25-4e31-8fd4-0413bf15d486'
          and profile['TeamIdentifier'] == [TEAM]
          and profile['Entitlements'].get('application-identifier') == TEAM + '.com.pourlune.app'
          and profile['Entitlements'].get('get-task-allow') is False
          and profile['ExpirationDate'].replace(tzinfo=timezone.utc) > datetime.now(timezone.utc)
          and not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices'))
    check(label + '_entitlements', entitlements.get('application-identifier') == TEAM + '.com.pourlune.app'
          and entitlements.get('com.apple.developer.team-identifier') == TEAM
          and entitlements.get('get-task-allow') is False)
    with tempfile.TemporaryDirectory(prefix='pourlune15-public-cert-') as tmp:
        prefix = str(Path(tmp) / 'cert')
        run('codesign', '-d', '--extract-certificates=' + prefix, str(bundle))
        signer = (Path(tmp) / 'cert0').read_bytes()
        signer_pin = hashlib.sha1(signer).hexdigest().upper()
        check(label + '_existing_public_signer', signer_pin == SIGNER and signer in profile['DeveloperCertificates'])
    signature_results.append({'bundle': label, 'codesign_exit': result.returncode,
                              'profile': profile['UUID'], 'signer_sha1': signer_pin})
    binary = (bundle / 'Runner').read_bytes()
    check(label + '_native_test_plugin_absent', all(x not in binary for x in
        [b'IntegrationTestPlugin', b'integration_test']))
details['signatures'] = signature_results

aot = (app / 'Frameworks/App.framework/App').read_bytes()
sentinels = ['liquid_color_reference.sqlite', 'visible_pour.sqlite', 'orange_pour_gap.sqlite', 'tap_reselect.sqlite', 'main60_five_color.sqlite', 'MAIN60_NATIVE_PASS', 'main60-v3-native-legacy',
             'b05_lifecycle.sqlite', 'LY_NATIVE_EVIDENCE', 'ADM01_NATIVE_PROBE',
             'parent_normal_closeout.sqlite', 'IntegrationTestPlugin', 'dev.flutter.integration_test',
             'ca-app-pub-3940256099942544/1712485313', 'ca-app-pub-3940256099942544/4411468910',
             'ca-app-pub-3940256099942544/1033173712', 'ca-app-pub-3940256099942544/5224354917']
check('aot_qa_test_unit_sentinels_absent', not any(s.encode() in aot for s in sentinels))
check('aot_public_destinations_present', all(expect[k].encode() in aot for k in
    ['POURLUNE_SUPPORT_URL', 'POURLUNE_PRIVACY_URL', 'POURLUNE_FEEDBACK_EMAIL']))


def uuids(path):
    return re.findall(r'UUID: ([A-F0-9-]+) \(([^)]+)\)', run('dwarfdump', '--uuid', str(path)).decode())


symbols = []
for dsym in (archive / 'dSYMs').glob('*.dSYM/Contents/Resources/DWARF/*'):
    name = dsym.name
    binary_rel = 'Runner' if name == 'Runner' else f'Frameworks/{name}.framework/{name}'
    identifiers = uuids(dsym)
    check('dsym_' + dsym.parent.parent.parent.name, bool(identifiers)
          and identifiers == uuids(archive_app / binary_rel) == uuids(app / binary_rel))
    symbols.append({'name': dsym.parent.parent.parent.name, 'uuid': identifiers, 'sha256': filehash(dsym)})
details['symbols'] = symbols
check('all_expected_dsyms', {x.name for x in (archive / 'dSYMs').glob('*.dSYM')} >=
      {'Runner.app.dSYM', 'App.framework.dSYM', 'Flutter.framework.dSYM', 'objective_c.framework.dSYM'})
plugins = json.loads((PACKAGE / 'ios-export/release-plugins.json').read_text())
check('only_integration_test_temporarily_excluded', plugins['excluded_native_dev_plugins'] == ['integration_test'])
check('generated_qa_inputs_restored', all(filehash(ROOT / 'app' / p) == data['before_sha256']
    and b'integration_test' in (ROOT / 'app' / p).read_bytes() for p, data in plugins['generated_inputs'].items()))
privacy = []
for path in app.rglob('PrivacyInfo.xcprivacy'):
    data = plistlib.loads(path.read_bytes())
    privacy.append({'path': str(path.relative_to(app)), 'sha256': filehash(path), 'tracking': data.get('NSPrivacyTracking')})
check('privacy_manifests_parse', len(privacy) == 24)
details['privacy'] = privacy

result = {'checked_at': datetime.now(timezone.utc).isoformat(), 'reviewer': 'parent independent read-only',
          'source': HEAD, 'candidate': str(PACKAGE), 'ipa_sha256': IPA_SHA, 'ipa_bytes': ipa.stat().st_size,
          'counts': {'mirror_files': len(actual_files), 'candidate_hashes': len(candidate['files_sha256']), 'source_files': len(sources)},
          'checks': checks, 'details': details, 'passed': all(checks.values()),
          'ci': {'run': 40287545684, 'independent_terminal': 'ci-independent-terminal.json'},
          'scope': 'Signed candidate package only; no upload, platform processing or physical installation claim.'}
(OUT / 'package-independent.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'passed': result['passed'], 'checks': len(checks), 'failed': [k for k, v in checks.items() if not v],
                  'counts': result['counts'], 'output': str(OUT / 'package-independent.json')}, ensure_ascii=False))
raise SystemExit(0 if result['passed'] else 1)
