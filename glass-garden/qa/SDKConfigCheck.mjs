// Explicit read-only live test-scope SDK compatibility check. No event POSTs.
import {writeFile} from 'node:fs/promises';
import {IDBFactory} from 'fake-indexeddb';
import {GameMunchiesClient} from '../.private-dependencies/gamemunchies-javascript/src/index.js';
import {GameServices} from '../web/services.mjs';
const results=[];
for(const platform of ['ios','android']){
 globalThis.indexedDB=new IDBFactory();const requests=[],diagnostics=[];let notify,timer;const changed=new Promise(resolve=>notify=resolve);class ObservedClient extends GameMunchiesClient {constructor(options,dependencies){super({...options,onConfigChanged:snapshot=>{if(snapshot.source==='remote')notify(snapshot);}},dependencies);}}
 const owner=new GameServices({SDK:ObservedClient,platform,statisticsEnabled:false,onDiagnostic:item=>diagnostics.push(item),dependencies:{browser:false,setInterval:()=>0,clearInterval(){},fetch:async(url,init)=>{
  if((init.method||'GET')!=='GET'||new URL(url).origin!=='https://api.gamemunchies.com')throw Error('Read-only SDK check rejected a non-configuration request');
  const response=await fetch(url,{...init,headers:{...init.headers,Origin:platform==='ios'?'http://127.0.0.1:43177':'https://appassets.androidplatform.net'}});
  requests.push({url,method:init.method||'GET',status:response.status,accessControlAllowOrigin:response.headers.get('access-control-allow-origin')});return response;
 }}});
 try{await owner.ready;await owner.client.refreshConfig();const snapshot=await Promise.race([changed,new Promise(resolve=>timer=setTimeout(()=>resolve(owner.client.getConfig()),6000))]);results.push({platform,statisticsEnabled:false,requests,diagnostics,source:snapshot.source,version:snapshot.version,enabled:snapshot.config.enabled,storage:'fake IndexedDB API for transport check only; not device durability'});}
 finally{clearTimeout(timer);await owner.dispose();}
}
await writeFile(new URL('../build/native/sdk-live-config-check.json',import.meta.url),JSON.stringify(results,null,2)+'\n');
console.log(JSON.stringify(results,null,2));
if(results.some(row=>row.source!=='remote'||row.requests.length!==1||row.requests[0].status!==200))process.exitCode=1;
