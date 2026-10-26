import base64,datetime,hashlib,json,plistlib,re,subprocess,sys,zipfile
from urllib.parse import quote
from pathlib import Path
R=Path('/Volumes/data/App Development/Pourlune');C=R/'build/beta-candidates/0.5.0-16/ios-audio-admob-test-1';OUT=R/'docs/development/evidence/audio-admob-testflight-20261026'
sys.path.insert(0,str(R/'tools/validation'))
from beta_build import sources
from ios_signing import inspect_profile
from ios_release_plugins import verify_no_test_plugin
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
c=json.loads((C/'candidate.json').read_text());frozen=json.loads((C/'sources.json').read_text())
assert c['git_head']=='2b364d62f060e3a537c47a9e1db987bb26c90fea';assert frozen==sources();assert c['source_manifest_sha256']==sha(C/'sources.json')
for name,digest in frozen.items():
 data=subprocess.check_output(['git','show',f"{c['git_head']}:{name}"],cwd=R);assert hashlib.sha256(data).hexdigest()==digest,name
for name,digest in c['files_sha256'].items():assert sha(C/name)==digest,name
ipa=C/'Pourlune-0.5.0-16.ipa';work=R/'build/package-author16-check/ios-audio-admob-test-1'
assert not work.exists();work.mkdir(parents=True)
with zipfile.ZipFile(ipa) as z:z.extractall(work)
app=work/'Payload/Runner.app';info=plistlib.loads((app/'Info.plist').read_bytes())
assert [info[k] for k in ['CFBundleIdentifier','CFBundleDisplayName','CFBundleShortVersionString','CFBundleVersion']]==['com.pourlune.app','Pourlune','0.5.0','16']
assert info['GADApplicationIdentifier']=='ca-app-pub-3090980891246277~5042293200'
assert info['FIREBASE_ANALYTICS_COLLECTION_ENABLED'] is False and info['FirebaseCrashlyticsCollectionEnabled'] is False
assets=app/'Frameworks/App.framework/flutter_assets';asset_count=0
for source in (R/'app/assets').rglob('*'):
 if source.is_file():assert sha(source)==sha(assets/quote(str(source.relative_to(R/'app')),safe='/')),str(source);asset_count+=1
levels=[];oldroot=R/'docs/development/evidence/main60-five-color-difficulty/old-main'
for n in range(1,61):
 p=json.loads((assets/f'assets/puzzles/main/main-{n:03}.json').read_text());old=json.loads((oldroot/f'main-{n:03}.json').read_text());count=2 if n<=4 else 3 if n<=8 else 4 if n<=20 else 5
 assert len(p['initial_bottom_to_top'])==count+2
 assert set(filter(None,p['target_labels']))==set('OGPBR'[:count])
 assert p['content_version']==old['content_version']+(n>=21)
 levels.append({'id':p['puzzle_id'],'version':p['content_version'],'colors':count,'initial_bottles':count+2})
baseline=json.loads((R/'docs/development/evidence/main60-five-color-difficulty/baseline.json').read_text())['hashes'];protected=0
for name,digest in baseline.items():
 if '/daily/' in name or '/catalog/' in name:assert sha(assets/Path(name).relative_to('app'))==digest;protected+=1
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True,capture_output=True)
ent=plistlib.loads(subprocess.check_output(['codesign','-d','--entitlements',':-',str(app)],stderr=subprocess.DEVNULL));assert ent['application-identifier']=='T7U878Z8H6.com.pourlune.app' and ent['get-task-allow'] is False
profile=inspect_profile(app/'embedded.mobileprovision');assert profile['certificate_sha1']=='13362E4AF31A860FA6B705DB5192AF78613F7A58';assert profile['uuid']=='74a202b2-3b25-4e31-8fd4-0413bf15d486'
archive=C/'ios-export/Runner.xcarchive';verify_no_test_plugin(app/'Runner');verify_no_test_plugin(archive/'Products/Applications/Runner.app/Runner')
for p in app.rglob('Info.plist'):
 if p!=app/'Info.plist':assert plistlib.loads(p.read_bytes()).get('CFBundleIdentifier')!='com.pourlune.app',str(p)
defs={}
for line in (R/'app/ios/Flutter/Generated.xcconfig').read_text().splitlines():
 if line.startswith('DART_DEFINES='):
  for value in line.split('=',1)[1].split(','):
   decoded=base64.b64decode(value).decode();k,v=decoded.split('=',1);defs[k]=v
