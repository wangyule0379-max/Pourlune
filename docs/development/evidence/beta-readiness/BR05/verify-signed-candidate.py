"""Read-only public artifact checks. No credential reads, key creation, signing or install."""
from pathlib import Path
import hashlib
import json
import subprocess
import urllib.parse
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[5]
E = Path(__file__).resolve().parent
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest = json.loads((E / 'signed-candidate.json').read_text())
signed = Path(manifest['artifact'])
unsigned = signed.parent / 'app-release-unsigned.aab'
jar = Path('/Users/wangyule/.cache/pourlune-tools/bundletool-all-1.18.3.jar')
assert sha(jar) == json.loads((E.parent / 'BR01/bundletool-download.json').read_text())['sha256']
commands = []
for name, args in [
    ('bundle-validate.log', ['validate', f'--bundle={signed}']),
    ('bundle-manifest.xml', ['dump', 'manifest', f'--bundle={signed}']),
    ('bundle-config.json', ['dump', 'config', f'--bundle={signed}']),
]:
    result = subprocess.run(['java', '-jar', str(jar), *args], capture_output=True, text=True, timeout=60)
    assert result.returncode == 0
    # Evidence output only; candidate is immutable.
    (E / name).write_text(result.stdout if name.endswith(('.xml', '.json')) else result.stdout + result.stderr)
    commands.append({'operation': args[0], 'exit_code': result.returncode})
xml = ET.parse(E / 'bundle-manifest.xml').getroot()
ns = '{http://schemas.android.com/apk/res/android}'
app, sdk = xml.find('application'), xml.find('uses-sdk')
assert xml.get('package') == 'com.pourlune.app'
assert xml.get(ns + 'versionName') == '0.5.0' and xml.get(ns + 'versionCode') == '5'
assert app.get(ns + 'label') == 'Pourlune' and sdk.get(ns + 'targetSdkVersion') == '36'
with zipfile.ZipFile(signed) as after, zipfile.ZipFile(unsigned) as before:
    payload = lambda z: {n: hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist()
                         if not n.upper().startswith('META-INF/')}
    after_payload = payload(after)
    assert after_payload == payload(before)
    assets = {urllib.parse.unquote(n[len('base/assets/flutter_assets/'):]):
              hashlib.sha256(after.read(n)).hexdigest() for n in after.namelist()
              if n.startswith('base/assets/flutter_assets/assets/') and not n.endswith('/')}
    expected = {str(p.relative_to(ROOT / 'app')): sha(p)
                for p in (ROOT / 'app/assets').rglob('*') if p.is_file()}
    assert all(assets.get(k) == v for k, v in expected.items())
    symbols = [{'member': n, 'bytes': after.getinfo(n).file_size,
                'sha256': hashlib.sha256(after.read(n)).hexdigest()}
               for n in after.namelist() if n.startswith('BUNDLE-METADATA/')
               and ('debugsymbols/' in n or n.endswith('proguard.map'))]
    assert len(symbols) == 10
    assert not any(b'IntegrationTestPlugin' in after.read(n)
                   for n in after.namelist() if n.endswith('.dex'))
config = json.loads((E / 'bundle-config.json').read_text())
assert config['optimizations']['uncompressNativeLibraries']['alignment'] == 'PAGE_ALIGNMENT_16K'
assert sha(signed) == manifest['files_sha256'][signed.name]
assert sha(unsigned) == manifest['derivation']['original_unsigned_sha256']
assert sha(Path(manifest['derivation']['original_unsigned'])) == sha(unsigned)
result = {'real_bundletool_commands': commands, 'identity': 'com.pourlune.app',
          'version': '0.5.0', 'build': 5, 'display_name': 'Pourlune',
          'min_sdk': sdk.get(ns + 'minSdkVersion'), 'target_sdk': sdk.get(ns + 'targetSdkVersion'),
          'signed_aab_bytes': signed.stat().st_size, 'signed_aab_sha256': sha(signed),
          'unsigned_aab_sha256': sha(unsigned), 'non_signature_payload_identical': True,
          'payload_entries': len(after_payload), 'source_assets': len(expected),
          'puzzle_assets': sum(k.startswith('assets/puzzles/') for k in expected),
          'all_assets_match_current_source': True, 'bundle_page_alignment': 'PAGE_ALIGNMENT_16K',
          'mapping_and_native_symbols': symbols, 'integration_test_plugin_present': False,
          'native_rebuilt': False, 'runtime_or_upload': False,
          'limits': 'public format/assets/symbols/payload checks; same accepted native ELF payload, not new16KB/32bit runtime proof'}
(E / 'artifact-verification.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({k: v for k, v in result.items() if k != 'mapping_and_native_symbols'}, indent=2))
