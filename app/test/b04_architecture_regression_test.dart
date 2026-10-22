import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:pourlune_dev/services/service_policy.dart';

import 'b04_controller_ads_test.dart' show config;

import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Handle, Transport;
import 'store_test.dart' show sample, finish, fixture;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-independent-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await store.close();
    dir.deleteSync(recursive: true);
  });
  test('B04-R01 shown ad retains native ownership beyond pre-show timeout', () async {
    final transport = Transport();
    final ads = AdCoordinator(
      store: store,
      transport: transport,
      configured: true,
      preShowTimeout: const Duration(milliseconds: 40),
    );
    try {
      await ads.initialize();
      ads.update(consent: true);
      final load = ads.preload(AdKind.rewarded);
      final h = Handle();
      transport.loads.last.complete(h);
      await load;
      final result = ads.show(AdKind.rewarded, 'review-ad');
      for (var n = 0; n < 100 && h.callbacks == null; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      h.callbacks!.shown();
      ads.update(isForeground: false);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final stillShowing = ads.showing, disposals = h.disposals;
      h.callbacks!.closed();
      await result;
      for (var n = 0; n < 100 && ads.fullScreenBusy; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(
        stillShowing,
        isTrue,
        reason:
            'Actual native overlay has not dismissed; timeout cannot remove it',
      );
      expect(
        disposals,
        0,
        reason: 'Disposal removes native reward callback routing',
      );
    } finally {
      ads.dispose();
    }
  });
  test('B04-R02 late fullscreen write retry preserves subsequent qualifying clears', () async {
    for (var level = 11; level <= 13; level++) {
      await store.settle(
        finish(sample('r$level', level: level)),
        replace: true,
      );
    }
    expect((await store.progress()).qualifyingClears, 3);
    await store.prepareFullscreen('shown-at13', 'interstitial');
    store.fault = (stage) {
      if (stage == 'fullscreen') throw StateError('disk fault');
    };
    await expectLater(
      store.recordFullscreen('shown-at13', 'interstitial', 1000000),
      throwsStateError,
    );
    store.fault = null;
    await store.settle(finish(sample('r14', level: 14)), replace: true);
    expect((await store.progress()).qualifyingClears, 4);
    await store.recordFullscreen('shown-at13', 'interstitial', 1000000);
    expect(
      (await store.progress()).qualifyingClears,
      1,
      reason: 'Level14 happened after the displayed ad and must not be consumed by its retry',
    );
  });
  Future<GameController> controller(ServiceHub hub, {int through = 12}) async {
    for (var n = 1; n <= through; n++) {
      await store.settle(finish(sample('seed$n', level: n)), replace: true);
    }
    final c = GameController(
      store,
      services: hub,
      library: ContentLibrary(
        main: {for (var n = 1; n <= 60; n++) n: fixture(n)},
      ),
    );
    await c.initialize();
    await hub.initializeLocal();
    hub.ads.update(consent: true);
    return c;
  }

  Future<Handle> ready(ServiceHub hub, Transport transport, AdKind kind) async {
    final loading = hub.ads.preload(kind);
    final h = Handle();
    final index = transport.kinds.lastIndexOf(kind);
    transport.loads[index].complete(h);
    await loading;
    await until(() => hub.ads.ready(kind));
    return h;
  }

  Future<void> solve(GameController c) async {
    for (final move in c.current!.puzzle.referenceMoves) {
      await c.pour(move.from, move.to);
    }
    expect(c.current!.completed, isTrue);
  }

  test('B04-R01 Controller Next does not navigate across shown deadline/background and only closes once on native dismissal', () async {
    final transport = Transport();
    final hub = ServiceHub(
      store: store,
      config: config,
      transport: transport,
      knownPuzzleIds: {},
      adPreShowTimeout: const Duration(milliseconds: 40),
    );
    final c = await controller(hub);
    try {
      await c.startLevel(13);
      await solve(c);
      final h = await ready(hub, transport, AdKind.interstitial);
      var ended = false;
      final next = c.nextLevel()
        ..then((_) {
          ended = true;
        });
      await until(() => h.shows == 1);
      h.callbacks!.shown();
      c.setForeground(false);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(ended, isFalse);
      expect(c.current!.puzzle.mainLevel, 13);
      expect(h.disposals, 0);
      expect(c.busy, isTrue);
      c.setForeground(true);
      await c.nextLevel();
      await c.goHome();
      expect(c.current!.puzzle.mainLevel, 13);
      h.callbacks!.closed();
      h.callbacks!.closed();
      await next;
      expect(c.current!.puzzle.mainLevel, 14);
      expect(c.busy, isFalse);
      expect(h.disposals, 1);
    } finally {
      c.dispose();
      hub.dispose();
    }
  });
  test('B04-R01 Controller received reward after shown deadline is saved once to original before close', () async {
    final transport = Transport();
    final hub = ServiceHub(
      store: store,
      config: config,
      transport: transport,
      knownPuzzleIds: {},
      adPreShowTimeout: const Duration(milliseconds: 40),
    );
    final c = await controller(hub, through: 3);
    try {
      await c.startLevel(4);
      final original = c.current!.id;
      final h = await ready(hub, transport, AdKind.rewarded);
      var ended = false;
      final watch = c.watchExtraBottle()
        ..then((_) {
          ended = true;
        });
      await until(() => h.shows == 1);
      h.callbacks!.shown();
      c.setForeground(false);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      c.setForeground(true);
      expect(ended, isFalse);
      expect(h.disposals, 0);
      h.callbacks!.reward();
      h.callbacks!.reward();
      await until(() => c.current!.extraBottleGranted);
      expect(c.current!.id, original);
      expect(c.busy, isTrue);
      expect(await store.db.query('reward_entitlements'), hasLength(1));
      h.callbacks!.closed();
      await watch;
      expect(c.busy, isFalse);
      expect(h.disposals, 1);
    } finally {
      c.dispose();
      hub.dispose();
    }
  });
  test('B04-R02 Controller13 failed timestamp allows14 free clear; retry retains1, duplicate retains1,15/16 correct cadence', () async {
    var elapsed = Duration.zero;
    final transport = Transport();
    final hub = ServiceHub(
      store: store,
      config: config,
      transport: transport,
      knownPuzzleIds: {},
      adClock: FullscreenCooldown(
        wall: () => DateTime.fromMillisecondsSinceEpoch(1000000),
        monotonic: () => elapsed,
      ),
    );
    final c = await controller(hub);
    try {
      await c.startLevel(13);
      await solve(c);
      final h = await ready(hub, transport, AdKind.interstitial);
      final next = c.nextLevel();
      await until(() => h.shows == 1);
      store.fault = (stage) {
        if (stage == 'fullscreen') throw StateError('disk');
      };
      h.callbacks!.shown();
      await until(() => hub.ads.timingSaveFailed);
      h.callbacks!.closed();
      await next;
      expect(c.current!.puzzle.mainLevel, 14);
      expect(c.busy, isFalse);
      await solve(c);
      expect((await store.progress()).qualifyingClears, 4);
      expect(c.phase, SavePhase.clean);
      final oldShow =
          (await store.db.query('fullscreen_attempts')).single['show_id']!
              as String;
      store.fault = null;
      await hub.ads.retryTiming();
      expect((await store.progress()).qualifyingClears, 1);
      await hub.ads.retryTiming();
      await store.recordFullscreen(oldShow, 'interstitial', 2000000);
      expect((await store.progress()).qualifyingClears, 1);
      elapsed = const Duration(seconds: 180);
      final second = await ready(hub, transport, AdKind.interstitial);
      final next14 = c.nextLevel();
      await until(() => second.shows > 0 || c.current!.puzzle.mainLevel == 15);
      if (second.shows > 0) second.callbacks!.failed();
      await next14;
      expect(
        second.shows,
        0,
        reason: 'Retry changed durable qualification to1; cached4 must not permit an early ad on14',
      );
      expect(c.current!.puzzle.mainLevel, 15);
      await solve(c);
      expect(c.progress.qualifyingClears, 2);
      await c.nextLevel();
      expect(c.current!.puzzle.mainLevel, 16);
      await solve(c);
      expect(c.progress.qualifyingClears, 3);
      await c.viewPatch();
      final next16 = c.nextLevel();
      for (var n = 0; n < 1000 && second.shows == 0; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(
        second.shows,
        1,
        reason:
            'level=${c.current?.puzzle.mainLevel}, page=${c.page}, phase=${c.phase}, busy=${c.busy}, qualifying=${c.progress.qualifyingClears}, eligible=${c.canCheckInterstitialOnNext}, ready=${hub.ads.ready(AdKind.interstitial)}, cooldown=${hub.ads.cooldown}, timingFailed=${hub.ads.timingSaveFailed}, notice=${c.notice}',
      );
      second.callbacks!.shown();
      second.callbacks!.closed();
      await next16;
      expect(c.current!.puzzle.mainLevel, 17);
      expect(c.progress.qualifyingClears, 0);
      await store.recordFullscreen(oldShow, 'interstitial', 1000000);
      expect((await store.progress()).qualifyingClears, 0);
    } finally {
      c.dispose();
      hub.dispose();
    }
  });
  test('B04-R02 prepared ordinal survives reopen; unknown shown fact is not invented; rewarded and reset never consume later clears', () async {
    for (var n = 11; n <= 13; n++) {
      await store.settle(finish(sample('l$n', level: n)), replace: true);
    }
    await store.prepareFullscreen('original13', 'interstitial');
    store.fault = (stage) {
      if (stage == 'fullscreen') throw StateError('disk');
    };
    await expectLater(
      store.recordFullscreen('original13', 'interstitial', 1000000),
      throwsStateError,
    );
    store.fault = null;
    await store.settle(finish(sample('l14', level: 14)), replace: true);
    await store.close();
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
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
    expect((await store.progress()).qualifyingClears, 4);
    await store.recordFullscreen('original13', 'interstitial', 1000000);
    expect((await store.progress()).qualifyingClears, 1);
    await store.prepareFullscreen('reward14', 'rewarded');
    await store.recordFullscreen('reward14', 'rewarded', 1100000);
    expect((await store.progress()).qualifyingClears, 1);
    await store.prepareFullscreen('stale-before-reset', 'interstitial');
    await store.resetProgress();
    await store.settle(finish(sample('new11', level: 11)), replace: true);
    await store.recordFullscreen('stale-before-reset', 'interstitial', 1050000);
    expect((await store.progress()).qualifyingClears, 1);
    expect(await store.lastFullscreenMillis(), 1100000);
    await store.close();
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    await store.recordFullscreen('original13', 'interstitial', 1000000);
    expect((await store.progress()).qualifyingClears, 1);
  });
}

Future<void> until(bool Function() condition) async {
  for (var n = 0; n < 2000 && !condition(); n++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}
