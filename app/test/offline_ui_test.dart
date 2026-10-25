import 'support/flame_board_ready.dart';

import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, finish;
import 'offline_controller_test.dart' show testLibrary;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'B02 teaching Skip Hint completion patch collection settings independent rules and daily',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('b02-widget-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(
        store,
        library: testLibrary(),
        clock: () => LocalDay('2026-10-22', 'Test', 480),
      );
      await t.runAsync(c.initialize);
      await t.pumpWidget(PourluneApp(controller: c));
      Future<void> tap(String key) async {
        if (key.contains('bottle-')) await waitForFlameArt(t);
        final f = find.byKey(Key(key));
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pump();
        await t.runAsync(() => store.db.rawQuery('SELECT 1'));
        await t.pump();
        for (var i = 0; i < 500 && (c.busy || c.hintSearching); i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          // Advance presentation in coarse frames; SQL still gets real I/O time.
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(c.busy, isFalse);
        expect(c.hintSearching, isFalse);
        await t.pumpAndSettle();
      }

      await tap('sample-main-001');
      expect(c.current!.tutorial!.active, isTrue);
      await tap('skip-tutorial');
      expect(await t.runAsync(store.tutorialDone), isTrue);
      final unchanged = c.current!.board;
      await tap('hint');
      expect(c.current!.board, unchanged);
      expect(c.hint!.move, isNotNull);
      await tap('bottle-${c.hint!.move!.to}');
      expect(c.current!.moveCount, 1);
      for (
        var attempts = 0;
        attempts < 20 && !c.current!.completed;
        attempts++
      ) {
        await tap('hint');
        expect(c.hint!.move, isNotNull);
        await tap('bottle-${c.hint!.move!.to}');
      }
      expect(c.current!.completed, isTrue);
      for (var level = 2; level <= 4; level++) {
        await tap('next');
        expect(c.current!.puzzle.mainLevel, level);
        expect(c.current!.tutorial, isNull);
        for (final m in c.current!.puzzle.referenceMoves) {
          await tap('bottle-${m.from}');
          await tap('bottle-${m.to}');
        }
      }
      await tap('view-patch');
      final patchSemantics = t.ensureSemantics();
      try {
        expect(find.bySemanticsLabel('New patch unlocked'), findsOneWidget);
      } finally {
        patchSemantics.dispose();
      }
      expect(c.progress.pieces, ['color_studio:1']);
      expect(c.progress.revealedPieces, isEmpty);
      await tap('view-collection');
      expect(c.progress.revealedPieces, ['color_studio:1']);
      expect(find.text('1 / 5 patches'), findsOneWidget);
      expect(find.byKey(const Key('play-from-scene')), findsOneWidget);
      expect(find.text('Play Level 5'), findsOneWidget);
      await tap('home');
      await tap('settings');
      await tap('setting-music');
      expect(c.settings.music, isFalse);
      final active = c.ordinary!.toJson();
      await tap('rules');
      await tap('demo-bottle-0');
      await tap('demo-bottle-2');
      for (final move in [(1, 0), (1, 2)]) {
        await tap('demo-bottle-${move.$1}');
        await tap('demo-bottle-${move.$2}');
      }
      expect(find.byKey(const Key('demo-skip')), findsNothing);
      expect(c.ordinary!.toJson(), active);
      await tap('rules-back');
      await tap('home');
      await tap('daily');
      await tap('today');
      expect(c.current!.slot, 'daily');
      await tap('bottle-0');
      await tap('bottle-2');
      expect(c.ordinary!.toJson(), active);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    },
  );
  testWidgets(
    'B02 foreground midnight and date rollback recheck calendar actions and display',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('b02-midnight-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      var day = LocalDay('2026-10-22', 'Test', 480);
      final c = GameController(store, library: testLibrary(), clock: () => day);
      await t.runAsync(c.initialize);
      await c.navigate(GamePage.daily);
      await t.pumpWidget(PourluneApp(controller: c));
      Future<void> tap(String key) async {
        if (key.contains('bottle-')) await waitForFlameArt(t);
        final f = find.byKey(Key(key));
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pump();
        for (var i = 0; i < 500 && c.busy; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          // Advance presentation in coarse frames; SQL still gets real I/O time.
          await t.pump(const Duration(milliseconds: 100));
        }
        await t.pumpAndSettle();
      }

      try {
        day = LocalDay('2026-10-23', 'Test', 480);
        await tap('date-2026-10-23');
        expect(find.byType(AlertDialog), findsNothing);
        expect(c.daily!.puzzleDate, '2026-10-23');
        await c.navigate(GamePage.daily);
        await t.pumpAndSettle();
        day = LocalDay('2026-10-22', 'Test', -300);
        await tap('date-2026-10-23');
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('Future dates cannot be played.'),
          ),
          findsOneWidget,
        );
        expect(c.daily!.puzzleDate, '2026-10-23');
        await t.tap(find.text('Close'));
        await t.pumpAndSettle();
        day = LocalDay('2026-10-24', 'Test', 480);
        await t.pump(const Duration(minutes: 1));
        expect(c.today.date, '2026-10-24');
        expect(find.text('Sat, Oct 24, 2026'), findsOneWidget);
        expect(find.byKey(const Key('date-2026-10-24')), findsOneWidget);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
  testWidgets(
    'B02 320px 2x calendar/settings/collection render and final story has no Next',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 800));
      final dir = Directory.systemTemp.createTempSync('b02-final-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      await t.runAsync(() async {
        for (var n = 1; n <= 60; n++) {
          await store.settle(finish(sample('all-$n', level: n)), replace: true);
        }
      });
      final c = GameController(
        store,
        library: testLibrary(),
        clock: () => LocalDay('2026-10-22', 'Test', 480),
      );
      await t.runAsync(c.initialize);
      c.resume();
      await t.pumpWidget(
        PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('next')), findsNothing);
      expect(find.text('Story complete'), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('view-collection')));
      await t.tap(find.byKey(const Key('view-collection')));
      await t.runAsync(() async {
        await store.db.rawQuery('SELECT 1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        while (c.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      });
      await t.pumpAndSettle();
      expect(c.progress.revealedPieces, contains('seaside_corner:5'));
      for (final page in [
        GamePage.home,
        GamePage.chapters,
        GamePage.daily,
        GamePage.collection,
        GamePage.settings,
      ]) {
        await c.navigate(page);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      await t.runAsync(() => c.startLevel(1));
      await c.goHome();
      await t.pumpAndSettle();
      expect(find.textContaining('Continue replay'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets('B02 no legal moves offers free rescue before requesting hint', (
    t,
  ) async {
    final dir = Directory.systemTemp.createTempSync('b02-no-moves-');
    final store = (await t.runAsync(
      () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
    ))!;
    final p = Puzzle.parse(
      File('assets/fixtures/main-012.reference.json').readAsStringSync(),
    );
    final raw = GameInstance.create(id: 'dead-board', puzzle: p).toJson()
      ..['board'] = <List<String>>[
        ['O', 'O', 'O', 'P'],
        ['G', 'G', 'G', 'P'],
        ['B', 'B', 'P', 'P'],
        ['O'],
        ['G'],
        ['B', 'B'],
      ]
      ..['board_revision'] = 1;
    await t.runAsync(() => store.save(GameInstance.fromJson(raw)));
    final c = GameController(
      store,
      library: ContentLibrary(main: {12: p}, engineering: true),
    );
    await t.runAsync(c.initialize);
    c.resume();
    await t.pumpWidget(PourluneApp(controller: c));
    await t.pumpAndSettle();
    expect(find.text('No moves available'), findsOneWidget);
    expect(find.byKey(const Key('pause')).hitTestable(), findsOneWidget);
    await t.runAsync(c.requestHint);
    await t.pumpAndSettle();
    expect(c.hint!.status, HintStatus.noMoves);
    expect(find.text('No moves available'), findsOneWidget);
    await t.runAsync(c.restart);
    await t.pumpAndSettle();
    expect(c.current!.board, p.initial);
    expect(find.text('No moves available'), findsNothing);
    await t.pumpWidget(const SizedBox());
    c.dispose();
    await t.runAsync(store.close);
    dir.deleteSync(recursive: true);
  });
  testWidgets(
    'B02 reset confirmation defaults to keeping progress; confirmed reset keeps preferences',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('b02-reset-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store, library: testLibrary());
      await t.runAsync(() async {
        await store.settle(finish(sample('reset-source', level: 4)));
        await c.initialize();
        await c.updateSetting('music', false);
        await c.navigate(GamePage.settings);
      });
      await t.pumpWidget(PourluneApp(controller: c));
      Future<void> tap(String key) async {
        if (key.contains('bottle-')) await waitForFlameArt(t);
        final f = find.byKey(Key(key));
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pump();
        for (var i = 0; i < 200 && c.busy; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pump();
        }
        await t.pumpAndSettle();
      }

      await tap('reset-progress');
      final keep = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Keep progress'),
      );
      expect(keep, findsOneWidget);
      await t.tap(keep);
      await t.pumpAndSettle();
      expect(c.progress.pieces, ['color_studio:1']);
      expect(c.settings.music, isFalse);
      await tap('reset-progress');
      await tap('confirm-reset');
      expect(c.page, GamePage.home);
      expect(c.progress.firstClears, 0);
      expect(c.progress.pieces, isEmpty);
      expect(c.progress.unlockedLevels, [1]);
      expect(c.settings.music, isFalse);
      expect(c.ordinary, isNull);
      expect(c.daily, isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    },
  );
}
