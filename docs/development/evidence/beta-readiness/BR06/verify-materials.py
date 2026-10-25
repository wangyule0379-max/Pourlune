from pathlib import Path
import hashlib,json,zipfile,plistlib,subprocess,sys,re,html.parser,urllib.request,urllib.parse
R=Path.cwd();B=R/'docs/development/evidence/beta-readiness/BR06'
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return h.hexdigest()
def load(p):return json.loads(p.read_text())
class Html(html.parser.HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=set();self.tags=[];self.attrs=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs);self.tags.append(tag);self.attrs.append(a)
  if 'id' in a:self.ids.add(a['id'])
  if tag=='a':self.links.append(a.get('href'))
report={'no_runtime_or_device_operations':True}
site=R/'docs/support/pages-site';assert sorted(x.name for x in site.iterdir())==['.nojekyll','index.html','privacy.html']
sitechecks={}
for p in site.glob('*.html'):
 text=p.read_text();d=Html();d.feed(text)
 assert not set(d.tags)&{'script','form','iframe','video','audio','img','input','object','embed','link'}
 assert not any(s in text for s in ['DRAFT','pending approval','verification required','decision required','example.com','LOCAL REVIEW','TODO'])
 assert 'width=device-width,initial-scale=1' in text and '@media(max-width:400px)' in text and 'min-height:44px' in text
 for link in d.links:
  if link.startswith('#'):assert link[1:] in d.ids
  elif link.startswith('https://'):pass
  elif link.startswith('mailto:'):assert link=='mailto:wangyule0379@gmail.com'
  else:assert (site/link).is_file()
 assert 'changjiang li' in text and 'mailto:wangyule0379@gmail.com' in d.links
 sitechecks[p.name]={'sha256':sha(p),'links_valid':True,'active_collection_elements_absent':True,'mobile_css_static_check':True}
report['site']=sitechecks
report['copy']=load(B/'copy-checks.json')
# Match directly evidenced licensed/synthesized copies, without refreshing asset manifests.
font=R/'docs/design/production-candidates/fonts/nunito';runtime=R/'app/assets/fonts/nunito'
report['font_copies']={p.name:sha(p)==sha(runtime/p.name) for p in font.iterdir() if p.is_file()};assert all(report['font_copies'].values())
audio=R/'docs/design/production-candidates/audio';report['audio_copies']={p.name:sha(p)==sha(R/'app/assets/audio'/p.name) for p in audio.glob('*.wav')};assert len(report['audio_copies'])==6 and all(report['audio_copies'].values())
# Keep historical artifacts intact.
old={R/'build/beta-candidates/0.5.0-5/ios-br01-3/Pourlune-0.5.0-5.ipa':'0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5',R/'build/beta-candidates/0.5.0-5/android-br01-3/app-release-unsigned.aab':'ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90',R/'build/beta-candidates/0.5.0-5/android-br05-sign-1/Pourlune-0.5.0-5-upload-signed.aab':'5016d22d030414dfbf3c9a84f59327badddb3d82cac1719df36c967e97593caa',R/'build/beta-owner-assisted/BR04/support-site-draft.zip':'0de74b755aa67590e542d238074225d7d5e990d89763812fc85bb24161a97ac2'}
report['old_frozen_hashes']={str(p.relative_to(R)):sha(p)==s for p,s in old.items()};assert all(report['old_frozen_hashes'].values())
base=R/'build/beta-candidates/0.5.0-6';candidates={p:load(base/f'{p}-br06-1/candidate.json') for p in ['android','ios']}
report['new_candidates']={}
for platform,c in candidates.items():
 assert c['build_number']==6 and c['version']=='0.5.0' and c['identity']=='com.pourlune.app' and c['ads']=='disabled' and not c['production_run_or_upload']
 assert c['public_destinations']=={'support_url':'https://wangyule0379-max.github.io/pourlune-support/','privacy_url':'https://wangyule0379-max.github.io/pourlune-support/privacy.html','feedback_email':'wangyule0379@gmail.com','ready':True}
 d=base/f'{platform}-br06-1';sources=load(d/'sources.json');assert all(sha(R/n)==s for n,s in sources.items())
 artifact=d/('Pourlune-0.5.0-6.ipa' if platform=='ios' else 'Pourlune-0.5.0-6-upload-signed.aab')
 observed=sha(artifact);assert c['files_sha256'][artifact.name]==observed
 (B/f'{platform}-candidate.json').write_text(json.dumps(c,indent=2)+'\n')
 report['new_candidates'][platform]={'path':str(artifact.relative_to(R)),'sha256':observed,'bytes':artifact.stat().st_size,'sources':len(sources),'source_manifest_sha256':sha(d/'sources.json'),'source_matches_current':True}
 with zipfile.ZipFile(artifact) as z:
  if platform=='ios':
   info=plistlib.loads(z.read('Payload/Runner.app/Info.plist'));assert info['CFBundleVersion']=='6' and info['CFBundleDisplayName']=='Pourlune' and info['CFBundleIdentifier']=='com.pourlune.app'
   names=[n for n in z.namelist() if n.endswith('PrivacyInfo.xcprivacy')];report['ios_privacy_manifests']=len(names)
   compiled=z.read('Payload/Runner.app/Frameworks/App.framework/App');prefix='Payload/Runner.app/Frameworks/App.framework/flutter_assets/'
   report['ios_minimum']=info['MinimumOSVersion'];report['ios_device_family']=info['UIDeviceFamily']
  else:
   compiled=z.read('base/lib/arm64-v8a/libapp.so');prefix='base/assets/flutter_assets/'
  destinations=c['public_destinations'];report[platform+'_destination_strings']={k:v.encode() in compiled for k,v in destinations.items() if k!='ready'};assert all(report[platform+'_destination_strings'].values())
  artnames=[n for n in z.namelist() if n.startswith(prefix+'assets/') and not n.endswith('/')]
  assert len(artnames)==136
  assert all(z.read(n)==(R/'app'/urllib.parse.unquote(n.removeprefix(prefix))).read_bytes() for n in artnames)
  report[platform+'_assets']={'count':len(artnames),'puzzles':len([n for n in artnames if '/puzzles/' in n]),'all_match_source':True}
  report[platform+'_notices_sha256']=hashlib.sha256(z.read(prefix+'NOTICES.Z')).hexdigest()
# Same native payload between signed and unsigned build6, metadata excluded.
u=base/'android-br06-1/app-release-unsigned.aab';s=base/'android-br06-1/Pourlune-0.5.0-6-upload-signed.aab'
with zipfile.ZipFile(u) as a,zipfile.ZipFile(s) as b:
 an={n for n in a.namelist() if not n.startswith('META-INF/') and not n.endswith('/')};bn={n for n in b.namelist() if not n.startswith('META-INF/') and not n.endswith('/')};assert an==bn and all(a.read(n)==b.read(n) for n in an)
 report['signed_unsigned_payload_entries_equal']=len(an)
 symbols=[n for n in an if 'debugsymbols/' in n or n.endswith('proguard.map')];report['android_symbols']={n:hashlib.sha256(b.read(n)).hexdigest() for n in symbols}
# Public cert pin already checked by real builder, no private key is opened by this collector.
report['android_signing']=load(base/'android-br06-1/signing.json');report['ios_signing']=load(base/'ios-br06-1/signing.json')
(B/'delivery-checks.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'checks':'passed','candidates':report['new_candidates'],'assets_each':136,'font_audio_copies':True,'old_frozen_unchanged':True},indent=2))
