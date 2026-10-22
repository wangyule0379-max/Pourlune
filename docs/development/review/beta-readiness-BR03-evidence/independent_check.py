from pathlib import Path
import hashlib,json,subprocess,re,zipfile
root=Path.cwd(); out=root/'docs/development/review/beta-readiness-BR03-evidence'
e=root/'docs/development/evidence/beta-readiness/BR03'
sha=lambda b:hashlib.sha256(b).hexdigest()
i=json.loads((e/'artifact-index.json').read_text()); p=json.loads((e/'packaging-check.json').read_text())
results={'build_install_launch_upload_performed':False}
with zipfile.ZipFile(p['path']) as z:
 assert sha(Path(p['path']).read_bytes())==p['sha256']
 assert sorted(z.namelist())==sorted(p['members']); assert z.testzip() is None
 for n in z.namelist():
  b=z.read(n)
  if n!='README.md': assert b==(root/n).read_bytes(),n
  assert not re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----|AIza[0-9A-Za-z_-]{35}',b),n
  assert not re.search(r'\.(?:p12|p8|jks|keystore|mobileprovision)$|GoogleService-Info.plist|google-services.json',n),n
 results['zip']={'members':len(z.namelist()),'sha256':p['sha256'],'crc_and_repository_bytes_match':True,'secret_pattern_scan_clear':True,'scope':'curated docs only, not proof of universal secret absence'}
ios=i['candidates'][0]; ids=[]
with zipfile.ZipFile(ios['path']) as ipa:
 assert sha(Path(ios['path']).read_bytes())==ios['sha256']
 for s in ios['symbols']:
  b=Path(s['exported_binary']); member='Payload/'+str(b).split('/Payload/',1)[1]
  assert b.read_bytes()==ipa.read(member)
  read=lambda f: sorted(re.findall(r'UUID: ([A-Fa-f0-9-]+)',subprocess.check_output(['xcrun','dwarfdump','--uuid',str(f)],text=True)))
  a,c=read(s['path']),read(b); assert a and a==c==sorted(s['uuid'])
  ids.append({'symbol':Path(s['path']).parents[3].name,'uuid':a,'matches_actual_ipa_binary':True})
results['ios_symbols']=ids
android=i['candidates'][1]
with zipfile.ZipFile(android['path']) as z:
 assert sha(Path(android['path']).read_bytes())==android['sha256']
 assert not any(n.upper().endswith(('.RSA','.DSA','.EC')) and n.upper().startswith('META-INF/') for n in z.namelist())
 for s in android['symbols']:
  b=z.read(s['member']); assert sha(b)==s['sha256']
  if 'preserved_copy' in s: assert Path(s['preserved_copy']).read_bytes()==b
 results['android']={'embedded_symbols':len(android['symbols']),'exact_embedded_hashes_and_preserved_mapping_match':True,'unsigned':True}
results['source_counts']=[]
for c in i['candidates']:
 sources=json.loads(Path(c['source_manifest']).read_text()); assert len(sources)==394
 assert all(sha((root/n).read_bytes())==v for n,v in sources.items())
 results['source_counts'].append(len(sources))
(out/'independent-check.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
