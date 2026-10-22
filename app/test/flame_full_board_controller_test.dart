import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/board_page.dart';

import 'support/flame_board_ready.dart';

import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'FB06 tutorial completion and same-instance label changes retain the active renderer and its two decoded layers',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('flame-board-state-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/board.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      FlameBoardGame game() => t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      try {
        await t.runAsync(() async {
          await store.save(
            GameInstance.create(
              id: 'teaching-retention',
              puzzle: fixture(),
              tutorial: true,
            ),
            replace: true,
          );
          await c.initialize();
          c.resume();
        });
        await t.pumpWidget(PourluneApp(controller: c, puzzles: [fixture()]));
        for (var n = 0; n < 300 && game().art == null; n++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pump();
        }
        final mounted = game(), art = game().art;
        expect(art, isNotNull);
        for (final m in c.current!.puzzle.referenceMoves.take(3)) {
          await t.runAsync(() => c.pour(m.from, m.to));
          await t.pump();
          expect(
            identical(game(), mounted),
            isTrue,
            reason: 'conditional assistance labels must not replace a same-instance game during a committed action',
          );
          expect(game().art, same(art));
          expect(art!.disposed, isFalse);
          await t.pumpAndSettle();
          expect(c.busy, isFalse);
        }
        expect(c.current!.moveCount, 3);
        expect(
          c.current!.board
              .where((b) => b.isNotEmpty)
              .every((b) => b.toSet().length == 1),
          isTrue,
        );
        expect(c.current!.completed, isFalse);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'FB05 replacing an active instance retains one working presentation owner',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('flame-board-replace-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/board.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      try {
        await t.runAsync(c.initialize);
        await t.runAsync(() => c.start(fixture()));
        await t.pumpWidget(PourluneApp(controller: c, puzzles: [fixture()]));
        await settleFlameBoard(t, c);
        final oldId = c.current!.id;
        await t.runAsync(() => c.start(fixture(), replace: true));
        await settleFlameBoard(t, c);
        expect(c.current!.id, isNot(oldId));
        expect(find.byType(BoardPage), findsOneWidget);
        expect(find.byType(GameWidget<FlameBoardGame>), findsOneWidget);
        await t.runAsync(() => c.pour(0, 2));
        expect(c.current!.moveCount, 1);
        expect(c.phase, SavePhase.clean);
        expect(
          c.motion,
          isNotNull,
          reason: 'retiring the old page must not detach the new page owner',
        );
        expect(
          c.busy,
          isTrue,
          reason:
              'the committed action still waits for its real visual callback',
        );
        await t.pumpWidget(const SizedBox());
        expect(
          c.motion,
          isNull,
          reason: 'the final owner removal cancels the visual',
        );
        expect(
          (await t.runAsync(() => store.load('ordinary')))!.instance!.toJson(),
          c.current!.toJson(),
        );
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
}
