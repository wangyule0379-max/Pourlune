// Only controlled developer QA state. No production save or network writes.
import {mkdir,writeFile} from 'node:fs/promises';import {createRequire} from 'node:module';import {createHash} from 'node:crypto';
import {initialState,validateState} from '../web/product-model.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js'),metadata=[];
await mkdir(new URL('../build/qa-fullscreen/',import.meta.url),{recursive:true});
for(const n of [13,20]){
 const data=initialState(R,P);data.analyticsChoice='declined';data.disclosureVersion=3;data.prefs={music:false,sound:false,haptics:false,reduced:false};data.currentLevel=n;data.completedLevels=Array.from({length:n-1},(_,i)=>i+1);data.completionReceipts=Object.fromEntries(data.completedLevels.map(i=>[i,crypto.randomUUID()]));data.roundInstanceIds[n]=crypto.randomUUID();const session=new R.Session(R.LEVELS[n-1]),path=R.solve(session.state,150000).path;
 for(const move of path.slice(0,-1))if(!session.pour(...move).ok)throw Error('Invalid QA continuation');
 P.capture(data.gameProgress,n-1,session,{completed:data.completedLevels.map(i=>i-1)},R.LEVELS);validateState(data,R,P);
 const body=JSON.stringify(data);await writeFile(new URL('../build/qa-fullscreen/checkpoint-'+n+'.json',import.meta.url),body);metadata.push({level:n,moves:session.moves,lastPour:path.at(-1),bottles:session.state.bottles.length,bytes:Buffer.byteLength(body),sha256:createHash('sha256').update(body).digest('hex'),scope:'controlled first-clear fixture, not natural campaign or native ad'});
}
await writeFile(new URL('../build/qa-fullscreen/checkpoints.json',import.meta.url),JSON.stringify(metadata,null,2)+'\n');console.log(JSON.stringify(metadata,null,2));