expected={'POURLUNE_FIREBASE_ENV':'prod','POURLUNE_FIREBASE_NATIVE_READY':'true','POURLUNE_AD_MODE':'test','POURLUNE_AD_PLATFORM':'ios','POURLUNE_AD_NATIVE_ID':'com.pourlune.app','POURLUNE_AD_APP_ID':info['GADApplicationIdentifier'],'POURLUNE_SUPPORT_URL':c['public_destinations']['support_url'],'POURLUNE_PRIVACY_URL':c['public_destinations']['privacy_url'],'POURLUNE_FEEDBACK_EMAIL':c['public_destinations']['feedback_email']}
for key,value in expected.items():assert defs.get(key)==value,key
assert not {'POURLUNE_DATABASE','POURLUNE_SCENARIO'} & defs.keys()
options=json.loads(defs['POURLUNE_FIREBASE_OPTIONS']);native=plistlib.loads((app/'GoogleService-Info.plist').read_bytes());assert options['appId']==native['GOOGLE_APP_ID'] and options['projectId']==native['PROJECT_ID'] and options['apiKey']==native['API_KEY'] and native['BUNDLE_ID']=='com.pourlune.app'
aot=(app/'Frameworks/App.framework/App').read_bytes();sentinels=['visible_pour.sqlite','orange_pour_gap.sqlite','tap_reselect.sqlite','main60_five_color.sqlite','MAIN60_NATIVE_PASS','main60-v3-native-legacy','b05_lifecycle.sqlite','LY_NATIVE_EVIDENCE','ADM01_NATIVE_PROBE','parent_normal_closeout.sqlite','IntegrationTestPlugin','dev.flutter.integration_test','admob_resume.sqlite','admob_resume_interstitial.sqlite','selected_audio.sqlite']
for value in sentinels:assert value.encode() not in aot,value
samples=['ca-app-pub-3940256099942544/1712485313','ca-app-pub-3940256099942544/4411468910']
for value in samples:assert value.encode() in aot,value
inventory=json.loads((R/'docs/development/evidence/admob-resume-20261026/console-registration.json').read_text())
for platform in inventory['apps'].values():
 for key in ('rewarded_id','interstitial_id'):assert platform[key].encode() not in aot,key
assert (C/'admob-registration.json').read_bytes()==(R/'app/config/admob/registration.json').read_bytes()
assert not (assets/'assets/audio/background.wav').exists()
for name in ('dream-culture.mp3','pour.wav','ATTRIBUTION.txt'):assert sha(R/'app/assets/audio'/name)==sha(assets/'assets/audio'/name)
assert b'Dream Culture' in (assets/'assets/audio/ATTRIBUTION.txt').read_bytes()
for key,value in c['public_destinations'].items():
 if key!='ready':assert value.encode() in aot,key
uuid=lambda p:re.findall(r'UUID: ([A-F0-9-]+) \(([^)]+)\)',subprocess.check_output(['dwarfdump','--uuid',str(p)],text=True))
dsyms=[]
for p in (archive/'dSYMs').glob('*/Contents/Resources/DWARF/*'):
 relative=Path('Runner') if p.name=='Runner' else Path('Frameworks')/f'{p.name}.framework'/p.name
 u=uuid(p);assert u and u==uuid(app/relative)==uuid(archive/'Products/Applications/Runner.app'/relative)
 dsyms.append({'path':str(p.relative_to(C)),'sha256':sha(p),'uuids':u})
assert {'Runner','App','Flutter'} <= {Path(r['path']).name for r in dsyms}
plugins=json.loads((C/'ios-export/release-plugins.json').read_text())
for name,row in plugins['generated_inputs'].items():assert sha(R/'app'/name)==row['before_sha256'],name
manifests=[]
for p in app.rglob('PrivacyInfo.xcprivacy'):
 d=plistlib.loads(p.read_bytes());assert isinstance(d,dict);manifests.append({'path':str(p.relative_to(app)),'sha256':sha(p)})
log=(C/'build.log').read_text()
for marker in ["Target 'FirebaseAnalyticsCore' in project 'Firebase'", "Target 'FirebaseAnalyticsCoreWrapper' in project 'Firebase'", "Target 'GoogleAppMeasurementCore' in project 'GoogleAppMeasurement'"]:
 assert marker in log,marker
for marker in ["Target 'FirebaseAnalytics' in project 'Firebase'", "Target 'FirebaseAnalyticsWrapper' in project 'Firebase'", "Target 'GoogleAppMeasurement' in project 'GoogleAppMeasurement'", "Target 'GoogleAppMeasurementIdentitySupport'"]:
 assert marker not in log,marker
report={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':c['git_head'],'candidate':str(C),'ipa':str(ipa),'ipa_sha256':sha(ipa),'ipa_bytes':ipa.stat().st_size,'source_files_exact_git_and_current':len(frozen),'candidate_file_hashes_verified':len(c['files_sha256']),'identity':{k:info[k] for k in ['CFBundleIdentifier','CFBundleDisplayName','CFBundleShortVersionString','CFBundleVersion','MinimumOSVersion']},'assets_exact':asset_count,'main_levels':levels,'protected_daily_catalog':protected,'signature_deep_strict':True,'profile':profile,'collection_defaults_off':True,'ads_disabled':False,'ad_mode':'test','registered_app_id':info['GADApplicationIdentifier'],'official_ios_sample_units_verified':samples,'owner_paid_units_absent':True,'normal_main':True,'compiled_firebase_native_match':True,'no_adid_product_selected':True,'qa_sentinels_absent':True,'archive_and_export_native_test_plugin_absent':True,'generated_dev_plugin_inputs_restored':True,'dsyms_match_archive_and_ipa':dsyms,'privacy_manifests':manifests,'flutter_contains_boringssl':b'boringssl' in (app/'Frameworks/Flutter.framework/Flutter').read_bytes(),'prod_run_symbols_store_upload':False,'independent_parent_package_gate':'pending','exact_ci':40335786098}
(OUT/'author-package.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['source','ipa_sha256','ipa_bytes','source_files_exact_git_and_current','assets_exact','protected_daily_catalog','signature_deep_strict','normal_main','ads_disabled','no_adid_product_selected']}))
