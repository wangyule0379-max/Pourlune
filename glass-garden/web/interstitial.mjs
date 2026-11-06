import {modelAdConsent,observation} from './ad-consent.mjs';
import {adLedger} from './fullscreen.mjs';
const stages={load_requested:'ad_load_requested',loaded:'ad_loaded',load_failed:'ad_load_failed',blocked:'ad_blocked',impression:'ad_impression',show_failed:'ad_show_failed'};
export class InterstitialAds {
 constructor({model,consent=modelAdConsent(model),services,send,gate,notify=()=>{},appVersion,uuid=()=>crypto.randomUUID(),now=()=>performance.now()}){Object.assign(this,{model,consent,services,send,gate,notify,appVersion,uuid,now});this.active=true;this.chain=Promise.resolve();this.processed=new Set();this.observing=new Map();this.warmedRounds=new Set();}
 async report(type,a,event,reason,stamp=this.consent.capture()){
  const first=observation(event),policy=type==='ad_impression';try{const owner=await this.services();if(!owner)return !policy;const context={kind:'interstitial',scene:'next_level',provider:'admob',appVersion:this.appVersion,opportunityId:a.id,loadAttemptId:a.id,...(reason?{reason}:{})};if(owner.observeAd)return await owner.observeAd(type,context,first,a.level,()=>this.consent.permits(stamp));if(this.consent.permits(stamp)){await owner.client.trackAdEvent(type,context,first,a.level);return true;}return !policy;}catch{return !policy;}
 }
 async warm(){
  const s=this.model.state,n=s.currentLevel,round=s.roundInstanceIds[n],f=adLedger(s);
  if(!this.active||this.gate.owner||this.gate.clock.remaining()>0||this.model.error||this.model.recoveryError||!round||n<13||n===20||n===40||n===100||f.qualifyingTotal-f.consumedTotal<2||(s.completedLevels.includes(n)&&!this.model.freshCompletions.has(round))||this.warmedRounds.has(round))return false;
  if(this.inventory&&this.now()-this.inventory.created>=0&&this.now()-this.inventory.created<3600000)return false;
  if(this.inventory)this.send({command:'cancel',kind:'interstitial',attemptId:this.inventory.id});
  const inventory=this.inventory={id:this.uuid(),level:n,roundId:round,created:this.now(),phase:'checking'};this.warmedRounds.add(round);
  let owner;try{owner=await this.services();await owner?.ready;}catch{}
  if(this.inventory!==inventory||!this.active||this.model.state.roundInstanceIds[this.model.state.currentLevel]!==round||!(owner?.canShowAd?.('interstitial','next_level',n)??owner?.client.canShowAd('interstitial','next_level',n))){if(this.inventory===inventory)this.inventory=null;return false;}
  inventory.phase='loading';this.send({command:'load',kind:'interstitial',attemptId:inventory.id});return true;
 }
 async next(level,round){
  const eligible=this.model.canCheckInterstitial(level,round);this.model.checkedNext.add(round);
  if(!eligible)return true;
  const inventory=this.inventory,a=inventory?{...inventory,level,roundId:round}:null;
  if(!a)return true;
  this.report('ad_opportunity',a);
  let owner;try{owner=await this.services();}catch{}
  const reason=!this.active?'in_background':this.gate.owner?'busy':this.gate.clock.remaining()>0?'cooldown':!(owner?.canShowAd?.('interstitial','next_level',level)??owner?.client.canShowAd('interstitial','next_level',level))?'config_disabled':inventory.phase!=='ready'||this.now()-inventory.created<0||this.now()-inventory.created>=3600000?'not_ready':null;
  if(reason){this.report('ad_blocked',a,undefined,reason);return true;}
  this.gate.owner=this;
  if(!await this.model.prepareFullscreen(a.id,'interstitial',level,round)){this.send({command:'cancel',kind:'interstitial',attemptId:a.id});this.inventory=null;this.gate.owner=null;return false;}
  // Recheck all volatile gates after the durable prepare transaction.
  if(!this.active||this.gate.clock.remaining()>0||!(owner.canShowAd?.('interstitial','next_level',level)??owner.client.canShowAd('interstitial','next_level',level))){await this.model.finishFullscreen(a.id);this.gate.owner=null;return !this.model.error;}
  this.attempt=a;this.shown=false;this.inventory=null;
  const result=new Promise(resolve=>this.resolve=resolve);this.notify('presenting',a);this.report('ad_show_attempted',a);this.send({command:'show',kind:'interstitial',attemptId:a.id});
  this.timer=setTimeout(()=>this.expire(),120000);this.timer.unref?.();return result;
 }
 finish(advance){clearTimeout(this.timer);if(this.gate.owner===this)this.gate.owner=null;const resolve=this.resolve;this.resolve=null;if(resolve)resolve(advance);}
 expire(){if(!this.resolve||this.shown)return false;this.send({command:'cancel',kind:'interstitial',attemptId:this.attempt.id});this.report('ad_show_failed',this.attempt,undefined,'timeout');this.model.finishFullscreen(this.attempt.id).then(ok=>{if(ok)this.finish(true);else this.notify('save_failed',this.attempt);});return true;}
 setActive(active){this.active=active;if(!active&&this.inventory){this.send({command:'cancel',kind:'interstitial',attemptId:this.inventory.id});this.inventory=null;}}
 receive(event){const stamp=this.consent.capture(event);this.chain=this.chain.then(()=>this.handle(event,stamp)).catch(()=>{});return this.chain;}
 async handle(event,stamp){
  if(this.model.recoveryError||!event||typeof event.id!=='string'||!Number.isFinite(Date.parse(event.occurredAt)))return;
  if(this.observing.has(event.id))return;if(this.processed.has(event.id)){this.send({command:'ack',eventId:event.id});return;}
  const saved=adLedger(this.model.working||this.model.state).attempts[event.attemptId],a=saved?{...saved,id:event.attemptId}:this.inventory?.id===event.attemptId?this.inventory:this.attempt?.id===event.attemptId?this.attempt:null;
  if(event.type==='loaded'&&this.inventory?.id===event.attemptId)this.inventory.phase='ready';
  if(['load_failed','blocked','cancelled'].includes(event.type)&&this.inventory?.id===event.attemptId)this.inventory=null;
  if(event.type==='shown'&&saved){if(this.attempt?.id===a.id){this.shown=true;clearTimeout(this.timer);}this.gate.clock.shown(Date.parse(event.occurredAt));if(!await this.model.recordFullscreen(a.id,event.occurredAt)&&this.model.error){this.notify('save_failed',a);return;}this.gate.clock.shown(adLedger(this.model.working||this.model.state).lastShownAt);if(this.attempt?.id===a.id){this.shown=true;clearTimeout(this.timer);}}
  if(['closed','show_failed','cancelled','blocked'].includes(event.type)&&saved){if(!await this.model.finishFullscreen(a.id)&&this.model.error){this.notify('save_failed',a);return;}if(this.attempt?.id===a.id)this.finish(true);}
  if(event.type==='state'&&Array.isArray(event.busyAttemptIds))for(const [id,item] of Object.entries(adLedger(this.model.working||this.model.state).attempts))if(item.status==='prepared'&&!event.busyAttemptIds.includes(id)&&!await this.model.finishFullscreen(id)&&this.model.error){this.notify('save_failed',item);return;}
  const work=Promise.resolve().then(async()=>{if(a&&stages[event.type]&&!await this.report(stages[event.type],a,{id:event.id,occurredAt:event.occurredAt},event.reason,stamp)){this.observing.delete(event.id);return;}this.processed.add(event.id);if(this.processed.size>256)this.processed.delete(this.processed.values().next().value);this.send({command:'ack',eventId:event.id});this.observing.delete(event.id);});this.observing.set(event.id,work);
 }
 async settleObservations(){await Promise.all([...this.observing.values()]);}
}
