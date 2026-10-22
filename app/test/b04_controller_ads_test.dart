import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Handle, Transport;
import 'store_test.dart' show sample, finish;

import 'package:pourlune_dev/data/content_library.dart';

import 'store_test.dart' show fixture;

const config = ServiceConfig(
  adMode: 'test',
  interstitialId: 'ca-app-pub-3940256099942544/1033173712',
  rewardedId: 'ca-app-pub-3940256099942544/5224354917',
);
void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late GameController c;
  late ServiceHub hub;
  late Transport transport;
  Future<void> until(bool Function() f) async {
    for (var n = 0; n < 2000 && !f(); n++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(f(), isTrue);
  }

  Future<void> init({int through = 0}) async {
    for (var n = 1; n <= through; n++) {
      await store.settle(finish(sample('seed$n', level: n)), replace: true);
    }
    await c.initialize();
    await hub.initializeLocal();
    hub.ads.update(consent: true);
  }

  Future<void> solve(int level) async {
    await c.startLevel(level);
    for (final move in c.current!.puzzle.referenceMoves) {
      await c.pour(move.from, move.to);
    }
    expect(c.current!.completed, isTrue);
  }

  Future<Handle> ready(AdKind kind) async {
    final f = hub.ads.preload(kind);
    final h = Handle();
    transport.loads.last.complete(h);
    await f;
    return h;
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-flow-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    transport = Transport();
    hub = ServiceHub(
      store: store,
      config: config,
      transport: transport,
      knownPuzzleIds: {
        for (var n = 1; n <= 60; n++) 'main-${n.toString().padLeft(3, '0')}',
      },
    );
    c = GameController(
      store,
      library: ContentLibrary(
        main: {for (var n = 1; n <= 60; n++) n: fixture(n)},
      ),
      services: hub,
    );
  });
  tearDown(() async {
    c.dispose();
    hub.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });
  test('AC13/32 fresh13 first Next shows once and owns navigation over double Next/Home', () async {
    await init(through: 12);
    await solve(13);
    final h = await ready(AdKind.interstitial);
    final next = c.nextLevel();
    await until(() => h.shows == 1);
    expect(c.current!.puzzle.mainLevel, 13);
    expect(c.busy, isTrue);
    await c.nextLevel();
    await c.goHome();
    h.callbacks!.shown();
    h.callbacks!.impression();
    h.callbacks!.closed();
    await next;
    expect(c.current!.puzzle.mainLevel, 14);
    expect(c.page, GamePage.board);
    expect(h.shows, 1);
    expect((await store.progress()).qualifyingClears, 0);
  });
  test('AC14 no inventory13 preserves qualification;14 new completion may show, late stock alone never shows', () async {
    await init(through: 12);
    await solve(13);
    await c.nextLevel();
    expect(c.current!.puzzle.mainLevel, 14);
    expect(c.progress.qualifyingClears, 3);
    for (final move in c.current!.puzzle.referenceMoves) {
      await c.pour(move.from, move.to);
    }
    final h = await ready(AdKind.interstitial);
    expect(h.shows, 0);
    final next = c.nextLevel();
    await until(() => h.shows == 1);
    h.callbacks!.shown();
    h.callbacks!.closed();
    await next;
    expect(c.current!.puzzle.mainLevel, 15);
  });
  test('AC15/16 piece16 is revealed before ad; Home/old settlement and chapter40 never check', () async {
    await init(through: 15);
    await solve(16);
    final h = await ready(AdKind.interstitial);
    await c.nextLevel();
    expect(c.page, GamePage.completion);
    expect(h.shows, 0);
    await c.viewPatch();
    final next = c.nextLevel();
    await until(() => h.shows == 1);
    expect(c.progress.revealedPieces, contains('color_studio:4'));
    h.callbacks!.failed();
    await next;
    await c.start(sample('chapter40', level: 40).puzzle, replace: true);
    for (final m in c.current!.puzzle.referenceMoves) {
      await c.pour(m.from, m.to);
    }
    await c.acknowledgeReveal(next: true);
    expect(h.shows, 1);
  });
  test('AC19/20 received confirmation commits during show; callback save failure freezes new rewards but free actions remain and Retry grants once', () async {
    await init(through: 3);
    await c.startLevel(4);
    final h = await ready(AdKind.rewarded);
    final watch = c.watchExtraBottle();
    await until(() => h.shows == 1);
    store.fault = (stage) {
      if (stage == 'reward_grant') throw StateError('disk');
    };
    h.callbacks!.shown();
    h.callbacks!.reward();
    await until(() => c.rewardSaveFailed);
    h.callbacks!.closed();
    await watch;
    expect(c.current!.extraBottleGranted, isFalse);
    expect(c.busy, isFalse);
    expect(c.canWatchExtraBottle, isFalse);
    await c.pour(0, 2);
    expect(c.current!.moveCount, 1);
    store.fault = null;
    await c.retryReward();
    await until(() => !c.rewardSaveFailed && c.current!.extraBottleGranted);
    expect(c.current!.moveCount, 1);
    expect(c.current!.board.length, 5);
    h.callbacks!.reward();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    expect(await store.db.query('reward_entitlements'), hasLength(1));
  });
  test('AC21 late reward on replaced origin stays pending and cannot be restored without exact explicit replacement identity', () async {
    await init(through: 4);
    await c.startLevel(4);
    final original = c.current!.id;
    final h = await ready(AdKind.rewarded);
    final watch = c.watchExtraBottle();
    await until(() => h.shows == 1);
    h.callbacks!.closed();
    await watch;
    await c.startLevel(5, replace: true);
    final newer = c.current!.id;
    h.callbacks!.reward();
    await until(() => c.pendingRewards.isNotEmpty && !c.busy);
    expect(c.current!.id, newer);
    expect(c.current!.extraBottleGranted, isFalse);
    await c.resumeRewardedPuzzle(
      c.pendingRewards.single.id,
      replacingInstance: newer,
    );
    expect(c.current!.id, original);
    expect(c.current!.extraBottleGranted, isTrue);
  });
  test('AC32 interstitial closed in background navigates exactly once after foreground return', () async {
    await init(through: 12);
    await solve(13);
    final h = await ready(AdKind.interstitial);
    final next = c.nextLevel();
    await until(() => h.shows == 1);
    c.setForeground(false);
    h.callbacks!.shown();
    h.callbacks!.closed();
    await next;
    expect(c.current!.puzzle.mainLevel, 13);
    c.setForeground(true);
    await until(() => c.current!.puzzle.mainLevel == 14 && !c.busy);
    c.setForeground(true);
    expect(c.current!.puzzle.mainLevel, 14);
  });
  test(
    'AC16 chapter40 protects stock and qualification;41 fresh Next may use it',
    () async {
      await init(through: 39);
      await solve(40);
      final h = await ready(AdKind.interstitial);
      await c.acknowledgeReveal(next: true);
      expect(c.current!.puzzle.mainLevel, 41);
      expect(h.shows, 0);
      expect(c.progress.qualifyingClears, 30);
      for (final move in c.current!.puzzle.referenceMoves) {
        await c.pour(move.from, move.to);
      }
      final next = c.nextLevel();
      await until(() => h.shows == 1);
      h.callbacks!.shown();
      h.callbacks!.closed();
      await next;
      expect(c.current!.puzzle.mainLevel, 42);
      expect(c.progress.qualifyingClears, 0);
    },
  );
}
