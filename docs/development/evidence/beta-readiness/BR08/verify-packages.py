"""Read-only BR08 artifact checks; writes only this evidence directory."""
from pathlib import Path
import hashlib,json,zipfile,plistlib,subprocess,re,urllib.parse,struct,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[5]; E=Path(__file__).resolve().parent
BASE=R/'build/beta-candidates/0.5.0-7'
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
def load(p):return json.loads(p.read_text())
def save(name,d): (E/name).write_text(json.dumps(d,indent=2)+'\n')
def run(args,name):
 p=subprocess.run([str(x) for x in args],capture_output=True,text=True,timeout=120)
 (E/(name+'.log')).write_text(p.stdout+p.stderr)
 assert p.returncode==0,(name,p.returncode)
 return p.stdout+p.stderr
b=load(E/'source-baseline.json'); report={'production_run_or_upload':False,'device_operations':False}
sources={p:load(BASE/f'{p}-br08-1/sources.json') for p in ['ios','android']}
assert sources['ios']==sources['android']
current=sources['ios']; assert set(current)==set(b['source_files_sha256'])
assert all(sha(R/n)==s for n,s in current.items())
delta=[n for n,s in current.items() if s!=b['source_files_sha256'][n]]
assert delta==['app/pubspec.yaml'],delta
accepted=subprocess.check_output(['git','show',b['accepted_ly_commit']+':app/pubspec.yaml'],cwd=R).decode()
assert (R/'app/pubspec.yaml').read_text()==accepted.replace('version: 0.5.0+6','version: 0.5.0+7')
report['source']={'files':len(current),'delta_from_accepted_ly':delta,'only_version_6_to_7':True,'all_current_match':True,'manifest_sha256':sha(BASE/'ios-br08-1/sources.json'),'locks':{n:s for n,s in current.items() if n.endswith(('pubspec.lock','Package.resolved'))}}
report['old_build6_unchanged']={n:sha(R/n)==s for n,s in b['old_frozen_build6_sha256'].items()};assert all(report['old_build6_unchanged'].values())
report['packages']={}
for platform in ['ios','android']:
 d=BASE/f'{platform}-br08-1'; c=load(d/'candidate.json')
 assert (c['identity'],c['version'],c['build_number'],c['ads'],c['firebase_environment'])==('com.pourlune.app','0.5.0',7,'disabled','prod')
 assert c['signed_for_upload'] and not c['production_run_or_upload']
 assert sha(d/'sources.json')==c['source_manifest_sha256']
 assert all(sha(d/n)==s for n,s in c['files_sha256'].items()),'frozen artifact drift'
 artifact=d/('Pourlune-0.5.0-7.ipa' if platform=='ios' else 'Pourlune-0.5.0-7-upload-signed.aab')
 result={'path':str(artifact.relative_to(R)),'bytes':artifact.stat().st_size,'sha256':sha(artifact),'candidate_files_all_verified':len(c['files_sha256'])}
 with zipfile.ZipFile(artifact) as z:
  assert len(z.namelist())==len(set(z.namelist()))
  if platform=='ios':
   prefix='Payload/Runner.app/Frameworks/App.framework/flutter_assets/';binary=z.read('Payload/Runner.app/Frameworks/App.framework/App')
   info=plistlib.loads(z.read('Payload/Runner.app/Info.plist'))
   assert (info['CFBundleIdentifier'],info['CFBundleDisplayName'],info['CFBundleShortVersionString'],info['CFBundleVersion'])==('com.pourlune.app','Pourlune','0.5.0','7')
   result['identity']={k:info[k] for k in ['CFBundleIdentifier','CFBundleDisplayName','CFBundleShortVersionString','CFBundleVersion','MinimumOSVersion','UIDeviceFamily','DTSDKName']}
   result['export_compliance_key']=info.get('ITSAppUsesNonExemptEncryption','absent; store question pending')
   result['privacy_manifests']=len([n for n in z.namelist() if n.endswith('PrivacyInfo.xcprivacy')])
  else:
   prefix='base/assets/flutter_assets/';binary=z.read('base/lib/arm64-v8a/libapp.so')
   result['symbols']={n:hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if 'debugsymbols/' in n or n.endswith('proguard.map')}
   assert any(n.endswith('proguard.map') for n in result['symbols'])
   elf=[]
   for n in z.namelist():
    if n.endswith('.so'):
     data=z.read(n); assert data[:4]==b'\x7fELF' and data[5]==1
     if data[4]==2:
      offset=struct.unpack_from('<Q',data,32)[0];size,count=struct.unpack_from('<HH',data,54);fmt,alignoff='<Q',48
     else:
      assert data[4]==1
      offset=struct.unpack_from('<I',data,28)[0];size,count=struct.unpack_from('<HH',data,42);fmt,alignoff='<I',28
     align=[struct.unpack_from(fmt,data,offset+i*size+alignoff)[0] for i in range(count) if struct.unpack_from('<I',data,offset+i*size)[0]==1]
     assert align and all(v>=16384 for v in align),(n,align)
     elf.append({'entry':n,'pt_load_alignments':align})
   result['elf_static_16kb']=elf
  assets=[n for n in z.namelist() if n.startswith(prefix+'assets/') and not n.endswith('/')]
  assert len(assets)==136
  assert all(z.read(n)==(R/'app'/urllib.parse.unquote(n.removeprefix(prefix))).read_bytes() for n in assets)
  puzzles=[n for n in assets if '/puzzles/' in n];assert len(puzzles)==90
  result['assets']={'count':len(assets),'puzzles':len(puzzles),'all_match_source':True}
  result['public_destinations_in_aot']={k:v.encode() in binary for k,v in c['public_destinations'].items() if k!='ready'};assert all(result['public_destinations_in_aot'].values())
 report['packages'][platform]=result
