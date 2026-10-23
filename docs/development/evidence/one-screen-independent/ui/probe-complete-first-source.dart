// Independent LY UI probes. Not a shipping/native harness. No capture APIs.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:pourlune_dev/presentation/game_screen.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'one_screen_layout_test.dart' as author;
import 'store_test.dart' show fixture, finish, daily;
import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

List<double> rectData(Rect r) => [r.left, r.top, r.right, r.bottom];

Rect safeRect(WidgetTester t) {
  final media = MediaQuery.of(t.element(find.byType(GameScreen)));
  return Rect.fromLTRB(
    media.padding.left,
    media.padding.top,
    media.size.width - media.padding.right,
    media.size.height - media.padding.bottom,
  );
}

// Include the inner scroll clip, not only the outer SafeArea.
Rect paneRect(WidgetTester t, Finder target) {
  var visible = safeRect(t);
  for (final e
      in find
          .ancestor(of: target, matching: find.byType(SingleChildScrollView))
          .evaluate()) {
    visible = visible.intersect(
      t.getRect(
        find.byElementPredicate((candidate) => identical(candidate, e)),
      ),
    );
  }
  return visible;
}

bool reportBounds(
  WidgetTester t,
  String label,
  Finder f, {
  bool mustFit = false,
  bool control = false,
}) {
  expect(f, findsOneWidget, reason: label);
  final rect = t.getRect(f), pane = paneRect(t, f);
  final inside =
      rect.left >= pane.left - .01 &&
      rect.top >= pane.top - .01 &&
      rect.right <= pane.right + .01 &&
      rect.bottom <= pane.bottom + .01;
  debugPrint(
    'LY_UI_OBSERVATION=${jsonEncode({'label': label, 'rect': rectData(rect), 'pane': rectData(pane), 'fully_inside_local_clip': inside, 'required_assertion': mustFit, 'control': control})}',
  );
  if (mustFit) expect(inside, isTrue, reason: '$label: $rect vs local $pane');
  if (control) {
    expect(rect.width, greaterThanOrEqualTo(48), reason: label);
    expect(rect.height, greaterThanOrEqualTo(48), reason: label);
    expect(f.hitTestable(), findsOneWidget, reason: label);
  }
  return inside;
}

void reportScrolls(WidgetTester t, String stage) {
  for (final e in find.byType(Scrollable).evaluate()) {
    final state = (e as StatefulElement).state as ScrollableState;
    debugPrint(
      'LY_UI_SCROLL=${jsonEncode({'stage': stage, 'pixels': state.position.pixels, 'min': state.position.minScrollExtent, 'max': state.position.maxScrollExtent})}',
    );
    expect(state.position.pixels, closeTo(0, .01), reason: stage);
  }
}

Future<void> mount(
  WidgetTester t,
  GameController c,
  double scale,
  Size size,
  double top,
  double bottom,
) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  t.view.padding = FakeViewPadding(top: top, bottom: bottom);
  await t.pumpWidget(
    PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
  );
  await t.pumpAndSettle();
  if (c.page == GamePage.board) await settleFlameBoard(t, c);
  if (c.page == GamePage.completion) await waitForFlameArt(t);
}

Future<void> withState(
  WidgetTester t,
  GameInstance state,
  Future<void> Function(GameController) body, {
  bool reward = false,
}) async {
  final dir = Directory.systemTemp.createTempSync('ly-ui-review-');
  final store = (await t.runAsync(
    () => GameStore.open('${dir.path}/ui.sqlite', factory: databaseFactoryFfi),
  ))!;
  final level = state.puzzle.mainLevel ?? 10;
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
      if (state.completed) {
        await store.settle(state);
      } else {
        await store.save(state);
      }
      await c.initialize();
      await c.resumeSlot(state.slot);
      if (reward) await c.viewPatch();
    });
    await body(c);
  } finally {
    c.cancelHint();
    await t.pumpWidget(const SizedBox());
    c.dispose();
    await t.runAsync(store.close);
    dir.deleteSync(recursive: true);
  }
}

