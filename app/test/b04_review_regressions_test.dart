import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:pourlune_dev/services/service_policy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Handle, Transport;
import 'b04_services_test.dart' show Fire, options;
import 'store_test.dart' show sample, fixture;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late GameController c;
  late ServiceHub hub;
  late Transport transport;
  late Fire fire;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('review-db');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    transport = Transport();
    fire = Fire();
    hub = ServiceHub(
      store: store,
      config: ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-3940256099942544/1033173712',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
        firebaseNativeReady: true,
        firebaseJson: options(),
      ),
      knownPuzzleIds: {'main-001'},
      transport: transport,
      firebase: fire,
    );
    c = GameController(
      store,
      library: ContentLibrary(main: {1: fixture()}),
      services: hub,
    );
  });
  tearDown(() async {
    c.dispose();
    hub.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });
  test('foreground return replenishes invalidated inventory without extra manual consent', () async {
    await c.initialize();
    await hub.initializeLocal();
    hub.ads.update(consent: true);
    final load = hub.ads.preload(AdKind.interstitial);
    transport.loads.single.complete(Handle());
    await load;
    c.setForeground(false);
    c.setForeground(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      transport.loads.length,
      greaterThan(1),
      reason: 'return to foreground must load replacement inventory',
    );
  });
  test('completed tutorial emits completion event', () async {
    await c.initialize();
    await hub.initializeLocal();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
    await c.startLevel(1);
    expect(c.current!.tutorial!.active, isTrue);
    for (final move in c.current!.puzzle.referenceMoves) {
      await c.pour(move.from, move.to);
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(c.current!.tutorial!.active, isFalse);
    expect(fire.events, contains('pl_tutorial_complete'));
  });
  test(
    'reset clears pending restore presentation and eligibility gate',
    () async {
      final origin = sample('origin', level: 4);
      await store.save(origin);
      await store.beginReward('attempt', origin);
      await store.closeReward('attempt');
      await store.save(sample('newer', level: 5), replace: true);
      await store.confirmReward('attempt');
      await c.initialize();
      await hub.initializeLocal();
      expect(c.pendingRewards, hasLength(1));
      await c.resetProgress();
      expect(await store.pendingRewards(), isEmpty);
      expect(c.pendingRewards, isEmpty);
    },
  );
  test(
    'closed actual display associates first legal pour with continuation once',
    () async {
      await c.initialize();
      await hub.initializeLocal();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await hub.updatePrivacy(const PrivacyChoices(analytics: true));
      await c.startLevel(1);
      hub.ads.update(consent: true);
      final load = hub.ads.preload(AdKind.rewarded);
      final h = Handle();
      transport.loads.last.complete(h);
      await load;
      final shown = hub.ads.show(AdKind.rewarded, 'actual-display');
      for (var i = 0; i < 100 && h.callbacks == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      h.callbacks!.shown();
      h.callbacks!.closed();
      await shown;
      final moves = c.current!.puzzle.referenceMoves;
      await c.pour(moves.first.from, moves.first.from);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fire.events.where((e) => e == 'pl_ad_continue'), isEmpty);
      await c.pour(moves.first.from, moves.first.to);
      await c.pour(moves[1].from, moves[1].to);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(fire.events.where((e) => e == 'pl_ad_continue'), hasLength(1));
    },
  );
  test('safe remote policy update replenishes while disabling never loads or shows', () async {
    await c.initialize();
    await hub.initializeLocal();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    hub.ads.update(consent: true);
    hub.ads.update(remote: const RemotePolicy());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(transport.loads, hasLength(2));
    hub.ads.update(remote: const RemotePolicy(adsEnabled: false));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(transport.loads, hasLength(2));
    expect(hub.ads.showing, isFalse);
  });
  test('tutorial completes after3 guided moves before puzzle win and only after Retry saves it', () async {
    await c.initialize();
    await hub.initializeLocal();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
    await c.startLevel(1);
    final moves = c.current!.puzzle.referenceMoves;
    for (final m in moves.take(2)) {
      await c.pour(m.from, m.to);
    }
    store.fault = (stage) {
      if (stage == 'snapshot') throw StateError('disk');
    };
    await c.pour(moves[2].from, moves[2].to);
    expect(c.phase, SavePhase.failed);
    expect(c.current!.completed, isFalse);
    expect(fire.events.where((e) => e == 'pl_tutorial_complete'), isEmpty);
    store.fault = null;
    await c.retry();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fire.events.where((e) => e == 'pl_tutorial_complete'), hasLength(1));
    for (final m in moves.skip(3)) {
      await c.pour(m.from, m.to);
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fire.events.where((e) => e == 'pl_tutorial_complete'), hasLength(1));
    expect(fire.events.where((e) => e == 'pl_tutorial_skip'), isEmpty);
  });
}
