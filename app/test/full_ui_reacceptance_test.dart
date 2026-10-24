import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/knit_components.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/scene_art.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture, finish;
import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });

  testWidgets('UI-R08 large-text hint preserves bottom capacity labels', (
    t,
  ) async {
    addTearDown(t.view.reset);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(375, 667);
    t.view.padding = const FakeViewPadding(top: 20);
    final dir = Directory.systemTemp.createTempSync('ui-hint-large-');
    final store = (await t.runAsync(
      () =>
          GameStore.open('${dir.path}/ui.sqlite', factory: databaseFactoryFfi),
    ))!;
    final puzzle = Puzzle.parse(
      File('assets/puzzles/main/main-021.json').readAsStringSync(),
    );
    final state = GameInstance.create(
      id: 'hint-large',
      puzzle: puzzle,
    ).grantExtraBottle();
    final c = GameController(
      store,
      library: ContentLibrary(main: {21: puzzle}),
    );
    try {
      await t.runAsync(() async {
        await store.save(state);
        await c.initialize();
        await c.resumeSlot('ordinary');
        await c.requestHint();
      });
      expect(c.hint?.move, isNotNull);
      await t.pumpWidget(
        PourluneApp(controller: c, textScaler: TextScaler.linear(1.65)),
      );
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      expect(find.text('Bottle added').hitTestable(), findsOneWidget);
      final viewport = t.getRect(
        find.byKey(PageStorageKey('board-viewport-${state.id}')),
      );
      final count = t.getRect(find.byKey(const Key('bottle-count-6')));
      expect(count.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(
        find.byKey(const Key('cancel-hint')).hitTestable(),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    }
  });

  testWidgets('Save failure actions stay visible after explanations scroll', (
    t,
  ) async {
    addTearDown(t.view.reset);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(375, 667);
    t.view.padding = const FakeViewPadding(top: 20);
    final dir = Directory.systemTemp.createTempSync('ui-save-priority-');
    final store = (await t.runAsync(
      () =>
          GameStore.open('${dir.path}/ui.sqlite', factory: databaseFactoryFfi),
    ))!;
    final puzzle = Puzzle.parse(
      File('assets/puzzles/main/main-021.json').readAsStringSync(),
    );
    final state = GameInstance.create(
      id: 'save-priority',
      puzzle: puzzle,
    ).grantExtraBottle();
    final c = GameController(
      store,
      library: ContentLibrary(main: {21: puzzle}),
    );
    try {
      await t.runAsync(() async {
        await store.save(state);
        await c.initialize();
        await c.resumeSlot('ordinary');
      });
      await t.pumpWidget(
        PourluneApp(controller: c, textScaler: TextScaler.linear(1.65)),
      );
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      await t.ensureVisible(find.byKey(const Key('fail-next')));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        c.failNextWrite();
        await c.tapBottle(0);
        await c.tapBottle(4);
      });
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      expect(c.phase, SavePhase.failed);
      expect(find.byKey(const Key('retry')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('stay')).hitTestable(), findsOneWidget);
      final board = t.getRect(
        find.byKey(PageStorageKey('board-viewport-${state.id}')),
      );
      expect(
        t.getRect(find.byKey(const Key('bottle-count-6'))).bottom,
        lessThanOrEqualTo(board.bottom),
      );
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    }
  });

  for (final date in ['2026-10-22', '2026-10-23']) {
    testWidgets('P15 direct replay is limited to today: $date', (t) async {
      addTearDown(t.view.reset);
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(390, 844);
      t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      final dir = Directory.systemTemp.createTempSync('ui-daily-replay-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/ui.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final definitions = parsePuzzleDefinitions([
        for (final file in Directory(
          'assets/puzzles/daily',
        ).listSync().whereType<File>())
          file.readAsStringSync(),
      ]);
      final catalog = DailyCatalog.parse(
        File('assets/catalog/daily.json').readAsStringSync(),
        definitions,
      );
      final saved = finish(
        GameInstance.create(
          id: 'ui-daily-replay',
          puzzle: catalog.forDate('2026-10-22'),
          slot: 'daily',
          puzzleDate: '2026-10-22',
          timeZone: 'Asia/Taipei',
          offsetMinutes: 480,
          catalogVersion: catalog.version,
        ),
      );
      final c = GameController(
        store,
        library: ContentLibrary(main: {1: fixture()}, daily: catalog),
        clock: () => LocalDay(date, 'Asia/Taipei', 480),
      );
      try {
        await t.runAsync(() async {
          await store.settle(saved);
          await c.initialize();
          await c.resumeSlot('daily');
        });
        await t.pumpWidget(PourluneApp(controller: c));
        await t.pumpAndSettle();
        final replay = find.byKey(const Key('daily-replay'));
        if (date != saved.puzzleDate) {
          expect(replay, findsNothing, reason: 'Past dates stay read-only.');
        } else {
          expect(replay.hitTestable(), findsOneWidget);
          await t.runAsync(() async {
            final advanced = Completer<void>();
            void onChanged() {
              if (c.page == GamePage.board &&
                  c.phase == SavePhase.clean &&
                  !advanced.isCompleted) {
                advanced.complete();
              }
            }

            c.addListener(onChanged);
            try {
              await t.tap(replay);
              await advanced.future.timeout(const Duration(seconds: 5));
            } finally {
              c.removeListener(onChanged);
            }
          });
          await t.pumpAndSettle();
          expect(c.daily!.id, isNot(saved.id));
          expect(c.daily!.isReplay, isTrue);
          expect(c.daily!.puzzleDate, date);
          expect(c.progress.dailyStamps, {saved.puzzleDate});
          expect(c.progress.firstClears, 0);
          expect(c.progress.pieces, isEmpty);
        }
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    });
  }

  testWidgets('UI-R08 hint instruction and reason fit a regular phone', (
    t,
  ) async {
    addTearDown(t.view.reset);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 844);
    t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    final dir = Directory.systemTemp.createTempSync('ui-hint-');
    final store = (await t.runAsync(
      () =>
          GameStore.open('${dir.path}/ui.sqlite', factory: databaseFactoryFfi),
    ))!;
    final c = GameController(
      store,
      library: ContentLibrary(main: {10: fixture(10)}),
    );
    try {
      await t.runAsync(() async {
        await c.initialize();
        await c.start(fixture(10));
        await c.requestHint();
      });
      expect(c.hint?.move, isNotNull);
      await t.pumpWidget(PourluneApp(controller: c));
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      final viewport = t.getRect(
        find.byKey(PageStorageKey('board-explanations-${c.current!.id}')),
      );
      final reason = t.getRect(find.textContaining('This moves the top'));
      expect(reason.top, greaterThanOrEqualTo(viewport.top));
      expect(reason.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(
        find.byKey(const Key('cancel-hint')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const Key('restart')).hitTestable(), findsOneWidget);
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    }
  });

  for (final reward in [false, true]) {
    testWidgets(
      'UI-R02/R03 ${reward ? 'patch' : 'completion'} keeps original hierarchy',
      (t) async {
        addTearDown(t.view.reset);
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(390, 844);
        t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        final dir = Directory.systemTemp.createTempSync('ui-settlement-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/ui.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final puzzle = Puzzle.fromJson(
          jsonDecode(
            File('assets/puzzles/main/main-012.json').readAsStringSync(),
          ) as Map<String, dynamic>,
        );
        final state = finish(
          GameInstance.create(id: 'ui-result', puzzle: puzzle),
        );
        final c = GameController(
          store,
          library: ContentLibrary(main: {12: puzzle}),
        );
        try {
          await t.runAsync(() async {
            await store.settle(state);
            await c.initialize();
            await c.resumeSlot('ordinary');
            if (reward) await c.viewPatch();
          });
          await t.pumpWidget(PourluneApp(controller: c));
          await t.pumpAndSettle();
          final primary = find.byKey(Key(reward ? 'next' : 'view-patch'));
          expect(
            t.getSize(primary).width,
            greaterThanOrEqualTo(350),
            reason: 'Primary action must own its own row, independent of secondary action count.',
          );
          if (reward) {
            expect(
              t.getSize(find.byType(SceneArt)).width,
              greaterThanOrEqualTo(240),
              reason:
                  'New patch is shown in the main scene, not a list thumbnail.',
            );
          } else {
            final success = find.byWidgetPredicate(
              (w) => w is KnitArt && w.name == 'success',
            );
            expect(t.getSize(success).height, greaterThanOrEqualTo(64));
            final first = t.getRect(find.byKey(const Key('preview-bottle-0')));
            final last = t.getRect(
              find.byKey(Key('preview-bottle-${state.board.length - 1}')),
            );
            expect(
              last.top,
              greaterThan(first.bottom),
              reason: 'Completed board retains its two-row grouping.',
            );
            expect(
              find.byKey(const Key('completion-progress')),
              findsOneWidget,
            );
          }
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      },
    );
  }

  testWidgets('UI-R01 Extra and helpers have distinct frames and hit regions', (
    t,
  ) async {
    addTearDown(t.view.reset);
    final dir = Directory.systemTemp.createTempSync('ui-r01-');
    final store = (await t.runAsync(
      () =>
          GameStore.open('${dir.path}/ui.sqlite', factory: databaseFactoryFfi),
    ))!;
    final c = GameController(
      store,
      library: ContentLibrary(main: {10: fixture(10)}),
    );
    try {
      await t.runAsync(() async {
        await c.initialize();
        await c.start(fixture(10));
      });
      for (final size in [const Size(320, 568), const Size(390, 844)]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = size;
          t.view.padding = FakeViewPadding(
            top: size.width == 320 ? 20 : 47,
            bottom: size.width == 320 ? 0 : 34,
          );
          await t.pumpWidget(
            PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
          );
          await t.pumpAndSettle();
          await settleFlameBoard(t, c);
          final extra = find.byKey(const Key('extra-bottle'));
          final extraRect = t.getRect(extra);
          final boxes = <Rect>[];
          for (final key in ['undo', 'hint', 'restart']) {
            final button = find.byKey(Key(key));
            final rect = t.getRect(button);
            // A visible gutter is part of separating these two control groups.
            expect(
              rect.top - extraRect.bottom,
              greaterThanOrEqualTo(8),
              reason: '$size/$scale Extra$extraRect $key$rect',
            );
            expect(rect.height, greaterThanOrEqualTo(48));
            for (final other in boxes) {
              expect(rect.overlaps(other), isFalse);
            }
            boxes.add(rect);
            final art = find.descendant(
              of: button,
              matching: find.byType(KnitArt),
            );
            final render = t.renderObject<RenderBox>(art);
            final painted = MatrixUtils.transformRect(
              render.getTransformTo(null),
              render.paintBounds,
            );
            expect(painted.overlaps(extraRect), isFalse);
            expect(button.hitTestable(), findsOneWidget);
          }
          expect(t.takeException(), isNull);
        }
      }
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    }
  });
}
