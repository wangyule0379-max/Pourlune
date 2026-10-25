import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture, daily;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late GameController c;
  late ServiceHub hub;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('direct-bottle-');
    store = await GameStore.open(
      '${dir.path}/game.sqlite',
      factory: databaseFactoryFfi,
    );
    hub = ServiceHub(
      store: store,
      config: const ServiceConfig(),
      knownPuzzleIds: {},
    );
    c = GameController(store, services: hub);
    await c.initialize();
    await c.start(fixture(4));
  });
  tearDown(() async {
    c.dispose();
    hub.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'disabled ads grant one saved bottle without advertising records',
    () async {
      final original = c.current!;
      await Future.wait([c.watchExtraBottle(), c.watchExtraBottle()]);
      expect(c.current!.extraBottleGranted, isTrue);
      expect(c.current!.board, [...original.board, <String>[]]);
      expect(c.current!.revision, original.revision + 1);
      expect(c.current!.moveCount, original.moveCount);
      expect(c.extraBottlePresentation, isNotNull);
      expect(
        (await store.load('ordinary')).instance!.toJson(),
        c.current!.toJson(),
      );
      expect(await store.db.query('reward_entitlements'), hasLength(1));
      for (final table in [
        'reward_attempts',
        'fullscreen_attempts',
        'fullscreen_shows',
        'receipts',
        'pieces',
      ]) {
        expect(await store.db.query(table), isEmpty, reason: table);
      }
      await c.watchExtraBottle();
      expect(c.current!.revision, original.revision + 1);
    },
  );

  test(
    'direct entitlement survives undo restart and real database reopen',
    () async {
      await c.pour(0, 2);
      await c.watchExtraBottle();
      await c.undo();
      await c.restart();
      expect(c.current!.board, [...c.current!.puzzle.initial, <String>[]]);
      final saved = c.current!.toJson();
      c.dispose();
      hub.dispose();
      await store.close();
      store = await GameStore.open(
        '${dir.path}/game.sqlite',
        factory: databaseFactoryFfi,
      );
      hub = ServiceHub(
        store: store,
        config: const ServiceConfig(),
        knownPuzzleIds: {},
      );
      c = GameController(store, services: hub);
      await c.initialize();
      c.resume();
      await c.watchExtraBottle();
      expect(c.current!.toJson(), saved);
      expect(c.extraBottlePresentation, isNull);
      expect(await store.db.query('reward_entitlements'), hasLength(1));
    },
  );

  test(
    'failed direct grant rolls back entitlement and board; retry grants once',
    () async {
      final before = c.current!.toJson();
      store.fault = (stage) {
        if (stage == 'reward_grant') throw StateError('disk full');
      };
      await c.watchExtraBottle();
      expect(c.phase, SavePhase.failed);
      expect(c.current!.toJson(), before);
      expect((await store.load('ordinary')).instance!.toJson(), before);
      expect(await store.db.query('reward_entitlements'), isEmpty);
      expect(c.extraBottlePresentation, isNull);
      await c.goHome();
      expect(c.page, GamePage.board);
      c.stayHere();
      store.fault = null;
      await c.retry();
      expect(c.phase, SavePhase.clean);
      expect(c.current!.extraBottleGranted, isTrue);
      expect(c.extraBottlePresentation, isNotNull);
      await c.retry();
      expect(await store.db.query('reward_entitlements'), hasLength(1));
    },
  );

  test(
    'tutorial levels stay ineligible and daily receives its own bottle',
    () async {
      await c.start(fixture(3), replace: true);
      await c.watchExtraBottle();
      expect(c.current!.extraBottleGranted, isFalse);
      await store.save(daily());
      c.dispose();
      c = GameController(store, services: hub);
      await c.initialize();
      await c.navigate(GamePage.board, slot: 'daily');
      await c.watchExtraBottle();
      expect(c.current!.slot, 'daily');
      expect(c.current!.extraBottleGranted, isTrue);
      expect(
        (await store.load('ordinary')).instance!.extraBottleGranted,
        isFalse,
      );
    },
  );

  testWidgets(
    'Extra bottle tap immediately adds a bottle without an ad dialog',
    (t) async {
      await t.binding.setSurfaceSize(const Size(402, 874));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(PourluneApp(controller: c));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('extra-bottle')));
        for (var i = 0; i < 100 && !c.current!.extraBottleGranted; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      });
      await t.pumpAndSettle();
      expect(c.current!.extraBottleGranted, isTrue);
      expect(find.text('Extra bottle added'), findsOneWidget);
      expect(find.byKey(const Key('watch-ad')), findsNothing);
      expect(find.text('No ad available'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
}
