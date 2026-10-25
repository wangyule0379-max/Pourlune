import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('canonical Small maximum type preserves seven readable bottles', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(375, 667);
    t.view.padding = const FakeViewPadding(top: 20);
    final dir = Directory.systemTemp.createTempSync('canonical-max-');
    final store = (await t.runAsync(
      () =>
          GameStore.open('${dir.path}/qa.sqlite', factory: databaseFactoryFfi),
    ))!;
    final puzzle = Puzzle.parse(
      File('assets/puzzles/main/main-012.json').readAsStringSync(),
    );
    var initial = GameInstance.create(id: 'canonical-max', puzzle: puzzle);
    for (final move in puzzle.referenceMoves.take(11)) {
      initial = initial.pour(move.from, move.to).state;
    }
    initial = initial.grantExtraBottle().pour(0, 5).state;
    final c = GameController(
      store,
      library: ContentLibrary(main: {12: puzzle}),
    );
    try {
      await t.runAsync(() async {
        await store.save(initial);
        await c.initialize();
        await c.resumeSlot('ordinary');
      });
      await t.pumpWidget(
        PourluneApp(
          controller: c,
          textScaler: const TextScaler.linear(3.1176470588235294),
        ),
      );
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      final viewport = t.getRect(
        find.byKey(const PageStorageKey('board-viewport-canonical-max')),
      );
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      debugPrint(
        'canonical max viewport=$viewport actions=${t.getRect(find.byKey(const Key('hint')))} bottle=${game.frame.layout.shape.visibleRect} label=${game.frame.layout.labelRect(0)}',
      );
      final problems = <String>[];
      Object? error;
      while ((error = t.takeException()) != null) {
        problems.add('$error');
      }
      if (viewport.height < 1) problems.add('No board viewport remains.');
      for (var i = 0; i < 7; i++) {
        final hit = t.getRect(find.byKey(Key('bottle-$i'))),
            count = t.getRect(find.byKey(Key('bottle-count-$i')));
        if (hit.height < 48) problems.add('Bottle $i body is below48px.');
        if (count.bottom > viewport.bottom + .01) {
          problems.add('Bottle $i capacity leaves the board viewport.');
        }
      }
      expect(
        problems,
        isEmpty,
        reason: 'Ordinary production presentation must pass through the now-approved responsive Info/dock composition.',
      );
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      t.view.reset();
      dir.deleteSync(recursive: true);
    }
  });
}
