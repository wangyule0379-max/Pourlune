import test from 'node:test';import assert from 'node:assert/strict';
import {IDBFactory} from 'fake-indexeddb';import {openStore} from '../web/storage.mjs';import {nativeCheckpoint} from '../qa/native-checkpoint.mjs';
test('native QA checkpoints preserve the first original across multiple imports and restore it without resetting revisions',async()=>{
 const indexedDB=new IDBFactory(),store=await openStore({indexedDB}),data={currentLevel:1,analyticsChoice:'declined',disclosureVersion:3,prefs:{music:false},gameProgress:{original:'six bottles'},analyticsResetToken:'existing-reset'};await store.write(data,0);
 const env={indexedDB,native:{identity:'dev.pourlune.glassgarden.localqa',services:'test'},location:{origin:'http://127.0.0.1:43177',pathname:'/index.html'}};
 try{for(const currentLevel of [16,39,100])await nativeCheckpoint({currentLevel,analyticsChoice:'declined',prefs:{}},env);
  assert.equal((await store.read()).revision,4);await nativeCheckpoint(null,env);assert.deepEqual(await store.read(),{revision:5,data});
  await assert.rejects(nativeCheckpoint({currentLevel:16,analyticsChoice:'declined'},{...env,native:{identity:'com.pourlune.app',services:'production'}}));assert.deepEqual(await store.read(),{revision:5,data});
 }finally{store.close();}
});