android=BASE/'android-br08-1'; aab=android/'Pourlune-0.5.0-7-upload-signed.aab'
with zipfile.ZipFile(android/'app-release-unsigned.aab') as a,zipfile.ZipFile(aab) as z:
 payload=lambda q:{n:hashlib.sha256(q.read(n)).hexdigest() for n in q.namelist() if not n.upper().startswith('META-INF/') and not n.endswith('/')}
 assert payload(a)==payload(z);report['signed_unsigned_equal_entries']=len(payload(z))
java=Path('/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home/bin');bt='/Users/wangyule/.cache/pourlune-tools/bundletool-all-1.18.3.jar'
run([java/'java','-jar',bt,'validate','--bundle='+str(aab)],'bundle-validate')
manifest=run([java/'java','-jar',bt,'dump','manifest','--bundle='+str(aab),'--module=base'],'bundle-manifest')
run([java/'java','-jar',bt,'dump','config','--bundle='+str(aab)],'bundle-config')
root=ET.fromstring(manifest);ns='{http://schemas.android.com/apk/res/android}'
assert root.attrib['package']=='com.pourlune.app' and root.attrib[ns+'versionCode']=='7' and root.attrib[ns+'versionName']=='0.5.0'
report['android_manifest']={'package':root.attrib['package'],'versionCode':root.attrib[ns+'versionCode'],'versionName':root.attrib[ns+'versionName'],'sdk':root.find('uses-sdk').attrib,'permissions':[n.attrib[ns+'name'] for n in root.findall('uses-permission')]}
p=subprocess.run([str(java/'keytool'),'-J-Duser.language=en','-printcert','-v','-jarfile',str(aab)],capture_output=True,text=True,timeout=60);assert p.returncode==0
pin=re.search(r'SHA256:\s*([A-Fa-f0-9:]+)',p.stdout)[1].replace(':','').upper();assert pin=='E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2'
report['android_certificate_sha256']=pin
# Strict verification using existing trust entry. Password file is passed by path only.
p=subprocess.run([str(java/'jarsigner'),'-J-Duser.language=en','-verify','-strict','-keystore','/Users/wangyule/.local/share/pourlune-signing/pourlune-upload.p12','-storepass:file','/Users/wangyule/.local/share/pourlune-signing/store-password',str(aab),'pourlune-upload'],capture_output=True,text=True,timeout=60)
assert p.returncode==0 and 'jar verified.' in p.stdout.lower();report['android_jarsigner_strict']=True
app=BASE/'ios-br08-1/ipa-inspection/Payload/Runner.app'
run(['codesign','--verify','--deep','--strict',app],'ios-codesign-verify')
p=subprocess.run(['codesign','-d','--entitlements',':-',str(app)],capture_output=True,timeout=60);assert p.returncode==0
ent=plistlib.loads(p.stdout);assert ent['application-identifier']=='T7U878Z8H6.com.pourlune.app' and ent['com.apple.developer.team-identifier']=='T7U878Z8H6' and ent['get-task-allow'] is False
report['ios_entitlements']=ent
p=subprocess.run(['security','cms','-D','-i',str(app/'embedded.mobileprovision')],capture_output=True,timeout=60);assert p.returncode==0
profile=plistlib.loads(p.stdout);assert profile['UUID']=='74a202b2-3b25-4e31-8fd4-0413bf15d486'
assert hashlib.sha1(profile['DeveloperCertificates'][0]).hexdigest().upper()=='13362E4AF31A860FA6B705DB5192AF78613F7A58'
report['ios_profile']={'uuid':profile['UUID'],'name':profile['Name'],'team':profile['TeamIdentifier'],'expiry':profile['ExpirationDate'].isoformat(),'application_identifier':profile['Entitlements']['application-identifier'],'certificate_sha1':hashlib.sha1(profile['DeveloperCertificates'][0]).hexdigest().upper()}
report['ios_dsyms']=[]
for d in (BASE/'ios-br08-1/ios-export/Runner.xcarchive/dSYMs').glob('*/Contents/Resources/DWARF/*'):
 binary=app/'Runner' if d.name=='Runner' else app/'Frameworks'/f'{d.name}.framework'/d.name
 get=lambda f:re.findall(r'UUID: ([A-F0-9-]+) \(([^)]+)\)',subprocess.check_output(['dwarfdump','--uuid',str(f)]).decode())
 uuids=get(d);assert uuids and uuids==get(binary)
 report['ios_dsyms'].append({'path':str(d.relative_to(R)),'sha256':sha(d),'uuids':uuids,'matches_exported_binary':True})
assert len(report['ios_dsyms'])==5
save('package-checks.json',report)
print(json.dumps({'checks':'passed','source_files':len(current),'delta':delta,'packages':{k:{n:v for n,v in d.items() if n in ['path','bytes','sha256','assets']} for k,d in report['packages'].items()},'dsyms':len(report['ios_dsyms']),'old_build6_unchanged':True},indent=2))
