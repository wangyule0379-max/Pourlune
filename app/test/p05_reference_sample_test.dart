import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/knit_components.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  });
  testWidgets(
    'P05 live six-bottle materials retain actual pour, reselection, true rejection, Undo and free Pause Restart',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(375, 667);
      t.view.padding = const FakeViewPadding(top: 20);
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('p05-live-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final puzzle = Puzzle.parse(
        File('assets/puzzles/main/main-012.json').readAsStringSync(),
      );
      final initial = GameInstance.create(id: 'p05-live', puzzle: puzzle);
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
        await t.pumpWidget(PourluneApp(controller: c));
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        expect(c.current!.board.length, 6);
        expect(
          find.descendant(
            of: find.byKey(const Key('board-feedback')),
            matching: find.byType(KnitPanel),
          ),
          findsNothing,
          reason: 'Normal PLAY has a simple rule heading, not the withdrawn permanent card.',
        );
        final viewport = t.getRect(
          find.byKey(PageStorageKey('board-viewport-${initial.id}')),
        );
        for (var i = 0; i < 6; i++) {
          final bottle = find.byKey(Key('bottle-$i'));
          final rect = t.getRect(bottle);
          final count = t.getRect(find.byKey(Key('bottle-count-$i')));
          expect(rect.top, greaterThanOrEqualTo(viewport.top));
          expect(count.bottom, lessThanOrEqualTo(viewport.bottom + .001));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(bottle.hitTestable(), findsOneWidget);
        }
        final buttons = [
          'undo',
          'hint',
          'extra-bottle',
        ].map((key) => t.getRect(find.byKey(Key(key)))).toList();
        expect(buttons.map((r) => r.top).toSet(), hasLength(1));
        expect(buttons.last.bottom, lessThanOrEqualTo(667));
        final move = puzzle.referenceMoves.first;
        await t.runAsync(() async {
          await t.tap(find.byKey(Key('bottle-${move.from}')));
          await t.tap(find.byKey(Key('bottle-${move.to}')));
        });
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        expect(c.current!.moveCount, 1);
        final persisted = (await t.runAsync(() => store.load('ordinary')))!
            .instance!;
        expect(persisted.board, initial.pour(move.from, move.to).state.board);
        expect(persisted.moveCount, 1);
        final invalid = [(0, 1), (1, 0), (2, 1), (3, 0)].firstWhere(
          (m) =>
              c.current!.board[m.$1].isNotEmpty &&
              pourBoard(c.current!.board, m.$1, m.$2).units == 0,
        );
        final before = c.current!;
        await t.tap(find.byKey(Key('bottle-${invalid.$1}')));
        await t.tap(find.byKey(Key('bottle-${invalid.$2}')));
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        expect(c.current!.board, before.board);
        expect(c.current!.moveCount, 1);
        expect(c.selectedSource, invalid.$2);
        expect(c.rejection, isNull);
        // Direct pour still reports genuine refusal; ordinary taps reselect.
        await t.runAsync(() => c.pour(invalid.$1, invalid.$2));
        expect(c.rejection, isNotNull);
        expect(c.current, same(before));
        await t.runAsync(() => t.tap(find.byKey(const Key('undo'))));
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        expect(c.current!.board, initial.board);
        final beforeHint = [
          for (var i = 0; i < 6; i++) t.getRect(find.byKey(Key('bottle-$i'))),
        ];
        await t.runAsync(c.requestHint);
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        expect(c.hint?.status, HintStatus.found);
        expect(
          t.getRect(find.byKey(const Key('feedback-badge'))).width,
          lessThanOrEqualTo(280),
        );
        expect(
          t.getSize(find.byKey(const Key('cancel-hint'))),
          const Size(48, 48),
        );
        for (var i = 0; i < 6; i++) {
          expect(t.getRect(find.byKey(Key('bottle-$i'))), beforeHint[i]);
        }
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const Key('cancel-hint')));
        await t.pumpAndSettle();
        expect(c.hint, isNull);
        expect(c.selectedSource, isNull);
        await t.tap(find.byKey(const Key('pause')));
        await t.pumpAndSettle();
        expect(
          find.byKey(const Key('pause-restart')).hitTestable(),
          findsOneWidget,
        );
        await t.tap(find.byKey(const Key('pause-restart')));
        await t.pumpAndSettle();
        expect(
          find.byKey(const Key('confirm-restart')).hitTestable(),
          findsOneWidget,
        );
        await t.runAsync(() => t.tap(find.byKey(const Key('confirm-restart'))));
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        expect(c.current!.board, initial.board);
        expect(c.phase, SavePhase.clean);
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
