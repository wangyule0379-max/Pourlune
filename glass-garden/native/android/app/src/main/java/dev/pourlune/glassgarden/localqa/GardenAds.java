package dev.pourlune.glassgarden.localqa;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
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
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
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
import java.util.ArrayList;

// Official test inventories, one fullscreen route. Retain original callback
// IDs/times until game acknowledgement; loading never decides when to show.
// One process owner survives Activity replacement; only its current Activity
// may send commands. Detached deliveries remain in the durable receipt queue.
final class GardenAds {
 private static final class Inventory {
  final String id,kind;boolean loading=true,cancelled=false;RewardedAd reward;InterstitialAd interstitial;
  Inventory(String id,String kind){this.id=id;this.kind=kind;}
 }
 private static GardenAds retained;
 private int qaTraceCount;
 private Activity activity;
 private Consumer<JSONObject> deliver;
 private final Context context;
 private final Handler main=new Handler(Looper.getMainLooper());
 private final SharedPreferences storage;
 private final ConsentInformation consent;
 private JSONArray queue;
 private boolean storageFailed=false,unreadable=false,initialized=false,initializing=false,active=false;
 private JSONObject statisticsGate=new JSONObject();
 private Inventory presenting;
 private final Map<String,Inventory> inventories=new HashMap<>();
 private final Map<String,JSONObject> observations=new HashMap<>();
 private final Map<String,String> attemptSessions=new HashMap<>();
 static GardenAds attach(Activity activity,Consumer<JSONObject> deliver){
  if(retained==null)retained=new GardenAds(activity,deliver);
  retained.activity=activity;retained.deliver=deliver;retained.active=false;retained.statisticsGate=new JSONObject();
  for(Inventory slot:new ArrayList<>(retained.inventories.values()))retained.cancel(slot);
  return retained;
 }
 void detach(Activity caller){if(activity!=caller)return;active=false;activity=null;deliver=null;statisticsGate=new JSONObject();for(Inventory slot:new ArrayList<>(inventories.values()))cancel(slot);}
 private GardenAds(Activity activity,Consumer<JSONObject> deliver){
  this.activity=activity;this.deliver=deliver;context=activity.getApplicationContext();storage=context.getSharedPreferences("garden_native_ad_receipts_v1",0);consent=UserMessagingPlatform.getConsentInformation(context);
  try{queue=new JSONArray(storage.getString("pending","[]"));for(int i=0;i<queue.length();i++){JSONObject e=queue.getJSONObject(i);if(!e.getString("attemptId").isEmpty())observations.put(e.getString("attemptId")+":"+e.getString("type"),e);}}catch(Exception error){storageFailed=true;unreadable=true;queue=new JSONArray();Log.e("GardenAds","Unreadable native receipt store; ads disabled");}
 }
 void setActive(Activity caller,boolean value){if(activity==caller)active=value;}
 void command(Activity caller,JSONObject message){if(activity==caller)command(message);}
 private void command(JSONObject message){
  String command=message.optString("command"),id=message.optString("attemptId"),kind=message.optString("kind","rewarded");
  if(command.equals("statistics-gate")){statisticsGate=new JSONObject();try{Object session=message.opt("session"),epoch=message.opt("epoch"),allowed=message.opt("allowed");if(session instanceof String&&epoch instanceof Number&&allowed instanceof Boolean){UUID.fromString((String)session);double value=((Number)epoch).doubleValue();if(Double.isFinite(value)&&value>=0&&value<=9007199254740991d&&Math.floor(value)==value)statisticsGate.put("session",session).put("epoch",epoch).put("allowed",allowed);}}catch(Exception error){statisticsGate=new JSONObject();}return;}
  if(command.equals("drain")){drain();return;}
  if(command.equals("state")){try{JSONArray ids=new JSONArray();for(Inventory slot:inventories.values())ids.put(slot.id);if(presenting!=null)ids.put(presenting.id);JSONObject event=new JSONObject().put("id",UUID.randomUUID().toString()).put("type","state").put("attemptId","").put("occurredAt",Instant.now().toString()).put("busyAttemptIds",ids);event.put("adConsent",new JSONObject(statisticsGate.toString()));queue.put(event);forward(event,!persist());}catch(Exception error){Log.e("GardenAds","Could not report native state");}return;}
  if(command.equals("ack")){ack(message.optString("eventId"));return;}
  if(command.equals("initialize")){for(Inventory slot:new ArrayList<>(inventories.values()))cancel(slot);updateConsent();return;}
  if(command.equals("privacy")){if(active&&presenting==null&&consent.getPrivacyOptionsRequirementStatus()==ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED)UserMessagingPlatform.showPrivacyOptionsForm(activity,error->{if(error!=null)Log.w("GardenAds","UMP privacy code="+error.getErrorCode()+" message="+error.getMessage());status();});return;}
  try{UUID.fromString(id);}catch(Exception error){return;}
  if(!kind.equals("rewarded")&&!kind.equals("interstitial"))return;
  if(command.equals("cancel")){Inventory slot=inventories.get(kind);if(slot!=null&&slot.id.equals(id))cancel(slot);return;}
  if(!active||storageFailed){emit("blocked",id,kind,!active?"in_background":"sdk_error",null);return;}
  if(command.equals("load")){attemptSessions.putIfAbsent(id,statisticsGate.optString("session"));load(id,kind);}
  if(command.equals("show"))show(id,kind);
 }
 private void cancel(Inventory slot){slot.cancelled=true;if(!slot.loading)inventories.remove(slot.kind);emit("cancelled",slot.id,slot.kind,null,null);}
 private void updateConsent(){consent.requestConsentInfoUpdate(activity,new ConsentRequestParameters.Builder().build(),this::status,error->{Log.w("GardenAds","UMP code="+error.getErrorCode()+" message="+error.getMessage());status();});}
 private void status(){emit("consent","","rewarded",null,null);}
 private void load(String id,String kind){
  Inventory old=inventories.get(kind);if(old!=null&&old.id.equals(id)){if(!old.loading)emit("loaded",id,kind,null,null);return;}
  if(old!=null||presenting!=null){emit("blocked",id,kind,"busy",null);return;}
  Inventory slot=new Inventory(id,kind);inventories.put(kind,slot);
  Runnable ready=()->{
   status();if(inventories.get(kind)!=slot)return;if(slot.cancelled){inventories.remove(kind);return;}
   if(!active||!consent.canRequestAds()){inventories.remove(kind);emit("blocked",id,kind,!active?"in_background":"privacy",null);return;}
   if(initialized){request(slot);return;}
   if(initializing){inventories.remove(kind);emit("blocked",id,kind,"busy",null);return;}
   initializing=true;MobileAds.setRequestConfiguration(new RequestConfiguration.Builder().setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_PG).build());
   new Thread(()->MobileAds.initialize(context,status->main.post(()->{
    initializing=false;initialized=true;status.getAdapterStatusMap().forEach((name,adapter)->Log.i("GardenAds","adapter="+name+" status="+adapter.getInitializationState()+" latency="+adapter.getLatency()+" description="+adapter.getDescription()));
    if(inventories.get(kind)!=slot)return;if(slot.cancelled){inventories.remove(kind);return;}
    if(active&&consent.canRequestAds())request(slot);else{inventories.remove(kind);emit("blocked",id,kind,!active?"in_background":"privacy",null);}
   })),"GardenAdsInit").start();
  };
  // Preloading cannot unexpectedly open a form during normal gameplay.
  if(kind.equals("rewarded"))UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity,error->{if(error!=null)Log.w("GardenAds","UMP form code="+error.getErrorCode()+" message="+error.getMessage());ready.run();});else ready.run();
 }
 private void request(Inventory slot){
  Bundle extras=new Bundle();extras.putString("npa","1");AdRequest request=new AdRequest.Builder().addNetworkExtrasBundle(AdMobAdapter.class,extras).build();emit("load_requested",slot.id,slot.kind,null,null);
  if(slot.kind.equals("rewarded"))RewardedAd.load(context,"ca-app-pub-3940256099942544/5224354917",request,new RewardedAdLoadCallback(){
   @Override public void onAdFailedToLoad(LoadAdError error){failed(slot,error);}
   @Override public void onAdLoaded(RewardedAd value){slot.reward=value;loaded(slot);}
  });else InterstitialAd.load(context,"ca-app-pub-3940256099942544/1033173712",request,new InterstitialAdLoadCallback(){
   @Override public void onAdFailedToLoad(LoadAdError error){failed(slot,error);}
   @Override public void onAdLoaded(InterstitialAd value){slot.interstitial=value;loaded(slot);}
  });
 }
 private void failed(Inventory slot,LoadAdError error){diagnostic(error);if(inventories.get(slot.kind)==slot)inventories.remove(slot.kind);emit("load_failed",slot.id,slot.kind,reason(error),error);}
 private void loaded(Inventory slot){if(inventories.get(slot.kind)!=slot)return;if(slot.cancelled){inventories.remove(slot.kind);return;}slot.loading=false;emit("loaded",slot.id,slot.kind,null,null);}
 private void show(String id,String kind){
  if(presenting!=null&&presenting.id.equals(id))return;Inventory slot=inventories.get(kind);
  if(activity==null||activity.isFinishing()||activity.isDestroyed()||slot==null||!slot.id.equals(id)||slot.loading||slot.cancelled||presenting!=null||!consent.canRequestAds()){emit("show_failed",id,kind,!consent.canRequestAds()?"privacy":"not_ready",null);return;}
  inventories.remove(kind);presenting=slot;FullScreenContentCallback callback=new FullScreenContentCallback(){
   @Override public void onAdShowedFullScreenContent(){emit("shown",id,kind,null,null);}
   @Override public void onAdImpression(){emit("impression",id,kind,null,null);}
   @Override public void onAdDismissedFullScreenContent(){if(presenting==slot)presenting=null;emit("closed",id,kind,null,null);}
   @Override public void onAdFailedToShowFullScreenContent(AdError error){if(presenting==slot)presenting=null;diagnostic(error);emit("show_failed",id,kind,"sdk_error",error);}
  };
  if(slot.reward!=null){slot.reward.setFullScreenContentCallback(callback);slot.reward.show(activity,reward->emit("reward",id,kind,null,null));}else if(slot.interstitial!=null){slot.interstitial.setFullScreenContentCallback(callback);slot.interstitial.show(activity);}else{presenting=null;emit("show_failed",id,kind,"not_ready",null);}
 }
 private static String reason(AdError e){return e.getCode()==AdRequest.ERROR_CODE_NO_FILL?"no_fill":e.getCode()==AdRequest.ERROR_CODE_NETWORK_ERROR?"network":"sdk_error";}
 private static void diagnostic(AdError e){Log.w("GardenAds","domain="+e.getDomain()+" code="+e.getCode()+" message="+e.getMessage());}
 private boolean persist(){if(unreadable)return false;boolean ok=storage.edit().putString("pending",queue.toString()).commit();if(!ok){storageFailed=true;Log.e("GardenAds","Native ad receipt write failed");}return ok;}
 private void forward(JSONObject event,boolean replayed){try{if(deliver!=null){JSONObject copy=new JSONObject(event.toString()).put("replayed",replayed);if(BuildConfig.ENABLE_QA_SERVICES&&qaTraceCount<256){qaTraceCount++;JSONObject trace=new JSONObject();for(String key:new String[]{"id","type","kind","attemptId","occurredAt","reason","error","replayed"})if(copy.opt(key)!=null)trace.put(key,copy.opt(key));Log.i("GardenAds","QA callback "+trace);}deliver.accept(copy);}}catch(Exception error){Log.e("GardenAds","Could not forward native callback");}}
 private void emit(String type,String attemptId,String kind,String reason,AdError error){
  try{String key=attemptId+":"+type;if(!attemptId.isEmpty()&&observations.containsKey(key)){forward(observations.get(key),true);return;}JSONObject event=new JSONObject().put("id",UUID.randomUUID().toString()).put("type",type).put("kind",kind).put("attemptId",attemptId).put("occurredAt",Instant.now().toString());if(reason!=null)event.put("reason",reason);if(error!=null)event.put("error",new JSONObject().put("domain",error.getDomain()).put("code",error.getCode()));if(type.equals("consent"))event.put("canRequestAds",consent.canRequestAds()).put("privacyRequired",consent.getPrivacyOptionsRequirementStatus()==ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED);if(!attemptId.isEmpty())observations.put(key,event);event.put("adConsent",new JSONObject(statisticsGate.toString()));queue.put(event);boolean durable=persist(),certain=attemptId.isEmpty()||(!statisticsGate.optString("session").isEmpty()&&statisticsGate.optString("session").equals(attemptSessions.get(attemptId)));forward(event,!durable||!certain);}catch(Exception error2){Log.e("GardenAds","Could not retain native callback");}
 }
 private void ack(String id){JSONArray remaining=new JSONArray();for(int i=0;i<queue.length();i++){JSONObject item=queue.optJSONObject(i);if(item!=null&&!id.equals(item.optString("id")))remaining.put(item);}queue=remaining;persist();}
 private void drain(){for(int i=0;i<queue.length();i++){JSONObject event=queue.optJSONObject(i);if(event!=null)forward(event,true);}}
}
