// Resolve only on transaction completion; request success alone is not a commit.
export async function openStore({indexedDB=globalThis.indexedDB,name='pourlune.glass-garden.product.v1'}={}) {
 if(!indexedDB) throw new Error('Persistent storage unavailable');
 const db=await new Promise((resolve,reject)=>{
  const q=indexedDB.open(name,1);
  q.onupgradeneeded=()=>q.result.createObjectStore('snapshots');
  q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error);
  q.onblocked=()=>reject(new Error('Close another game window and retry'));
 });
 db.onversionchange=()=>db.close();
 function transaction(mode,work){return new Promise((resolve,reject)=>{
  let tx;try{tx=db.transaction('snapshots',mode,{durability:'strict'});}catch(e){if(!(e instanceof TypeError))return reject(e);tx=db.transaction('snapshots',mode);}
  let value,failure;tx.oncomplete=()=>resolve(value);tx.onerror=()=>{};tx.onabort=()=>reject(failure||tx.error||new Error('Save transaction aborted'));
  try{work(tx.objectStore('snapshots'),v=>value=v,e=>{failure=e;tx.abort();});}catch(e){failure=e;tx.abort();}
 });}
 const read=()=>transaction('readonly',(store,done)=>{const q=store.get('current');q.onsuccess=()=>done(q.result??null);});
 function write(data,expectedRevision,quarantine=false){
  const snapshot=structuredClone(data);
  return transaction('readwrite',(store,done,fail)=>{
   const q=store.get('current');q.onsuccess=()=>{
    const current=q.result,revision=Number.isSafeInteger(current?.revision)?current.revision:0;
    if(revision!==expectedRevision)return fail(new Error('Save conflict: another window committed progress'));
    if(current)store.put(current,quarantine?'quarantine:'+revision:'previous');
    const next={revision:revision+1,data:snapshot};store.put(next,'current');done(next);
   };
  });
 }
 function resetKey(scope){if(typeof scope!=='string'||!scope||scope.length>512)throw Error('Invalid statistics scope');return 'statistics-reset-ack:'+scope;}
 const readStatisticsResetAck=scope=>transaction('readonly',(store,done,fail)=>{const q=store.get(resetKey(scope));q.onsuccess=()=>{if(q.result!=null&&(typeof q.result!=='string'||!q.result))return fail(Error('Unreadable statistics reset receipt'));done(q.result??null);};});
 const ackStatisticsReset=(scope,token)=>transaction('readwrite',(store,done)=>{if(typeof token!=='string'||!token||token.length>128)throw Error('Invalid statistics reset token');store.put(token,resetKey(scope));done(token);});
 return {read,write:(data,revision)=>write(data,revision),replace:(data,revision)=>write(data,revision,true),readStatisticsResetAck,ackStatisticsReset,close:()=>db.close()};
}
