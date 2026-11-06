import test from 'node:test';
import assert from 'node:assert/strict';
import {recordAdObservation} from '../web/ad-observation-recorder.mjs';
import {GameServices} from '../web/services.mjs';

const event={id:'original-receipt',occurredAt:'2026-11-07T00:00:00.000Z'};
const context={kind:'interstitial',scene:'next_level'};
test('official adapter routes a permitted observation once and denied impressions only to policy',async()=>{
 const calls=[],client={trackAdEvent:async(...args)=>{calls.push(['metric',...args]);return event.id;},recordInterstitialImpressionPolicy:async(...args)=>{calls.push(['policy',...args]);return event.id;},getStorageStatus:()=> 'persistent'};
 await recordAdObservation(client,'ad_impression',context,event,13,true);
 await recordAdObservation(client,'ad_impression',context,event,13,false);
 await recordAdObservation(client,'ad_closed',context,event,13,false);
 await recordAdObservation(client,'ad_impression',{kind:'rewarded'},event,13,false);
 assert.deepEqual(calls,[['metric','ad_impression',context,event,13],['policy','next_level',event,13]]);
 for(const status of ['unverified','memory','failed']){client.getStorageStatus=()=>status;for(const share of [false,true])await assert.rejects(recordAdObservation(client,'ad_impression',context,event,13,share),/not durably recorded/);}
});
test('failed official policy persistence retains the native receipt and gates interstitials until successful retry',async()=>{
 class SDK {constructor(){this.result='';this.storage='persistent';}start(){}getStorageStatus(){return this.storage;}canShowAd(){return true;}setStatisticsEnabled(){}dispose(){}async recordInterstitialImpressionPolicy(){if(this.result instanceof Error)throw this.result;return this.result;}}
 const owner=new GameServices({SDK,platform:'ios',statisticsEnabled:true,adObservationRecorder:recordAdObservation});
 try{await owner.ready;await owner.settle();
  for(const result of ['', 'different-receipt',new Error('write failed')]){owner.client.result=result;assert.equal(await owner.observeAd('ad_impression',context,event,13,()=>false),false);assert.equal(owner.canShowAd('interstitial','next_level',13),false);}
  owner.client.result=event.id;owner.client.storage='failed';assert.equal(await owner.observeAd('ad_impression',context,event,13,()=>false),false);
  owner.client.storage='persistent';assert.equal(await owner.observeAd('ad_impression',context,event,13,()=>false),true);assert.equal(owner.canShowAd('interstitial','next_level',13),true);
 }finally{await owner.dispose();}
});
