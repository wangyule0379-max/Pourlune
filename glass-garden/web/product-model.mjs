export function initialState(R,P){return {version:1,catalog:R.CATALOG_ID,currentLevel:1,completedLevels:[],roundInstanceIds:{},completionReceipts:{},gameProgress:P.load(null,null,{levels:R.LEVELS,catalog:R.CATALOG_ID}),analyticsChoice:'unasked',disclosureVersion:1,prefs:{music:false,sound:true,haptics:false,reduced:false},group:0,listScroll:0};}
export function validateState(s,R,P){
 const object=v=>v&&typeof v==='object'&&!Array.isArray(v),integer=(n,min,max)=>Number.isInteger(n)&&n>=min&&n<=max;
 if(!object(s)||s.version!==1||s.catalog!==R.CATALOG_ID||!integer(s.currentLevel,1,100)||!Array.isArray(s.completedLevels)||s.completedLevels.some((n,i)=>n!==i+1)||s.completedLevels.length>100||!object(s.roundInstanceIds)||!object(s.completionReceipts)||!object(s.prefs)||Object.values(s.prefs).some(x=>typeof x!=='boolean')||!['unasked','allowed','declined'].includes(s.analyticsChoice)||s.disclosureVersion!==1||!integer(s.group,0,9)||!Number.isFinite(s.listScroll)||s.listScroll<0)throw Error('Unreadable product save');
 for(const key of ['music','sound','haptics','reduced'])if(typeof s.prefs[key]!=='boolean')throw Error('Unreadable settings');
 const gp=s.gameProgress;
 if(!object(gp)||gp.current!==s.currentLevel-1||gp.version!==3||gp.catalog!==R.CATALOG_ID||!object(gp.slots)||Object.keys(gp.slots).length>100||!Array.isArray(gp.completed)||JSON.stringify(gp.completed)!==JSON.stringify(s.completedLevels.map(n=>n-1)))throw Error('Unreadable campaign progress');
 const levelKey=key=>String(Number(key))===key&&integer(Number(key),1,100);
 for(const [key,id] of Object.entries(s.roundInstanceIds))if(!levelKey(key)||typeof id!=='string'||!id||!gp.slots[key])throw Error('Unreadable round identity');
 for(const [key,id] of Object.entries(s.completionReceipts))if(!levelKey(key)||typeof id!=='string'||!id||!s.completedLevels.includes(Number(key)))throw Error('Unreadable completion receipt');
 for(const n of s.completedLevels)if(!s.completionReceipts[n])throw Error('Missing completion receipt');
 for(const [key,slot] of Object.entries(gp.slots)){
  const n=Number(key),level=R.LEVELS[n-1];
  if(!integer(n,1,100)||!object(slot)||slot.uid!==level.uid||slot.level!==n-1||!Array.isArray(slot.history)||slot.history.length>=10000||!R.validState(slot.state,level)||typeof s.roundInstanceIds[n]!=='string'||!s.roundInstanceIds[n])throw Error('Unreadable level save');
  const restored=P.restore(level,slot);
  if(restored.moves!==slot.moves||restored.history.length!==slot.history.length||!R.sameBoard(restored.state,slot.state))throw Error('Invalid move history');
 }
 return s;
}
export class Product {
 constructor({store,R,P,onChange=()=>{},uuid=()=>crypto.randomUUID()}){Object.assign(this,{store,R,P,onChange,uuid});this.state=initialState(R,P);this.working=this.state;this.revision=0;this.saving=0;this.error=null;this.recoveryError=null;this.pending=null;this.chain=Promise.resolve();}
 async open(){try{const raw=await this.store.read();this.revision=Number.isSafeInteger(raw?.revision)?raw.revision:0;if(raw)this.state=validateState(raw.data,this.R,this.P);this.working=this.state;this.recoveryError=null;}catch(e){this.recoveryError=e.message;}this.onChange(this);return !this.recoveryError;}
 unlocked(n){return n===1||this.state.completedLevels.includes(n)||this.state.completedLevels.includes(n-1);}
 resumable(n,s=this.state){const slot=s.gameProgress.slots[n];return !!(s.roundInstanceIds[n]&&slot&&!this.R.isSolved(slot.state));}
 homeTarget(){if(this.state.completedLevels.length===100)return null;return this.resumable(this.state.currentLevel)?this.state.currentLevel:this.state.completedLevels.length+1;}
 save(next,{replace=false}={}){
  if(this.recoveryError&&!replace)return Promise.resolve(false);
  validateState(next,this.R,this.P);this.working=structuredClone(next);this.pending=this.working;
  if(this.error&&!replace)return Promise.resolve(false);
  const snapshot=structuredClone(next);this.saving++;this.onChange(this);
  const job=this.chain.then(async()=>{
   if(this.error&&!replace)return false;
   try{const record=await this.store[replace?'replace':'write'](snapshot,this.revision);this.revision=record.revision;this.state=record.data;if(this.pending===next||this.saving===1)this.pending=null;this.recoveryError=null;return true;}catch(e){this.error=e.message;return false;}
  }).finally(()=>{this.saving--;if(!this.saving&&!this.error)this.working=this.state;this.onChange(this);});
  this.chain=job.catch(e=>{this.error=e.message;this.onChange(this);return false;});return this.chain;
 }
 async retry(){await this.chain;if(!this.pending)return !this.error;const next=this.pending;this.error=null;return this.save(next);}
 async replaceCorrupt(){await this.chain;this.error=null;return this.save(initialState(this.R,this.P),{replace:true});}
 async reloadSaved(){await this.chain;this.error=null;this.pending=null;return this.open();}
 async chooseAnalytics(choice){if(!['allowed','declined'].includes(choice))return false;return this.save({...this.working,analyticsChoice:choice});}
 async preference(key,value){if(!['sound','reduced'].includes(key)||typeof value!=='boolean')return false;return this.save({...this.working,prefs:{...this.working.prefs,[key]:value}});}
 async enter(n,{restart=false}={}){
  if(this.error||this.recoveryError||this.saving||this.state.analyticsChoice==='unasked'||!Number.isInteger(n)||n<1||n>100||!this.unlocked(n))return false;
  const next=structuredClone(this.state);next.currentLevel=n;next.gameProgress.current=n-1;
  if(restart||!this.resumable(n)){
   next.roundInstanceIds[n]=this.uuid();const session=new this.R.Session(this.R.LEVELS[n-1]);
   this.P.capture(next.gameProgress,n-1,session,{sound:next.prefs.sound,reduced:next.prefs.reduced,completed:next.completedLevels.map(x=>x-1)},this.R.LEVELS);
  }
  return this.save(next);
 }
 async capture(session,index,round=this.working.roundInstanceIds[index+1]){
  const n=index+1;if(!round||round!==this.working.roundInstanceIds[n]||this.recoveryError)return false;
  const next=structuredClone(this.working);next.currentLevel=n;
  if(this.R.isSolved(session.state)){
   if(!next.completedLevels.includes(n))next.completedLevels.push(n);
   next.completedLevels.sort((a,b)=>a-b);next.completionReceipts[n]=round;
  }
  this.P.capture(next.gameProgress,index,session,{sound:next.prefs.sound,reduced:next.prefs.reduced,completed:next.completedLevels.map(x=>x-1)},this.R.LEVELS);
  // Lifecycle/animation may checkpoint the same complete action. Join its
  // transaction rather than writing or issuing another completion receipt.
  if(JSON.stringify(next)===JSON.stringify(this.working))return this.chain.then(()=>!this.error);
  return this.save(next);
 }
 async next(){if(this.state.currentLevel===100)return false;return this.enter(this.state.currentLevel+1);}
 close(){this.store.close();}
}
