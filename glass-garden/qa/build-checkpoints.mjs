// Actual rule replay fixtures, never distributed in the player package.
import {mkdir,writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {initialState,validateState} from '../web/product-model.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js');
export function createCheckpoints(){
const completed=[],cases=[];
for(let n=1;n<=100;n++){
 const level=R.LEVELS[n-1],session=new R.Session(level),solution=R.solve(session.state,150000);
 if(solution.status!=='solved'||!solution.path.length)throw Error('No verified replay for '+n);
 for(let k=0;k<solution.path.length;k++){
  const before=R.clone(session.state),history=structuredClone(session.history),known=session.known?.slice(),moves=session.moves;
  const result=session.pour(...solution.path[k]);if(!result.ok)throw Error('Illegal replay '+n+':'+k);
  const collectorFull=n===16&&before.bottles[before.collector].length<before.capacity&&session.state.bottles[before.collector].length===before.capacity;
  const opensCover=n===39&&result.unlocked?.length&&!cases.some(c=>c.level===39);
  const finalMove=n===100&&k===solution.path.length-1;
  if(collectorFull||opensCover||finalMove){
   const data=initialState(R,P);data.currentLevel=n;data.group=Math.floor((n-1)/10);data.analyticsChoice='declined';
   for(let i=0;i<completed.length;i++){const id='qa-s3-round-'+(i+1);data.roundInstanceIds[i+1]=id;data.completionReceipts[i+1]=id;data.completedLevels.push(i+1);data.gameProgress.slots[i+1]=structuredClone(completed[i]);}
   const pending=new R.Session(level);Object.assign(pending,{state:before,history,moves,known});data.roundInstanceIds[n]='qa-s3-round-'+n;
   P.capture(data.gameProgress,n-1,pending,{sound:true,reduced:false,completed:data.completedLevels.map(i=>i-1)},R.LEVELS);
   validateState(data,R,P);
   cases.push({level:n,reason:collectorFull?'last pink pour fills tall collector':opensCover?'next actual pour opens first cover':'actual last winning pour of level100',nextPour:solution.path[k],remainingPath:solution.path.slice(k),data});
  }
 }
 if(!R.isSolved(session.state))throw Error('Replay did not solve '+n);
 const progress=P.load(null,null);P.capture(progress,n-1,session,{sound:true,reduced:false,completed:[]},R.LEVELS);completed.push(progress.slots[n]);
}
if(cases.length!==3)throw Error('Expected exactly three representative checkpoints');
return cases;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
const cases=createCheckpoints();
await mkdir(new URL('../build/qa/',import.meta.url),{recursive:true});
const metadata=[];
for(const entry of cases){const body=JSON.stringify(entry.data),name='checkpoint-'+entry.level+'.json';await writeFile(new URL('../build/qa/'+name,import.meta.url),body);metadata.push({level:entry.level,reason:entry.reason,nextPour:entry.nextPour,remainingPath:entry.remainingPath,moves:entry.data.gameProgress.slots[entry.level].moves,completed:entry.data.completedLevels.length,bytes:Buffer.byteLength(body),sha256:createHash('sha256').update(body).digest('hex')});}
await writeFile(new URL('../build/qa/checkpoints.json',import.meta.url),JSON.stringify({source:'100 real-rule solutions replayed; no source/save edits',cases:metadata},null,2)+'\n');
console.log(JSON.stringify(metadata,null,2));
}
