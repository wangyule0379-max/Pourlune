import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pourlune_dev/presentation/pourlune_app.dart';

import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  for (final screen in [
    (const Size(440, 956), 1.0),
    (const Size(440, 956), 2.35),
    (const Size(375, 667), 1.0),
  ]) {
    final scale = screen.$2;
    testWidgets(
      'production dock full page holds seven separated readouts at ${screen.$1}/$scale',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = screen.$1;
        t.view.padding = screen.$1.width == 375
            ? const FakeViewPadding(top: 20)
            : const FakeViewPadding(top: 62, bottom: 34);
        addTearDown(t.view.reset);
        final semantics = t.ensureSemantics();
        final dir = Directory.systemTemp.createTempSync('p05-dock-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final puzzle = Puzzle.parse(
          File('assets/puzzles/main/main-012.json').readAsStringSync(),
        );
        var state = GameInstance.create(id: 'dock-fixture', puzzle: puzzle);
        for (final move in puzzle.referenceMoves.take(11)) {
          state = state.pour(move.from, move.to).state;
        }
        state = state.grantExtraBottle();
        final c = GameController(store);
        try {
          await t.runAsync(() async {
            await store.save(state, replace: true);
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          await t.pumpWidget(
            PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
          );
          await waitForFlameArt(t);
          await t.pumpAndSettle();
          expect(
            find.bySemanticsLabel(
              RegExp(r'^Bottle 1\. Target Orange circle\. Bottom to top:'),
            ),
            findsOneWidget,
            reason:
                'QA candidate retains meaningful target and contents labels',
          );
          for (final key in ['home', 'pause', 'undo', 'hint', 'extra-bottle']) {
            expect(
              find.byKey(Key(key)),
              findsOneWidget,
              reason: 'candidate must retain the complete real BoardPage',
            );
          }
          expect(
            find.byKey(const Key('dock-readout-0')),
            scale > 2 ? findsOneWidget : findsNothing,
          );
          final game = t
              .widget<GameWidget<FlameBoardGame>>(
                find.byType(GameWidget<FlameBoardGame>),
              )
              .game!;
          final initialMouths = [...game.frame.layout.mouths];
          expect(game.frame.layout.shape.width, greaterThanOrEqualTo(48));
          final canvas = t.getRect(find.byKey(const Key('dock-canvas')));
          if (screen.$1.width == 375 && scale == 1) {
            expect(
              game.frame.layout.shape.visibleRect.height,
              greaterThanOrEqualTo(130),
              reason: 'Reuse the resting lower-caption area instead of shrinking seven bottles to reserve an empty second strip.',
            );
            for (var i = game.frame.layout.topRowCount; i < 7; i++) {
              expect(
                t.getRect(find.byKey(Key('bottle-count-$i'))).top,
                greaterThanOrEqualTo(canvas.bottom),
                reason: 'Quiet lower captions fill the same future dock band.',
              );
            }
          }

          await t.runAsync(() => c.pour(4, 6));
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
          final initialIndex = t.getTopLeft(
            find.byKey(const Key('dock-moving-index')),
          );
          final initialCounts = [...game.frame.counts];
          await t.pump(const Duration(milliseconds: 50));
          expect(
            game.frame.counts,
            initialCounts,
            reason:
                'the source moves during approach before a capacity boundary',
          );
          expect(
            (t.getTopLeft(find.byKey(const Key('dock-moving-index'))) -
                    initialIndex)
                .distance,
            greaterThan(1),
            reason:
                'index must follow the actual source between capacity updates',
          );
          for (var i = 0; i < 7; i++) {
            final f = find.byKey(Key('dock-readout-$i'));
            expect(f, findsOneWidget);
            expect(
              find.byKey(Key('dock-group-$i')),
              findsOneWidget,
              reason: 'each readout needs its own separated cream group',
            );
            final rect = t.getRect(f);
            expect(rect.top, greaterThanOrEqualTo(canvas.bottom));
            if (i > 0) {
              final previous = t.getRect(
                find.byKey(Key('dock-readout-${i - 1}')),
              );
              if ((rect.top - previous.top).abs() < .01) {
                expect(rect.left - previous.right, greaterThanOrEqualTo(4));
              } else {
                expect(rect.top - previous.bottom, greaterThanOrEqualTo(4));
              }
            }
            final cap = find.descendant(
              of: find.byKey(Key('dock-group-$i')),
              matching: find.text('${game.frame.counts[i]}/4'),
            );
            expect(cap, findsOneWidget);
            final capacity = t.getRect(cap);
            expect(capacity.left, greaterThanOrEqualTo(rect.left + 1));
            expect(capacity.right, lessThanOrEqualTo(rect.right - 1));
            expect(capacity.bottom, lessThanOrEqualTo(rect.bottom));
            expect(
              rect.bottom,
              lessThanOrEqualTo(
                screen.$1.height - (screen.$1.width == 375 ? 0 : 34),
              ),
            );
          }
          expect(find.text('4/4'), findsWidgets);
          expect(c.motion, isNotNull);
          expect(find.byKey(const Key('dock-moving-index')), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pump(const Duration(seconds: 2));
          await t.pump();
          expect(
            find.byKey(const Key('dock-readout-0')),
            scale > 2 ? findsOneWidget : findsNothing,
          );
          expect(
            game.frame.layout.mouths,
            initialMouths,
            reason: 'dock does not reflow bottles during or after movement',
          );
          expect(c.current!.board[4], isEmpty);
          expect(c.current!.board[6], ['O', 'O', 'O', 'O']);
        } finally {
          await t.pumpWidget(const SizedBox());
          semantics.dispose();
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      },
    );
  }
}
