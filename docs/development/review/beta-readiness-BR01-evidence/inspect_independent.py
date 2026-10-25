"""Architecture read-only BR01 frozen-package verification; no device or upload."""
from pathlib import Path
import hashlib, json, plistlib, subprocess, sys, zipfile, struct
import xml.etree.ElementTree as ET
from urllib.parse import unquote

R = Path(__file__).resolve().parents[4]
E = Path(__file__).resolve().parent
C = R / 'build/beta-candidates/0.5.0-5'
I, A = C / 'ios-br01-3', C / 'android-br01-3'
ipa, aab = I / 'Pourlune-0.5.0-5.ipa', A / 'app-release-unsigned.aab'
app = I / 'ipa-inspection/Payload/Runner.app'
sha = lambda b: hashlib.sha256(b).hexdigest()
result = {'scope': 'read-only frozen files, local public signing metadata; no install/run/upload'}
for folder in [I, A]:
    manifest = json.loads((folder / 'sources.json').read_text())
    mismatch = [n for n, h in manifest.items() if not (R/n).is_file() or sha((R/n).read_bytes()) != h]
    assert not mismatch, mismatch
    result[folder.name + '_source'] = {'count': len(manifest), 'mismatches': mismatch}
assert sha(ipa.read_bytes()) == '0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5'
assert sha(aab.read_bytes()) == 'ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90'
result['ipa_sha256'], result['aab_sha256'] = sha(ipa.read_bytes()), sha(aab.read_bytes())
with zipfile.ZipFile(ipa) as z:
    checked = 0
    for name in z.namelist():
        if name.endswith('/') or not name.startswith('Payload/Runner.app/'):
            continue
        assert z.read(name) == (I / 'ipa-inspection' / name).read_bytes(), name
        checked += 1
    result['extracted_ipa_files_match'] = checked
v = subprocess.run(['codesign','--verify','--deep','--strict',str(app)],capture_output=True,text=True)
(E/'codesign-independent.log').write_text(v.stdout+v.stderr)
assert v.returncode == 0
ent_cmd = subprocess.run(['codesign','-d','--entitlements',':-',str(app)],capture_output=True)
assert ent_cmd.returncode == 0
ent = plistlib.loads(ent_cmd.stdout)
assert ent['application-identifier'] == 'T7U878Z8H6.com.pourlune.app'
assert ent['get-task-allow'] is False
sys.path.insert(0,str(R/'tools/validation'))
from ios_signing import inspect_profile
profile = inspect_profile(app/'embedded.mobileprovision')
expected = json.loads((I/'signing.json').read_text())
assert profile['uuid'] == expected['uuid'] and profile['certificate_sha1'] == expected['certificate_sha1']
result['signature'] = {**profile,'deep_strict':True,'get_task_allow':False}
info = plistlib.loads((app/'Info.plist').read_bytes())
assert [info[k] for k in ['CFBundleIdentifier','CFBundleDisplayName','CFBundleShortVersionString','CFBundleVersion']] == ['com.pourlune.app','Pourlune','0.5.0','5']
result['ios'] = {k:info.get(k) for k in ['CFBundleIdentifier','CFBundleDisplayName','MinimumOSVersion','DTSDKName','DTXcodeBuild','UIDeviceFamily','FirebaseCrashlyticsCollectionEnabled','FIREBASE_ANALYTICS_COLLECTION_ENABLED']}
ids = [str(p.relative_to(app)) for p in app.rglob('Info.plist') if plistlib.loads(p.read_bytes()).get('CFBundleIdentifier')=='com.pourlune.app']
assert ids == ['Info.plist'], ids
privacy = list(app.rglob('PrivacyInfo.xcprivacy'))
assert len(privacy)==24
result['ios']['privacy_manifest_count']=len(privacy)
jar=Path('/Users/wangyule/.cache/pourlune-tools/bundletool-all-1.18.3.jar')
receipt=json.loads((R/'docs/development/evidence/beta-readiness/BR01/bundletool-download.json').read_text())
assert sha(jar.read_bytes()) == receipt['sha256']
outputs={}
for label,args in [('validate',['validate']),('manifest',['dump','manifest']),('config',['dump','config'])]:
    p=subprocess.run(['java','-jar',str(jar),*args,'--bundle='+str(aab)],capture_output=True,text=True)
    assert p.returncode == 0, p.stderr
    (E/('bundle-'+label+'-independent.txt')).write_text(p.stdout+p.stderr)
    outputs[label]=p.stdout
m=ET.fromstring(outputs['manifest']); ns='{http://schemas.android.com/apk/res/android}'
assert m.get('package')=='com.pourlune.app'
assert m.get(ns+'versionCode')=='5' and m.get(ns+'versionName')=='0.5.0'
assert m.find('uses-sdk').get(ns+'targetSdkVersion')=='36'
assert m.find('application').get(ns+'label')=='Pourlune'
assert json.loads(outputs['config'])['optimizations']['uncompressNativeLibraries']['alignment']=='PAGE_ALIGNMENT_16K'
s=subprocess.run(['jarsigner','-J-Duser.language=en','-verify',str(aab)],capture_output=True,text=True)
assert s.returncode==0 and 'jar is unsigned' in s.stdout.lower()
(E/'jarsigner-independent.log').write_text(s.stdout+s.stderr)
result['android']={'target_sdk':36,'signature':'unsigned','bundle_alignment':'PAGE_ALIGNMENT_16K','permissions':[n.get(ns+'name') for n in m.findall('uses-permission')]}
with zipfile.ZipFile(aab) as z:
    alignment={}
    for n in z.namelist():
        if n.startswith('base/lib/') and n.endswith('.so'):
            b=z.read(n); assert b[:4]==b'\x7fELF', n
            if b[4]==1:
                result['android'].setdefault('additional_32bit_libraries',[]).append(n)
                continue
            assert b[:6]==b'\x7fELF\x02\x01', n
            offset=struct.unpack_from('<Q',b,32)[0]; size,num=struct.unpack_from('<HH',b,54)
            vals=[struct.unpack_from('<Q',b,offset+i*size+48)[0] for i in range(num) if struct.unpack_from('<I',b,offset+i*size)[0]==1]
            assert vals and min(vals)>=16384
            alignment[n]=vals
    assert len(alignment)==8
    result['android']['elf_load_alignment']=alignment
    count=0
    android_assets={unquote(n):n for n in z.namelist()}
    assets_root=app/'Frameworks/App.framework/flutter_assets'
    ios_assets={unquote(str(p.relative_to(assets_root))):p for p in assets_root.rglob('*') if p.is_file()}
    for p in (R/'app/assets').rglob('*'):
        if not p.is_file(): continue
        rel=str(p.relative_to(R/'app'))
        assert z.read(android_assets['base/assets/flutter_assets/'+rel])==p.read_bytes()
        assert ios_assets[rel].read_bytes()==p.read_bytes()
        count+=1
    assert not any(b'IntegrationTestPlugin' in z.read(n) for n in z.namelist() if n.endswith('.dex'))
    result['assets_matching_both']=count
assert not any('integration_test' in str(p) for p in app.rglob('*'))
result['limits']=['No production runtime/network or installation','No store processing or ownership assertion','No 16KB runtime; static only','No physical device, audio or screenshot observation']
(E/'candidate-independent.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'ok':True,'source_counts':[result[x+'_source']['count'] for x in ['ios-br01-3','android-br01-3']], 'assets':result['assets_matching_both'],'ios_signed':True,'android_unsigned':True}))
