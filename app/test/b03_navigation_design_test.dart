import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:pourlune_dev/presentation/scene_art.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'store_test.dart' show finish, sample;

void main() {
  sqfliteFfiInit();

  // Catches an omitted welcome hero or presentation accidentally granting patches.
  testWidgets(
    'P01 welcome shows decorative full scene without earning patches',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 800));
      final dir = Directory.systemTemp.createTempSync(
        'b03-navigation-welcome-',
      );
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store, library: testLibrary());
      await t.runAsync(c.initialize);
      try {
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
        );
        await t.pumpAndSettle();
        expect(find.text('A little color. A little calm.'), findsOneWidget);
        final hero = t.widget<SceneArt>(find.byType(SceneArt));
        expect(hero.pieces, [
          'color_studio:1',
          'color_studio:2',
          'color_studio:3',
          'color_studio:4',
          'color_studio:5',
        ]);
        expect(c.progress.pieces, isEmpty);
        await t.ensureVisible(find.byKey(const Key('sample-main-001')));
        expect(
          t.getSize(find.byKey(const Key('sample-main-001'))).height,
          greaterThanOrEqualTo(48),
        );
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
        await t.binding.setSurfaceSize(null);
      }
    },
  );

  // Catches moving the action above its saved scene context or hiding entrances.
  testWidgets(
    'P02 saved scene and patches precede play with three usable entrances',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 800));
      final dir = Directory.systemTemp.createTempSync('b03-navigation-home-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      await t.runAsync(
        () => store.settle(finish(sample('patch-four', level: 4))),
      );
      final c = GameController(store, library: testLibrary());
      await t.runAsync(c.initialize);
      try {
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
        );
        await t.pumpAndSettle();
        final hero = find.byType(SceneArt).first;
        final play = find.byKey(const Key('sample-main-001'));
        expect(t.getTopLeft(hero).dy, lessThan(t.getTopLeft(play).dy));
        expect(find.text('1 / 5 patches'), findsOneWidget);
        expect(t.widget<SceneArt>(hero).pieces, ['color_studio:1']);
        for (final key in ['chapters', 'daily', 'collection', 'settings']) {
          final entrance = find.byKey(Key(key));
          await t.ensureVisible(entrance);
          expect(t.getSize(entrance).shortestSide, greaterThanOrEqualTo(48));
        }
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const Key('settings')));
        await t.pumpAndSettle();
        expect(c.page, GamePage.settings);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
        await t.binding.setSurfaceSize(null);
      }
    },
  );

  // Catches a baked-in date and loss of the existing real calendar action keys.
  testWidgets(
    'P14 calendar hero uses current date and preserves read-only history',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 800));
      final dir = Directory.systemTemp.createTempSync('b03-navigation-daily-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(
        store,
        library: testLibrary(),
        clock: () => LocalDay('2026-10-22', 'Test', 480),
      );
      await t.runAsync(c.initialize);
      await c.navigate(GamePage.daily);
      try {
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
        );
        await t.pumpAndSettle();
        final hero = find.byKey(const Key('daily-calendar-hero'));
        expect(hero, findsOneWidget);
        expect(
          find.descendant(of: hero, matching: find.text('22')),
          findsOneWidget,
        );
        final historical = find.byKey(const Key('date-2026-10-21'));
        await t.ensureVisible(historical);
        await t.tap(historical);
        await t.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(c.daily, isNull);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
        await t.binding.setSurfaceSize(null);
      }
    },
  );
}
