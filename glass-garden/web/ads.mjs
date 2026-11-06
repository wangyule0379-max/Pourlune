import {modelAdConsent,observation} from './ad-consent.mjs';
const stages={load_requested:'ad_load_requested',blocked:'ad_blocked',loaded:'ad_loaded',load_failed:'ad_load_failed',impression:'ad_impression',reward:'ad_reward_earned',show_failed:'ad_show_failed'};
export class RewardedAds {
 constructor({model,consent=modelAdConsent(model),services,send,notify=()=>{},appVersion,gate={clock:{remaining:()=>0,shown(){}},owner:null}}){Object.assign(this,{model,consent,services,send,notify,appVersion,gate});this.active=true;this.phase='idle';this.chain=Promise.resolve();this.processed=new Set();this.observing=new Map();}
 async report(type,attempt,event,reason,stamp=this.consent.capture()){
  const first=observation(event);try{const owner=await this.services();if(!owner)return true;const context={kind:'rewarded',scene:'extra_bottle',provider:'admob',appVersion:this.appVersion,opportunityId:attempt.id,loadAttemptId:attempt.id,...(reason?{reason}:{})};if(owner.observeAd)return await owner.observeAd(type,context,first,attempt.level,()=>this.consent.permits(stamp));if(this.consent.permits(stamp))await owner.client.trackAdEvent(type,context,first,attempt.level);}catch{/* Statistics cannot prevent a legitimate game reward. */}return true;
 }
 async watch(){
  if(this.phase!=='idle'||!this.active||this.gate.owner||this.gate.clock.remaining()>0){this.notify('unavailable');return false;}this.gate.owner=this;
  this.phase='checking';const operation=this.operation=(this.operation||0)+1;this.notify('loading');
  let owner;try{owner=await this.services();await owner?.ready;}catch{}
  if(operation!==this.operation||!this.active)return false;
  if(!owner?.client.canShowAd('rewarded','extra_bottle',this.model.state.currentLevel)){this.phase='idle';this.gate.owner=null;this.notify('unavailable');return false;}
  const attempt=await this.model.prepareReward();
  if(operation!==this.operation||!this.active){if(attempt)await this.model.finishRewardAttempt(attempt.id);return false;}
  if(!attempt){this.phase='idle';this.gate.owner=null;this.notify(this.model.error?'save_failed':this.model.hasExtraBottle?.()?'received':'unavailable',{level:this.model.state.currentLevel});return false;}
  this.attempt=attempt;this.phase='loading';this.earned=false;this.shown=false;this.notify('loading');
  this.report('ad_opportunity',attempt);
  this.send({command:'load',attemptId:attempt.id});
  this.timer=setTimeout(()=>{if(['loading','presenting'].includes(this.phase)&&!this.shown)this.cancel('timeout');},120000);this.timer.unref?.();return true;
 }
 cancel(reason='unknown',{silent=false}={}){if(this.shown||!['checking','loading','presenting'].includes(this.phase))return false;this.operation=(this.operation||0)+1;clearTimeout(this.timer);if(['loading','presenting'].includes(this.phase)){this.send({command:'cancel',attemptId:this.attempt.id});this.report('ad_blocked',this.attempt,undefined,reason);this.model.finishRewardAttempt(this.attempt.id);this.model.finishFullscreen(this.attempt.id);}this.phase='idle';if(this.gate.owner===this)this.gate.owner=null;if(!silent)this.notify(reason==='timeout'?'unavailable':'cancelled');return true;}
 setActive(active){this.active=active;if(!active&&['checking','loading'].includes(this.phase))this.cancel('in_background');}
 receive(event){const stamp=this.consent.capture(event);this.chain=this.chain.then(()=>this.handle(event,stamp)).catch(()=>{});return this.chain;}
 async handle(event,stamp){
  if(this.model.recoveryError)return; // Retain native receipts until their original save can be read.
  if(!event||typeof event.id!=='string'||!Number.isFinite(Date.parse(event.occurredAt)))return;
  if(this.observing.has(event.id))return;
  if(this.processed.has(event.id)){this.send({command:'ack',eventId:event.id});return;}
  const attempt=this.model.working?.rewardAttempts?.[event.attemptId]||this.model.state.rewardAttempts?.[event.attemptId]||(this.attempt?.id===event.attemptId?this.attempt:null),current=this.attempt?.id===event.attemptId,observation={id:event.id,occurredAt:event.occurredAt};
  if(event.type==='shown'&&attempt){if(current){this.shown=true;clearTimeout(this.timer);}this.gate.clock.shown(Date.parse(event.occurredAt));if(!await this.model.recordFullscreen(attempt.id,event.occurredAt)&&this.model.error){this.notify('save_failed',attempt);return;}this.gate.clock.shown(this.model.working.fullscreen?.lastShownAt??Date.parse(event.occurredAt));if(current){this.shown=true;clearTimeout(this.timer);}}
  if(event.type==='reward'&&attempt){const ok=await this.model.grantReward(attempt.id);if(!ok&&this.model.error){this.notify('save_failed',attempt);return;}if(ok){const samePuzzle=this.attempt?.level===attempt.level&&this.attempt?.puzzleId===attempt.puzzleId;if(current||samePuzzle)this.earned=true;if(samePuzzle&&this.phase==='loading')this.cancel('not_ready',{silent:true});this.notify('reward',attempt);}}
  if(event.type==='loaded'&&current&&this.phase==='loading'){
   const operation=this.operation;let owner;try{owner=await this.services();}catch{}
   const permitted=()=>this.operation===operation&&this.attempt?.id===attempt.id&&this.phase==='loading'&&this.active&&!this.model.error&&!this.model.recoveryError&&this.gate.owner===this&&!this.model.hasExtraBottle?.(attempt.level)&&this.gate.clock.remaining()===0&&owner?.client.canShowAd('rewarded','extra_bottle',attempt.level);
   const prepared=permitted()&&await this.model.prepareFullscreen(attempt.id,'rewarded',attempt.level,attempt.roundId);
   if(prepared&&permitted()){this.phase='presenting';this.report('ad_show_attempted',attempt);this.send({command:'show',attemptId:attempt.id});this.notify('presenting');}
   else {if(prepared)await this.model.finishFullscreen(attempt.id);if(this.operation===operation&&this.phase==='loading')this.cancel(this.active?'not_ready':'in_background');}
  }
  if(['closed','load_failed','show_failed','cancelled','blocked'].includes(event.type)&&attempt){
   if(!await this.model.finishFullscreen(attempt.id)&&this.model.error){this.notify('save_failed',attempt);return;}
   if(!await this.model.finishRewardAttempt(attempt.id)&&this.model.error){this.notify('save_failed',attempt);return;}
   if(current&&this.attempt?.id===event.attemptId&&['loading','presenting'].includes(this.phase)){clearTimeout(this.timer);this.phase='idle';if(this.gate.owner===this)this.gate.owner=null;this.notify(this.earned?'received':event.type==='closed'?'unrewarded':'unavailable',attempt);}
  }
  if(event.type==='state'&&Array.isArray(event.busyAttemptIds))for(const a of Object.values(this.model.working?.rewardAttempts||this.model.state.rewardAttempts||{})){if(a.status==='prepared'&&!event.busyAttemptIds.includes(a.id)&&!await this.model.finishRewardAttempt(a.id)&&this.model.error){this.notify('save_failed',a);return;}}
  const finish=async()=>{
   if(stages[event.type]&&attempt){const failure=event.type.endsWith('failed')||event.type==='blocked';await this.report(stages[event.type],attempt,observation,failure?(['no_fill','network','timeout','privacy','busy','in_background','not_ready'].includes(event.reason)?event.reason:'sdk_error'):undefined,stamp);}
   this.processed.add(event.id);if(this.processed.size>256)this.processed.delete(this.processed.values().next().value);this.send({command:'ack',eventId:event.id});this.observing.delete(event.id);
  };
  const work=Promise.resolve().then(finish);this.observing.set(event.id,work);
 }
 async settleObservations(){await Promise.all([...this.observing.values()]);}
}
