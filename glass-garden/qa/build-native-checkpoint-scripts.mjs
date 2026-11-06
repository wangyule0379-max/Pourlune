import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {nativeCheckpoint} from './native-checkpoint.mjs';
const root=new URL('../build/qa/',import.meta.url),out=new URL('../build/qa-native-checkpoint/',import.meta.url);
const {cases}=JSON.parse(await readFile(new URL('checkpoints.json',root),'utf8'));
await mkdir(out,{recursive:true});
for(const level of [16,39,100,null]){
 let data=null;
 if(level!==null){const raw=await readFile(new URL(`checkpoint-${level}.json`,root));if(createHash('sha256').update(raw).digest('hex')!==cases.find(c=>c.level===level)?.sha256)throw Error('Checkpoint hash mismatch');data=JSON.parse(raw);}
 await writeFile(new URL(level===null?'restore.js':`import-${level}.js`,out),`(${nativeCheckpoint.toString()})(${JSON.stringify(data)}).then(result=>{console.log(result);location.reload();}).catch(error=>console.error(error));\n`);
}
console.log('Generated inspector-only scripts with verified checkpoint hashes; no device or save accessed.');
