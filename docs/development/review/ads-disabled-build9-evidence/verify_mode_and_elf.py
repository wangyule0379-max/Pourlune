from pathlib import Path
import json,base64,struct,zipfile,re,hashlib,shlex
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'build/beta-candidates/0.5.0-9'
report={}
log=(BASE/'ios-ads-disabled-1/build.log').read_text()
expected={'POURLUNE_AD_MODE':'disabled','POURLUNE_AD_PLATFORM':'ios','POURLUNE_AD_NATIVE_ID':'com.pourlune.app','POURLUNE_AD_APP_ID':'ca-app-pub-3940256099942544~1458002511','POURLUNE_FIREBASE_ENV':'prod','POURLUNE_FIREBASE_NATIVE_READY':'true'}
decoded={}
for line in log.splitlines():
 if 'DART_DEFINES' not in line:continue
 for token in shlex.split(line):
  if not token.startswith('DART_DEFINES='):continue
  for value in token.split('=',1)[1].split(','):
   try: field=base64.b64decode(value).decode();key,content=field.split('=',1)
   except (ValueError,UnicodeError):continue
   if key in expected:decoded[key]=content
matched={k:decoded.get(k)==v for k,v in expected.items()}
assert all(matched.values())
assert 'lib/main.dart' in log and 'FIREBASE_ANALYTICS_WITHOUT_ADID' in log
report['ios_archive_expected_encoded_selection']=matched
report['ios_expected_selection']=expected
report['ios_normal_main_noadid_markers']=True
android_log=(BASE/'android-ads-disabled-1/build.log').read_text()
# Native guard JSON if present is an extra source; final mode is also corroborated by
# exact source, candidate args and platform-specific AOT units independently checked.
report['android_log_contains_disabled_selection']='"mode": "disabled"' in android_log
elf=[]
with zipfile.ZipFile(BASE/'android-ads-disabled-1/Pourlune-0.5.0-9-upload-signed.aab') as z:
 for n in z.namelist():
  if not (n.startswith('base/lib/') and n.endswith('.so')):continue
  b=z.read(n); assert b[:4]==b'\x7fELF';e='<' if b[5]==1 else '>'
  if b[4]==2:off=struct.unpack_from(e+'Q',b,32)[0];sz,num=struct.unpack_from(e+'HH',b,54);alignment_offset=48;fmt='Q'
  else:off=struct.unpack_from(e+'I',b,28)[0];sz,num=struct.unpack_from(e+'HH',b,42);alignment_offset=28;fmt='I'
  align=[struct.unpack_from(e+fmt,b,off+i*sz+alignment_offset)[0] for i in range(num) if struct.unpack_from(e+'I',b,off+i*sz)[0]==1]
  assert align and all(v>=16384 for v in align),n
  elf.append({'entry':n,'pt_load_alignment':align})
report['elf_static_alignment']=elf
report['real_device_16kb_test']=False
Path(__file__).with_name('mode-and-elf.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'ios_expected_selection':all(matched.values()),'android_guard_log_disabled_selection':report['android_log_contains_disabled_selection'],'elf_count':len(elf)}))
