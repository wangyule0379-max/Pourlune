import test from 'node:test';import assert from 'node:assert/strict';import {IDBFactory} from 'fake-indexeddb';import {readFile} from 'node:fs/promises';
import {GameMunchiesClient} from '../.private-dependencies/gamemunchies-javascript/src/index.js';
import {GameServices} from '../web/services.mjs';import {recordAdObservation} from '../web/ad-observation-recorder.mjs';
for(const platform of ['ios','android'])test(`official0.3.1 ${platform}: denied policy ACK survives restart without new metrics or deleting legitimate same-ID retries`,async()=>{
 globalThis.indexedDB=new IDBFactory();let now=Date.now();const requests=[],config=JSON.parse(await readFile(new URL('fixtures/public-qa-config-v4.json',import.meta.url),'utf8'));config.platform=platform;
 const dependencies={browser:false,now:()=>now,setInterval:()=>0,clearInterval(){},fetch:async(url,init)=>{if(init.method==='POST'){requests.push(JSON.parse(init.body));return new Response('',{status:503});}return new Response(JSON.stringify(config),{status:200});}};
 const make=()=>new GameServices({SDK:GameMunchiesClient,adObservationRecorder:recordAdObservation,platform,statisticsEnabled:true,dependencies});let owner=make();
 const event={id:crypto.randomUUID(),occurredAt:new Date(now).toISOString()},denied={id:crypto.randomUUID(),occurredAt:event.occurredAt},attempt=crypto.randomUUID(),context={kind:'rewarded',scene:'extra_bottle',provider:'admob',appVersion:'0.1.0+11',opportunityId:attempt,loadAttemptId:attempt},policy={...context,kind:'interstitial',scene:'next_level'};
 try{await owner.ready;await owner.settle();await owner.client.refreshConfig();assert.equal(owner.canShowAd('interstitial','next_level',13),true);
  assert.equal(await owner.observeAd('ad_impression',context,event,13,()=>true),true);
  assert.equal(await owner.observeAd('ad_impression',policy,event,13,()=>false),true);
  assert.equal(await owner.observeAd('ad_impression',policy,denied,13,()=>false),true);
  assert.equal(owner.pendingAdPolicy.size,0);assert.equal(owner.client.getStorageStatus(),'persistent');assert.equal(owner.canShowAd('interstitial','next_level',13),false);
  await owner.dispose();owner=make();await owner.ready;await owner.settle();await owner.client.refreshConfig();assert.equal(owner.canShowAd('interstitial','next_level',13),false);
  now+=600000;await owner.client.flush();now+=600000;await owner.client.flush();assert.equal(owner.canShowAd('interstitial','next_level',13),true);
  const events=requests.flatMap(b=>b.events||[]),same=events.filter(e=>e.id===event.id);assert.ok(same.length>=2);assert.ok(same.every(e=>e.occurredAt===event.occurredAt&&e.ad.kind==='rewarded'));assert.equal(new Set(same.map(e=>e.installationId)).size,1);assert.equal(events.some(e=>e.id===denied.id),false);
  await owner.revokeNow();const count=requests.length;now+=600000;await owner.client.flush();assert.equal(requests.length,count);
 }finally{await owner.dispose();}
});
