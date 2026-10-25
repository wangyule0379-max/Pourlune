import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Transport;
import 'support/b04_v4_fixture.dart';
import 'store_test.dart' show sample, daily, finish;

void main() {
  sqfliteFfiInit();
  test('B04-R02 nonempty schema4 to5 preserves both slots/rewards/choices/count; legacy uncertain show is not a consumption boundary', () async {
    final dir = Directory.systemTemp.createTempSync('b04-v4-');
    final path = '${dir.path}/g.db';
    final active = sample(
      'legacy-active',
      level: 14,
    ).pour(0, 2).state.grantExtraBottle();
    final pending = sample('legacy-origin', level: 4).grantExtraBottle();
    await writeLegacyV4(
      path,
      databaseFactoryFfi,
      active: active,
      pending: pending,
      dailyState: daily(),
    );
    final store = await GameStore.open(path, factory: databaseFactoryFfi);
    try {
      expect(await store.db.getVersion(), 5);
      expect(
        (await store.load('ordinary')).instance!.toJson(),
        active.toJson(),
      );
      expect((await store.load('daily')).instance!.toJson(), daily().toJson());
      expect((await store.progress()).qualifyingClears, 2);
      expect((await store.progress()).receipts, 1);
      expect((await store.readSettings()).music, isFalse);
      expect(
        (await store.pendingRewards()).single.origin.toJson(),
        pending.toJson(),
      );
      expect(await store.db.query('reward_entitlements'), hasLength(1));
      expect(await store.readServiceValue('privacy_choices'), {
        'analytics': false,
        'crash': true,
      });
      expect(await store.claimServiceEvent('legacy-event'), isFalse);
      expect(await store.lastFullscreenMillis(), 1000000);
      expect(await store.db.query('fullscreen_attempts'), isEmpty);
      final ads = AdCoordinator(
        store: store,
        transport: Transport(),
        configured: true,
      );
      try {
        await ads.initialize();
        expect(ads.cooldown.inSeconds, greaterThanOrEqualTo(179));
      } finally {
        ads.dispose();
      }
      await expectLater(
        store.recordFullscreen('legacy-uncertain', 'interstitial', 1100000),
        throwsStateError,
      );
      expect((await store.progress()).qualifyingClears, 2);
      expect(await store.db.query('fullscreen_shows'), hasLength(1));
      await store.recordFullscreen('legacy-shown', 'interstitial', 1200000);
      expect((await store.progress()).qualifyingClears, 2);
      await store.prepareFullscreen('new-known', 'interstitial');
      await store.recordFullscreen('new-known', 'interstitial', 1200000);
      expect((await store.progress()).qualifyingClears, 0);
      await store.settle(finish(active));
      expect((await store.progress()).qualifyingClears, 1);
      await store.recordFullscreen('new-known', 'interstitial', 1300000);
      expect((await store.progress()).qualifyingClears, 1);
    } finally {
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
