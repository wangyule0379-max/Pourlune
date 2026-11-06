package dev.pourlune.glassgarden.localqa;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import org.json.JSONObject;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.LinkOption;
import java.nio.file.NoSuchFileException;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.List;
import java.util.Arrays;

final class LegacyReader {
 private static final List<String> KEYS=Arrays.asList("music","sound","haptics","reduced_motion","color_symbols","strong_contrast");
 private static boolean exists(Path path)throws IOException{
  try{BasicFileAttributes attrs=Files.readAttributes(path,BasicFileAttributes.class,LinkOption.NOFOLLOW_LINKS);if(!attrs.isRegularFile()||attrs.isSymbolicLink())throw new IOException("Unexpected previous-save file");return true;}
  catch(NoSuchFileException error){return false;}
 }
 static JSONObject read(Context context)throws Exception{
  JSONObject result=new JSONObject().put("protocolVersion",1).put("sourceFile","pourlune_dev.sqlite").put("originalRetained",true);
  Path source=context.getDatabasePath("pourlune_dev.sqlite").toPath();
  if(!exists(source)){if(exists(new File(source.toString()+"-wal").toPath())||exists(new File(source.toString()+"-shm").toPath()))throw new IOException("Orphaned previous-save journal");return result.put("status","missing");}
  Path scratch=Files.createTempDirectory(context.getCacheDir().toPath(),"garden-legacy-");
  try{
   Path copy=scratch.resolve("pourlune_dev.sqlite");
   // Never let SQLite open/checkpoint the original main, WAL or SHM.
   for(String suffix:new String[]{"","-wal","-shm"}){Path original=new File(source.toString()+suffix).toPath();if(exists(original))Files.copy(original,new File(copy.toString()+suffix).toPath());}
   try(SQLiteDatabase db=SQLiteDatabase.openDatabase(copy.toString(),null,SQLiteDatabase.OPEN_READONLY)){
    try(Cursor check=db.rawQuery("PRAGMA quick_check(1)",null)){if(!check.moveToFirst()||!"ok".equals(check.getString(0))||check.moveToNext())throw new IOException("Unreadable previous-save contents");}
    int version=db.getVersion();if(version<1||version>5)throw new IOException("Unsupported previous-save schema");
    JSONObject preferences=new JSONObject();
    if(version>=3)try(Cursor rows=db.rawQuery("SELECT key,value FROM settings",null)){
     while(rows.moveToNext()){if(rows.getType(0)!=Cursor.FIELD_TYPE_STRING)throw new IOException("Unreadable setting key");String key=rows.getString(0);if(!KEYS.contains(key))continue;int value=rows.getInt(1);if(rows.getType(1)!=Cursor.FIELD_TYPE_INTEGER||(value!=0&&value!=1))throw new IOException("Unreadable setting value");preferences.put(key,value==1);}
    }
    Object privacy=JSONObject.NULL;
    if(version>=4)try(Cursor rows=db.rawQuery("SELECT value FROM service_values WHERE key=?",new String[]{"privacy_choices"})){
     if(rows.moveToFirst()){if(rows.getType(0)!=Cursor.FIELD_TYPE_STRING)throw new IOException("Unreadable privacy value");JSONObject raw=new JSONObject(rows.getString(0));if(!(raw.opt("analytics") instanceof Boolean)||!(raw.opt("crash") instanceof Boolean))throw new IOException("Unreadable privacy choice");privacy=new JSONObject().put("analytics",raw.getBoolean("analytics")).put("crash",raw.getBoolean("crash"));}
    }
    return result.put("status","present").put("databaseVersion",version).put("preferences",preferences).put("privacy",privacy);
   }
  }finally{
   // Cleanup only this unique copied family; originals never enter this subtree.
   File[] files=scratch.toFile().listFiles();if(files!=null)for(File file:files)Files.deleteIfExists(file.toPath());Files.deleteIfExists(scratch);
  }
 }
}
