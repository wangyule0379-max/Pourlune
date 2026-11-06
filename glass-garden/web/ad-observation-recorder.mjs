// SDK 0.3.1 contract. Bind only after the official fixed package is verified.
// GameServices awaits startup and serializes this with consent changes.
export async function recordAdObservation(client,type,context,event,level,share){
 const policy=type==='ad_impression'&&context.kind==='interstitial';
 if(!share&&!policy)return;
 const id=share?await client.trackAdEvent(type,context,event,level):await client.recordInterstitialImpressionPolicy(context.scene,event,level);
 if(policy&&(id!==event.id||client.getStorageStatus()!=='persistent'))throw Error('Ad policy was not durably recorded');
}
