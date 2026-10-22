// B05 real SQLite + widget interaction; no VoiceOver/physical-device claim.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'store_test.dart' show sample, finish;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await loader.load();
  });
  late Directory dir;
  late GameStore store;
  late ServiceHub hub;
  late GameController c;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b05-a11y-');
    store = await GameStore.open(
      '${dir.path}/b05.sqlite',
      factory: databaseFactoryFfi,
    );
    for (var n = 1; n <= 3; n++) {
      await store.settle(finish(sample('qa-$n', level: n)), replace: true);
    }
    hub = ServiceHub(
      store: store,
      config: const ServiceConfig(),
      knownPuzzleIds: {},
    );
    await hub.initializeLocal();
    c = GameController(store, library: testLibrary(), services: hub);
    await c.initialize();
  });
  tearDown(() async {
    c.dispose();
    hub.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });
  Future<void> show(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    final insets = FakeViewPadding(
      top: 62 * t.view.devicePixelRatio,
      bottom: 34 * t.view.devicePixelRatio,
    );
    t.view.padding = insets;
    t.view.viewPadding = insets;
    addTearDown(t.view.resetPadding);
    addTearDown(t.view.resetViewPadding);
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.runAsync(() => t.tap(f));
    await t.pumpAndSettle();
  }

  testWidgets(
    'B05 narrow2x privacy content scrolls to independent choices and saves',
    (t) async {
      await c.navigate(GamePage.settings);
      await show(t);
      await tap(t, find.byKey(const Key('privacy')));
      for (final key in ['analytics-choice', 'crash-choice']) {
        final f = find.byKey(Key(key));
        final toggle = find.descendant(of: f, matching: find.byType(Switch));
        // Scroll the actual control into view, beyond explanatory text.
        await tap(t, toggle);
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pumpAndSettle();
      }
      expect(hub.choices.analytics, isTrue);
      expect(hub.choices.crash, isTrue);
      expect(
        await t.runAsync(() => store.readServiceValue('privacy_choices')),
        {'analytics': true, 'crash': true},
      );
      expect(t.takeException(), isNull);
      await tap(t, find.text('Close'));
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'B05 narrow2x earlier reward confirmation remains readable and actionable',
    (t) async {
      late String origin, replaced;
      await t.runAsync(() async {
        await c.startLevel(4);
        origin = c.current!.id;
        await store.beginReward('b05-controlled', c.current!);
        await c.startLevel(3, replace: true);
        replaced = c.current!.id;
        await store.confirmReward('b05-controlled');
        c.dispose();
        c = GameController(store, library: testLibrary(), services: hub);
        await c.initialize();
        expect(c.pendingRewards.single.origin.id, origin);
        await c.goHome();
      });
      await show(t);
      expect(
        t.takeException(),
        isNull,
        reason: 'pending reward card before dialog',
      );
      await tap(t, find.text('Resume rewarded puzzle'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        t.takeException(),
        isNull,
        reason: 'Replacement explanation must fit or scroll at320x568/2x',
      );
      expect(c.current!.id, replaced);
      final confirm = find.byKey(const Key('confirm-reward-restore'));
      final paragraph = t.renderObject<RenderParagraph>(
        find.descendant(of: confirm, matching: find.byType(RichText)),
      );
      final copy = paragraph.text.toPlainText();
      for (final match in RegExp(r'\S+').allMatches(copy)) {
        expect(
          paragraph.getBoxesForSelection(
            TextSelection(baseOffset: match.start, extentOffset: match.end),
          ),
          hasLength(1),
          reason: 'Confirmation button must not split a word at320x568/2x',
        );
      }
      await tap(t, confirm);
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await t.pumpAndSettle();
      expect(c.current!.id, origin);
      expect(c.current!.extraBottleGranted, isTrue);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
