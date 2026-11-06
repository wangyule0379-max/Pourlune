package dev.pourlune.glassgarden.localqa;

import android.content.Context;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Build;
import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.View;

final class NativeEffects {
 private final Context context;
 private final Runnable stopWebAudio;
 private MediaPlayer player;
 private boolean enabled=false,active=false,waitForInteraction=false,preparing=false;
 private final BroadcastReceiver route=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent intent){waitForInteraction=true;sync();stopWebAudio.run();}};
 NativeEffects(Context context,Runnable stopWebAudio){this.context=context;this.stopWebAudio=stopWebAudio;IntentFilter filter=new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);if(Build.VERSION.SDK_INT>=33)context.registerReceiver(route,filter,Context.RECEIVER_NOT_EXPORTED);else context.registerReceiver(route,filter);}
 void setActive(boolean value){active=value;sync();}
 void music(boolean wanted){enabled=wanted;sync();}
 void interaction(){waitForInteraction=false;sync();}
 void haptic(View view){if(active)view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);}
 private void sync(){
  try{syncPlayer();}catch(IllegalStateException error){if(player!=null)player.release();player=null;preparing=false;Log.w("GardenQA","Optional music state unavailable");}
 }
 private void syncPlayer(){
  if(preparing)return;
  if(!enabled||!active||waitForInteraction){if(player!=null&&player.isPlaying())player.pause();return;}
  if(player!=null){if(!player.isPlaying())player.start();return;}
  MediaPlayer next=new MediaPlayer();
  try(AssetFileDescriptor file=context.getAssets().openFd("web/media/dream-culture.mp3")){
   next.setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build());
   // Preserve the old app's no-focus request; no background service or wake lock.
   next.setDataSource(file.getFileDescriptor(),file.getStartOffset(),file.getLength());next.setLooping(true);next.setVolume(.12f,.12f);
   next.setOnPreparedListener(value->{if(player!=value)return;preparing=false;sync();});
   next.setOnErrorListener((value,what,extra)->{if(player==value){player=null;preparing=false;value.release();Log.w("GardenQA","Optional music unavailable");}return true;});
   player=next;preparing=true;next.prepareAsync();
  }catch(Exception error){if(player==next)player=null;preparing=false;next.release();Log.w("GardenQA","Optional music unavailable");}
 }
 void close(){active=false;enabled=false;try{context.unregisterReceiver(route);}catch(IllegalArgumentException ignored){}if(player!=null){player.release();player=null;}preparing=false;}
}
