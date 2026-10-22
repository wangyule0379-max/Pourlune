import json, os, signal, subprocess, sys, time
from pathlib import Path
root=Path('/Volumes/data/App Development/Pourlune')
platform=sys.argv[1]
driver=[str(root/'.venv/bin/python'),str(root/'tools/validation/flame_sample.py'),platform]
out=root/'docs/development/evidence/flame-sample'/platform
subprocess.run([*driver,'prepare-restore','--id','architecture-before-kill'],check=True)
before=json.loads((out/'architecture-before-kill.json').read_text())
assert before['pour_view']['stage']=='pour' and before['bottles']['motion'] is not None
assert before['bottles']['phase']=='clean'
assert before['bottles']['instance']==before['bottles']['saved']
old=before['pid']; killed_at=time.time_ns()
if platform=='ios':
 os.kill(old, signal.SIGKILL)
 subprocess.run(['xcrun','simctl','launch','9B172C50-E5CB-4F3F-8F16-0A3DB04F495D','dev.pourlune.pourluneDev'],check=True,capture_output=True)
else:
 adb=['/Users/wangyule/Library/Android/sdk/platform-tools/adb','-s','emulator-5584']
 subprocess.run([*adb,'shell','am','force-stop','dev.pourlune.pourlune_dev'],check=True,capture_output=True)
 empty=subprocess.run([*adb,'shell','pidof','dev.pourlune.pourlune_dev'],capture_output=True,text=True)
 assert not empty.stdout.strip()
 subprocess.run([*adb,'shell','am','start','-n','dev.pourlune.pourlune_dev/.MainActivity'],check=True,capture_output=True)
# QA response file appears only after real session and images are ready.
subprocess.run([*driver,'state','--id','architecture-after-kill'],check=True)
after=json.loads((out/'architecture-after-kill.json').read_text())
assert old != after['pid']
for key in ['bottles','patch']:
 for field in ['instance','saved','settings','first_clears','receipts','pieces','revealed']:
  assert before[key][field]==after[key][field], (key,field)
assert after['bottles']['motion'] is None and not after['bottles']['busy']
assert after['pour_view']['stage']=='idle' and after['pour_view']['paused']
proof={'ok':True,'same_install':True,'before_pid':old,'after_pid':after['pid'],'host_kill_unix_ns':killed_at,'kill':'SIGKILL' if platform=='ios' else 'am force-stop; pid absence checked','before_visual_elapsed_ms':before['pour_view']['elapsed_ms'],'exact_fields_compared':['instance','saved','settings','first_clears','receipts','pieces','revealed'],'restored_visual':'complete saved state, no resumed half-pour','reinstall_between':False}
(root/'docs/development/review/flame-sample-evidence'/('restore-'+platform+'.json')).write_text(json.dumps(proof,indent=2)+'\n')
print(json.dumps(proof))
