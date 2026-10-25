import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_controller_ads_test.dart' show config;
import 'b04_ads_test.dart' show Handle, Transport;
import 'offline_controller_test.dart' show testLibrary;
import 'store_test.dart' show sample, finish;

Future<void> tap(WidgetTester t, Finder finder) async {
  await t.runAsync(() => t.tap(finder));
  await t.pump();
}

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  });
  late Directory dir;
  late GameStore store;
  late GameController c;
  late ServiceHub hub;
  late Transport transport;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-ui-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    for (var n = 1; n <= 3; n++) {
      await store.settle(finish(sample('seed$n', level: n)), replace: true);
    }
    transport = Transport();
    hub = ServiceHub(
      store: store,
      config: config,
      transport: transport,
      knownPuzzleIds: {},
    );
    await hub.initializeLocal();
    hub.ads.update(consent: true);
    c = GameController(store, library: testLibrary(), services: hub);
    await c.initialize();
    await c.startLevel(4);
  });
  tearDown(() async {
    c.dispose();
    hub.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });
  testWidgets(
    'AC07/18 two-step extra requires explicit Watch and real callback boundary; free tools remain',
    (t) async {
      final f = hub.ads.preload(AdKind.rewarded);
      final h = Handle();
      transport.loads.last.complete(h);
      await f;
      await t.pumpWidget(PourluneApp(controller: c));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('extra-bottle')));
      await tap(t, find.byKey(const Key('extra-bottle')));
      await t.pumpAndSettle();
      expect(h.shows, 0);
      expect(
        await t.runAsync(() => store.db.query('reward_attempts')),
        isEmpty,
      );
      await tap(t, find.text('Not now'));
      await t.pumpAndSettle();
      expect(h.shows, 0);
      await tap(t, find.byKey(const Key('extra-bottle')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('watch-ad')));
      await t.pump();
      await t.runAsync(() async {
        await store.db.rawQuery('SELECT 1');
        for (var n = 0; n < 200 && h.callbacks == null; n++) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        expect(h.shows, 1);
        h.callbacks!.shown();
        h.callbacks!.reward();
        h.callbacks!.closed();
        for (
          var n = 0;
          n < 200 && (!c.current!.extraBottleGranted || c.busy);
          n++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      });
      await t.pumpAndSettle();
      expect(c.current!.extraBottleGranted, isTrue);
      expect(find.text('Extra bottle added'), findsOneWidget);
      expect(find.byKey(const Key('extra-added-feedback')), findsOneWidget);
      expect(find.byKey(const Key('undo')), findsOneWidget);
      expect(find.byKey(const Key('hint')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'AC06/36 privacy choices are separate and persist without Firebase; Rules back announces Settings',
    (t) async {
      await c.navigate(GamePage.settings);
      await t.pumpWidget(PourluneApp(controller: c));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('privacy')));
      await tap(t, find.byKey(const Key('privacy')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('analytics-choice')));
      await t.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await t.pump();
      expect(hub.choices.analytics, isTrue);
      expect(hub.choices.crash, isFalse);
      expect(
        (await t.runAsync(() => store.readServiceValue('privacy_choices'))
            as Map)['analytics'],
        isTrue,
      );
      await tap(t, find.text('Close'));
      await t.pumpAndSettle();
      await c.navigate(GamePage.rules);
      await t.pumpAndSettle();
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byTooltip('Home'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'AC07 Pause Restart stays full width at320px/2x; levels1-3 hide extra offer',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
      );
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('pause')));
      await t.pumpAndSettle();
      expect(
        t.getSize(find.byKey(const Key('pause-restart'))).width,
        greaterThan(210),
      );
      expect(t.takeException(), isNull);
      await tap(t, find.byKey(const Key('resume-pause')));
      await t.pumpAndSettle();
      await t.runAsync(() => c.startLevel(3, replace: true));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('extra-bottle')), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
}
