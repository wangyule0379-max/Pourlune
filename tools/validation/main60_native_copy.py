import argparse,hashlib,json,plistlib,shutil,sqlite3,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--run',required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
if a.device not in ['63B0908A-15C4-4CE1-A1AC-7E8DD958A645','A4A83180-67E1-48B4-9BE8-D8DFFC387DFB']:raise SystemExit('explicit dedicated target required')
if a.device=='F9C16DE7-01D8-4740-B796-A3A2DB8C3265':raise SystemExit('F9 protected')
if a.out.exists():raise SystemExit('fresh output required')
bundle='dev.pourlune.parentNormalValidation';deadline=time.monotonic()+900
while time.monotonic()<deadline:
 r=subprocess.run(['xcrun','simctl','get_app_container',a.device,bundle,'data'],capture_output=True,text=True)
 if r.returncode==0:
  container=Path(r.stdout.strip());found=list(container.glob('Documents/main60-five-color-native/runtime.json'))
  if found:
   try:report=json.loads(found[0].read_text())
   except (ValueError,OSError):report={}
   if report.get('run')==a.run and report.get('status')=='evidence_ready':
    source=found[0].parent;a.out.mkdir(parents=True)
    for item in source.iterdir():
     if item.name!='copied' and item.is_file():shutil.copy2(item,a.out/item.name)
    db=container/'Documents/main60_five_color.sqlite'
    with sqlite3.connect(f'file:{db}?mode=ro',uri=True) as src,sqlite3.connect(a.out/'snapshot.sqlite') as dst:src.backup(dst)
    app=Path(subprocess.check_output(['xcrun','simctl','get_app_container',a.device,bundle,'app'],text=True).strip())
    assert plistlib.loads((app/'Info.plist').read_bytes())['CFBundleIdentifier']==bundle
    kernel=next(app.rglob('kernel_blob.bin'))
    sha=lambda q:hashlib.sha256(q.read_bytes()).hexdigest()
    meta={'run':a.run,'device':a.device,'bundle':bundle,'container':str(container),'runner_sha256':sha(app/'Runner'),'kernel_sha256':sha(kernel),'snapshot_sha256':sha(a.out/'snapshot.sqlite'),'source':'native test entrypoint delegates normal main/Bootstrap; not the separate normal-main binary'}
    (a.out/'host-copy.json').write_text(json.dumps(meta,indent=2)+'\n');(source/'copied').write_text(a.run)
    print(json.dumps(meta),flush=True);break
 time.sleep(.5)
else:raise SystemExit('current native evidence not ready before copy deadline')
