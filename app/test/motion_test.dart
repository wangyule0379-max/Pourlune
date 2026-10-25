import 'dart:async';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';

import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';

import 'support/flame_board_paint.dart';

import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  FlameBoardGame boardGame(WidgetTester t) => t
      .widget<GameWidget<FlameBoardGame>>(
        find.byType(GameWidget<FlameBoardGame>),
      )
      .game!;
  Future<void> artReady(WidgetTester t) async {
    for (var n = 0; n < 300 && boardGame(t).art == null; n++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await t.pump();
    }
    expect(boardGame(t).art, isNotNull);
    await t.pump();
  }

  Future<void> controllerCase(
    Future<void> Function(GameController, GameStore) check,
  ) async {
    final dir = Directory.systemTemp.createTempSync('motion-controller-');
    final store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    final c = GameController(store);
    try {
      await c.initialize();
      await c.start(fixture());
      c.attachMotionPresenter();
      await check(c, store);
    } finally {
      c.dispose();
      await store.close();
      dir.deleteSync(recursive: true);
    }
  }

  test(
    'AC-33 pending storage and presentation both block free actions',
    () => controllerCase((c, store) async {
      final entered = Completer<void>(), release = Completer<void>();
      final held = store.db.transaction((_) async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final write = c.pour(0, 2);
      final committed = c.current!.toJson();
      expect(c.phase, SavePhase.saving);
      expect(c.motion!.before, fixture().initial);
      expect(c.motion!.after, c.current!.board);
      expect(c.motion!.instanceId, c.current!.id);
      expect(c.motion!.revision, c.current!.revision);
      expect(c.motion!.units, 2);
      await c.tapBottle(1);
      await c.undo();
      await c.restart();
      await c.requestHint();
      expect(c.current!.toJson(), committed);
      expect(c.hintSearching, isFalse);
      c.completeMotion(c.motion!.token);
      expect(c.busy, isTrue, reason: 'Finishing visuals cannot finish SQL');
      release.complete();
      await held;
      await write;
      expect(c.busy, isFalse);
      expect((await store.load('ordinary')).instance!.toJson(), committed);
    }),
  );
  test(
    'AC-33 background and navigation cancel presentation without changing move or history',
    () => controllerCase((c, store) async {
      await c.pour(0, 2);
      final committed = c.current!.toJson();
      final oldToken = c.motion!.token;
      c.setForeground(false);
      expect(c.motion, isNull);
      expect(c.busy, isFalse);
      expect((await store.load('ordinary')).instance!.toJson(), committed);
      c.setForeground(true);
      await c.pour(1, 0);
      final newToken = c.motion!.token;
      c.completeMotion(oldToken);
      expect(c.motion!.token, newToken);
      expect(c.busy, isTrue);
      await c.goHome();
      expect(c.motion, isNull);
      expect(c.page, GamePage.home);
      expect(c.current!.moveCount, 2);
      c.completeMotion(newToken);
      expect(c.page, GamePage.home);
      c.resume();
      await c.undo();
      expect(c.current!.moveCount, 1);
    }),
  );
  test(
    'AC-09 failed-save free play resumes after animation and retry persists whole state',
    () => controllerCase((c, store) async {
      store.fault = (stage) {
        if (stage == 'snapshot') throw StateError('disk full');
      };
      await c.pour(0, 2);
      expect(c.phase, SavePhase.failed);
      expect(c.busy, isTrue);
      c.completeMotion(c.motion!.token);
      expect(c.phase, SavePhase.failed);
      expect(c.busy, isFalse);
      await c.pour(1, 0);
      expect(c.current!.moveCount, 2);
      c.completeMotion(c.motion!.token);
      expect(c.phase, SavePhase.failed);
      await c.goHome();
      expect(c.page, GamePage.board);
      store.fault = null;
      await c.retry();
      expect(c.page, GamePage.home);
      expect(
        (await store.load('ordinary')).instance!.toJson(),
        c.current!.toJson(),
      );
    }),
  );
  test(
    'AC-07 presentation preserves extra bottle through undo and restart',
    () => controllerCase((c, store) async {
      c.current = c.current!
          .grantExtraBottle(); // Explicit engineering reward seed.
      await c.pour(0, 4);
      c.completeMotion(c.motion!.token);
      await c.pour(1, 0);
      c.completeMotion(c.motion!.token);
      await c.undo();
      await c.undo();
      expect(c.current!.extraBottleGranted, isTrue);
      expect(c.current!.board.length, 5);
      expect(c.current!.board.last, isEmpty);
      await c.restart();
      expect(c.current!.extraBottleGranted, isTrue);
      expect(c.current!.history, isEmpty);
      expect(c.current!.moveCount, 0);
      expect(
        (await store.load('ordinary')).instance!.extraBottleGranted,
        isTrue,
      );
    }),
  );
  test(
    'AC-33 new SQLite connection recovers whole move while old presentation is active',
    () => controllerCase((c, store) async {
      await c.pour(0, 2);
      expect(c.motion, isNotNull);
      final restoredStore = await GameStore.open(
        store.db.path,
        factory: databaseFactoryFfi,
      );
      final restored = GameController(restoredStore);
      try {
        await restored.initialize();
        expect(restored.current!.toJson(), c.current!.toJson());
        expect(restored.motion, isNull);
        await restored.undo();
        expect(restored.current!.moveCount, 0);
        expect(restored.current!.board, fixture().initial);
      } finally {
        restored.dispose();
        await restoredStore.close();
      }
    }),
  );
  test(
    'AC-12 completed animation never settles or grants a second time',
    () => controllerCase((c, store) async {
      var receipts = 0;
      store.fault = (stage) {
        if (stage == 'receipt') receipts++;
      };
      for (final m in c.current!.puzzle.referenceMoves) {
        await c.pour(m.from, m.to);
        final token = c.motion!.token;
        if (c.current!.completed) {
          expect(c.page, GamePage.board);
          expect(c.receipt, isNotNull);
          expect((await store.progress()).firstClears, 1);
        }
        c.completeMotion(token);
        c.completeMotion(token);
      }
      expect(c.page, GamePage.completion);
      expect(receipts, 1);
      c.setForeground(false);
      expect((await store.progress()).firstClears, 1);
      expect(receipts, 1);
    }),
  );
  testWidgets('AC-33 moving bottle paints above all stationary bottles', (
    t,
  ) async {
    final before = GameInstance.create(
      id: 'foreground-motion',
      puzzle: fixture(),
    );
    final after = before.pour(0, 2).state;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BoardView(
            state: after,
            selected: null,
            onTap: null,
            motion: PourMotion(
              token: 1,
              from: 0,
              to: 2,
              units: 2,
              before: before.board,
              after: after.board,
              instanceId: after.id,
              revision: after.revision,
              reducedMotion: false,
            ),
          ),
        ),
      ),
    );
    await artReady(t);
    await t.pump(const Duration(milliseconds: 350));
    final game = boardGame(t), probe = PaintOrderProbe(boardGame(t).art!);
    final recorder = ui.PictureRecorder();
    probe.paint(
      Canvas(recorder),
      game.frame,
      const PlayerSettings(),
      press: List.filled(4, 0),
    );
    recorder.endRecording().dispose();
    final painted = probe.order;
    expect(painted.toSet(), {0, 1, 2, 3});
    expect(
      painted.last,
      0,
      reason: 'The moving mouth must not be occluded by a stationary bottle',
    );
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'AC-33 committed move locks board until local animation finishes',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('motion-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store);
      await t.runAsync(c.initialize);
      await t.runAsync(() => c.start(fixture()));
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: c,
              builder: (_, _) => SingleChildScrollView(
                child: BoardPage(
                  controller: c,
                  onRestart: () {},
                  onPause: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await artReady(t);
      await t.tap(find.byKey(const Key('bottle-0')));
      await t.pumpAndSettle();
      await t.pump(const Duration(milliseconds: 160));
      final liftedMouth = boardGame(t).frame.poses[0].mouth;
      expect(
        liftedMouth.dy,
        closeTo(boardGame(t).frame.layout.mouths[0].dy - 8, .01),
      );
      await t.runAsync(() => t.tap(find.byKey(const Key('bottle-2'))));
      await t.pump();
      expect(
        boardGame(t).frame.poses[0].mouth,
        liftedMouth,
        reason: 'The actual legal pour starts at the current raised pose without a jump.',
      );
      await t.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 3));
        while (c.phase == SavePhase.saving &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      expect(c.current!.moveCount, 1);
      expect(c.phase, SavePhase.clean);
      expect(
        c.busy,
        isTrue,
        reason: 'Presentation must keep free board actions locked after SQL commits',
      );
      await c.undo();
      await c.restart();
      await c.pour(1, 0);
      expect(c.current!.moveCount, 1);
      await t.pump();
      await t.pump(const Duration(milliseconds: 450));
      expect(c.busy, isTrue);
      final frame = boardGame(t).frame;
      expect(frame.poses[0].angle.abs(), greaterThan(.5));
      final semantics = t.ensureSemantics();
      for (final index in [0, 2]) {
        expect(
          t
              .getSemantics(find.byKey(Key('bottle-$index')))
              .getSemanticsData()
              .label,
          contains('${frame.counts[index]} of 4'),
        );
      }
      semantics.dispose();
      final visualVolume =
          frame.bands.expand((b) => b).fold(0.0, (sum, b) => sum + b.units) +
          (frame.pour?.inStream ?? 0);
      expect(
        visualVolume,
        closeTo(
          c.current!.board.fold(0, (sum, b) => sum + b.length).toDouble(),
          1e-8,
        ),
      );
      await t.pumpAndSettle();
      expect(c.busy, isFalse);
      expect(
        (await t.runAsync(() => store.load('ordinary')))!.instance!.toJson(),
        c.current!.toJson(),
      );
      final unchanged = c.current!.toJson();
      await t.runAsync(() => c.pour(0, 2)); // Green cannot pour onto orange.
      expect(c.current!.toJson(), unchanged);
      expect(c.rejection, isNotNull);
      expect(c.rejectedBottle, 2);
      expect(c.busy, isFalse);
      await t.pump();
      await t.pump(const Duration(milliseconds: 75));
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    },
  );

  testWidgets(
    'AC-31 reduced motion uses short highlight without stream or displacement',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('motion-reduced-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store);
      await t.runAsync(c.initialize);
      await t.runAsync(() => c.start(fixture()));
      c.settings = const PlayerSettings(reducedMotion: true);
      var paused = false;
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: c,
              builder: (_, _) => SingleChildScrollView(
                child: BoardPage(
                  controller: c,
                  onRestart: () {},
                  onPause: () {
                    paused = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await artReady(t);
      final before = t.getTopLeft(find.byKey(const Key('bottle-0')));
      await t.runAsync(() => c.pour(0, 2));
      expect(c.motion!.duration, const Duration(milliseconds: 180));
      await t.pump();
      await t.pump(const Duration(milliseconds: 90));
      final frame = boardGame(t).frame;
      expect(frame.pour, isNull);
      expect(
        frame.poses.every((pose) => pose.angle == 0 && pose.scale == 1),
        isTrue,
      );
      expect(frame.active?.from, 0);
      expect(frame.poses[0].mouth, frame.layout.mouths[0]);
      expect(t.getTopLeft(find.byKey(const Key('bottle-0'))), before);
      expect(c.busy, isTrue);
      await t.pumpAndSettle();
      expect(c.busy, isFalse);
      expect(c.current!.moveCount, 1);
      await t.runAsync(() => c.pour(1, 0));
      await t.pump();
      await t.pump(const Duration(milliseconds: 45));
      await t.ensureVisible(find.byKey(const Key('pause')));
      await t.tap(find.byKey(const Key('pause')));
      expect(paused, isTrue);
      expect(c.motion, isNull);
      expect(c.current!.moveCount, 2);
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    },
  );
}
