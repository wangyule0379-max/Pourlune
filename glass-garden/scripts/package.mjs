import {cp,mkdir,readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {root,files,sha,verify} from './verify.mjs';
import {policyContent} from '../web/views.mjs';
const tag=process.argv[2],includeSdk=process.argv.includes('--sdk'),includeAds=process.argv.includes('--ads'),copiedOnly=process.argv.includes('--copied-inputs-only');
if(includeAds&&!includeSdk)throw Error('Ads require the verified service SDK and connected notice');
if(!tag||!/^[a-z0-9][a-z0-9-]{0,63}$/.test(tag))throw Error('Supply a new candidate name, e.g. s2-r1');
if(copiedOnly&&(!tag?.startsWith('ci-')||includeSdk||includeAds))throw Error('Copied-input CI mode is only for ci- tags without private SDK or ads');
const checks=await verify({inputs:!copiedOnly}),out=path.join(root,'build',tag);
await mkdir(path.join(root,'build'),{recursive:true});
await mkdir(out); // Refuse to overwrite a frozen candidate.
await cp(path.join(root,'web'),path.join(out,'web'),{recursive:true,filter:src=>!src.endsWith('/src/samples.js')});
let sdk=null;
if(includeSdk){
 sdk=JSON.parse(await readFile(path.join(root,'sdk-manifest.json')));
 for(const [name,hash] of Object.entries(sdk.files)){const source=path.join(root,'.private-dependencies/gamemunchies-javascript',name);if(sha(await readFile(source))!==hash)throw Error('Private SDK source hash mismatch: '+name);}
 await cp(path.join(root,'.private-dependencies/gamemunchies-javascript'),path.join(out,'web/sdk/gamemunchies'),{recursive:true});
 const privacy=path.join(out,'web/privacy.html'),html=await readFile(privacy,'utf8');if(!html.includes(policyContent(false)))throw Error('Unknown static privacy template');await writeFile(privacy,html.replace(policyContent(false),policyContent(true,includeAds)));
}
const manifest=[];
for(const name of await files(path.join(out,'web'))){const data=await readFile(path.join(out,'web',name));manifest.push({path:'web/'+name,bytes:data.length,sha256:sha(data)});}
const record={stage:tag.split('-')[0].toUpperCase()+' representative web pages; not native/SDK/store acceptance',tag,nativeBridgeVersion:4,ads:includeAds?'official_test':null,sdk:sdk?{version:sdk.version,archiveSha256:sdk.archive_sha256,sourceCommit:sdk.source_commit}:null,createdAt:new Date().toISOString(),checks,sourceManifestSha256:sha(await readFile(path.join(root,'source-manifest.json'))),files:manifest};
await writeFile(path.join(out,'artifact-manifest.json'),JSON.stringify(record,null,2)+'\n');
console.log(JSON.stringify({candidate:out,files:manifest.length,bytes:manifest.reduce((n,f)=>n+f.bytes,0),manifestSha256:sha(Buffer.from(JSON.stringify(record,null,2)+'\n'))},null,2));
