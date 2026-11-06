import {cp,mkdir,readFile,rm,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {root,sha} from './verify.mjs';
const tag=process.argv[2];if(!tag||!/^[a-z0-9-]+$/.test(tag))throw Error('Supply a frozen candidate name');
const candidate=path.join(root,'build',tag),raw=await readFile(path.join(candidate,'artifact-manifest.json')),manifest=JSON.parse(raw);
for(const file of manifest.files){const data=await readFile(path.join(candidate,file.path));if(data.length!==file.bytes||sha(data)!==file.sha256)throw Error('Frozen file mismatch: '+file.path);}
for(const rel of ['native/android/app/src/main/assets/web','native/ios/Resources/Web']){
 const dest=path.join(root,rel);await rm(dest,{recursive:true,force:true});await mkdir(path.dirname(dest),{recursive:true});await cp(path.join(candidate,'web'),dest,{recursive:true});
 for(const file of manifest.files)if(sha(await readFile(path.join(dest,file.path.slice(4))))!==file.sha256)throw Error('Staged file mismatch: '+file.path);
}
const record={candidate:tag,manifestSha256:sha(raw),files:manifest.files.length,bytes:manifest.files.reduce((n,f)=>n+f.bytes,0),identity:'dev.pourlune.glassgarden.localqa',services:'not integrated'};
await mkdir(path.join(root,'build/native'),{recursive:true});await writeFile(path.join(root,'build/native/staged-web.json'),JSON.stringify(record,null,2)+'\n');console.log(JSON.stringify(record,null,2));
