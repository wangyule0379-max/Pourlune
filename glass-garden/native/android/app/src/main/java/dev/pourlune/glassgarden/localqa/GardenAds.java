package dev.pourlune.glassgarden.localqa;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.UUID;
import java.time.Instant;
import java.util.function.Consumer;
import java.util.Map;
import java.util.HashMap;

// Native test ads only. The JS game saves the bound attempt before load/show;
// this owner retains earned callbacks until the game acknowledges its transaction.
final class GardenAds {
 private final Activity activity;
 private final Consumer<JSONObject> deliver;
 private final SharedPreferences storage;
 private final ConsentInformation consent;
 private JSONArray queue;
 private boolean storageFailed=false,unreadable=false,initialized=false,initializing=false,shown=false,active=false,cancelled=false;
 private String loadingId=null,loadedId=null,shownId=null;
 private final Map<String,JSONObject> observations=new HashMap<>();
 private RewardedAd ad;
 GardenAds(Activity activity,Consumer<JSONObject> deliver){
  this.activity=activity;this.deliver=deliver;storage=activity.getSharedPreferences("garden_native_ad_receipts_v1",0);
  consent=UserMessagingPlatform.getConsentInformation(activity);
  try{queue=new JSONArray(storage.getString("pending","[]"));for(int i=0;i<queue.length();i++){JSONObject e=queue.getJSONObject(i);if(!e.getString("attemptId").isEmpty())observations.put(e.getString("attemptId")+":"+e.getString("type"),e);}}catch(Exception error){storageFailed=true;unreadable=true;queue=new JSONArray();Log.e("GardenAds","Unreadable native receipt store; ads disabled");}
 }
 void setActive(boolean value){active=value;}
 void command(JSONObject message){
  String command=message.optString("command"),id=message.optString("attemptId");
  if(command.equals("drain")){drain();return;}
  if(command.equals("state")){try{JSONArray ids=new JSONArray();if(loadingId!=null)ids.put(loadingId);if(loadedId!=null)ids.put(loadedId);if(shownId!=null)ids.put(shownId);JSONObject event=new JSONObject().put("id",UUID.randomUUID().toString()).put("type","state").put("attemptId","").put("occurredAt",Instant.now().toString()).put("busyAttemptIds",ids);queue.put(event);persist();deliver.accept(event);}catch(Exception error){Log.e("GardenAds","Could not report native state");}return;}
  if(command.equals("ack")){ack(message.optString("eventId"));return;}
  if(command.equals("initialize")){updateConsent();return;}
  if(command.equals("privacy")){if(active&&consent.getPrivacyOptionsRequirementStatus()==ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED)UserMessagingPlatform.showPrivacyOptionsForm(activity,error->{if(error!=null)Log.w("GardenAds","UMP privacy code="+error.getErrorCode()+" message="+error.getMessage());status();});return;}
  try{UUID.fromString(id);}catch(Exception error){return;}
  if(command.equals("cancel")){if(!shown){if(id.equals(loadingId))cancelled=true;if(id.equals(loadedId)){loadedId=null;ad=null;}emit("cancelled",id,null,null);}return;}
  if(!active){emit(command.equals("show")?"show_failed":"load_failed",id,"in_background",null);return;}
  if(storageFailed){emit("load_failed",id,"sdk_error",null);return;}
  if(command.equals("load"))load(id);
  if(command.equals("show"))show(id);
 }
 private void updateConsent(){consent.requestConsentInfoUpdate(activity,new ConsentRequestParameters.Builder().build(),this::status,error->{Log.w("GardenAds","UMP code="+error.getErrorCode()+" message="+error.getMessage());status();});}
 private void status(){emit("consent","",null,null);}
 private void load(String id){
  if(id.equals(loadingId))return;if(id.equals(loadedId)){emit("loaded",id,null,null);return;}
  if(loadingId!=null||loadedId!=null||shown){emit("load_failed",id,"busy",null);return;}
  loadingId=id;cancelled=false;
  UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity,error->{
   if(error!=null)Log.w("GardenAds","UMP form code="+error.getErrorCode()+" message="+error.getMessage());
   status();if(!id.equals(loadingId))return;if(cancelled){loadingId=null;return;}
   if(!active||!consent.canRequestAds()){loadingId=null;emit("load_failed",id,!active?"in_background":"privacy",null);return;}
   if(initialized){request(id);return;}
   if(initializing){loadingId=null;emit("load_failed",id,"busy",null);return;}
   initializing=true;MobileAds.setRequestConfiguration(new RequestConfiguration.Builder().setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_PG).build());
   new Thread(()->MobileAds.initialize(activity,status->activity.runOnUiThread(()->{
    initializing=false;initialized=true;
    status.getAdapterStatusMap().forEach((name,adapter)->Log.i("GardenAds","adapter="+name+" status="+adapter.getInitializationState()+" latency="+adapter.getLatency()+" description="+adapter.getDescription()));
    if(id.equals(loadingId)&&cancelled){loadingId=null;return;}
    if(id.equals(loadingId)&&active&&consent.canRequestAds())request(id);else if(id.equals(loadingId)){loadingId=null;emit("load_failed",id,!active?"in_background":"privacy",null);}
   })),"GardenAdsInit").start();
  });
 }
 private void request(String id){
  Bundle extras=new Bundle();extras.putString("npa","1");
  RewardedAd.load(activity,"ca-app-pub-3940256099942544/5224354917",new AdRequest.Builder().addNetworkExtrasBundle(AdMobAdapter.class,extras).build(),new RewardedAdLoadCallback(){
   @Override public void onAdFailedToLoad(LoadAdError error){diagnostic(error);if(id.equals(loadingId))loadingId=null;emit("load_failed",id,reason(error),error);}
   @Override public void onAdLoaded(RewardedAd value){if(!id.equals(loadingId))return;loadingId=null;if(cancelled)return;loadedId=id;ad=value;emit("loaded",id,null,null);}
  });
 }
 private void show(String id){
  if(shown&&id.equals(shownId))return;
  if(!id.equals(loadedId)||ad==null||shown||!consent.canRequestAds()){if(id.equals(loadedId)){loadedId=null;ad=null;}emit("show_failed",id,!consent.canRequestAds()?"privacy":"not_ready",null);return;}
  RewardedAd value=ad;ad=null;loadedId=null;shown=true;shownId=id;
  value.setFullScreenContentCallback(new FullScreenContentCallback(){
   @Override public void onAdShowedFullScreenContent(){emit("shown",id,null,null);}
   @Override public void onAdImpression(){emit("impression",id,null,null);}
   @Override public void onAdDismissedFullScreenContent(){shown=false;shownId=null;emit("closed",id,null,null);}
   @Override public void onAdFailedToShowFullScreenContent(AdError error){shown=false;shownId=null;diagnostic(error);emit("show_failed",id,"sdk_error",error);}
  });
  value.show(activity,reward->emit("reward",id,null,null));
 }
 private static String reason(AdError e){return e.getCode()==AdRequest.ERROR_CODE_NO_FILL?"no_fill":e.getCode()==AdRequest.ERROR_CODE_NETWORK_ERROR?"network":"sdk_error";}
 private static void diagnostic(AdError e){Log.w("GardenAds","domain="+e.getDomain()+" code="+e.getCode()+" message="+e.getMessage());}
 private void persist(){if(unreadable)return;if(!storage.edit().putString("pending",queue.toString()).commit()){storageFailed=true;Log.e("GardenAds","Native ad receipt write failed");}}
 private void emit(String type,String attemptId,String reason,AdError error){
  try{String key=attemptId+":"+type;if(!attemptId.isEmpty()&&observations.containsKey(key)){deliver.accept(observations.get(key));return;}JSONObject event=new JSONObject().put("id",UUID.randomUUID().toString()).put("type",type).put("attemptId",attemptId).put("occurredAt",Instant.now().toString());
   if(reason!=null)event.put("reason",reason);
   if(error!=null)event.put("error",new JSONObject().put("domain",error.getDomain()).put("code",error.getCode()));
   if(type.equals("consent"))event.put("canRequestAds",consent.canRequestAds()).put("privacyRequired",consent.getPrivacyOptionsRequirementStatus()==ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED);
   if(!attemptId.isEmpty())observations.put(key,event);queue.put(event);persist();deliver.accept(event);
  }catch(Exception error2){Log.e("GardenAds","Could not retain native callback");}
 }
 private void ack(String id){JSONArray remaining=new JSONArray();for(int i=0;i<queue.length();i++){JSONObject item=queue.optJSONObject(i);if(item!=null&&!id.equals(item.optString("id")))remaining.put(item);}queue=remaining;persist();}
 private void drain(){for(int i=0;i<queue.length();i++){JSONObject event=queue.optJSONObject(i);if(event!=null)deliver.accept(event);}}
}
