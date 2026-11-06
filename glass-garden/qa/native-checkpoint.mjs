// Inspector-only QA helper. Never included in the player package.
export async function nativeCheckpoint(data,{native=globalThis.GardenNative,location=globalThis.location,indexedDB=globalThis.indexedDB}={}){
 if(native?.identity!=='dev.pourlune.glassgarden.localqa'||native?.services!=='test'||location?.origin!=='http://127.0.0.1:43177'||location?.pathname!=='/index.html')throw Error('Independent native QA page required');
 if(data!==null&&(![16,39,100].includes(data?.currentLevel)||data.analyticsChoice!=='declined'))throw Error('Verified declined checkpoint required');
 const db=await new Promise((resolve,reject)=>{const q=indexedDB.open('pourlune.glass-garden.product.v1',1);q.onupgradeneeded=()=>q.transaction.abort();q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error);});
 try{return await new Promise((resolve,reject)=>{
  const tx=db.transaction('snapshots','readwrite'),store=tx.objectStore('snapshots'),key='qa-native-original-20261107';let result,error;
  tx.oncomplete=()=>resolve(result);tx.onabort=()=>reject(error||tx.error||Error('QA transaction aborted'));tx.onerror=()=>{};
  const fail=e=>{error=e;tx.abort();};
  const current=store.get('current');current.onsuccess=()=>{
   const before=current.result;if(!before||!Number.isSafeInteger(before.revision)||before.data?.analyticsChoice!=='declined')return fail(Error('Existing declined QA save required'));
   const backup=store.get(key);backup.onsuccess=()=>{
    if(data===null&&!backup.result)return fail(Error('Original QA backup missing'));
    if(!backup.result)store.put(before,key);
    const next=data===null?backup.result.data:{...data,prefs:before.data.prefs,analyticsChoice:'declined',disclosureVersion:before.data.disclosureVersion,analyticsResetToken:before.data.analyticsResetToken};
    store.put({revision:before.revision+1,data:next},'current');
    result={action:data===null?'restored':'synthetic-checkpoint',level:next.currentLevel,revision:before.revision+1,originalRetained:true};
   };
  };
 });}finally{db.close();}
}
