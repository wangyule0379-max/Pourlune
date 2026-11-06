// Reproduction only: owns fake IndexedDB and intercepts every HTTP request.
// Never contact production/test servers or export a real installation ID.
import {createRequire} from 'node:module';import {IDBFactory} from 'fake-indexeddb';
import {GameMunchiesClient} from '../.private-dependencies/gamemunchies-javascript/src/index.js';
import {GameServices,serviceScope,statisticsAllowed} from '../web/services.mjs';import {RewardedAds} from '../web/ads.mjs';import {Product} from '../web/product-model.mjs';import {openStore} from '../web/storage.mjs';
const require=createRequire(import.meta.url),R=require('../web/game/src/rules.js'),P=require('../web/game/src/progress.js');globalThis.indexedDB=new IDBFactory();let now=Date.now(),release;const requests=[],held=new Promise(resolve=>release=resolve),store=await openStore({indexedDB:globalThis.indexedDB,name:'ad-consent-repro'}),model=new Product({store,R,P,policyVersion:3});let owner;
try{
 await model.open();await model.chooseAnalytics('declined');await model.enter(1);const attempt=await model.prepareReward();await model.prepareFullscreen(attempt.id,'rewarded',1,attempt.roundId);await model.recordFullscreen(attempt.id,new Date(now).toISOString());await model.finishFullscreen(attempt.id);await model.finishRewardAttempt(attempt.id);
 const scope=serviceScope('ios');await store.ackStatisticsReset(scope,model.state.analyticsResetToken);
 model.onCommit=(next,previous)=>held.then(o=>o.committed(next,previous));
 const ads=new RewardedAds({model,services:()=>held,send(){},appVersion:'0.1.0+8'}),event={id:crypto.randomUUID(),attemptId:attempt.id,type:'impression',occurredAt:new Date(now).toISOString(),replayed:false,adConsent:ads.consent.snapshot()};
 await ads.receive(event); // Native backlog observed while the saved choice is Off.
 await model.chooseAnalytics('allowed');
 const token=model.state.analyticsResetToken,ack=await store.readStatisticsResetAck(scope);
 owner=new GameServices({SDK:GameMunchiesClient,platform:'ios',policyVersion:3,statisticsEnabled:statisticsAllowed(model.state,3),pendingResetToken:token!==ack?token:null,acknowledgeReset:t=>store.ackStatisticsReset(scope,t),dependencies:{browser:false,now:()=>now,setInterval:()=>0,clearInterval(){},fetch:async(url,init)=>{if(init.method==='POST')requests.push(JSON.parse(init.body));return new Response('',{status:503});}}});
 release(owner);await owner.ready;await owner.settle();await ads.settleObservations();now+=600000;await owner.client.flush();
 const queued=requests.some(p=>(p.events||[]).some(e=>e.id===event.id));
 console.log(JSON.stringify({scope:'isolated in-memory QA; all HTTP intercepted',offNativeObservationQueuedAfterAllow:queued,rewardVerification:'not exercised in this impression-only repro',requiresOrdinaryMetricFix:queued,interstitialPolicyOnlyCapability:"separate release blocker; see SDK controlled regression"},null,2));
}finally{if(owner)await owner.dispose();model.close();}
