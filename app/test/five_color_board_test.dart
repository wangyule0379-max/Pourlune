import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/bottle_foot_label.dart';
import 'package:pourlune_dev/presentation/completion_bottles.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

Widget shell(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('seven/eight bottles have distinct bounded geometry and routes', () {
    for (final width in [320.0, 390.0]) {
      for (final count in [7, 8]) {
        final layout = BoardLayout(width: width, count: count, maxHeight: 470);
        expect(layout.cells, hasLength(count));
        expect(layout.mouths, hasLength(count));
        expect(layout.topRowCount, 4);
        for (var i = 0; i < count; i++) {
          final hit = layout.hitRect(i);
          expect(hit.left, greaterThanOrEqualTo(0));
          expect(hit.right, lessThanOrEqualTo(width));
          expect(hit.height, greaterThanOrEqualTo(48));
          for (var j = i + 1; j < count; j++) {
            expect(hit.overlaps(layout.hitRect(j)), isFalse);
          }
        }
        expect(layout.cells.last.bottom, lessThanOrEqualTo(470));
        expect(
          layout
              .hintRoute(0, count - 1)
              .every((p) => p.dx.isFinite && p.dy.isFinite),
          isTrue,
        );
      }
    }
  });

  testWidgets('fifth color, eighth native action, movement and Undo render', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    final tapped = <int>[];
    final completed = <int>[];
    var state = boardFixture(colors: 5);
    Future<void> show({int? selected, PourMotion? motion}) => t.pumpWidget(
      shell(
        SizedBox(
          width: 360,
          height: 470,
          child: BoardView(
            state: state,
            selected: selected,
            onTap: tapped.add,
            motion: motion,
            onMotionComplete: completed.add,
          ),
        ),
      ),
    );
    try {
      await show();
      await waitForFlameArt(t);
      expect(find.byKey(const Key('bottle-6')), findsOneWidget);
      expect(find.byKey(const Key('bottle-7')), findsNothing);
      state = state.grantExtraBottle();
      await show(selected: 4);
      await t.pump(const Duration(milliseconds: 250));
      expect(
        t.getSemantics(find.byKey(const Key('bottle-4'))).label,
        contains('Rose star'),
      );
      for (var i = 0; i < 5; i++) {
        expect(
          t.widget<TargetCushion>(find.byKey(Key('bottle-target-$i'))).target,
          state.puzzle.targets[i],
        );
      }
      final eighth = find.byKey(const Key('bottle-7'));
      await t.tap(eighth);
      expect(tapped, [7]);
      final node = t.getSemantics(eighth);
      node.owner!.performAction(node.id, ui.SemanticsAction.tap);
      expect(tapped, [7, 7]);
      expect(find.byKey(const Key('dock-readout')), findsNothing);
      var move = boardMove(state, 4, 7);
      state = move.after;
      await show(motion: move.motion);
      await t.pump(const Duration(seconds: 3));
      await t.pump();
      expect(completed, [1]);
      state = state.undo();
      expect(state.board, hasLength(8));
      await show(selected: 0);
      await t.pump(const Duration(milliseconds: 200));
      move = boardMove(state, 0, 7, token: 2);
      state = move.after;
      await show(motion: move.motion);
      await t.pump(const Duration(seconds: 3));
      await t.pump();
      expect(completed, [1, 2]);
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      expect(game.frame.counts, state.board.map((b) => b.length));
      state = boardFixture(colors: 5, id: 'replacement');
      await show();
      await t.pump();
      expect(find.byKey(const Key('bottle-7')), findsNothing);
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox());
      semantics.dispose();
    }
  });

  testWidgets('five-target badge stays above every first-row bottle', (
    t,
  ) async {
    var state = boardFixture(colors: 5);
    for (final move in state.puzzle.referenceMoves) {
      state = state.pour(move.from, move.to).state;
    }
    await t.pumpWidget(
      shell(
        SizedBox(
          width: 360,
          height: 400,
          child: CompletionBottles(
            state: state,
            settings: const PlayerSettings(),
            badge: const ColoredBox(
              key: Key('five-target-badge'),
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
    final badge = t.getRect(find.byKey(const Key('five-target-badge')));
    for (var i = 0; i < 3; i++) {
      expect(
        t.getRect(find.byKey(Key('completion-bottle-$i'))).top,
        greaterThanOrEqualTo(badge.bottom + 4),
        reason:
            'the middle target mouth must remain fully visible below the badge',
      );
    }
    await t.pumpWidget(const SizedBox());
  });

  for (final compact in [false, true]) {
    testWidgets(
      'five completed targets use bounded 3+2 rows (compact=$compact)',
      (t) async {
        var state = boardFixture(colors: 5);
        for (final move in state.puzzle.referenceMoves) {
          state = state.pour(move.from, move.to).state;
        }
        expect(state.completed, isTrue);
        await t.pumpWidget(
          shell(
            SizedBox(
              width: 320,
              height: 350,
              child: CompletionBottles(
                state: state,
                settings: const PlayerSettings(),
                singleRow: compact,
              ),
            ),
          ),
        );
        for (var i = 0; i < 20; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pump();
        }
        final rects = <Rect>[];
        for (var i = 0; i < 5; i++) {
          final bottle = find.byKey(Key('completion-bottle-$i'));
          expect(bottle, findsOneWidget);
          rects.add(t.getRect(bottle));
          expect(find.byKey(Key('completion-target-$i')), findsOneWidget);
        }
        expect(rects.take(3).map((r) => r.top).toSet(), hasLength(1));
        expect(rects.skip(3).map((r) => r.top).toSet(), hasLength(1));
        expect(rects[3].top, greaterThan(rects[0].bottom));
        final bounds = t.getRect(find.byType(CompletionBottles));
        for (final rect in rects) {
          expect(rect.left, greaterThanOrEqualTo(bounds.left));
          expect(rect.right, lessThanOrEqualTo(bounds.right));
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
        }
        expect(find.byKey(const Key('completion-bottle-5')), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
