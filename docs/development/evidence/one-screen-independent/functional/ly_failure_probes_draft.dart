// Deferred independent probes for the frozen LY snapshot. NOT EXECUTED.
// Stage as app/test/ly_independent_failure_probes_test.dart only in an approved
// isolated execution copy; the relative imports intentionally target its tests.
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;
import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  sqfliteFfiInit();
  for (final stay in [false, true]) {
    testWidgets('LY-independent failed receipt queued Next Stay=$stay', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 568);
      t.view.padding = const FakeViewPadding(top: 20);
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('ly-independent-');
      final store = (await t.runAsync(() => GameStore.open(
        '${dir.path}/probe.sqlite', factory: databaseFactoryFfi,
      )))!;
      final feedback = <GameFeedback>[];
      final c = GameController(store,
        library: ContentLibrary(main: {10: fixture(10), 11: fixture(11)}),
        onFeedback: feedback.add,
      );
      try {
        await t.runAsync(() async {
          await c.initialize();
          await c.start(fixture(10));
          final moves = c.current!.puzzle.referenceMoves;
          for (final m in moves.take(moves.length - 1)) {
            await c.pour(m.from, m.to);
          }
          store.fault = (stage) {
            if (stage == 'receipt') throw StateError('independent receipt fault');
          };
          await c.pour(moves.last.from, moves.last.to);
        });
        final completedId = c.current!.id;
        expect(c.phase, SavePhase.failed);
        expect(c.receipt, isNull);
        expect(feedback.where((e) => e == GameFeedback.complete), isEmpty);
        await t.pumpWidget(PourluneApp(controller: c,
          textScaler: const TextScaler.linear(1.3)));
        await t.pumpAndSettle();
        for (final key in ['next', 'next', 'home']) {
          final f = find.byKey(Key(key));
          expect(f.hitTestable(), findsOneWidget);
          await t.tap(f);
          await t.pump();
        }
        expect(c.page, GamePage.completion);
        expect(c.current!.id, completedId);
        expect((await t.runAsync(store.progress))!.receipts, 0);
        if (stay) {
          await t.tap(find.byKey(const Key('stay')));
          await t.pump();
          expect(c.phase, SavePhase.failed);
        }
        store.fault = null;
        await t.tap(find.byKey(const Key('retry')));
        await t.pump();
        for (var i = 0; i < 300 && c.busy; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(c.busy, isFalse);
        await t.pumpAndSettle();
        expect(c.phase, SavePhase.clean);
        expect((await t.runAsync(store.progress))!.receipts, 1);
        expect(c.page, stay ? GamePage.completion : GamePage.board);
        expect(c.current!.puzzle.mainLevel, stay ? 10 : 11);
        expect(c.current!.id == completedId, stay);
        final idAfter = c.current!.id;
        await t.runAsync(c.retry);
        expect(c.current!.id, idAfter);
        expect((await t.runAsync(store.progress))!.receipts, 1);
        expect(feedback.where((e) => e == GameFeedback.complete).length,
          lessThanOrEqualTo(1));
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    });
  }

  testWidgets('LY-independent resize and font threshold during same Flame pour', (t) async {
    final before = boardFixture(extra: true);
    final move = boardMove(before, 0, 6);
    final releases = <int>[];
    final taps = <int>[];
    Widget view(double scale, double height, {bool moving = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SizedBox(width: 320, height: height,
          child: BoardView(key: const Key('stable-board'),
            state: moving ? move.after : before,
            selected: null, onTap: taps.add,
            motion: moving ? move.motion : null,
            onMotionComplete: releases.add,
          ),
        )),
      ),
    );
    await t.pumpWidget(view(1, 400));
    await waitForFlameArt(t);
    final game = t.widget<GameWidget<FlameBoardGame>>(
      find.byType(GameWidget<FlameBoardGame>)).game!;
    await t.pumpWidget(view(1, 400, moving: true));
    await t.pump(const Duration(milliseconds: 350));
    expect(game.frame.active, isNotNull);
    await t.pumpWidget(view(2, 240, moving: true));
    await t.pump();
    expect(t.widget<GameWidget<FlameBoardGame>>(
      find.byType(GameWidget<FlameBoardGame>)).game, same(game));
    expect(game.closed, isFalse);
    await t.pumpWidget(view(1.3, 400, moving: true));
    await t.pump(const Duration(seconds: 2));
    expect(game.closed, isFalse);
    expect(releases, [move.motion.token]);
    expect(game.frame.active, isNull);
    expect(game.frame.contents, move.after.board);
    expect(game.frame.counts, move.after.board.map((b) => b.length).toList());
    await t.tap(find.byKey(const Key('bottle-0')));
    await t.pump();
    expect(taps, [0]);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
