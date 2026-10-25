import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_policy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Handle implements AdHandle {
  Completer<void>? platformCall;
  AdCallbacks? callbacks;
  int shows = 0, disposals = 0;
  @override
  Future<void> show(AdCallbacks value) async {
    shows++;
    callbacks = value;
    if (platformCall != null) await platformCall!.future;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class Transport implements AdTransport {
  final loads = <Completer<AdHandle>>[];
  final kinds = <AdKind>[];
  @override
  Future<AdHandle> load(AdKind kind) {
    final c = Completer<AdHandle>();
    kinds.add(kind);
    loads.add(c);
    return c.future;
  }
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late Transport transport;
  late AdCoordinator ads;
  var elapsed = Duration.zero;
  Future<void> until(bool Function() f) async {
    for (var n = 0; n < 1000 && !f(); n++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(f(), isTrue);
  }

  Future<Handle> ready([AdKind kind = AdKind.rewarded]) async {
    final f = ads.preload(kind);
    final h = Handle();
    transport.loads.last.complete(h);
    await f;
    return h;
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-ads-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    transport = Transport();
    elapsed = Duration.zero;
    ads = AdCoordinator(
      store: store,
      transport: transport,
      configured: true,
      clock: FullscreenCooldown(
        wall: () => DateTime.fromMillisecondsSinceEpoch(1000000),
        monotonic: () => elapsed,
      ),
    );
    await ads.initialize();
    ads.update(consent: true);
  });
  tearDown(() async {
    ads.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });
  test('AC18/34 no consent no loading; ready/late loading never auto shows; stale result disposed', () async {
    ads.update(consent: false);
    await ads.preload(AdKind.rewarded);
    expect(transport.loads, isEmpty);
    ads.update(consent: true);
    final f = ads.preload(AdKind.rewarded);
    ads.update(isForeground: false);
    final old = Handle();
    transport.loads.last.complete(old);
    await f;
    await until(() => old.disposals == 1);
    expect(old.shows, 0);
    expect(ads.ready(AdKind.rewarded), isFalse);
    ads.update(isForeground: true);
    final current = await ready();
    expect(current.shows, 0);
    expect(ads.ready(AdKind.rewarded), isTrue);
  });
  test('AC19/32 double intent, duplicate callbacks and closure do not award; old delivered confirmation retains own request after next show', () async {
    final a = await ready();
    var oldRewards = 0, newRewards = 0;
    final result = ads.show(AdKind.rewarded, 'A', onReward: () => oldRewards++);
    await until(() => a.shows == 1);
    expect((await ads.show(AdKind.rewarded, 'B')).shown, isFalse);
    a.callbacks!.shown();
    a.callbacks!.shown();
    a.callbacks!.closed();
    a.callbacks!.closed();
    await result;
    await until(() => !ads.fullScreenBusy);
    expect(oldRewards, 0);
    expect(await store.db.query('fullscreen_shows'), hasLength(1));
    elapsed = const Duration(seconds: 180);
    final b = await ready();
    final second = ads.show(AdKind.rewarded, 'B', onReward: () => newRewards++);
    await until(() => b.shows == 1);
    a.callbacks!.reward();
    a.callbacks!.reward();
    expect(oldRewards, 1);
    expect(newRewards, 0);
    ads.update(remote: const RemotePolicy(adsEnabled: false));
    b.callbacks!.shown();
    b.callbacks!.reward();
    b.callbacks!.closed();
    await second;
    await until(() => !ads.fullScreenBusy);
    expect(newRewards, 1);
  });
  test('AC17/32 actual shown starts180 even when save fails; Retry persists once and blocks further fullscreens until safe', () async {
    final a = await ready();
    store.fault = (stage) {
      if (stage == 'fullscreen') throw StateError('disk');
    };
    final result = ads.show(AdKind.rewarded, 'A');
    await until(() => a.shows == 1);
    a.callbacks!.shown();
    await until(() => ads.timingSaveFailed);
    a.callbacks!.closed();
    await result;
    expect(ads.cooldown, const Duration(seconds: 180));
    expect(await store.lastFullscreenMillis(), isNull);
    expect(await store.readServiceValue('fullscreen_intent'), isNotNull);
    store.fault = null;
    await ads.retryTiming();
    expect(ads.timingSaveFailed, isFalse);
    expect(await store.lastFullscreenMillis(), 1000000);
    expect(await store.readServiceValue('fullscreen_intent'), isNull);
    elapsed = const Duration(seconds: 179);
    expect(ads.cooldown, const Duration(seconds: 1));
    elapsed = const Duration(seconds: 180);
    expect(ads.cooldown, Duration.zero);
  });
  test('AC18/32 failed show does not consume timestamp and unlocks once; future ready stock is not displayed', () async {
    final a = await ready(AdKind.interstitial);
    final result = ads.show(AdKind.interstitial, 'I');
    await until(() => a.shows == 1);
    a.callbacks!.failed();
    a.callbacks!.closed();
    expect((await result).shown, isFalse);
    await until(() => a.disposals > 0);
    expect(ads.showing, isFalse);
    expect(await store.lastFullscreenMillis(), isNull);
  });
  test(
    'AC32 dispose ends pending native callback wait and timer exactly once',
    () async {
      final a = await ready();
      final result = ads.show(AdKind.rewarded, 'disposed');
      await until(() => a.shows == 1);
      ads.dispose();
      expect(
        (await result.timeout(const Duration(milliseconds: 50))).reason,
        'disposed',
      );
      a.callbacks!.closed();
      // setUp owner already disposed; replace with a fresh object for tearDown.
      ads = AdCoordinator(
        store: store,
        transport: transport,
        configured: false,
      );
    },
  );
  test('AC32 missing platform show reply still releases at watchdog without duplicate navigation', () async {
    ads.dispose();
    ads = AdCoordinator(
      store: store,
      transport: transport,
      configured: true,
      preShowTimeout: const Duration(milliseconds: 20),
    );
    await ads.initialize();
    ads.update(consent: true);
    final a = await ready();
    a.platformCall = Completer<void>();
    final result = ads.show(AdKind.rewarded, 'no-platform-reply');
    await until(() => a.shows == 1);
    expect(
      (await result.timeout(const Duration(milliseconds: 100))).reason,
      'timeout',
    );
    a.platformCall!.complete();
    expect(ads.showing, isFalse);
  });
  test(
    'AC32 failed intent cleanup remains retryable after unshown failure',
    () async {
      final a = await ready();
      await store.db.execute(
        "CREATE TRIGGER fail_clear BEFORE DELETE ON service_values WHEN old.key = 'fullscreen_intent' BEGIN SELECT RAISE(FAIL, 'disk'); END",
      );
      final result = ads.show(AdKind.rewarded, 'clear-fail');
      await until(() => a.shows == 1);
      a.callbacks!.failed();
      await result;
      await until(() => ads.timingSaveFailed);
      await store.db.execute('DROP TRIGGER fail_clear');
      await ads.retryTiming();
      expect(ads.timingSaveFailed, isFalse);
      expect(await store.readServiceValue('fullscreen_intent'), isNull);
      expect(ads.showing, isFalse);
    },
  );
  test(
    'B04-R01 late platform show Future error cannot close a confirmed overlay',
    () async {
      ads.dispose();
      ads = AdCoordinator(
        store: store,
        transport: transport,
        configured: true,
        preShowTimeout: const Duration(milliseconds: 20),
      );
      await ads.initialize();
      ads.update(consent: true);
      final h = await ready();
      h.platformCall = Completer<void>();
      final result = ads.show(AdKind.rewarded, 'late-platform-error');
      await until(() => h.shows == 1);
      h.callbacks!.shown();
      h.platformCall!.completeError(StateError('late platform response'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ads.showing, isTrue);
      expect(h.disposals, 0);
      h.callbacks!.closed();
      expect((await result).reason, 'dismissed');
      expect(h.disposals, 1);
    },
  );
}
