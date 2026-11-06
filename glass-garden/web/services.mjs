export const QA_GAME_ID='566121d2-a3f5-4950-8bd9-6ff2f673a0ac';
export const PRODUCTION_GAME_ID='8feaf0dc-ec12-4308-ac58-16b2180f2d63';
function target(environment,identity){if(environment==='test'&&(identity==null||identity==='dev.pourlune.glassgarden.localqa'))return {environment,gameId:QA_GAME_ID,identity:identity||'dev.pourlune.glassgarden.localqa'};if(environment==='production'&&identity==='com.pourlune.app')return {environment,gameId:PRODUCTION_GAME_ID,identity};throw Error('Explicit matching production identity required');}
export function serviceTarget(native){if(!native||!['ios','android'].includes(native.platform))return null;if(native.services==='test'&&(native.identity==null||native.identity==='dev.pourlune.glassgarden.localqa'))return target('test',native.identity);if(native.services==='production'&&native.identity==='com.pourlune.app'&&native.ads==='test')return target('production',native.identity);return null;}
export const serviceScope=(platform,environment='test')=>JSON.stringify(['https://api.gamemunchies.com',target(environment,environment==='production'?'com.pourlune.app':undefined).gameId,platform,environment]);
export const statisticsAllowed=(state,requiredVersion=2)=>state.analyticsChoice==='allowed'&&state.disclosureVersion>=requiredVersion;

// Own the official SDK once. Observations follow confirmed game commits; game
// storage/navigation never await a service request or pretend a service is ready.
export class GameServices {
 constructor({SDK,platform,statisticsEnabled=false,pendingResetToken=null,acknowledgeReset=null,dependencies={},onDiagnostic=()=>{},policyVersion=2,environment='test',identity}){
  if(!['ios','android'].includes(platform))throw Error('Explicit native QA platform required');
  const service=target(environment,identity);this.environment=service.environment;this.gameId=service.gameId;this.policyVersion=policyVersion;this.allowed=statisticsEnabled;this.applied=statisticsEnabled&&!pendingResetToken;this.acknowledgeReset=acknowledgeReset;this.consentGeneration=0;this.active=null;this.observed={};this.disposed=false;this.pending=Promise.resolve();
  // Existing QA scene keys are a decode boundary, not enabled game placements.
  this.client=new SDK({baseUrl:'https://api.gamemunchies.com',gameId:service.gameId,platform,environment:service.environment,defaultConfig:{enabled:false,interstitial:{enabled:false,minIntervalSeconds:0,scenes:{next_level:false}},rewarded:{scenes:{extra_bottle:false}}},statisticsEnabled:this.applied,storageFailurePolicy:'disable',onDiagnostic}, {...dependencies,browser:false});
  this.ready=Promise.resolve().then(async()=>{await this.client.start();if(pendingResetToken&&this.client.getStorageStatus()!=='failed')await this.recordReset(pendingResetToken);}).catch(()=>this.fail());
  this.ready.then(()=>{this.pending=this.pending.then(async()=>{if(!this.disposed&&!this.failed&&this.client.getStorageStatus()!=='failed')await this.applyConsent(this.allowed,this.consentGeneration);}).catch(()=>this.fail());});
 }
 fail(){this.failed=true;try{Promise.resolve(this.client.setStatisticsEnabled(false)).catch(()=>{});}catch{}}
 async recordReset(token){if(this.acknowledgedResetToken===token)return;if(typeof this.acknowledgeReset!=='function')throw Error('Durable reset acknowledgement required');await this.acknowledgeReset(token);this.acknowledgedResetToken=token;}
 async applyConsent(enabled,generation){if(enabled&&generation!==this.consentGeneration)return false;if(this.applied!==enabled){await this.client.setStatisticsEnabled(enabled);this.applied=enabled;}return enabled&&this.allowed&&generation===this.consentGeneration;}
 committed(next,previous,occurredAt=new Date().toISOString()){
  const enabledAtCommit=statisticsAllowed(next,this.policyVersion)&&!this.heldOff,withdrawn=this.allowed&&!enabledAtCommit;
  let withdrawal=null;
  if(withdrawn){
   this.consentGeneration++;
   // Abort SDK event requests now, even while an older job awaits startup.
   try{withdrawal=Promise.resolve(this.client.setStatisticsEnabled(false)).catch(()=>{this.failed=true;});}catch{this.failed=true;}
  }
  const generation=this.consentGeneration;this.allowed=enabledAtCommit;
  const events=[];
  for(const [level,id] of Object.entries(next.roundInstanceIds))if(previous.roundInstanceIds[level]!==id&&this.observed[level]!==id){
   this.observed[level]=id;
   if(enabledAtCommit)events.push({id,occurredAt});
  }
  this.pending=this.pending.then(async()=>{
   await this.ready;if(this.disposed||this.failed||this.client.getStorageStatus()==='failed')return;
   if(withdrawal){await withdrawal;this.applied=false;}
   if(!enabledAtCommit&&next.analyticsResetToken)await this.recordReset(next.analyticsResetToken);
   if(!await this.applyConsent(enabledAtCommit,generation))return;
   for(const event of events){if(!this.allowed||this.disposed||generation!==this.consentGeneration)break;await this.client.track('round_start',event);}
  }).catch(()=>this.fail());
  return this.pending;
 }
 revokeNow(){this.heldOff=true;this.allowed=false;this.consentGeneration++;let stop;try{stop=Promise.resolve(this.client.setStatisticsEnabled(false)).catch(()=>this.fail());}catch{this.fail();stop=Promise.resolve();}this.pending=this.pending.then(async()=>{await this.ready;await stop;this.applied=false;}).catch(()=>this.fail());return this.pending;}
 allowAfterCommit(state){if(!statisticsAllowed(state,this.policyVersion))return;this.heldOff=false;this.allowed=true;const generation=this.consentGeneration;this.pending=this.pending.then(async()=>{await this.ready;if(!this.disposed&&!this.failed&&this.client.getStorageStatus()!=='failed')await this.applyConsent(true,generation);}).catch(()=>this.fail());return this.pending;}
 setActive(active){if(this.active===active)return;this.active=active;if(!this.disposed&&!this.failed)this.client.setForeground(active);}
 settle(){return this.pending;}
 async dispose(){this.disposed=true;await this.ready;await this.pending;await this.client.dispose();}
}
