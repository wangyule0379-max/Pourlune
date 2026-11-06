import {cp,mkdir,readFile,rm,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {root,sha} from './verify.mjs';
const tag=process.argv[2],production=process.argv.includes('--production'),argument=name=>process.argv[process.argv.indexOf(name)+1],version=production?argument('--version'):null,buildNumber=production?argument('--build-number'):null;
if(production&&(!process.argv.includes('--version')||!process.argv.includes('--build-number')||!/^[0-9]+[.][0-9]+[.][0-9]+$/.test(version)||!/^[1-9][0-9]{0,8}$/.test(buildNumber)))throw Error('Production staging requires explicit store-verified --version and --build-number');if(!tag||!/^[a-z0-9-]+$/.test(tag))throw Error('Supply a frozen candidate name');
const candidate=path.join(root,'build',tag),raw=await readFile(path.join(candidate,'artifact-manifest.json')),manifest=JSON.parse(raw);
if(production&&(!manifest.checks.inputsVerified||!manifest.sdk||manifest.ads!=='official_test'))throw Error('Production staging requires verified original inputs, fixed SDK and official test ads');
for(const file of manifest.files){const data=await readFile(path.join(candidate,file.path));if(data.length!==file.bytes||sha(data)!==file.sha256)throw Error('Frozen file mismatch: '+file.path);}
for(const rel of ['native/android/app/src/main/assets/web','native/ios/Resources/Web']){
 const dest=path.join(root,rel);await rm(dest,{recursive:true,force:true});await mkdir(path.dirname(dest),{recursive:true});await cp(path.join(candidate,'web'),dest,{recursive:true});
 for(const file of manifest.files)if(sha(await readFile(path.join(dest,file.path.slice(4))))!==file.sha256)throw Error('Staged file mismatch: '+file.path);
}
const record={candidate:tag,manifestSha256:sha(raw),files:manifest.files.length,bytes:manifest.files.reduce((n,f)=>n+f.bytes,0),identity:production?'com.pourlune.app':'dev.pourlune.glassgarden.localqa',serviceTarget:production?'production':'test',version,buildNumber,nativeBridgeVersion:manifest.nativeBridgeVersion||1,ads:manifest.ads||null,services:manifest.sdk?'official JS SDK'+manifest.sdk.version+' staged; explicit native QA flag required':'not integrated'};
await mkdir(path.join(root,'build/native'),{recursive:true});await writeFile(path.join(root,'build/native/staged-web.json'),JSON.stringify(record,null,2)+'\n');console.log(JSON.stringify(record,null,2));
