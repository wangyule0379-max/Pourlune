import test from 'node:test';import assert from 'node:assert/strict';
import {AdObservationConsent} from '../web/ad-consent.mjs';
test('native observation permission is captured before work and cannot revive across a choice',()=>{
 let allowed=false;const sent=[],gate=new AdObservationConsent({allowed:()=>allowed});gate.attach(m=>sent.push(m));
 const live=()=>({replayed:false,adConsent:gate.snapshot()});const off=gate.capture(live());allowed=true;gate.changed();assert.equal(gate.permits(off),false);
 const on=gate.capture(live());assert.equal(gate.permits(on),true);allowed=false;gate.changed();allowed=true;gate.changed();assert.equal(gate.permits(on),false);assert.equal(sent.at(-1).allowed,true);
});
test('replays, missing native provenance and other document sessions never generate new metrics',()=>{
 const gate=new AdObservationConsent({allowed:()=>true});for(const event of [{},{replayed:true,adConsent:gate.snapshot()},{replayed:false,adConsent:{...gate.snapshot(),session:crypto.randomUUID()}},{replayed:false,adConsent:{...gate.snapshot(),allowed:false}}])assert.equal(gate.permits(gate.capture(event)),false);
 assert.equal(gate.permits(gate.capture({replayed:false,adConsent:gate.snapshot()})),true);assert.equal(gate.permits(gate.capture()),true);
});
import {GameServices} from '../web/services.mjs';
class SDK {constructor(config){this.enabled=config.statisticsEnabled;this.events=[];}start(){}getStorageStatus(){return 'ready';}setStatisticsEnabled(value){this.enabled=value;}trackAdEvent(type,context,event,level){this.events.push({type,context,event,level,enabled:this.enabled});}canShowAd(){return true;}dispose(){}}
test('late denied ordinary metrics are skipped and denied interstitial policy is retained without clearing valid SDK events',async()=>{
 const owner=new GameServices({SDK,platform:'ios',statisticsEnabled:true});await owner.ready;await owner.settle();
 const context={kind:'rewarded'},event={id:crypto.randomUUID(),occurredAt:new Date().toISOString()};
 assert.equal(await owner.observeAd('ad_impression',context,event,1,()=>false),true);assert.equal(owner.client.events.length,0);
 assert.equal(await owner.observeAd('ad_impression',{kind:'interstitial'},event,13,()=>false),false);assert.equal(owner.canShowAd('interstitial','next_level',13),false);assert.equal(owner.client.enabled,true);assert.equal(owner.client.events.length,0);
 await owner.revokeNow();assert.equal(await owner.observeAd('ad_impression',{kind:'interstitial'},event,13,()=>false),true);assert.equal(owner.client.events.length,1);assert.equal(owner.client.events[0].enabled,false);assert.equal(owner.canShowAd('interstitial','next_level',13),true);await owner.dispose();
});
test('per-observation official adapter can update policy without sharing or changing the global permission',async()=>{
 const records=[],owner=new GameServices({SDK,platform:'ios',statisticsEnabled:true,adObservationRecorder:async(client,type,context,event,level,share)=>records.push({type,event,share,enabled:client.enabled})});await owner.ready;await owner.settle();
 const event={id:crypto.randomUUID(),occurredAt:new Date().toISOString()};assert.equal(await owner.observeAd('ad_impression',{kind:'interstitial'},event,13,()=>false),true);assert.deepEqual(records,[{type:'ad_impression',event,share:false,enabled:true}]);assert.equal(owner.client.enabled,true);await owner.dispose();
});
