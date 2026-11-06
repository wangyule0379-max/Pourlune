import {readFile,readdir,stat} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
export const root=fileURLToPath(new URL('../',import.meta.url));
export const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
export async function files(dir,prefix=''){
 const found=[];for(const name of (await readdir(dir)).sort()){const rel=prefix+name,p=path.join(dir,name);if((await stat(p)).isDirectory())found.push(...await files(p,rel+'/'));else found.push(rel);}return found;
}
export async function verify({inputs=false}={}){
 const ledger=JSON.parse(await readFile(path.join(root,'source-manifest.json'))),errors=[];
 for(const item of ledger.original_manifest.files){
  if(inputs&&sha(await readFile(item.source))!==item.sha256)errors.push('Changed source: '+item.source);
  if(!ledger.modified_copy_wiring.includes(item.copy)&&sha(await readFile(path.join(root,item.copy.startsWith('game/')?'web':'',item.copy)))!==item.copy_sha256)errors.push('Changed copied source: '+item.copy);
 }
 if(inputs)for(const [name,hash] of Object.entries(ledger.prototype_inputs))if(sha(await readFile(path.join(ledger.prototype_root,name)))!==hash)errors.push('Changed prototype input: '+name);
 const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js');
 if(R.LEVELS.length!==100||R.LEVELS.some((level,i)=>level.id!==i+1))errors.push('Campaign is not the fixed 100 levels');
 const html=await readFile(path.join(root,'web/index.html'),'utf8'),loader=await readFile(path.join(root,'web/game-loader.js'),'utf8');
 if(!html.includes("connect-src 'self'")||!html.includes('product.mjs')||html.includes('dev.html'))errors.push('Unexpected player entry');
 if(!loader.includes("history.replaceState(null,''")||!loader.includes('parent.GardenHost'))errors.push('Game must only start through product host');
 const project=JSON.parse(await readFile(path.join(root,'web/game/project.json')));
 if(project.jsList.includes('src/samples.js')||project.jsList.at(-1)!=='../game-bridge.js')errors.push('Unexpected game script wiring');
 for(const name of ['privacy.html','licenses.html'])await stat(path.join(root,'web',name));
 if(errors.length)throw Error(errors.join('\n'));
 return {sourceFiles:ledger.original_manifest.files.length,coreFilesPreserved:ledger.source_core_preservation.length,campaignLevels:R.LEVELS.length,inputsVerified:inputs,webFiles:(await files(path.join(root,'web'))).length};
}
if(process.argv[1]===fileURLToPath(import.meta.url))console.log(JSON.stringify(await verify({inputs:process.argv.includes('--inputs')}),null,2));
