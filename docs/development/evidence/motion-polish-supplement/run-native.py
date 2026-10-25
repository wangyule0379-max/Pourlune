import hashlib,json,subprocess,time,re,plistlib
from pathlib import Path
R=Path('/Volumes/data/App Development/Pourlune'); E=R/'docs/development/evidence/motion-polish-supplement'; A='/Users/wangyule/Library/Android/sdk/platform-tools/adb'; D='255890D5-B4A3-42F9-B1A2-409E77118348'; I='dev.pourlune.motionSupplementValidation'; P='dev.pourlune.motion_supplement'; commands=[]
def run(*args,check=True):
 p=subprocess.run(args,capture_output=True,text=True); commands.append({'command':list(args),'code':p.returncode,'stdout':p.stdout,'stderr':p.stderr});(E/'native-commands.json').write_text(json.dumps(commands,indent=2));
 if check and p.returncode: raise RuntimeError((args,p.stderr))
 return p.stdout.strip()
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def validate(d):
 assert d['ok'] and d['gesture_count']==1 and d['prepared_for_next_launch']
 assert d['accepted']['snapshot_writes']==1 and d['accepted']['new_instance_count']==1
 assert d['accepted']['instance']==d['accepted']['saved_instance'] and d['accepted']['moves']==0 and d['accepted']['revision']==0
 assert d['dart_start_us']<=d['product_main_call_us']<d['home_enabled_hit_testable_us']<=d['pointer_down_request_us']<=d['pointer_down_sent_us']<=d['pointer_up_request_us']<=d['first_controller_response_us']<=d['first_accepted_committed_navigation_us']
 assert d['requested_poll_interval_ms']==5 and d['database'].endswith('/motion_supplement.sqlite')
 assert d['before_gesture']['ordinary'] is None and not d['before_gesture']['tutorial_complete']
 assert not d['captures_screen_or_audio'] and d['excludes_native_pre_dart']
 return d
inventory=json.loads((E/'device-inventory.json').read_text()); results={}
assert 'Booted' in run('xcrun','simctl','list','devices',D)
assert run(A,'-s','emulator-5588','emu','avd','name').splitlines()[0]=='Pourlune_FullBoard_API36'
for platform in ('ios','android'):
 out=E/platform;out.mkdir(exist_ok=True)
 if platform=='ios':
  candidate=R/'build/motion-supplement-candidates/ios/Runner.app'; assert plistlib.loads((candidate/'Info.plist').read_bytes())['CFBundleIdentifier']==I
  run('xcrun','simctl','install',D,str(candidate)); container=Path(run('xcrun','simctl','get_app_container',D,I,'data'));binary=Path(run('xcrun','simctl','get_app_container',D,I,'app'))
  before={'container':str(container),'installed_kernel_sha256':sha(binary/'Frameworks/App.framework/flutter_assets/kernel_blob.bin'),'installed_info_sha256':sha(binary/'Info.plist')}
 else:
  candidate=R/'build/motion-supplement-candidates/android/app-debug.apk'; run(A,'-s','emulator-5588','install',str(candidate)); before={'candidate_sha256':sha(candidate),'package_dump':run(A,'-s','emulator-5588','shell','dumpsys','package',P)}
 samples=[]
 for n in range(4):
  label='preparation' if n==0 else f'sample-{n}'
  if platform=='ios':
   run('xcrun','simctl','terminate',D,I,check=False); began=time.monotonic(); launch=run('xcrun','simctl','launch',D,I); command_ms=(time.monotonic()-began)*1000; pid=int(launch.rsplit(':',1)[1].strip())
  else:
   run(A,'-s','emulator-5588','shell','am','force-stop',P); began=time.monotonic(); launch=run(A,'-s','emulator-5588','shell','am','start','-n',P+'/dev.pourlune.pourlune_dev.MainActivity'); command_ms=(time.monotonic()-began)*1000
   deadline=time.monotonic()+20;pid=0
   while time.monotonic()<deadline and not pid:
    value=run(A,'-s','emulator-5588','shell','pidof',P,check=False);pid=int(value.split()[0]) if value else 0;time.sleep(.05)
   assert pid
  deadline=time.monotonic()+100;data=None
  while time.monotonic()<deadline:
   if platform=='ios':
    paths=list(container.rglob(f'*-{pid}.json')); paths=[p for p in paths if p.parent.name=='motion-supplement'];raw=paths[0].read_text() if paths else ''
   else:
    raw=run(A,'-s','emulator-5588','shell','run-as',P,'cat',f'databases/motion-supplement/startup-{pid}.json',check=False)
    if not raw: raw=run(A,'-s','emulator-5588','shell','run-as',P,'cat',f'databases/motion-supplement/error-{pid}.json',check=False)
   if raw:
    data=json.loads(raw);break
   time.sleep(.1)
  assert data is not None, (platform,label,'no report')
  (out/f'{label}.json').write_text(json.dumps(data,indent=2));validate(data);assert data['pid']==pid
  data['host_launch_command_ms']=command_ms;data['host_command_includes_native_pre_dart_but_not_first_pixel']=True;data['counted_sample']=n>0;(out/f'{label}.json').write_text(json.dumps(data,indent=2))
  samples.append({'label':label,'pid':pid,'enabled_ms':data['home_enabled_hit_testable_us']/1000,'accepted_ms':data['first_accepted_committed_navigation_us']/1000,'host_launch_command_ms':command_ms});print(platform,label,'PASS',samples[-1],flush=True)
 if platform=='ios':
  after={'container':run('xcrun','simctl','get_app_container',D,I,'data'),'installed_kernel_sha256':sha(binary/'Frameworks/App.framework/flutter_assets/kernel_blob.bin'),'installed_info_sha256':sha(binary/'Info.plist')};assert after==before
  old_hash=sha(Path(inventory['ios']['old_fb_data'])/'Documents/flame_full_board.sqlite') if (Path(inventory['ios']['old_fb_data'])/'Documents/flame_full_board.sqlite').exists() else None
  if old_hash is None:
   files=list(Path(inventory['ios']['old_fb_data']).rglob('*.sqlite')); assert len(files)==1,files;old_hash=sha(files[0])
 else:
  after={'candidate_sha256':sha(candidate),'package_dump':run(A,'-s','emulator-5588','shell','dumpsys','package',P)}
  # Runtime state may differ; install identity/time/codePath must not.
  def stable(dump):return [s.strip() for s in dump.splitlines() if re.search(r'codePath=|firstInstallTime=|lastUpdateTime=|versionCode=',s)]
  assert stable(before['package_dump'])==stable(after['package_dump'])
  old_hash=run(A,'-s','emulator-5588','shell','run-as','dev.pourlune.pourlune_dev','sha256sum','databases/flame_full_board.sqlite').split()[0]
 assert old_hash==inventory[platform]['old_db_sha256'],(platform,old_hash)
 assert len({x['pid'] for x in samples})==4
 results[platform]={'before':before,'after':after,'samples':samples,'old_fb_db_unchanged':True};(E/'native-summary.json').write_text(json.dumps(results,indent=2))
print('MS01_BOTH_PLATFORMS_PASS',flush=True)
