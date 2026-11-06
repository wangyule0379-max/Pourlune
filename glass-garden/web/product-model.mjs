import {withExtraBottle,expandSlot} from './extra-bottle.mjs';
import {applyLegacy,legacyRecord} from './legacy.mjs';
import {adLedger,validateFullscreen} from './fullscreen.mjs';
export function initialState(R,P){return {version:1,catalog:R.CATALOG_ID,currentLevel:1,completedLevels:[],roundInstanceIds:{},completionReceipts:{},gameProgress:P.load(null,null,{levels:R.LEVELS,catalog:R.CATALOG_ID}),analyticsChoice:'unasked',disclosureVersion:1,prefs:{music:true,sound:true,haptics:true,reduced:false},group:0,listScroll:0};}
const puzzleId=(s,n)=>s.puzzleInstanceIds?.[n]||s.roundInstanceIds[n];
const rewarded=(s,n)=>!!s.extraBottles?.[n]&&s.extraBottles[n].puzzleId===puzzleId(s,n);
const activeLevel=(s,n,R)=>rewarded(s,n)?withExtraBottle(R.LEVELS[n-1],R):R.LEVELS[n-1];
export function validateState(s,R,P){
 const object=v=>v&&typeof v==='object'&&!Array.isArray(v),integer=(n,min,max)=>Number.isInteger(n)&&n>=min&&n<=max;
 if(!object(s)||s.version!==1||s.catalog!==R.CATALOG_ID||!integer(s.currentLevel,1,100)||!Array.isArray(s.completedLevels)||s.completedLevels.some((n,i)=>n!==i+1)||s.completedLevels.length>100||!object(s.roundInstanceIds)||!object(s.completionReceipts)||!object(s.prefs)||Object.values(s.prefs).some(x=>typeof x!=='boolean')||!['unasked','allowed','declined'].includes(s.analyticsChoice)||![1,2,3].includes(s.disclosureVersion)||!integer(s.group,0,9)||!Number.isFinite(s.listScroll)||s.listScroll<0)throw Error('Unreadable product save');
 for(const key of ['music','sound','haptics','reduced'])if(typeof s.prefs[key]!=='boolean')throw Error('Unreadable settings');
 if(s.analyticsResetToken!=null&&(typeof s.analyticsResetToken!=='string'||!s.analyticsResetToken||s.analyticsResetToken.length>128))throw Error('Unreadable statistics choice receipt');
 if(s.legacyImport!=null){legacyRecord(s.legacyImport);if(!Number.isFinite(Date.parse(s.legacyImport.importedAt)))throw Error('Unreadable previous-save import receipt');}
 validateFullscreen(s);const gp=s.gameProgress;
 if(!object(gp)||gp.current!==s.currentLevel-1||gp.version!==3||gp.catalog!==R.CATALOG_ID||!object(gp.slots)||Object.keys(gp.slots).length>100||!Array.isArray(gp.completed)||JSON.stringify(gp.completed)!==JSON.stringify(s.completedLevels.map(n=>n-1)))throw Error('Unreadable campaign progress');
 const levelKey=key=>String(Number(key))===key&&integer(Number(key),1,100);
 for(const [key,id] of Object.entries(s.roundInstanceIds))if(!levelKey(key)||typeof id!=='string'||!id||!gp.slots[key])throw Error('Unreadable round identity');
 for(const [key,id] of Object.entries(s.completionReceipts))if(!levelKey(key)||typeof id!=='string'||!id||!s.completedLevels.includes(Number(key)))throw Error('Unreadable completion receipt');
 for(const n of s.completedLevels)if(!s.completionReceipts[n])throw Error('Missing completion receipt');
 for(const name of ['puzzleInstanceIds','rewardAttempts','extraBottles'])if(s[name]!=null&&!object(s[name]))throw Error('Unreadable reward ledger');
 for(const [key,id] of Object.entries(s.puzzleInstanceIds||{}))if(!levelKey(key)||typeof id!=='string'||!id||!gp.slots[key])throw Error('Unreadable puzzle identity');
 for(const [id,a] of Object.entries(s.rewardAttempts||{}))if(!object(a)||id!==a.id||typeof id!=='string'||!id||!integer(a.level,1,100)||!gp.slots[a.level]||typeof a.puzzleId!=='string'||!a.puzzleId||a.puzzleId!==puzzleId(s,a.level)||typeof a.roundId!=='string'||!a.roundId||!Number.isFinite(Date.parse(a.createdAt))||!['prepared','closed'].includes(a.status))throw Error('Unreadable reward attempt');
 for(const [key,r] of Object.entries(s.extraBottles||{})){const a=s.rewardAttempts?.[r?.attemptId];if(!levelKey(key)||!object(r)||!a||a.level!==Number(key)||r.puzzleId!==puzzleId(s,Number(key))||!Number.isFinite(Date.parse(r.grantedAt)))throw Error('Unreadable extra-bottle receipt');}
 for(const [key,slot] of Object.entries(gp.slots)){
  const n=Number(key),level=integer(n,1,100)?activeLevel(s,n,R):null;
  if(!integer(n,1,100)||!object(slot)||slot.uid!==level.uid||slot.level!==n-1||!Array.isArray(slot.history)||slot.history.length>=10000||!R.validState(slot.state,level)||typeof s.roundInstanceIds[n]!=='string'||!s.roundInstanceIds[n])throw Error('Unreadable level save');
  const restored=P.restore(level,slot);
  if(restored.moves!==slot.moves||restored.history.length!==slot.history.length||!R.sameBoard(restored.state,slot.state))throw Error('Invalid move history');
 }
 return s;
}
export class Product {
 constructor({store,R,P,onChange=()=>{},uuid=()=>crypto.randomUUID(),policyVersion=1,onCommit=()=>{}}){Object.assign(this,{store,R,P,onChange,uuid,policyVersion,onCommit});this.freshCompletions=new Set();this.checkedNext=new Set();this.state=initialState(R,P);this.working=this.state;this.revision=0;this.saving=0;this.error=null;this.recoveryError=null;this.pending=null;this.chain=Promise.resolve();}
 async open(){this.freshCompletions.clear();this.checkedNext.clear();try{const raw=await this.store.read();this.hasSave=!!raw;this.revision=Number.isSafeInteger(raw?.revision)?raw.revision:0;if(raw)this.state=validateState(raw.data,this.R,this.P);this.working=this.state;this.recoveryError=null;}catch(e){this.recoveryError=e.message;}this.onChange(this);return !this.recoveryError;}
 async importLegacy(record){if(this.recoveryError)throw Error('Restore the existing save before importing settings');if(this.hasSave)return true;if(this.error||this.saving||this.pending)return false;return this.save(applyLegacy(this.state,record));}
 unlocked(n){return n===1||this.state.completedLevels.includes(n)||this.state.completedLevels.includes(n-1);}
 resumable(n,s=this.state){const slot=s.gameProgress.slots[n];return !!(s.roundInstanceIds[n]&&slot&&!this.R.isSolved(slot.state));}
 activeLevel(n,s=this.state){return activeLevel(s,n,this.R);}
 hasExtraBottle(n=this.state.currentLevel,s=this.state){return rewarded(s,n);}
 homeTarget(){if(this.state.completedLevels.length===100)return null;return this.resumable(this.state.currentLevel)?this.state.currentLevel:this.state.completedLevels.length+1;}
 save(next,{replace=false}={}){
  if(this.recoveryError&&!replace)return Promise.resolve(false);
  validateState(next,this.R,this.P);this.working=structuredClone(next);this.pending=this.working;
  if(this.error&&!replace)return Promise.resolve(false);
  const snapshot=structuredClone(next);this.saving++;this.onChange(this);
  const job=this.chain.then(async()=>{
   if(this.error&&!replace)return false;
   try{const previous=this.state;const record=await this.store[replace?'replace':'write'](snapshot,this.revision);this.revision=record.revision;this.state=record.data;this.hasSave=true;for(const n of this.state.completedLevels)if(!previous.completedLevels.includes(n))this.freshCompletions.add(this.state.completionReceipts[n]);Promise.resolve().then(()=>this.onCommit(record.data,previous)).catch(()=>{});if(this.pending===next||this.saving===1)this.pending=null;this.recoveryError=null;return true;}catch(e){this.error=e.message;return false;}
  }).finally(()=>{this.saving--;if(!this.saving&&!this.error)this.working=this.state;this.onChange(this);});
  this.chain=job.catch(e=>{this.error=e.message;this.onChange(this);return false;});return this.chain;
 }
 async retry(){await this.chain;if(!this.pending)return !this.error;const next=this.pending;this.error=null;return this.save(next);}
 async replaceCorrupt(){await this.chain;this.error=null;return this.save(initialState(this.R,this.P),{replace:true});}
 async reloadSaved(){await this.chain;this.error=null;this.pending=null;return this.open();}
 needsAnalyticsChoice(){return this.state.analyticsChoice==='unasked'||(this.state.analyticsChoice==='allowed'&&this.state.disclosureVersion<this.policyVersion);}
 async chooseAnalytics(choice){if(!['allowed','declined'].includes(choice))return false;return this.save({...this.working,analyticsChoice:choice,disclosureVersion:this.policyVersion,...(choice==='declined'?{analyticsResetToken:this.uuid()}:{})});}
 async preference(key,value){if(!['music','sound','haptics','reduced'].includes(key)||typeof value!=='boolean')return false;return this.save({...this.working,prefs:{...this.working.prefs,[key]:value}});}
 async enter(n,{restart=false,listScroll}={}){
  if(this.error||this.recoveryError||this.saving||this.needsAnalyticsChoice()||!Number.isInteger(n)||n<1||n>100||!this.unlocked(n))return false;
  const next=structuredClone(this.state);next.currentLevel=n;next.gameProgress.current=n-1;if(listScroll!==undefined)next.listScroll=listScroll;
  if(restart||!this.resumable(n)){
   const keep=restart&&this.resumable(n);next.puzzleInstanceIds??={};next.extraBottles??={};next.rewardAttempts??={};
   next.puzzleInstanceIds[n]=keep?puzzleId(next,n):this.uuid();
   if(!keep){delete next.extraBottles[n];for(const [id,a] of Object.entries(next.rewardAttempts))if(a.level===n)delete next.rewardAttempts[id];}
   next.roundInstanceIds[n]=this.uuid();const session=new this.R.Session(this.activeLevel(n,next));
   this.P.capture(next.gameProgress,n-1,session,{sound:next.prefs.sound,reduced:next.prefs.reduced,completed:next.completedLevels.map(x=>x-1)},this.R.LEVELS);
  }
  return this.save(next);
 }
 async capture(session,index,round=this.working.roundInstanceIds[index+1]){
  const n=index+1;if(!round||round!==this.working.roundInstanceIds[n]||this.recoveryError||!this.R.validState(session.state,this.activeLevel(n,this.working)))return false;
  const next=structuredClone(this.working);next.currentLevel=n;
  if(this.R.isSolved(session.state)){
   if(!next.completedLevels.includes(n)){next.completedLevels.push(n);if(next.fullscreen)next.fullscreen.qualifyingTotal=Math.max(0,next.completedLevels.length-10);}
   next.completedLevels.sort((a,b)=>a-b);next.completionReceipts[n]=round;
  }
  this.P.capture(next.gameProgress,index,session,{sound:next.prefs.sound,reduced:next.prefs.reduced,completed:next.completedLevels.map(x=>x-1)},this.R.LEVELS);
  // Lifecycle/animation may checkpoint the same complete action. Join its
  // transaction rather than writing or issuing another completion receipt.
  if(JSON.stringify(next)===JSON.stringify(this.working))return this.chain.then(()=>!this.error);
  return this.save(next);
 }
 async next(){if(this.state.currentLevel===100)return false;return this.enter(this.state.currentLevel+1);}
 canCheckInterstitial(n,round,{ignoreChecked=false}={}){const s=this.state,f=adLedger(s);return !this.error&&!this.recoveryError&&!this.saving&&s.currentLevel===n&&s.roundInstanceIds[n]===round&&s.completionReceipts[n]===round&&this.freshCompletions.has(round)&&(ignoreChecked||!this.checkedNext.has(round))&&n>=11&&n<100&&n!==20&&n!==40&&f.qualifyingTotal-f.consumedTotal>=3;}
 async prepareFullscreen(id,kind,level,roundId){await this.chain;if(this.error||this.recoveryError||this.saving||!['rewarded','interstitial'].includes(kind))return false;const existing=adLedger(this.state).attempts[id];if(existing)return existing.kind===kind&&existing.level===level&&existing.roundId===roundId&&existing.status==='prepared';if(kind==='rewarded'){if(!this.state.rewardAttempts?.[id]||this.state.rewardAttempts[id].roundId!==roundId)return false;}else if(!this.canCheckInterstitial(level,roundId,{ignoreChecked:true}))return false;const next=structuredClone(this.state);next.fullscreen=structuredClone(adLedger(next));next.fullscreen.attempts[id]={kind,level,roundId,boundary:next.fullscreen.qualifyingTotal,status:'prepared',createdAt:new Date().toISOString()};return this.save(next);}
 async recordFullscreen(id,occurredAt){await this.chain;const at=Date.parse(occurredAt),a=adLedger(this.working).attempts[id];if(!a||!Number.isSafeInteger(at)||at<0)return false;if(a.shownAt!=null)return !this.error;const next=structuredClone(this.working),f=next.fullscreen;f.attempts[id].shownAt=at;f.attempts[id].status='shown';f.lastShownAt=Math.max(f.lastShownAt||0,at);if(a.kind==='interstitial')f.consumedTotal=Math.max(f.consumedTotal,a.boundary);return this.save(next);}
 async finishFullscreen(id){await this.chain;const a=adLedger(this.working).attempts[id];if(!a)return true;if(a.status==='closed')return !this.error;const next=structuredClone(this.working);next.fullscreen.attempts[id].status='closed';return this.save(next);}
 async prepareReward(){
  if(this.error||this.recoveryError||this.saving||this.needsAnalyticsChoice())return false;
  const n=this.state.currentLevel;if(!this.resumable(n)||rewarded(this.state,n)||Object.values(this.state.rewardAttempts||{}).some(a=>a.level===n&&a.status==='prepared'))return false;
  const next=structuredClone(this.state),a={id:this.uuid(),level:n,puzzleId:puzzleId(next,n),roundId:next.roundInstanceIds[n],createdAt:new Date().toISOString(),status:'prepared'};
  next.rewardAttempts??={};next.rewardAttempts[a.id]=a;return await this.save(next)?a:false;
 }
 async finishRewardAttempt(id){await this.chain;const a=this.working.rewardAttempts?.[id];if(!a)return false;if(a.status==='closed')return !this.error;const next=structuredClone(this.working);next.rewardAttempts[id].status='closed';return this.save(next);}
 async grantReward(id){
  await this.chain;const a=this.working.rewardAttempts?.[id];if(!a||a.puzzleId!==puzzleId(this.working,a.level))return false;
  if(rewarded(this.working,a.level))return !this.error;
  const next=structuredClone(this.working);next.extraBottles??={};next.extraBottles[a.level]={puzzleId:a.puzzleId,attemptId:id,grantedAt:new Date().toISOString()};next.gameProgress.slots[a.level]=expandSlot(next.gameProgress.slots[a.level]);
  return this.save(next);
 }
 close(){this.store.close();}
}
