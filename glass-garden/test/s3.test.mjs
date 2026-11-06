import test from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {IDBFactory} from 'fake-indexeddb';
import {createCheckpoints} from '../qa/build-checkpoints.mjs';
import {openStore} from '../web/storage.mjs';
import {Product} from '../web/product-model.mjs';
import {pageView} from '../web/views.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js'),cases=createCheckpoints();
test('real-rule checkpoint last100 commits complete campaign with no101 and keeps all history',async()=>{
 const fixture=cases.find(c=>c.level===100),store=await openStore({indexedDB:new IDBFactory(),name:'final100'});await store.write(fixture.data,0);
 const model=new Product({store,R,P});assert.equal(await model.open(),true);const session=P.restore(R.LEVELS[99],model.state.gameProgress.slots[100]);assert.equal(session.moves,51);
 assert.ok(session.pour(...fixture.nextPour).ok);await model.capture(session,99,model.state.roundInstanceIds[100]);assert.equal(model.state.completedLevels.length,100);assert.equal(model.homeTarget(),null);assert.equal(await model.next(),false);
 const home=pageView('home',model.state,{R,targetLevel:model.homeTarget()});assert.match(home,/Play Again/);assert.match(home,/data-action="levels"/);assert.doesNotMatch(home,/Level 101/);assert.equal(Object.keys(model.state.gameProgress.slots).length,100);assert.equal(session.undo(),true);model.close();
});
test('tall collector and cover checkpoints keep real legal histories and Undo',()=>{
 for(const n of [16,39]){const fixture=cases.find(c=>c.level===n),session=P.restore(R.LEVELS[n-1],fixture.data.gameProgress.slots[n]),before=R.clone(session.state),m=session.pour(...fixture.nextPour);assert.equal(m.ok,true);if(n===16)assert.equal(session.state.bottles[session.state.collector].length,session.state.capacity);else assert.ok(m.unlocked.length);assert.equal(session.undo(),true);assert.equal(R.sameBoard(session.state,before),true);}
});
test('unavailable capabilities never overwrite explicit saved preferences on reopen or choice change',async()=>{
 const data=structuredClone(cases[0].data);data.prefs={music:true,sound:false,haptics:true,reduced:true};const store=await openStore({indexedDB:new IDBFactory(),name:'preferences'});await store.write(data,0);const model=new Product({store,R,P});await model.open();await model.chooseAnalytics('declined');assert.deepEqual(model.state.prefs,data.prefs);assert.deepEqual(model.state.gameProgress.slots,data.gameProgress.slots);model.close();
});
