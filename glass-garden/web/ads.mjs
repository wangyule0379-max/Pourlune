const stages={loaded:'ad_loaded',load_failed:'ad_load_failed',impression:'ad_impression',reward:'ad_reward_earned',show_failed:'ad_show_failed'};
export class RewardedAds {
 constructor({model,services,send,notify=()=>{},appVersion}){Object.assign(this,{model,services,send,notify,appVersion});this.active=true;this.phase='idle';this.chain=Promise.resolve();this.processed=new Set();this.observing=new Map();}
 async report(type,attempt,event,reason){try{const owner=await this.services();if(!owner)return;const context={kind:'rewarded',scene:'extra_bottle',provider:'admob',appVersion:this.appVersion,opportunityId:attempt.id,loadAttemptId:attempt.id,...(reason?{reason}:{})};await owner.client.trackAdEvent(type,context,event,attempt.level);}catch{/* Statistics cannot prevent a legitimate game reward. */}}
 async watch(){
  if(this.phase!=='idle'||!this.active)return false;
  this.phase='checking';const operation=this.operation=(this.operation||0)+1;this.notify('loading');
  let owner;try{owner=await this.services();await owner?.ready;}catch{}
  if(operation!==this.operation||!this.active)return false;
  if(!owner?.client.canShowAd('rewarded','extra_bottle')){this.phase='idle';this.notify('unavailable');return false;}
  const attempt=await this.model.prepareReward();
  if(operation!==this.operation||!this.active){if(attempt)await this.model.finishRewardAttempt(attempt.id);return false;}
  if(!attempt){this.phase='idle';this.notify(this.model.error?'save_failed':'unavailable');return false;}
  this.attempt=attempt;this.phase='loading';this.earned=false;this.notify('loading');
  this.report('ad_opportunity',attempt);this.report('ad_load_requested',attempt);
  this.send({command:'load',attemptId:attempt.id});
  this.timer=setTimeout(()=>{if(this.phase==='loading')this.cancel('timeout');},120000);this.timer.unref?.();return true;
 }
 cancel(reason='unknown'){if(!['checking','loading'].includes(this.phase))return false;this.operation=(this.operation||0)+1;clearTimeout(this.timer);if(this.phase==='loading'){this.send({command:'cancel',attemptId:this.attempt.id});this.report('ad_blocked',this.attempt,undefined,reason);this.model.finishRewardAttempt(this.attempt.id);}this.phase='idle';this.notify(reason==='timeout'?'unavailable':'cancelled');return true;}
 setActive(active){this.active=active;if(!active&&['checking','loading'].includes(this.phase))this.cancel('in_background');}
 receive(event){this.chain=this.chain.then(()=>this.handle(event)).catch(()=>{});return this.chain;}
 async handle(event){
  if(this.model.recoveryError)return; // Retain native receipts until their original save can be read.
  if(!event||typeof event.id!=='string'||!Number.isFinite(Date.parse(event.occurredAt)))return;
  if(this.observing.has(event.id))return;
  if(this.processed.has(event.id)){this.send({command:'ack',eventId:event.id});return;}
  const attempt=this.model.working?.rewardAttempts?.[event.attemptId]||this.model.state.rewardAttempts?.[event.attemptId]||(this.attempt?.id===event.attemptId?this.attempt:null),current=this.attempt?.id===event.attemptId,observation={id:event.id,occurredAt:event.occurredAt};
  if(event.type==='reward'&&attempt){const ok=await this.model.grantReward(attempt.id);if(!ok&&this.model.error){this.notify('save_failed',attempt);return;}if(ok){if(current)this.earned=true;this.notify('reward',attempt);}}
  if(event.type==='loaded'&&current&&this.phase==='loading'){
   clearTimeout(this.timer);if(this.active){this.phase='presenting';this.report('ad_show_attempted',attempt);this.send({command:'show',attemptId:attempt.id});this.notify('presenting');}else this.cancel('in_background');
  }
  if(['closed','load_failed','show_failed','cancelled'].includes(event.type)&&attempt){
   if(!await this.model.finishRewardAttempt(attempt.id)&&this.model.error){this.notify('save_failed',attempt);return;}
   if(current){clearTimeout(this.timer);this.phase='idle';this.notify(this.earned?'received':event.type==='closed'?'unrewarded':'unavailable',attempt);}
  }
  if(event.type==='state'&&Array.isArray(event.busyAttemptIds))for(const a of Object.values(this.model.working?.rewardAttempts||this.model.state.rewardAttempts||{})){if(a.status==='prepared'&&!event.busyAttemptIds.includes(a.id)&&!await this.model.finishRewardAttempt(a.id)&&this.model.error){this.notify('save_failed',a);return;}}
  const finish=async()=>{
   if(stages[event.type]&&attempt){const failure=event.type.endsWith('failed');await this.report(stages[event.type],attempt,observation,failure?(['no_fill','network','timeout','privacy','busy','in_background','not_ready'].includes(event.reason)?event.reason:'sdk_error'):undefined);}
   this.processed.add(event.id);if(this.processed.size>256)this.processed.delete(this.processed.values().next().value);this.send({command:'ack',eventId:event.id});this.observing.delete(event.id);
  };
  const work=Promise.resolve().then(finish);this.observing.set(event.id,work);
 }
 async settleObservations(){await Promise.all([...this.observing.values()]);}
}
