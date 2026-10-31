import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_policy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Handle, Transport;

class PreparingStore extends Fake implements GameStore {
  PreparingStore(this.backing);
  final GameStore backing;
  Completer<void>? prepared, release;
  @override
  Future<Object?> readServiceValue(String key) => backing.readServiceValue(key);
  @override
  Future<int?> lastFullscreenMillis() => backing.lastFullscreenMillis();
  @override
  Future<void> prepareFullscreen(String id, String kind) async {
    await backing.prepareFullscreen(id, kind);
    prepared?.complete();
    await release?.future;
  }

  @override
  Future<void> clearFullscreenIntent(String id) =>
      backing.clearFullscreenIntent(id);
  @override
  Future<void> recordFullscreen(String id, String kind, int millis) =>
      backing.recordFullscreen(id, kind, millis);
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late GameStore backing;
  late PreparingStore store;
  late Transport transport;
  late AdCoordinator ads;
  var permitted = true, showPermitted = true;
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));
  setUp(() async {
    directory = Directory.systemTemp.createTempSync('gm-ad-rules-');
    backing = await GameStore.open(
      '${directory.path}/qa.sqlite',
      factory: databaseFactoryFfi,
    );
    store = PreparingStore(backing);
    transport = Transport();
    permitted = true;
    showPermitted = true;
    ads = AdCoordinator(
      store: store,
      transport: transport,
      configured: true,
      rulesAllowLoad: (_) => permitted,
      rulesAllowShow: (_) => showPermitted,
    );
    await ads.initialize();
    ads.update(consent: true);
  });
  tearDown(() async {
    ads.dispose();
    for (final pending in transport.loads) {
      if (!pending.isCompleted) pending.complete(Handle());
    }
    await settle();
    await backing.close();
    directory.deleteSync(recursive: true);
  });
  Future<Handle> inventory() async {
    final pending = ads.preload(AdKind.rewarded), handle = Handle();
    transport.loads.last.complete(handle);
    await pending;
    return handle;
  }

  test('remote scene blocks loading and discards a late allowed load after closing', () async {
    permitted = false;
    await ads.preload(AdKind.rewarded);
    expect(transport.loads, isEmpty);
    permitted = true;
    final pending = ads.preload(AdKind.rewarded);
    permitted = false;
    ads.update(remote: const RemotePolicy());
    final handle = Handle();
    transport.loads.first.complete(handle);
    await pending;
    await settle();
    expect(handle.disposals, 1);
    expect(ads.ready(AdKind.rewarded), false);
    expect(handle.shows, 0);
  });
  test(
    'config off then on while SQLite prepares revokes the original opportunity',
    () async {
      final handle = await inventory();
      store.prepared = Completer();
      store.release = Completer();
      final showing = ads.show(AdKind.rewarded, 'unstarted');
      await store.prepared!.future;
      permitted = false;
      ads.update(remote: const RemotePolicy());
      permitted = true;
      ads.update(remote: const RemotePolicy());
      store.release!.complete();
      final result = await showing;
      expect(result.reason, 'stale');
      expect(handle.shows, 0);
      expect(await backing.readServiceValue('fullscreen_intent'), isNull);
    },
  );
  test(
    'remote interval blocks show while keeping preloaded inventory',
    () async {
      showPermitted = false;
      final handle = await inventory();
      expect(ads.ready(AdKind.rewarded), false);
      await ads.preload(AdKind.rewarded);
      expect(transport.loads.length, 1);
      expect(handle.disposals, 0);
      expect((await ads.show(AdKind.rewarded, 'interval')).shown, false);
      showPermitted = true;
      expect(ads.ready(AdKind.rewarded), true);
    },
  );
  test('rule closes during a shown ad without cancelling its original legal reward', () async {
    final handle = await inventory();
    var rewards = 0;
    final showing = ads.show(
      AdKind.rewarded,
      'shown',
      onReward: () => rewards++,
    );
    while (handle.callbacks == null) {
      await settle();
    }
    handle.callbacks!.shown();
    permitted = false;
    ads.update(remote: const RemotePolicy());
    handle.callbacks!.reward();
    handle.callbacks!.reward();
    handle.callbacks!.closed();
    expect((await showing).shown, true);
    expect(rewards, 1);
    await ads.retryTiming();
  });
}
