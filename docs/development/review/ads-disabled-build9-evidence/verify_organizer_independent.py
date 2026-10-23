"""Independent byte-diff and signing verification; no build/sign/upload/device use."""
from pathlib import Path
import datetime,hashlib,json,plistlib,struct,subprocess,zipfile,re
R=Path(__file__).resolve().parents[4];O=Path(__file__).resolve().parent
B=R/'build/beta-candidates/0.5.0-9/ios-ads-disabled-1'
OLD=B/'Pourlune-0.5.0-9.ipa'
NEW=R/'build/store-submission/0.5.0-9/ios-organizer-attempt-1/prepared-upload.ipa'
INSPECT=R/'build/store-submission/0.5.0-9/architecture-organizer-review'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(OLD)=='194ce45cfe31cd73259a05be9cde4f422624d60f721492a81867d5a1ee1abd74'
assert sha(NEW)=='7fd86c11a7cfc5053b1a96aa381134861e9aec0b8a75311adef25c189b51d117'
commands=[]
def run(name,args):
 p=subprocess.run([str(v) for v in args],capture_output=True,timeout=90)
 commands.append({'operation':name,'exit_code':p.returncode});assert p.returncode==0,(name,p.returncode)
 return p.stdout
# Leave headers, load commands, fat metadata and padding intact; mask only actual signature blobs.
def signature_ranges(blob,base=0):
 magic=blob[:4];ranges=[]
 if magic in (b'\xca\xfe\xba\xbe',b'\xca\xfe\xba\xbf'):
  wide=magic[-1]==0xbf;num=struct.unpack_from('>I',blob,4)[0]
  for i in range(num):
   off,size=struct.unpack_from('>QQ' if wide else '>II',blob,8+i*(32 if wide else 20)+8)
   assert 0<off<off+size<=len(blob)
   ranges+=signature_ranges(blob[off:off+size],base+off)
 else:
  assert magic==b'\xcf\xfa\xed\xfe'
  num,total=struct.unpack_from('<II',blob,16);pos=32
  for _ in range(num):
   kind,size=struct.unpack_from('<II',blob,pos);assert size>=8 and pos+size<=32+total
   if kind==0x1d:
    off,length=struct.unpack_from('<II',blob,pos+8);assert 32+total<=off<off+length<=len(blob)
    ranges.append((base+off,base+off+length))
   pos+=size
  assert pos==32+total
 assert ranges
 return ranges
prefix='Payload/Runner.app/';seal=prefix+'_CodeSignature/CodeResources'
with zipfile.ZipFile(OLD) as a,zipfile.ZipFile(NEW) as b:
 names=lambda z:{n for n in z.namelist() if not n.endswith('/')}
 assert b.testzip() is None and len(b.namelist())==len(set(b.namelist()))
 assert names(a)==names(b)
 assert all(not Path(n).is_absolute() and '..' not in Path(n).parts for n in names(b))
 diff=sorted(n for n in names(a) if a.read(n)!=b.read(n));assert len(diff)==9 and seal in diff
 checks={}
 for n in diff:
  if n==seal:continue
  x,y=a.read(n),b.read(n);assert len(x)==len(y);rs=signature_ranges(x);assert rs==signature_ranges(y)
  xx,yy=bytearray(x),bytearray(y)
  for start,end in rs:xx[start:end]=yy[start:end]=b'\0'*(end-start)
  assert xx==yy,n
  checks[n]={'bytes':len(x),'signature_blob_ranges':rs,'all_other_bytes_including_headers_equal':True}
 x,y=plistlib.loads(a.read(seal)),plistlib.loads(b.read(seal));assert x.keys()==y.keys()
 expected={n[len(prefix):] for n in checks if '/Frameworks/' in n}
 for k in x:
  if k in ('files','files2'):
   assert x[k].keys()==y[k].keys();assert {n for n in x[k] if x[k][n]!=y[k][n]}==expected
  else:assert x[k]==y[k]
 assert not any('.dSYM/' in n for n in names(b))
 if not INSPECT.exists():
  INSPECT.mkdir();run('extract_independent_copy',['ditto','-x','-k',NEW,INSPECT])
 for n in names(b):assert (INSPECT/n).read_bytes()==b.read(n),n
 info=plistlib.loads(b.read(prefix+'Info.plist'))
 assert (info['CFBundleIdentifier'],info['CFBundleVersion'],info['CFBundleShortVersionString'])==('com.pourlune.app','9','0.5.0')
 count=len(names(b))
app=INSPECT/'Payload/Runner.app'
run('new_codesign_deep_strict',['codesign','--verify','--deep','--strict',app])
ent=plistlib.loads(run('new_entitlements',['codesign','-d','--entitlements',':-',app]));oldent=plistlib.loads(run('accepted_entitlements',['codesign','-d','--entitlements',':-',B/'ipa-inspection/Payload/Runner.app']))
assert ent==oldent and ent['application-identifier']=='T7U878Z8H6.com.pourlune.app' and ent['get-task-allow'] is False
profile=plistlib.loads(run('actual_profile',['security','cms','-D','-i',app/'embedded.mobileprovision']))
assert profile['UUID']=='74a202b2-3b25-4e31-8fd4-0413bf15d486' and profile['ExpirationDate']>datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
certprefix=INSPECT/'public-signer-';run('extract_public_certificate',['codesign','-d','--extract-certificates='+str(certprefix),app])
pin=hashlib.sha1(Path(str(certprefix)+'0').read_bytes()).hexdigest().upper();assert pin=='13362E4AF31A860FA6B705DB5192AF78613F7A58'
uuids=[]
for p in (B/'ios-export/Runner.xcarchive/dSYMs').glob('*/Contents/Resources/DWARF/*'):
 binary=app/'Runner' if p.name=='Runner' else app/'Frameworks'/(p.name+'.framework')/p.name
 def uuid(path):return re.findall(r'UUID: ([A-Fa-f0-9-]+) \(([^)]+)\)',run('uuid_'+path.name,['xcrun','dwarfdump','--uuid',path]).decode())
 x,y=uuid(p),uuid(binary);assert x and x==y;uuids.append({'module':p.name,'uuid':x})
assert len(uuids)==5
candidate=json.loads((B/'candidate.json').read_text());assert all(sha(B/n)==h for n,h in candidate['files_sha256'].items())
report={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'accepted_ipa_sha256':sha(OLD),'organizer_ipa_sha256':sha(NEW),'file_entries':count,'unchanged_entries':count-len(diff),'signature_only_changed_entries':diff,'binary_checks':checks,'seal_change_only_changed_framework_hashes':True,'independent_extracted_tree_byte_equal':True,'identity':{'bundle':'com.pourlune.app','version':'0.5.0','build':'9'},'actual_signer_sha1':pin,'entitlements_equal':True,'profile_uuid':profile['UUID'],'dsym_matches':uuids,'accepted_candidate_files_unchanged':len(candidate['files_sha256']),'commands':commands,'upload_or_device_execution':False}
(O/'organizer-independent-final.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'result':'PASS','files':count,'signature_only_changes':len(diff),'commands':len(commands),'sha256':sha(NEW)}))
