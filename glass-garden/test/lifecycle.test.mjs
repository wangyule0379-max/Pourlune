import test from 'node:test';import assert from 'node:assert/strict';import vm from 'node:vm';import {readFileSync,existsSync} from 'node:fs';
const path=new URL('../web/game-bridge.js',import.meta.url);
function bridge(){assert.ok(existsSync(path),'production lifecycle bridge is required');let handled=0,terminated=0,paused=0;const timers=new Set([42]);
 function Scene(){};Scene.prototype={bindUI(){},refresh(){},finishPour(){},select(){},undo(){},handleHint(){handled++;},clearHint(){},wake(){},rest(){},loadLevel(){}};
 const targets=[{disabled:false}];const host={blocked:()=>true,canRender:()=>false,gameProgress:()=>null,ready(){},boardChanged(){},hintStatus(){},closeSheet(){},capture:async()=>true};
 const worker=function(){this.terminate=()=>terminated++;};const elements=new Map();const el=id=>{if(!elements.has(id))elements.set(id,{setAttribute(){},style:{},disabled:false,hidden:false});return elements.get(id);};
 const context=vm.createContext({PourProgress:{load(){}},PourluneScene:Scene,parent:{GardenHost:host},window:{},document:{getElementById:el,querySelectorAll:selector=>selector.includes('bottle-targets')?targets:[]},Worker:worker,clearTimeout:id=>timers.delete(id),setTimeout(){},cc:{game:{pause(){paused++;}},director:{setNextDeltaTimeZero(){}}},console});vm.runInContext(readFileSync(path,'utf8'),context);return {scene:Object.create(Scene.prototype),host,timers,targets,get:()=>({handled,terminated,paused})};}
test('cancel terminates real bridge worker and invalidates late response',()=>{const h=bridge(),s=h.scene;s.hintTimer=42;s.hintRequest=7;s.searching=true;s.worker={terminate:()=>h.host.terminated=true};s.cancelHint();s.handleHint({id:7,status:'solved',path:[[0,1]]});assert.equal(h.host.terminated,true);assert.equal(h.timers.size,0);assert.equal(s.hintRequest,8);assert.equal(h.get().handled,0);});
test('child wake cannot resume engine under hidden parent/modal',()=>{const h=bridge();h.scene.wake();assert.equal(h.get().paused,1);});

// Run the unchanged game's real pour handler with only Cocos animation ports held.
// If persistence stays in animation completion, killing the animation loses this move.
import {createRequire} from 'node:module';import {IDBFactory} from 'fake-indexeddb';import {openStore} from '../web/storage.mjs';import {Product} from '../web/product-model.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js');
async function interrupted(lastMove,stale=false){
 const store=await openStore({indexedDB:new IDBFactory(),name:'interrupt'}),model=new Product({store,R,P});await model.open();await model.chooseAnalytics('declined');await model.enter(1);
 const session=P.restore(R.LEVELS[0],model.state.gameProgress.slots[1]),path=R.solve(session.state,150000).path;
 if(lastMove)for(const move of path.slice(0,-1))session.pour(...move);
 await model.capture(session,0);const before=session.moves;
 const action=()=>({easing(){return this;}}),cc={Scene:{extend:proto=>{function S(){}S.prototype=proto;return S;}},p:(x,y)=>({x,y}),moveTo:action,bezierTo:action,spawn:action,sequence:action,delayTime:action,actionTween:action,callFunc:action,easeSineInOut:action,easeSineOut:action,game:{pause(){}},director:{setNextDeltaTimeZero(){}}};
 const host={gameProgress:()=>model.state.gameProgress,roundId:n=>model.working.roundInstanceIds[n],capture:s=>model.capture(s.session,s.levelIndex),blocked:()=>false,canRender:()=>false,hintStatus(){}};
 const ctx=vm.createContext({PourRules:R,PourProgress:{...P},PourRender:{pourAngle:()=>.8,pourPose:home=>home},PourWaterAudio:{Sounds:function(){}},cc,parent:{GardenHost:host},document:{getElementById:()=>({hidden:false,style:{}}),querySelectorAll:()=>[]},location:{hash:''},clearTimeout(){},setTimeout(){},console});ctx.window=ctx;vm.runInContext(readFileSync(new URL('../web/game-runtime.js',import.meta.url),'utf8'),ctx);vm.runInContext(readFileSync(new URL('../web/game-bridge.js',import.meta.url),'utf8'),ctx);
 const s=Object.create(ctx.PourluneScene.prototype);Object.assign(s,{session,progress:model.state.gameProgress,levelIndex:0,_roundId:model.state.roundInstanceIds[1],selected:-1,busy:false,reduced:false,hintRequest:0,bottles:R.layoutFor(R.LEVELS[0]).slots.map(([x,y])=>({home:{x,y},w:84,h:216,liquidUnit:40,screen:()=>({x,y}),stopAllActions(){},setLocalZOrder(){},runAction(){}})),audio:{},refresh(){},say(){},runAction(){}});
 s.pour(...path[lastMove?path.length-1:0]);const callback=s.flow;await model.chain;
 assert.equal(model.state.gameProgress.slots[1].moves,before+1,'move did not commit before any animation callback');assert.equal(model.state.gameProgress.slots[1].history.length,before+1);
 if(lastMove){assert.deepEqual(model.state.completedLevels,[1]);assert.equal(model.state.completionReceipts[1],model.state.roundInstanceIds[1]);}
 if(stale){await model.enter(1,{restart:true});const fresh=structuredClone(model.state);s.finishPour(callback);await model.chain;assert.deepEqual(model.state,fresh,'late animation wrote old board into new round');}
 model.close();
}
test('interrupt before first pour animation finishes still restores committed action',()=>interrupted(false));
test('winning move completion commits before animation finish or late callbacks',()=>interrupted(true));

test('late animation callback from old round cannot replace restarted progress',()=>interrupted(true,true));

test('pending save preserves existing return-stage bottle queue but hidden parent blocks it',()=>{const h=bridge();h.scene.returning=true;h.host.canRender=()=>true;h.scene.refresh();assert.equal(h.targets[0].disabled,false,'return-stage target was locked by persistence');h.host.canRender=()=>false;h.scene.refresh();assert.equal(h.targets[0].disabled,true);});

test('late successful save feedback cannot target a restored session with the same round',async()=>{const h=bridge(),s=h.scene;let resolve,played=0;h.host.roundId=()=> 'same-round';h.host.canRender=()=>true;h.host.capture=()=>new Promise(done=>resolve=done);const state={};Object.assign(s,{flow:{state},_actionRound:'same-round',session:{state},levelIndex:0,_winSound:()=>played++});s.finishPour({state});s.session={state:{restored:true}};resolve(true);await Promise.resolve();await Promise.resolve();assert.equal(played,0,'old finish played win feedback in a restored session');});
test('the saved Win sheet can play its legitimate success cue even though board input is paused',async()=>{const h=bridge(),s=h.scene;let played=0;h.host.roundId=()=> 'current';h.host.canRender=()=>false;h.host.canPlayWin=()=>true;const state={};Object.assign(s,{flow:{state},_actionRound:'current',session:{state},levelIndex:0,_winSound:()=>played++});s.finishPour({state});await Promise.resolve();await Promise.resolve();assert.equal(played,1);});
