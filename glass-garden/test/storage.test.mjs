import test from 'node:test';
import assert from 'node:assert/strict';
import {IDBFactory, IDBObjectStore} from 'fake-indexeddb';
let openStore;
try { ({openStore}=await import('../web/storage.mjs')); } catch(e) { if(e.code!=='ERR_MODULE_NOT_FOUND') throw e; }
const ready=()=>assert.equal(typeof openStore,'function','transaction-complete product store is required');
test('nonempty whole snapshot survives close and reopen',async()=>{
 ready(); const indexedDB=new IDBFactory();let s=await openStore({indexedDB,name:'persist'});
 const data={level:2,board:[['pink'],[]],round:'r2',history:[[]],choice:'declined'};
 assert.equal((await s.write(data,0)).revision,1);s.close();s=await openStore({indexedDB,name:'persist'});
 assert.deepEqual((await s.read()).data,data);s.close();
});
test('put request success followed by transaction abort must reject and retain old save',async()=>{
 ready();const indexedDB=new IDBFactory();const s=await openStore({indexedDB,name:'abort'});await s.write({moves:1},0);
 const original=IDBObjectStore.prototype.put;let succeeded=false;
 IDBObjectStore.prototype.put=function(value,key){const q=original.call(this,value,key);if(key==='current')q.addEventListener('success',()=>{succeeded=true;this.transaction.abort();});return q;};
 try{await assert.rejects(s.write({moves:2},1));}finally{IDBObjectStore.prototype.put=original;}
 assert.equal(succeeded,true);assert.deepEqual((await s.read()).data,{moves:1});s.close();
});
test('another tab cannot silently overwrite a newer commit',async()=>{
 ready();const indexedDB=new IDBFactory();const a=await openStore({indexedDB,name:'conflict'}),b=await openStore({indexedDB,name:'conflict'});
 await a.write({round:'new'},0);await assert.rejects(b.write({round:'stale'},0),/conflict/);assert.equal((await b.read()).data.round,'new');a.close();b.close();
});
test('explicit replacement quarantines corrupt payload atomically',async()=>{
 ready();const indexedDB=new IDBFactory();const s=await openStore({indexedDB,name:'quarantine'});await s.write({broken:true},0);await s.replace({fresh:true},1);
 const db=await new Promise((resolve,reject)=>{const q=indexedDB.open('quarantine');q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error);});
 const old=await new Promise((resolve,reject)=>{const q=db.transaction('snapshots').objectStore('snapshots').get('quarantine:1');q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error);});
 assert.deepEqual(old.data,{broken:true});assert.deepEqual((await s.read()).data,{fresh:true});db.close();s.close();
});
