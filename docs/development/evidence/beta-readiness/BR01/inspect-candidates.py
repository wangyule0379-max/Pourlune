"""Read only the frozen BR01-3 outputs; never install/run or upload a candidate."""
from pathlib import Path
import hashlib,json,plistlib,struct,subprocess,urllib.parse,zipfile
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[5]
E=Path(__file__).resolve().parent
C=R/'build/beta-candidates/0.5.0-5'
IOS=C/'ios-br01-3'; ANDROID=C/'android-br01-3'
app=IOS/'ipa-inspection/Payload/Runner.app';aab=ANDROID/'app-release-unsigned.aab'
sha=lambda b: hashlib.sha256(b).hexdigest()
info=plistlib.loads((app/'Info.plist').read_bytes());privacy=[];ids=[]
for f in sorted(app.rglob('PrivacyInfo.xcprivacy')):
 d=plistlib.loads(f.read_bytes());privacy.append({'path':str(f.relative_to(app)),'sha256':sha(f.read_bytes()),**d})
for f in sorted(app.rglob('Info.plist')):
 d=plistlib.loads(f.read_bytes())
 if 'CFBundleIdentifier' in d:ids.append({'path':str(f.relative_to(app)),'bundle':d['CFBundleIdentifier']})
assert [x['path'] for x in ids if x['bundle']=='com.pourlune.app']==['Info.plist']
assert not any('integration_test' in str(f) for f in app.rglob('*'))
ios={'candidate':'ios-br01-3','identity':info['CFBundleIdentifier'],'display_name':info['CFBundleDisplayName'],'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'minimum_os':info['MinimumOSVersion'],'sdk':info['DTSDKName'],'xcode_build':info['DTXcodeBuild'],'device_family':info['UIDeviceFamily'],'bundle_identifiers':ids,'sdk_privacy_manifests':privacy,'embedded_sdk_ids_do_not_equal_app':True,'contains_integration_test':False,'native_defaults':{k:v for k,v in info.items() if 'COLLECTION' in k or 'CrashlyticsCollection' in k or 'ALLOW_' in k or 'ScreenReporting' in k},'limits':'vendor manifest aggregation/source inspection, not Xcode-generated privacy report/store form or runtime receipt'}
(E/'ios-native-final.json').write_text(json.dumps(ios,indent=2)+'\n')
jar=Path('/Users/wangyule/.cache/pourlune-tools/bundletool-all-1.18.3.jar');receipt=json.loads((E/'bundletool-download.json').read_text());assert sha(jar.read_bytes())==receipt['sha256']
for name,args in [('bundle-validate-final.log',['validate',f'--bundle={aab}']),('bundle-manifest-final.xml',['dump','manifest',f'--bundle={aab}']),('bundle-config-final.json',['dump','config',f'--bundle={aab}'])]:
 p=subprocess.run(['java','-jar',str(jar),*args],capture_output=True,text=True);(E/name).write_text(p.stdout if name.endswith(('.xml','.json')) else p.stdout+p.stderr);assert p.returncode==0
m=ET.parse(E/'bundle-manifest-final.xml').getroot();a='{http://schemas.android.com/apk/res/android}';sdk=m.find('uses-sdk');application=m.find('application');native=[]
with zipfile.ZipFile(aab) as z:
 for name in z.namelist():
  if not (name.startswith('base/lib/') and name.endswith('.so')):continue
  b=z.read(name);row={'path':name,'bytes':len(b),'sha256':sha(b)}
  if b[:5]==b'\x7fELF\x02' and b[5]==1:
   offset=struct.unpack_from('<Q',b,32)[0];size,num=struct.unpack_from('<HH',b,54);align=[struct.unpack_from('<Q',b,offset+i*size+48)[0] for i in range(num) if struct.unpack_from('<I',b,offset+i*size)[0]==1];assert align and all(v>=16384 for v in align);row.update(load_segment_alignment=align,all_load_segments_16k_aligned=True)
  native.append(row)
 prefix='base/assets/flutter_assets/'
 android_assets={urllib.parse.unquote(n[len(prefix):]):sha(z.read(n)) for n in z.namelist() if n.startswith(prefix+'assets/') and not n.endswith('/')}
 dex_has_integration=any(b'IntegrationTestPlugin' in z.read(n) for n in z.namelist() if n.endswith('.dex'))
assert not dex_has_integration
config=json.loads((E/'bundle-config-final.json').read_text());assert config['optimizations']['uncompressNativeLibraries']['alignment']=='PAGE_ALIGNMENT_16K'
android={'candidate':'android-br01-3','identity':m.get('package'),'display_label':application.get(a+'label'),'version':m.get(a+'versionName'),'build':m.get(a+'versionCode'),'min_sdk':sdk.get(a+'minSdkVersion'),'target_sdk':sdk.get(a+'targetSdkVersion'),'permissions':[n.get(a+'name') for n in m.findall('uses-permission')],'metadata':[{ 'name':n.get(a+'name'),'value':n.get(a+'value'),'resource':n.get(a+'resource')} for n in application.findall('meta-data')],'services':[{k:v for k,v in s.attrib.items()} for s in application.findall('service')],'native_libraries':native,'bundle_page_alignment':'PAGE_ALIGNMENT_16K','dex_contains_integration_test_plugin':dex_has_integration,'limits':'format/manifest/ELF/asset inspection; unsigned, not16KB runtime/device installation/store processing'}
assert android['identity']=='com.pourlune.app' and android['target_sdk']=='36' and android['display_label']=='Pourlune'
(E/'android-native-final.json').write_text(json.dumps(android,indent=2)+'\n')
ios_assets_root=app/'Frameworks/App.framework/flutter_assets'
ios_assets={urllib.parse.unquote(str(p.relative_to(ios_assets_root))):sha(p.read_bytes()) for p in (ios_assets_root/'assets').rglob('*') if p.is_file()}
source_assets={str(p.relative_to(R/'app')):sha(p.read_bytes()) for p in (R/'app/assets').rglob('*') if p.is_file()}
assert all(ios_assets.get(k)==v and android_assets.get(k)==v for k,v in source_assets.items())
summary={'version':'0.5.0','build':5,'source_asset_count':len(source_assets),'puzzles':len([k for k in source_assets if k.startswith('assets/puzzles/')]),'all_source_assets_match_both_candidates':True,'assets_sha256':source_assets,'ios_ipa_sha256':sha((IOS/'Pourlune-0.5.0-5.ipa').read_bytes()),'android_aab_sha256':sha(aab.read_bytes()),'ios_signing':json.loads((IOS/'signing.json').read_text()),'android_signature':'unsigned (jarsigner verified in candidate builder)','ios_sdk_privacy_manifest_count':len(privacy),'android_target':36,'runtime_or_upload_performed':False}
(E/'candidate-inspection.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k not in {'assets_sha256','ios_signing'}},indent=2))
