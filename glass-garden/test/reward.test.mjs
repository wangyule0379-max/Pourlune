import test from 'node:test';import assert from 'node:assert/strict';import {createRequire} from 'node:module';import {IDBFactory} from 'fake-indexeddb';import {openStore} from '../web/storage.mjs';import {Product,validateState} from '../web/product-model.mjs';
import {withExtraBottle,expandSlot} from '../web/extra-bottle.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js');
async function app(){const store=await openStore({indexedDB:new IDBFactory(),name:'reward'}),a=new Product({store,R,P});await a.open();await a.chooseAnalytics('declined');await a.enter(1);return a;}
test('reward is persisted before show and only its receipt adds one ordinary bottle; close is not reward',async()=>{
 const a=await app();assert.equal(typeof a.prepareReward,'function');const initial=structuredClone(a.state.gameProgress.slots[1]),attempt=await a.prepareReward();assert.ok(attempt.id);assert.deepEqual(a.state.gameProgress.slots[1],initial);assert.equal((await a.store.read()).data.rewardAttempts[attempt.id].puzzleId,attempt.puzzleId);
 await a.finishRewardAttempt(attempt.id);assert.deepEqual(a.state.gameProgress.slots[1],initial);assert.equal(await a.grantReward('unknown'),false);
 assert.equal(await a.grantReward(attempt.id),true);const slot=a.state.gameProgress.slots[1];assert.equal(slot.state.bottles.length,initial.state.bottles.length+1);assert.deepEqual(R.counts(slot.state),R.counts(initial.state));assert.equal(slot.state.collector,-1);const rev=a.revision;assert.equal(await a.grantReward(attempt.id),true);assert.equal(a.revision,rev);assert.equal(await a.prepareReward(),false);a.close();
});
test('reward survives Undo, Restart and process restore without resetting the puzzle entitlement',async()=>{
 const a=await app();const s=P.restore(a.activeLevel(1),a.state.gameProgress.slots[1]);s.pour(...R.solve(s.state,150000).path[0]);await a.capture(s,0);const before=structuredClone(a.state.gameProgress.slots[1]),round=a.state.roundInstanceIds[1],attempt=await a.prepareReward();await a.grantReward(attempt.id);
 const expanded=P.restore(a.activeLevel(1),a.state.gameProgress.slots[1]);assert.equal(expanded.history.length,before.history.length);assert.equal(expanded.undo(),true);assert.equal(expanded.state.bottles.length,before.state.bottles.length+1);await a.capture(expanded,0);await a.enter(1,{restart:true});assert.notEqual(a.state.roundInstanceIds[1],round);assert.equal(a.state.puzzleInstanceIds[1],attempt.puzzleId);assert.equal(a.state.gameProgress.slots[1].state.bottles.length,before.state.bottles.length+1);assert.equal(await a.prepareReward(),false);
 const b=new Product({store:a.store,R,P});assert.equal(await b.open(),true);assert.equal(b.activeLevel(1).emptyCount,R.LEVELS[0].emptyCount+1);assert.equal(await b.prepareReward(),false);b.close();
});
test('late reward targets the retained original puzzle, never a new replay or another current level',async()=>{
 const a=await app(),attempt=await a.prepareReward();const s=P.restore(a.activeLevel(1),a.state.gameProgress.slots[1]);for(const move of R.solve(s.state,150000).path)s.pour(...move);await a.capture(s,0);await a.enter(2);const two=structuredClone(a.state.gameProgress.slots[2]);assert.equal(await a.grantReward(attempt.id),true);assert.equal(a.state.currentLevel,2);assert.deepEqual(a.state.gameProgress.slots[2],two);await a.enter(1);assert.equal(a.state.gameProgress.slots[1].state.bottles.length,R.initialState(R.LEVELS[0]).bottles.length);assert.equal(await a.grantReward(attempt.id),false);assert.ok(await a.prepareReward());a.close();
});
test('aborted reward transaction keeps bottle and receipt pending together for one retry',async()=>{
 const a=await app(),attempt=await a.prepareReward(),before=structuredClone(a.state),write=a.store.write;a.store.write=()=>Promise.reject(Error('quota'));assert.equal(await a.grantReward(attempt.id),false);assert.deepEqual(a.state,before);assert.equal(a.pending.extraBottles[1].attemptId,attempt.id);assert.equal(a.pending.gameProgress.slots[1].state.bottles.length,before.gameProgress.slots[1].state.bottles.length+1);a.store.write=write;assert.equal(await a.retry(),true);assert.equal(await a.grantReward(attempt.id),true);validateState(a.state,R,P);a.close();
});
test('all100 fixed definitions stay byte-identical; expanded states preserve legal history, covers and collector',()=>{
 const frozen=JSON.stringify(R.LEVELS);
 for(const base of R.LEVELS){
  const level=withExtraBottle(base,R),s=new R.Session(base);let poured=false;
  for(let i=0;i<s.state.bottles.length&&!poured;i++)for(let j=0;j<s.state.bottles.length;j++)if(s.pour(i,j).ok){poured=true;break;}
  const progress={slots:{}};P.capture(progress,base.id-1,s,{},R.LEVELS);const slot=expandSlot(progress.slots[base.id]),restored=P.restore(level,slot);
  assert.ok(R.validState(slot.state,level),'valid expanded '+base.id);assert.deepEqual(restored.state,slot.state);assert.deepEqual(restored.history,slot.history);assert.equal(restored.moves,s.moves);assert.deepEqual(R.counts(restored.state),R.counts(s.state));assert.equal(level.emptyCount,base.emptyCount+1);assert.equal(level.layout.unit,base.layout.unit);
  if(poured){assert.ok(restored.undo());assert.ok(R.sameBoard(restored.state,R.initialState(level)));}
 }
 assert.equal(JSON.stringify(R.LEVELS),frozen);
});
test('rewarded ordinary, collector, covered and max15 boards solve using original moves and win rules',()=>{
 for(const n of [1,16,39,61,99,100]){const s=new R.Session(withExtraBottle(R.LEVELS[n-1],R)),solution=R.solve(s.state,150000);assert.equal(solution.status,'solved','hint '+n);for(const m of solution.path)assert.ok(s.pour(...m).ok);assert.ok(R.isSolved(s.state),'win '+n);if(n===100)assert.equal(s.state.bottles.length,15);}
});
test('every rewarded bottle has its own nonoverlapping lane; units and tall capacity stay unchanged',()=>{
 for(const base of R.LEVELS){const level=withExtraBottle(base,R),state=R.initialState(level),layout=R.layoutFor(level),normal=4*layout.unit+33;assert.equal(layout.slots.length,state.bottles.length);
  const boxes=layout.slots.map(([x,y],i)=>{const tall=i===state.collector;return {left:x-42,right:x+42,top:y-10,bottom:y+normal+(tall?Math.max(0,layout.span-1)*layout.unit*6:0)+10};});
  if(state.collector>=0){const [x,y]=layout.slots[state.collector],bottom=y+normal+Math.max(0,layout.span-1)*layout.unit*6;boxes.push({left:x-70,right:x+70,top:bottom+57,bottom:bottom+93});}
  for(let i=0;i<boxes.length;i++){const a=boxes[i];assert.ok(a.left>=0&&a.right<=480);for(let j=i+1;j<boxes.length;j++){const b=boxes[j];assert.ok(a.right<=b.left||a.left>=b.right||a.bottom<=b.top||a.top>=b.bottom,'overlap '+base.id+' '+i+'/'+j);}}
 }
});