// Await actual disk continuations after a real tap before closing its store.
Future<void> finishWrite(WidgetTester t, GameController c) async {
  for (var i = 0; i < 200 && c.phase == SavePhase.saving; i++) {
    await t.pump(const Duration(milliseconds: 10));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(
    c.phase,
    isNot(SavePhase.saving),
    reason: 'UI probe must finish actual save before teardown',
  );
}

Rect semanticsRect(SemanticsNode node) {
  var matrix = Matrix4.identity();
  SemanticsNode? current = node;
  while (current != null) {
    if (current.transform != null) matrix = current.transform! * matrix;
    current = current.parent;
  }
  return MatrixUtils.transformRect(matrix, node.rect);
}

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await loader.load();
  });

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
  ]) {
    testWidgets('LY-UI-G01 $branch first-screen local clips', (t) async {
      addTearDown(t.view.reset);
      final level = switch (branch) {
        'patch' || 'reward' => 4,
        'chapter' => 20,
        'final' || 'reward-final' => 60,
        _ => 10,
      };
      var state = branch == 'daily'
          ? daily()
          : GameInstance.create(
              id: 'ui-$branch',
              isReplay: branch == 'replay',
              puzzle: branch == 'completed-seven'
                  ? Puzzle.parse(
                      File('assets/puzzles/main/main-010.json')
                          .readAsStringSync(),
                    )
                  : fixture(level),
            );
      if (branch == 'completed-seven') state = state.grantExtraBottle();
      state = finish(state);
      await withState(t, state, (c) async {
        final keys = switch (branch) {
          'final' => [
            'daily-final',
            'view-collection',
            'replay-levels',
            'home',
          ],
          'chapter' => ['next', 'view-collection', 'home'],
          'daily' => ['daily-calendar', 'home'],
          'replay' => ['replay-again', 'choose-level', 'home'],
          'patch' => ['view-patch', 'home'],
          'reward' => ['next', 'view-collection'],
          'reward-final' => ['daily-final', 'replay-levels', 'view-collection'],
          _ => ['next', 'home'],
        };
        for (final scale in [1.0, 1.3]) {
          for (final screen in author.screens) {
            await mount(t, c, scale, screen.size, screen.top, screen.bottom);
            final tag = '$branch/$scale/${screen.size}';
            reportScrolls(t, tag);
            for (final key in keys) {
              reportBounds(
                t,
                '$tag/$key',
                find.byKey(Key(key)),
                mustFit: true,
                control: true,
              );
            }
            reportBounds(
              t,
              '$tag/save-status',
              find.byKey(const Key('save-status')),
              mustFit: true,
            );
            if (!branch.startsWith('reward')) {
              for (var i = 0; i < state.board.length; i++) {
                reportBounds(
                  t,
                  '$tag/preview-$i',
                  find.byKey(Key('preview-bottle-$i')),
                  mustFit: true,
                );
                reportBounds(
                  t,
                  '$tag/count-$i',
                  find.byKey(Key('preview-bottle-count-$i')),
                  mustFit: true,
                );
              }
            }
            // Measure branch descriptions/scenes without silently deciding that
            // every long secondary sentence is a new no-scroll requirement.
            final l = AppLocalizations.of(t.element(find.byType(GameScreen)));
            for (final text in [
              l.firstClearSaved,
              l.dailyComplete,
              l.replayComplete,
              l.storyCompleteBody,
              l.chapterComplete,
              l.addedCollection,
              l.newPatch,
            ]) {
              final found = find.text(text);
              for (var i = 0; i < found.evaluate().length; i++) {
                reportBounds(t, '$tag/text:$text', found.at(i));
              }
            }
            final scenes = find.byType(ScenePreview);
            for (var i = 0; i < scenes.evaluate().length; i++) {
              reportBounds(t, '$tag/scene-$i', scenes.at(i));
            }
            expect(t.takeException(), isNull, reason: tag);
          }
        }
      }, reward: branch.startsWith('reward'));
    });
  }

  for (final situation in [
    'hint',
    'tutorial',
    'save-failed',
    'reward-warning',
  ]) {
    for (final spec in [
      (Size(320, 568), 2.0, 20.0, 0.0),
      (Size(360, 640), 1.5, 24.0, 24.0),
    ]) {
      testWidgets('LY-UI-G02 $situation scale${spec.$2} local action clip', (
        t,
      ) async {
        addTearDown(t.view.reset);
        // Reuse author setup, including a real pending hint computation, by
        // constructing only this UI state. No SDK or award is simulated.
        final dir = Directory.systemTemp.createTempSync('ly-ui-info-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/ui.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final p = situation == 'tutorial'
            ? fixture()
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
              final state = GameInstance.create(
                id: 'ui-$situation',
                puzzle: p,
              ).grantExtraBottle();
              await store.save(state);
              await c.initialize();
              await c.resumeSlot('ordinary');
              if (situation == 'save-failed') {
                c.failNextWrite();
                await c.pour(0, 4);
                expect(c.phase, SavePhase.failed);
              }
            }
          });
          if (situation == 'reward-warning') {
            c.rewardSaveFailed = true;
            c.rewardIssue = 'confirmation_save_failed';
          }
          await mount(t, c, spec.$2, spec.$1, spec.$3, spec.$4);
          if (situation == 'hint') {
            request = c.requestHint();
            await t.pumpAndSettle();
            expect(c.hintSearching, isTrue);
          }
          reportScrolls(t, situation);
          for (final key in [
            'home',
            'pause',
            'undo',
            'restart',
            if (situation != 'tutorial') 'hint',
            if (c.offersExtraBottle) 'extra-bottle',
            if (situation == 'hint') 'cancel-hint',
            if (situation == 'tutorial') 'skip-tutorial',
            if (situation == 'save-failed') ...['retry', 'stay'],
            if (situation == 'reward-warning') 'retry-reward',
          ]) {
            reportBounds(
              t,
              '$situation/${spec.$2}/$key',
              find.byKey(Key(key)),
              mustFit: true,
              control: true,
            );
          }
          if (situation == 'hint') {
            await t.tap(find.byKey(const Key('cancel-hint')));
            await t.pumpAndSettle();
            await request;
            expect(c.hintSearching, isFalse);
          } else if (situation == 'tutorial') {
            await t.tap(find.byKey(const Key('skip-tutorial')));
            await finishWrite(t, c);
            await t.pumpAndSettle();
            expect(c.current!.tutorial?.active ?? false, isFalse);
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
  }

  testWidgets('LY-UI-G03 seven bottles focus semantics without scrolling', (
    t,
  ) async {
    addTearDown(t.view.reset);
    final semantics = t.ensureSemantics();
    try {
      await withState(t, boardFixture(extra: true), (c) async {
        await mount(t, c, 1.3, const Size(320, 568), 20, 0);
        reportScrolls(t, 'semantics-initial');
        for (var i = 0; i < 7; i++) {
          final f = find.byKey(Key('bottle-$i'));
          reportBounds(
            t,
            'semantics/bottle-$i',
            f,
            mustFit: true,
            control: true,
          );
          final node = t.getSemantics(f), data = node.getSemanticsData();
          expect(data.label, contains('Bottle ${i + 1}'));
          expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
          final semanticRect = semanticsRect(node), visualRect = t.getRect(f);
          expect(semanticRect.left, closeTo(visualRect.left, 1));
          expect(semanticRect.top, closeTo(visualRect.top, 1));
          expect(semanticRect.width, closeTo(visualRect.width, 1));
          expect(semanticRect.height, closeTo(visualRect.height, 1));
        }
        expect(
          t
              .getSemantics(find.byKey(const Key('undo')))
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
        final target = find.byKey(const Key('bottle-0'));
        final button = t.widget<ButtonStyleButton>(target);
        final child = find
            .descendant(
              of: target,
              matching: find.byWidgetPredicate(
                (w) => identical(w, button.child),
              ),
            )
            .first;
        final focus = Focus.of(t.element(child));
        for (final key in [
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
        ]) {
          c.clearSelection();
          await t.pump();
          focus.requestFocus();
          await t.pump();
          expect(focus.hasPrimaryFocus, isTrue);
          reportBounds(
            t,
            'focused bottle',
            target,
            mustFit: true,
            control: true,
          );
          await t.sendKeyEvent(key);
          await t.pumpAndSettle();
          expect(c.selectedSource, 0);
          reportScrolls(t, 'focused keyboard action');
        }
        c.clearSelection();
        await t.pump();
        final node = t.getSemantics(target);
        node.owner!.performAction(node.id, ui.SemanticsAction.tap);
        await t.pump();
        expect(c.selectedSource, 0);
        expect(c.current!.moveCount, 0);
        expect(t.takeException(), isNull);
      });
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'LY-UI-G03 completion preview has no actionable bottle semantics',
    (t) async {
      addTearDown(t.view.reset);
      final semantics = t.ensureSemantics();
      try {
        await withState(t, finish(boardFixture(extra: true)), (c) async {
          await mount(t, c, 1.3, const Size(320, 568), 20, 0);
          for (var i = 0; i < 7; i++) {
            final data = t
                .getSemantics(find.byKey(Key('preview-bottle-$i')))
                .getSemanticsData();
            expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
            expect(data.hasFlag(ui.SemanticsFlag.isButton), isFalse);
          }
          reportScrolls(t, 'completion semantics');
          expect(t.takeException(), isNull);
        });
      } finally {
        semantics.dispose();
      }
    },
  );
}
