from pathlib import Path
import hashlib,json,subprocess,sys,zipfile
root=Path.cwd(); out=root/'docs/development/review/beta-readiness-BR04-evidence'; e=root/'docs/development/evidence/beta-readiness/BR04'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
scope=json.loads((e/'scope-manifest.json').read_text())['author_files_sha256']
drift=[n for n,h in scope.items() if sha(root/n)!=h]
assert not drift,drift
site=json.loads((e/'public-site-package.json').read_text()); folder=Path(site['deploy_root'])
assert sorted(p.name for p in folder.iterdir())==sorted(site['allowed_files'])
assert sha(Path(site['zip']))==site['zip_sha256']
with zipfile.ZipFile(site['zip']) as z:
 assert z.testzip() is None
 assert sorted(z.namelist())==sorted(site['allowed_files'])
 for n,h in site['files_sha256'].items():
  assert sha(folder/n)==h and z.read(n)==(folder/n).read_bytes()
  if n.endswith('.html'):
   t=z.read(n).decode(); assert 'DRAFT' in t and 'noindex' in t
   assert not any(tag in t.lower() for tag in ['<script','<iframe','<form','<img'])
index=json.loads((root/'docs/development/evidence/beta-readiness/BR03/artifact-index.json').read_text())
artifacts=[]
for c in index['candidates']:
 assert sha(Path(c['path']))==c['sha256']
 artifacts.append({'platform':c['platform'],'sha256':c['sha256'],'unchanged':True})
probes=[]
base=[sys.executable,str(root/'tools/validation/beta_build.py'),'--platform','android']
variants=[['--support-url','http://public.org'],['--android-key-alias','pourlune-upload'],['--android-keystore',str(root/'build/missing-review-key'),'--android-key-alias','pourlune-upload','--android-store-password-file',str(root/'build/missing-review-pass'),'--android-certificate-sha256','A1'*32]]
for j,args in enumerate(variants):
 dest=root/f'build/br04-independent-refusal-{j}'
 assert not dest.exists()
 r=subprocess.run([*base,'--output',str(dest),*args],capture_output=True,text=True)
 assert r.returncode==1 and not dest.exists()
 probes.append({'case':j,'exit':r.returncode,'output_created':False,'error':json.loads(r.stderr)})
result={'scope_files_matched':len(scope),'public_zip_exact_three_draft_files':True,'old_candidates':artifacts,'actual_cli_refusals':probes,'private_keys_generated_or_read':False,'native_build_run_or_sign_performed':False,'device_operations':False}
(out/'independent-check.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
(out/'accepted-source-hashes.json').write_text(json.dumps({n:sha(root/n) for n in scope},indent=2)+'\n')
