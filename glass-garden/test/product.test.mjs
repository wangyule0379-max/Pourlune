import test from 'node:test';import assert from 'node:assert/strict';import {createRequire} from 'node:module';import {IDBFactory} from 'fake-indexeddb';import {openStore} from '../web/storage.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js');let Product;
try{({Product}=await import('../web/product-model.mjs'));}catch(e){if(e.code!=='ERR_MODULE_NOT_FOUND')throw e;}
async function app(name='game'){assert.equal(typeof Product,'function','persistent product coordinator is required');const store=await openStore({indexedDB:new IDBFactory(),name});const a=new Product({store,R,P});await a.open();return a;}
function solve(a){const session=P.restore(R.LEVELS[a.state.currentLevel-1],a.state.gameProgress.slots[a.state.currentLevel]);for(const m of R.solve(session.state,150000).path)session.pour(...m);return session;}
test('actual rules: replay1 Next retains unfinished2 board/history/round and Undo; restart replaces only2',async()=>{
 const a=await app();await a.chooseAnalytics('declined');await a.enter(1);await a.capture(solve(a),0);assert.deepEqual(a.state.completedLevels,[1]);await a.enter(2);
 const two=P.restore(R.LEVELS[1],a.state.gameProgress.slots[2]);two.pour(...R.solve(two.state,150000).path[0]);await a.capture(two,1);const before=structuredClone(a.state),id=before.roundInstanceIds[2];
 await a.enter(1);await a.capture(solve(a),0);await a.next();assert.equal(a.state.currentLevel,2);assert.equal(a.state.roundInstanceIds[2],id);assert.deepEqual(a.state.gameProgress.slots[2],before.gameProgress.slots[2]);
 const resumed=P.restore(R.LEVELS[1],a.state.gameProgress.slots[2]);assert.ok(resumed.undo());assert.equal(resumed.moves,0);await a.capture(resumed,1);await a.enter(2,{restart:true});assert.notEqual(a.state.roundInstanceIds[2],id);assert.equal(a.state.gameProgress.slots[2].moves,0);a.close();
});
test('new round commits once; resume/reload and rejected analytics never queue events',async()=>{
 const a=await app();assert.equal(await a.enter(1),false);await a.chooseAnalytics('declined');await a.enter(1);const id=a.state.roundInstanceIds[1];await a.enter(1);assert.equal(a.state.roundInstanceIds[1],id);assert.equal(a.state.analyticsChoice,'declined');assert.equal('events' in a.state,false);a.close();
});
test('save abort gates state transition and retry commits the same pending round',async()=>{
 const a=await app();await a.chooseAnalytics('declined');const old=structuredClone(a.state),write=a.store.write;let failed=true;a.store.write=(...v)=>failed?Promise.reject(Error('disk unavailable')):write(...v);
 assert.equal(await a.enter(1),false);assert.deepEqual(a.state,old);const id=a.pending.roundInstanceIds[1];assert.ok(a.error);failed=false;assert.equal(await a.retry(),true);assert.equal(a.state.roundInstanceIds[1],id);a.close();
});
test('completion receipt is atomic/idempotent and stale round callback cannot complete replacement',async()=>{
 const a=await app();await a.chooseAnalytics('allowed');await a.enter(1);const old=a.state.roundInstanceIds[1],done=solve(a);await a.enter(1,{restart:true});assert.equal(await a.capture(done,0,old),false);assert.deepEqual(a.state.completedLevels,[]);
 await a.capture(solve(a),0);const receipt=a.state.completionReceipts[1],revision=a.revision;await a.capture(solve(a),0);assert.equal(a.revision,revision,'duplicate completion checkpoint wrote again');assert.equal(a.state.completionReceipts[1],receipt);assert.deepEqual(a.state.completedLevels,[1]);assert.equal(a.homeTarget(),2);a.close();
});
test('malformed persisted slot blocks restore and replacement is explicit',async()=>{
 const a=await app();await a.chooseAnalytics('declined');await a.enter(1);const broken=structuredClone(a.state);broken.gameProgress.slots[1].history=[{nonsense:1}];await a.store.write(broken,a.revision);
 const b=new Product({store:a.store,R,P});await b.open();assert.ok(b.recoveryError);assert.equal(await b.enter(1),false);assert.equal(await b.replaceCorrupt(),true);assert.deepEqual(b.state.completedLevels,[]);assert.equal(b.state.analyticsChoice,'unasked');b.close();
});
test('locked levels cannot be entered; all100 has no101',async()=>{const a=await app();await a.chooseAnalytics('declined');assert.equal(await a.enter(40),false);assert.equal(a.state.currentLevel,1);a.state.currentLevel=100;assert.equal(await a.next(),false);a.close();});

test('inconsistent saved current pointer or detached round is retained as corruption',async()=>{for(const corrupt of [s=>s.gameProgress.current=99,s=>s.roundInstanceIds[2]='detached']){const a=await app();await a.chooseAnalytics('declined');await a.enter(1);const broken=structuredClone(a.state);corrupt(broken);await a.store.write(broken,a.revision);const b=new Product({store:a.store,R,P});assert.equal(await b.open(),false);assert.ok(b.recoveryError);assert.deepEqual((await a.store.read()).data,broken);b.close();}});

test('reopening nonempty product data preserves explicit settings and refusal',async()=>{const a=await app();await a.chooseAnalytics('declined');await a.enter(1);const session=P.restore(R.LEVELS[0],a.state.gameProgress.slots[1]);session.pour(...R.solve(session.state,150000).path[0]);await a.capture(session,0);await a.preference('sound',false);await a.preference('reduced',true);const before=structuredClone(a.state),b=new Product({store:a.store,R,P});assert.equal(await b.open(),true);assert.deepEqual(b.state,before);assert.equal(b.state.prefs.sound,false);assert.equal(b.state.analyticsChoice,'declined');assert.equal(P.restore(R.LEVELS[0],b.state.gameProgress.slots[1]).undo(),true);b.close();});

test('a rejected statistics observer cannot turn a committed game save into failure',async()=>{const a=await app();a.onCommit=async()=>{throw Error('statistics unavailable');};assert.equal(await a.chooseAnalytics('declined'),true);assert.equal(await a.enter(1),true);await Promise.resolve();assert.equal(a.error,null);assert.equal((await a.store.read()).data.roundInstanceIds[1],a.state.roundInstanceIds[1]);a.close();});
