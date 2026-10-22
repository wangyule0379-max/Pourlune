import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'b04_ads_test.dart' show Handle, Transport;
import 'store_test.dart' show sample, finish;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-independent-');
    store = await GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi);
  });
  tearDown(() async {await store.close();dir.deleteSync(recursive:true);});
  test('B04-R01 shown ad retains native ownership beyond pre-show timeout', () async {
    final transport = Transport();
    final ads = AdCoordinator(store:store,transport:transport,configured:true,showTimeout:const Duration(milliseconds:40));
    try {
      await ads.initialize();ads.update(consent:true);
      final load=ads.preload(AdKind.rewarded); final h=Handle();transport.loads.last.complete(h);await load;
      final result=ads.show(AdKind.rewarded,'review-ad');
      for(var n=0;n<100 && h.callbacks==null;n++){await Future<void>.delayed(const Duration(milliseconds:1));}
      h.callbacks!.shown();
      ads.update(isForeground:false);
      await Future<void>.delayed(const Duration(milliseconds:80));
      final stillShowing=ads.showing, disposals=h.disposals;
      h.callbacks!.closed();await result;
      for(var n=0;n<100 && ads.fullScreenBusy;n++){await Future<void>.delayed(const Duration(milliseconds:1));}
      expect(stillShowing,isTrue,reason:'Actual native overlay has not dismissed; timeout cannot remove it');
      expect(disposals,0,reason:'Disposal removes native reward callback routing');
    } finally {ads.dispose();}
  });
  test('B04-R02 late fullscreen write retry preserves subsequent qualifying clears', () async {
    for(var level=11;level<=13;level++){await store.settle(finish(sample('r$level',level:level)),replace:true);}
    expect((await store.progress()).qualifyingClears,3);
    store.fault=(stage){if(stage=='fullscreen')throw StateError('disk fault');};
    await expectLater(store.recordFullscreen('shown-at13','interstitial',1000000),throwsStateError);
    store.fault=null;
    await store.settle(finish(sample('r14',level:14)),replace:true);
    expect((await store.progress()).qualifyingClears,4);
    await store.recordFullscreen('shown-at13','interstitial',1000000);
    expect((await store.progress()).qualifyingClears,1,reason:'Level14 happened after the displayed ad and must not be consumed by its retry');
  });
}
