import {cp,mkdir,readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {root,files,sha,verify} from './verify.mjs';
const tag=process.argv[2];
if(!tag||!/^[a-z0-9][a-z0-9-]{0,63}$/.test(tag))throw Error('Supply a new candidate name, e.g. s2-r1');
const checks=await verify({inputs:true}),out=path.join(root,'build',tag);
await mkdir(path.join(root,'build'),{recursive:true});
await mkdir(out); // Refuse to overwrite a frozen candidate.
await cp(path.join(root,'web'),path.join(out,'web'),{recursive:true,filter:src=>!src.endsWith('/src/samples.js')});
const manifest=[];
for(const name of await files(path.join(out,'web'))){const data=await readFile(path.join(out,'web',name));manifest.push({path:'web/'+name,bytes:data.length,sha256:sha(data)});}
const record={stage:tag.split('-')[0].toUpperCase()+' representative web pages; not native/SDK/store acceptance',tag,createdAt:new Date().toISOString(),checks,sourceManifestSha256:sha(await readFile(path.join(root,'source-manifest.json'))),files:manifest};
await writeFile(path.join(out,'artifact-manifest.json'),JSON.stringify(record,null,2)+'\n');
console.log(JSON.stringify({candidate:out,files:manifest.length,bytes:manifest.reduce((n,f)=>n+f.bytes,0),manifestSha256:sha(Buffer.from(JSON.stringify(record,null,2)+'\n'))},null,2));
