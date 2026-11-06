package dev.pourlune.glassgarden.localqa;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.FrameLayout;
import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.WebViewCompat;
import androidx.webkit.WebViewFeature;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import org.json.JSONObject;

public final class MainActivity extends Activity {
 private static final String HOST="appassets.androidplatform.net", ENTRY="https://"+HOST+"/assets/web/index.html";
 private FrameLayout root;
 private WebView web;
 private Button retry;
 private GardenAds ads;

 @Override public void onCreate(Bundle saved) {
  super.onCreate(saved);
  root=new FrameLayout(this); root.setBackgroundColor(Color.rgb(255,248,239)); setContentView(root);
  if(Build.VERSION.SDK_INT>=30){getWindow().setDecorFitsSystemWindows(false);root.setOnApplyWindowInsetsListener((view,insets)->{android.graphics.Insets bars=insets.getInsets(WindowInsets.Type.systemBars()|WindowInsets.Type.displayCutout());view.setPadding(bars.left,bars.top,bars.right,bars.bottom);return insets;});}
  if(Build.VERSION.SDK_INT>=33)getOnBackInvokedDispatcher().registerOnBackInvokedCallback(android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT,this::back);
  WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG);
  if(BuildConfig.ENABLE_QA_SERVICES)ads=new GardenAds(this,event->{if(web!=null)web.evaluateJavascript("window.GardenAdEvents && window.GardenAdEvents.receive("+event.toString()+")",null);});
  openGame();
 }
 private static boolean local(Uri uri){return "https".equals(uri.getScheme())&&HOST.equals(uri.getHost())&&uri.getPath()!=null&&uri.getPath().startsWith("/assets/web/")&&(uri.getPort()==-1||uri.getPort()==443);}
 private static WebResourceResponse denied(){return new WebResourceResponse("text/plain","UTF-8",403,"Local resources only",Collections.singletonMap("Cache-Control","no-store"),new ByteArrayInputStream("Local resources only".getBytes(StandardCharsets.UTF_8)));}
 private void openGame(){
  if(web!=null){root.removeView(web);web.destroy();}
  if(retry!=null){root.removeView(retry);retry=null;}
  web=new WebView(this);root.addView(web,new FrameLayout.LayoutParams(-1,-1));
  web.setBackgroundColor(Color.rgb(255,248,239));web.getSettings().setJavaScriptEnabled(true);web.getSettings().setDomStorageEnabled(true);web.getSettings().setAllowFileAccess(false);web.getSettings().setAllowContentAccess(false);web.getSettings().setMediaPlaybackRequiresUserGesture(true);web.getSettings().setMixedContentMode(android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW);
  if(BuildConfig.ENABLE_QA_SERVICES&&WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)&&WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)){
   WebViewCompat.addWebMessageListener(web,"GardenAdsBridge",Collections.singleton("https://"+HOST),(view,message,origin,mainFrame,reply)->{if(mainFrame&&ENTRY.equals(view.getUrl()))try{ads.command(new JSONObject(message.getData()));}catch(Exception error){Log.w("GardenAds","Invalid bridge command");}});
   WebViewCompat.addDocumentStartJavaScript(web,"if(window===window.top)Object.defineProperty(window,'GardenNative',{value:Object.freeze({platform:'android',services:'test',ads:'test',appVersion:'0.1.0+3',send:message=>window.GardenAdsBridge.postMessage(JSON.stringify(message))}),writable:false});",Collections.singleton("https://"+HOST));
  }
  WebViewAssetLoader loader=new WebViewAssetLoader.Builder().addPathHandler("/assets/",new WebViewAssetLoader.AssetsPathHandler(this)).build();
  web.setWebViewClient(new WebViewClient(){
   @Override public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest request){if(BuildConfig.ENABLE_QA_SERVICES&&"https".equals(request.getUrl().getScheme())&&"api.gamemunchies.com".equals(request.getUrl().getHost())&&(request.getUrl().getPort()==-1||request.getUrl().getPort()==443))return null;if(!local(request.getUrl()))return denied();WebResourceResponse response=loader.shouldInterceptRequest(request.getUrl());if(response!=null&&request.getUrl().getPath().endsWith(".mjs"))response.setMimeType("text/javascript");return response==null?denied():response;}
   @Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest request){if(request.isForMainFrame()&&request.hasGesture()&&"https://policies.google.com/privacy".equals(request.getUrl().toString())){try{startActivity(new Intent(Intent.ACTION_VIEW,request.getUrl()));}catch(android.content.ActivityNotFoundException error){Log.w("GardenQA","No browser available for privacy policy");}return true;}return !local(request.getUrl());}
   @Override public void onReceivedError(WebView v,WebResourceRequest request,WebResourceError error){if(request.isForMainFrame())failed();}
   @Override public void onReceivedHttpError(WebView v,WebResourceRequest request,WebResourceResponse response){if(request.isForMainFrame())failed();}
  });
  web.setWebChromeClient(new WebChromeClient(){@Override public boolean onConsoleMessage(ConsoleMessage message){if(BuildConfig.DEBUG&&message.messageLevel()==ConsoleMessage.MessageLevel.ERROR)Log.e("GardenQA",message.message());return true;}});
  web.loadUrl(ENTRY);
 }
 private void failed(){runOnUiThread(()->{if(retry!=null)return;web.onPause();retry=new Button(this);retry.setText("Could not open local game files. Retry");retry.setOnClickListener(v->openGame());FrameLayout.LayoutParams p=new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.WRAP_CONTENT,Gravity.CENTER);root.addView(retry,p);});}
 private void lifecycle(boolean active){if(web!=null)web.evaluateJavascript("window.GardenLifecycle && window.GardenLifecycle.setActive("+active+")",null);}
 @Override public void onResume(){super.onResume();if(ads!=null)ads.setActive(true);if(web!=null){web.onResume();lifecycle(true);}}
 @Override public void onPause(){lifecycle(false);if(ads!=null)ads.setActive(false);if(web!=null)web.onPause();super.onPause();}
 private void back(){if(web==null){finish();return;}web.evaluateJavascript("window.GardenLifecycle ? window.GardenLifecycle.back() : false",handled->{if(!"true".equals(handled)){if(web.canGoBack())web.goBack();else finish();}});}
 @SuppressWarnings("deprecation") @Override public void onBackPressed(){back();}
 @Override public void onDestroy(){if(web!=null){root.removeView(web);web.destroy();web=null;}super.onDestroy();}
}
