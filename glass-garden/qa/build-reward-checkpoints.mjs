// Controlled receipt fixtures for visual/interaction QA, never a native ad pass.
import {mkdir,writeFile} from 'node:fs/promises';import {createRequire} from 'node:module';import {createHash} from 'node:crypto';
import {IDBFactory} from 'fake-indexeddb';import {openStore} from '../web/storage.mjs';import {Product,initialState,validateState} from '../web/product-model.mjs';import {createCheckpoints} from './build-checkpoints.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js'),original=createCheckpoints(),metadata=[];
await mkdir(new URL('../build/qa-reward/',import.meta.url),{recursive:true});
for(const n of [1,16,39,61,100]){
 let data;
 if([16,39,100].includes(n))data=structuredClone(original.find(c=>c.level===n).data);
 else if(n===1){data=initialState(R,P);data.roundInstanceIds[1]=crypto.randomUUID();P.capture(data.gameProgress,0,new R.Session(R.LEVELS[0]),{},R.LEVELS);}
 else {data=structuredClone(original.find(c=>c.level===100).data);data.currentLevel=n;data.completedLevels=data.completedLevels.filter(i=>i<n);data.gameProgress.completed=data.completedLevels.map(i=>i-1);for(const map of [data.roundInstanceIds,data.completionReceipts,data.gameProgress.slots])for(const key of Object.keys(map))if(Number(key)>=n)delete map[key];data.roundInstanceIds[n]=crypto.randomUUID();P.capture(data.gameProgress,n-1,new R.Session(R.LEVELS[n-1]),{},R.LEVELS);}
 data.analyticsChoice='declined';data.disclosureVersion=3;validateState(data,R,P);
 const store=await openStore({indexedDB:new IDBFactory(),name:'controlled-reward-'+n});await store.write(data,0);const model=new Product({store,R,P,policyVersion:3});if(!await model.open())throw Error('Fixture did not restore');
 const attempt=await model.prepareReward();if(!attempt||!await model.grantReward(attempt.id)||!await model.finishRewardAttempt(attempt.id))throw Error('Controlled reward did not commit');
 const saved=model.state,slot=saved.gameProgress.slots[n],solution=R.solve(slot.state,150000);if(solution.status!=='solved')throw Error('No verified continuation');
 const body=JSON.stringify(saved),name='checkpoint-'+n+'.json';await writeFile(new URL('../build/qa-reward/'+name,import.meta.url),body);
 metadata.push({level:n,scope:'controlled receipt, not AdMob callback',bottles:slot.state.bottles.length,moves:slot.moves,nextPour:solution.path[0],remainingPath:solution.path,bytes:Buffer.byteLength(body),sha256:createHash('sha256').update(body).digest('hex')});model.close();
}
await writeFile(new URL('../build/qa-reward/checkpoints.json',import.meta.url),JSON.stringify(metadata,null,2)+'\n');console.log(JSON.stringify(metadata.map(({remainingPath,...item})=>item),null,2));
