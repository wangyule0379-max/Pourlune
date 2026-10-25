import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';
import 'store_test.dart' show fixture, finish, daily;

const screens = [
  (size: Size(375, 667), top: 20.0, bottom: 0.0),
  (size: Size(390, 844), top: 47.0, bottom: 34.0),
  (size: Size(430, 932), top: 59.0, bottom: 34.0),
  (size: Size(360, 640), top: 24.0, bottom: 24.0),
  (size: Size(320, 568), top: 20.0, bottom: 0.0),
];

void visible(WidgetTester t, String key, Rect viewport, {bool control = true}) {
  fullyVisible(t, find.byKey(Key(key)), viewport, label: key, control: control);
}

void fullyVisible(WidgetTester t, Finder finder, Rect viewport, {
  String label = '', bool control = false,
}) {
  expect(finder, findsOneWidget, reason: label);
  for (final ancestor in find.ancestor(
    of: finder, matching: find.byType(SingleChildScrollView),
  ).evaluate()) {
    viewport = viewport.intersect(t.getRect(
      find.byElementPredicate((candidate) => identical(candidate, ancestor)),
    ));
  }
  final rect = t.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(viewport.left - .01), reason: label);
  expect(rect.top, greaterThanOrEqualTo(viewport.top - .01), reason: label);
  expect(rect.right, lessThanOrEqualTo(viewport.right + .01), reason: label);
  expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + .01), reason: label);
  if (control) {
    expect(rect.width, greaterThanOrEqualTo(48), reason: label);
    expect(rect.height, greaterThanOrEqualTo(48), reason: label);
    expect(finder.hitTestable(), findsOneWidget, reason: label);
  }
}

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  testWidgets(
    'LY01 real Level10 controls and six bottles are visible without scrolling',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(375, 667);
      t.view.padding = const FakeViewPadding(top: 20);
      addTearDown(t.view.reset);
      final puzzle = Puzzle.fromJson(
        jsonDecode(File('assets/puzzles/main/main-010.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final dir = Directory.systemTemp.createTempSync('ly-layout-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/layout.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(
        store,
        library: ContentLibrary(main: {10: puzzle}),
      );
      try {
        await t.runAsync(c.initialize);
        await t.runAsync(() => c.start(puzzle));
        await t.pumpWidget(PourluneApp(controller: c));
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        const viewport = Rect.fromLTRB(0, 20, 375, 667);
        for (final key in [
          for (var i = 0; i < 6; i++) 'bottle-$i',
          'pause',
          'home',
          'extra-bottle',
          'undo',
          'hint',
          'restart',
        ]) {
          final finder = find.byKey(Key(key));
          expect(finder, findsOneWidget);
          final rect = t.getRect(finder);
          expect(
            viewport.contains(rect.topLeft) &&
                rect.bottom <= viewport.bottom &&
                rect.right <= viewport.right,
            isTrue,
            reason: '$key must be fully visible on first frame, actual $rect',
          );
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(
            finder.hitTestable(),
            findsOneWidget,
            reason: '$key must not need ensureVisible/scroll',
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
  for (var count = 4; count <= 7; count++) {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      testWidgets('LY04 $count bottles text $scale first screen matrix', (
        t,
      ) async {
        addTearDown(t.view.reset);
        final dir = Directory.systemTemp.createTempSync('ly-matrix-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/layout.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final p = Puzzle.fromJson(
          boardFixture(colors: count == 7 ? 4 : count - 2).puzzle.toJson()
            ..['main_level'] = 10
            ..['puzzle_id'] = 'main-010',
        );
        var state = GameInstance.create(id: 'ly-$count', puzzle: p);
        if (count == 7) state = state.grantExtraBottle();
        final c = GameController(store, library: ContentLibrary(main: {10: p}));
        try {
          await t.runAsync(() async {
            await store.save(state);
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          for (final screen in screens) {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = screen.size;
            t.view.padding = FakeViewPadding(
              top: screen.top,
              bottom: screen.bottom,
            );
            await t.pumpWidget(
              PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
            );
            await t.pumpAndSettle();
            await settleFlameBoard(t, c);
            final bounds = Rect.fromLTRB(
              0,
              screen.top,
              screen.size.width,
              screen.size.height - screen.bottom,
            );
            for (final key in [
              'home',
              'pause',
              'extra-bottle',
              'undo',
              'hint',
              'restart',
            ]) {
              visible(t, key, bounds);
            }
            final boardScroll = t.state<ScrollableState>(
              find.descendant(
                of: find.byKey(const Key('board-accessibility-viewport')),
                matching: find.byType(Scrollable),
              ),
            );
            for (var i = 0; i < count; i++) {
              if (scale <= 1.3 || boardScroll.position.maxScrollExtent < .01) {
                visible(t, 'bottle-$i', bounds);
                visible(t, 'bottle-count-$i', bounds, control: false);
              } else {
                final scroll = find.byKey(
                  const Key('board-accessibility-viewport'),
                );
                await t.drag(scroll, const Offset(0, -500));
                await t.pumpAndSettle();
                visible(t, 'bottle-${count - 1}', bounds);
                for (final key in [
                  'home',
                  'pause',
                  'extra-bottle',
                  'undo',
                  'hint',
                  'restart',
                ]) {
                  visible(t, key, bounds);
                }
                break;
              }
            }
            if (scale <= 1.3) {
              expect(
                boardScroll.position.maxScrollExtent,
                lessThan(.01),
                reason: '$count/$scale/${screen.size} no board scrolling',
              );
            }
            expect(
              t.takeException(),
              isNull,
              reason: '$count/$scale/${screen.size}',
            );
          }
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      });
    }
  }
  testWidgets(
    'LY04 failed save keeps seven bottles and retry on first screen',
    (t) async {
      addTearDown(t.view.reset);
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 568);
      t.view.padding = const FakeViewPadding(top: 20);
      final dir = Directory.systemTemp.createTempSync('ly-failure-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/layout.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final p = Puzzle.fromJson(
        boardFixture().puzzle.toJson()
          ..['main_level'] = 10
          ..['puzzle_id'] = 'main-010',
      );
      final state = GameInstance.create(
        id: 'ly-save-fail',
        puzzle: p,
      ).grantExtraBottle();
      final c = GameController(store, library: ContentLibrary(main: {10: p}));
      try {
        await t.runAsync(() async {
          await store.save(state);
          await c.initialize();
          await c.resumeSlot('ordinary');
          c.failNextWrite();
          await c.pour(0, 4);
        });
        expect(c.phase, SavePhase.failed);
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: const TextScaler.linear(1.3)),
        );
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        const bounds = Rect.fromLTRB(0, 20, 320, 568);
        for (final key in [
          'retry',
          'stay',
          'home',
          'pause',
          'extra-bottle',
          'undo',
          'hint',
          'restart',
          for (var i = 0; i < 7; i++) 'bottle-$i',
        ]) {
          visible(t, key, bounds);
        }
        expect(t.takeException(), isNull);
        for (var i = 0; i < 7; i++) {
          visible(t, 'bottle-count-$i', bounds, control: false);
        }
        final scroll = t.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('board-accessibility-viewport')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scroll.position.maxScrollExtent, lessThan(.01));
        expect(
          (await t.runAsync(() => store.load('ordinary')))!.instance!.moveCount,
          0,
        );
        await t.tap(find.byKey(const Key('retry')));
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await t.pumpAndSettle();
        expect(c.phase, SavePhase.clean);
        expect(
          (await t.runAsync(() => store.load('ordinary')))!.instance!.moveCount,
          1,
        );
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
  testWidgets(
    'LY03 failed completion prioritizes unsaved receipt and Retry over recovery notice',
    (t) async {
      addTearDown(t.view.reset);
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 568);
      t.view.padding = const FakeViewPadding(top: 20);
      final dir = Directory.systemTemp.createTempSync('ly-receipt-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/layout.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final p = fixture(10),
          c = GameController(
            store,
            library: ContentLibrary(main: {10: fixture(10), 11: fixture(11)}),
          );
      try {
        await t.runAsync(() async {
          await c.initialize();
          await c.start(p);
          for (final move in p.referenceMoves.take(
            p.referenceMoves.length - 1,
          )) {
            await c.pour(move.from, move.to);
          }
          store.fault = (stage) {
            if (stage == 'receipt') throw StateError('LY receipt rollback');
          };
          final last = p.referenceMoves.last;
          await c.pour(last.from, last.to);
        });
        expect(c.phase, SavePhase.failed);
        expect(c.receipt, isNull);
        c.recoveryNotice = 'recovered';
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: const TextScaler.linear(1.3)),
        );
        await t.pumpAndSettle();
        const bounds = Rect.fromLTRB(0, 20, 320, 568);
        for (final key in ['retry', 'stay', 'next', 'home']) {
          visible(t, key, bounds);
        }
        expect((await t.runAsync(store.progress))!.receipts, 0);
        store.fault = null;
        await t.tap(find.byKey(const Key('retry')));
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await t.pumpAndSettle();
        expect(c.phase, SavePhase.clean);
        expect((await t.runAsync(store.progress))!.receipts, 1);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
  for (final situation in ['tutorial', 'hint', 'noMoves', 'reward']) {
    testWidgets('LY04 $situation information keeps first screen actions', (
      t,
    ) async {
      addTearDown(t.view.reset);
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 568);
      t.view.padding = const FakeViewPadding(top: 20);
      final dir = Directory.systemTemp.createTempSync('ly-info-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/layout.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final p = situation == 'tutorial'
          ? fixture()
          : situation == 'noMoves'
          ? Puzzle.parse(
              File('assets/fixtures/main-012.reference.json')
                  .readAsStringSync(),
            )
          : Puzzle.fromJson(
              boardFixture().puzzle.toJson()
                ..['main_level'] = 10
                ..['puzzle_id'] = 'main-010',
            );
      final pending = Completer<HintResult>();
      final c = GameController(
        store,
        library: ContentLibrary(main: {p.mainLevel!: p}),
        hintLauncher: (_) => (
          result: pending.future,
          cancel: () {
            if (!pending.isCompleted) {
              pending.complete(const HintResult(HintStatus.cancelled));
            }
          },
          released: Future<void>.value(),
        ),
      );
      Future<void>? request;
      try {
        await t.runAsync(() async {
          await c.initialize();
          if (situation == 'tutorial') {
            await c.startLevel(1);
          } else {
            var state = GameInstance.create(id: 'ly-$situation', puzzle: p);
            if (situation == 'hint' || situation == 'reward') {
              state = state.grantExtraBottle();
            }
            if (situation == 'noMoves') {
              state = GameInstance.fromJson(
                state.toJson()
                  ..['board'] = <List<String>>[
                    ['O', 'O', 'O', 'P'],
                    ['G', 'G', 'G', 'P'],
                    ['B', 'B', 'P', 'P'],
                    ['O'],
                    ['G'],
                    ['B', 'B'],
                  ]
                  ..['board_revision'] = 1,
              );
            }
            await store.save(state);
            await c.initialize();
            await c.resumeSlot('ordinary');
          }
        });
        if (situation == 'reward') {
          c.rewardSaveFailed = true;
          c.rewardIssue = 'confirmation_save_failed';
        }
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: const TextScaler.linear(1.3)),
        );
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        if (situation == 'hint') {
          request = c.requestHint();
          await t.pumpAndSettle();
          expect(c.hintSearching, isTrue);
        }
        if (situation == 'noMoves') {
          expect(find.text('No moves available'), findsOneWidget);
        }
        if (situation == 'reward') {
          final warning = find.textContaining(
            'A reward confirmation was received',
          );
          final pane = find.byKey(
            PageStorageKey('board-explanations-${c.current!.id}'),
          );
          expect(
            t.getRect(warning).intersect(t.getRect(pane)).height,
            greaterThanOrEqualTo(20),
            reason: 'Reward warning must be visible before scrolling, not buried beneath ordinary instructions.',
          );
        }
        const bounds = Rect.fromLTRB(0, 20, 320, 568);
        for (final key in [
          'home',
          'pause',
          'undo',
          'restart',
          if (situation != 'tutorial') 'hint',
          if (situation == 'hint') 'cancel-hint',
          if (situation == 'tutorial') 'skip-tutorial',
          for (var i = 0; i < c.current!.board.length; i++) 'bottle-$i',
        ]) {
          visible(t, key, bounds);
        }
        if (situation == 'hint') {
          await t.tap(find.byKey(const Key('cancel-hint')));
          await t.pumpAndSettle();
          await request;
          expect(c.hintSearching, isFalse);
        }
        expect(t.takeException(), isNull);
      } finally {
        c.cancelHint();
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    });
  }
  for (final situation in ['hint', 'tutorial']) {
    for (final spec in [
      (size: const Size(320, 568), scale: 2.0, top: 20.0, bottom: 0.0),
      (size: const Size(360, 640), scale: 1.5, top: 24.0, bottom: 24.0),
    ]) {
      testWidgets('LY-R02 $situation ${spec.scale} action survives information scroll', (t) async {
        addTearDown(t.view.reset);
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = spec.size;
        t.view.padding = FakeViewPadding(top: spec.top, bottom: spec.bottom);
        final dir = Directory.systemTemp.createTempSync('ly-r02-');
        final store = (await t.runAsync(() => GameStore.open(
          '${dir.path}/layout.sqlite', factory: databaseFactoryFfi,
        )))!;
        final p = situation == 'tutorial' ? fixture() : fixture(10);
        final pending = Completer<HintResult>();
        final c = GameController(store, library: ContentLibrary(main: {p.mainLevel!: p}),
          hintLauncher: (_) => (result: pending.future, cancel: () {
            if (!pending.isCompleted) {pending.complete(const HintResult(HintStatus.cancelled));}
          }, released: Future<void>.value()),
        );
        Future<void>? request;
        try {
          await t.runAsync(() async {
            await c.initialize();
            if (situation == 'tutorial') {await c.startLevel(1);} else {await c.start(p);}
          });
          await t.pumpWidget(PourluneApp(controller: c, textScaler: TextScaler.linear(spec.scale)));
          await t.pumpAndSettle();
          await settleFlameBoard(t, c);
          if (situation == 'hint') {request = c.requestHint(); await t.pumpAndSettle();}
          final key = situation == 'hint' ? 'cancel-hint' : 'skip-tutorial';
          final action = find.byKey(Key(key));
          final pane = find.byKey(PageStorageKey('board-explanations-${c.current!.id}'));
          final paneRect = t.getRect(pane);
          final bounds = Rect.fromLTRB(0, spec.top, spec.size.width, spec.size.height - spec.bottom);
          fullyVisible(t, action, Rect.fromLTRB(bounds.left, paneRect.top, bounds.right, paneRect.bottom),
            label: '$key complete48 inside information height', control: true);
          final before = t.getRect(action);
          await t.drag(pane, const Offset(0, -160));
          await t.pumpAndSettle();
          expect(t.getRect(action), before, reason: '$key stays outside text scrolling');
          visible(t, key, bounds);
          for (final fixed in ['home','pause','undo','restart',if (situation == 'hint') 'hint']) {
            visible(t, fixed, bounds);
          }
          await t.tap(action);
          for (var i = 0; i < 200 && c.phase == SavePhase.saving; i++) {
            await t.pump(const Duration(milliseconds: 10));
            await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          }
          await t.pumpAndSettle();
          if (situation == 'hint') {await request; expect(c.hintSearching, isFalse);}
          else {expect(c.phase, SavePhase.clean); expect(c.current!.tutorial?.active ?? false, isFalse);}
          expect(t.takeException(), isNull);
        } finally {
          c.cancelHint(); await t.pumpWidget(const SizedBox()); c.dispose();
          await t.runAsync(store.close); dir.deleteSync(recursive: true);
        }
      });
    }
  }
  for (final branch in [
    'ordinary',
    'patch',
    'chapter',
    'final',
    'daily',
    'replay',
    'reward',
    'reward-final',
    'completed-seven',
    'chapter-seven',
    'final-seven',
  ]) {
    testWidgets('LY03 $branch completion actions need no scroll', (t) async {
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('ly-completion-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/layout.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final level = switch (branch) {
        'patch' || 'reward' => 4,
        'chapter' || 'chapter-seven' => 20,
        'final' || 'reward-final' || 'final-seven' => 60,
        _ => 10,
      };
      var initial = branch == 'daily'
          ? daily()
          : GameInstance.create(
              id: 'ly-$branch',
              puzzle: branch.endsWith('-seven')
                  ? Puzzle.parse(
                      File('assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json')
                          .readAsStringSync(),
                    )
                  : fixture(level),
              isReplay: branch == 'replay',
            );
      if (branch.endsWith('-seven')) initial = initial.grantExtraBottle();
      final state = finish(initial);
      final c = GameController(
        store,
        library: ContentLibrary(
          main: {
            level: state.puzzle,
            if (level < 60) level + 1: fixture(level + 1),
          },
        ),
      );
      try {
        await t.runAsync(() async {
          await store.settle(state);
          await c.initialize();
          await c.resumeSlot(state.slot);
          if (branch.startsWith('reward')) await c.viewPatch();
        });
        final keys = switch (branch) {
          'final' || 'final-seven' => [
            'daily-final',
            'view-collection',
            'replay-levels',
            'home',
          ],
          'chapter' || 'chapter-seven' => ['next', 'view-collection', 'home'],
          'daily' => ['daily-calendar', 'home'],
          'replay' => ['replay-again', 'choose-level', 'home'],
          'patch' => ['view-patch', 'home'],
          'reward' => ['next', 'view-collection'],
          'reward-final' => ['daily-final', 'replay-levels', 'view-collection'],
          _ => ['next', 'home'],
        };
        for (final scale in [1.0, 1.3, 1.5, 2.0]) {
          for (final screen in screens) {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = screen.size;
            t.view.padding = FakeViewPadding(
              top: screen.top,
              bottom: screen.bottom,
            );
            await t.pumpWidget(
              PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
            );
            await t.pumpAndSettle();
            final bounds = Rect.fromLTRB(
              0,
              screen.top,
              screen.size.width,
              screen.size.height - screen.bottom,
            );
            for (final key in keys) {
              visible(t, key, bounds);
            }
            if (scale <= 1.3) {
              final l = AppLocalizations.of(t.element(find.byKey(Key(keys.first))));
              if (branch.startsWith('reward')) {
                for (final text in [l.newPatch, l.addedCollection]) {
                  fullyVisible(t, find.text(text), bounds, label: '$branch/$scale/${screen.size}/$text');
                }
              } else {
                final status = branch == 'daily' ? l.stampSaved(state.puzzleDate!)
                    : branch == 'replay' ? l.replayComplete : l.firstClearSaved;
                fullyVisible(t, find.text(status), bounds, label: '$branch/$scale/${screen.size}/saved status');
                if (branch.startsWith('chapter') || branch.startsWith('final')) {
                  fullyVisible(t, find.text(l.chapterComplete), bounds, label: '$branch/$scale/${screen.size}/chapter status');
                }
              }
              final scenes = find.byType(ScenePreview);
              for (var i = 0; i < scenes.evaluate().length; i++) {
                fullyVisible(t, scenes.at(i), bounds, label: '$branch/$scale/${screen.size}/scene');
              }
            }
            if (scale <= 1.3 && !branch.startsWith('reward')) {
              final actionsTop = keys
                  .map((k) => t.getRect(find.byKey(Key(k))).top)
                  .reduce((a, b) => a < b ? a : b);
              for (var i = 0; i < state.board.length; i++) {
                visible(t, 'preview-bottle-$i', bounds, control: false);
                visible(t, 'preview-bottle-count-$i', bounds, control: false);
                expect(
                  t.getRect(find.byKey(Key('preview-bottle-$i'))).bottom,
                  lessThanOrEqualTo(actionsTop),
                  reason:
                      '$branch/$scale/${screen.size} preview ${t.getRect(find.byKey(const Key('completion-preview')))} actionsTop $actionsTop',
                );
              }
            }
            expect(
              t.takeException(),
              isNull,
              reason: '$branch/$scale/${screen.size}',
            );
          }
        }
        expect((await t.runAsync(store.progress))!.receipts, 1);
        expect(c.current!.id, state.id);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    });
  }
}
