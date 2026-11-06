const defaults={music:true,sound:true,haptics:true,reduced_motion:false,color_symbols:true,strong_contrast:false};
const object=x=>x&&typeof x==='object'&&!Array.isArray(x);
export function legacyRecord(raw){
 if(!object(raw)||raw.protocolVersion!==1||!['present','missing'].includes(raw.status)||raw.sourceFile!=='pourlune_dev.sqlite'||raw.originalRetained!==true)throw Error('Could not read the preserved previous save');
 if(raw.status==='missing')return {protocolVersion:1,status:'missing',sourceFile:raw.sourceFile,originalRetained:true};
 if(!Number.isInteger(raw.databaseVersion)||raw.databaseVersion<1||raw.databaseVersion>5||!object(raw.preferences)||Object.entries(raw.preferences).some(([key,value])=>!(key in defaults)||typeof value!=='boolean'))throw Error('Unreadable previous settings or schema');
 if(raw.privacy!=null&&(!object(raw.privacy)||typeof raw.privacy.analytics!=='boolean'||typeof raw.privacy.crash!=='boolean'))throw Error('Unreadable previous privacy settings');
 return {protocolVersion:1,status:'present',sourceFile:raw.sourceFile,databaseVersion:raw.databaseVersion,originalRetained:true,preferences:{...defaults,...raw.preferences},privacy:raw.privacy?{analytics:raw.privacy.analytics,crash:raw.privacy.crash}:null,sdkState:'original platform storage retained; no private SDK state rewrite or event replay'};
}
export function applyLegacy(state,raw){
 const record=legacyRecord(raw),next=structuredClone(state);next.legacyImport={...record,importedAt:new Date().toISOString()};
 if(record.status==='present'){
  const p=record.preferences;next.prefs={music:p.music,sound:p.sound,haptics:p.haptics,reduced:p.reduced_motion};
  next.analyticsChoice=record.privacy?.analytics?'allowed':'declined';next.disclosureVersion=1;
 }
 return next;
}
export function readNativeLegacy(native,window,{setTimeout=globalThis.setTimeout,clearTimeout=globalThis.clearTimeout}={}){
 return new Promise((resolve,reject)=>{
  const receiver={receive:record=>{clearTimeout(timer);if(window.GardenLegacy===receiver)delete window.GardenLegacy;resolve(record);}};
  const timer=setTimeout(()=>{if(window.GardenLegacy===receiver)delete window.GardenLegacy;reject(Error('Previous-save read timed out; original data is kept'));},10000);
  window.GardenLegacy=receiver;
  try{native.send({command:'legacy-read'});}catch(error){clearTimeout(timer);delete window.GardenLegacy;reject(error);}
 });
}
