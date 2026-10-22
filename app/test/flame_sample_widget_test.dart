import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;

import 'dart:ui' show SemanticsAction, SemanticsActionEvent, Tristate;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/development/flame_sample/games.dart';
import 'package:pourlune_dev/development/flame_sample/session.dart';
import 'package:pourlune_dev/development/flame_sample_main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, finish;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  Future<void> until(WidgetTester t, bool Function() ready) async {
    for (var n = 0; n < 500 && !ready(); n++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(ready(), isTrue);
  }

  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pump();
  }

  Future<void> app(
    WidgetTester t,
    Future<void> Function(FlameSampleSession) check,
  ) async {
    final dir = Directory.systemTemp.createTempSync('flame-widget-');
    final s = (await t.runAsync(() async {
      final a = await GameStore.open(
        '${dir.path}/pour.sqlite',
        factory: databaseFactoryFfi,
      );
      final b = await GameStore.open(
        '${dir.path}/patch.sqlite',
        factory: databaseFactoryFfi,
      );
      final c = GameController(a), p = GameController(b);
      await c.initialize();
      await c.start(pourFixture(2), replay: true);
      for (var n = 1; n <= 3; n++) {
        await b.settle(finish(sample('seed-$n', level: n)), replace: true);
      }
      var state = sample('reward-four', level: 4);
      for (final m in state.puzzle.referenceMoves.take(
        state.puzzle.referenceMoves.length - 1,
      )) {
        state = state.pour(m.from, m.to).state;
      }
      await b.save(state, replace: true);
      await p.initialize();
      c.settings = p.settings = const PlayerSettings(
        music: false,
        sound: false,
        haptics: false,
      );
      return FlameSampleSession(c, p);
    }))!;
    try {
      await t.pumpWidget(FlameSampleApp(session: s));
      await check(s);
    } finally {
      await t.pumpWidget(const SizedBox());
      await t.runAsync(s.close);
      dir.deleteSync(recursive: true);
    }
  }

  testWidgets(
    'Flame hand gestures commit one move; background snaps and exiting frees images',
    (t) => app(t, (s) async {
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      expect(game.ownedImages, 2);
      await tap(t, 'flame-bottle-0');
      await t.pump(const Duration(milliseconds: 150));
      expect(s.bottles.selectedSource, 0);
      await tap(t, 'flame-bottle-1');
      await tap(t, 'flame-bottle-1');
      await until(t, () => s.bottles.phase == SavePhase.clean);
      expect(s.bottles.current!.revision, 1);
      expect(s.bottles.current!.moveCount, 1);
      await t.pump(const Duration(milliseconds: 330));
      expect(s.bottles.motion, isNotNull);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(s.bottles.motion, isNull);
      expect(
        (await t.runAsync(() => s.bottles.store.load('ordinary')))!.instance!
            .toJson(),
        s.bottles.current!.toJson(),
      );
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await until(t, () => game.paused);
      final updates = game.updates;
      await t.pump(const Duration(milliseconds: 400));
      expect(game.updates, updates);
      await tap(t, 'sample-patch');
      await until(
        t,
        () => find.byType(GameWidget<PatchSampleGame>).evaluate().isNotEmpty,
      );
      expect(game.closed, isTrue);
      expect(game.ownedImages, 0);
      expect(s.bottles.progress.firstClears, 0);
    }),
  );
  testWidgets(
    'review: pending patch reveal cannot restart a flight after background cancellation',
    (t) => app(t, (s) async {
      await tap(t, 'sample-patch');
      final game = t
          .widget<GameWidget<PatchSampleGame>>(
            find.byType(GameWidget<PatchSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'sample-complete');
      await until(
        t,
        () => s.patch.phase == SavePhase.clean && s.patch.current!.completed,
      );
      late Completer<void> entered, release;
      late Future<void> held;
      await t.runAsync(() async {
        entered = Completer<void>();
        release = Completer<void>();
        held = s.patch.store.db.transaction((_) async {
          entered.complete();
          await release.future;
        });
        await entered.future;
      });
      try {
        await tap(t, 'sample-place');
        expect(s.patch.phase, SavePhase.saving);
        expect(game.active, isTrue);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await t.pump();
        expect(game.active, isFalse);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pump();
      } finally {
        release.complete();
        await t.runAsync(() => held);
      }
      await until(t, () => s.patch.phase == SavePhase.clean);
      await t.pump(const Duration(milliseconds: 100));
      expect(s.patch.progress.revealedPieces, ['color_studio:1']);
      expect(
        game.active,
        isFalse,
        reason:
            'cancelled save continuation must not restart animation or sound',
      );
      expect(game.snapshot()['progress'], 1);
    }),
  );
  testWidgets(
    'review: reduced idle and failed-reveal pixels retain the unplaced source piece',
    (t) => app(t, (s) async {
      await tap(t, 'sample-patch');
      final game = t
          .widget<GameWidget<PatchSampleGame>>(
            find.byType(GameWidget<PatchSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'sample-complete');
      await until(
        t,
        () => s.patch.phase == SavePhase.clean && s.patch.current!.completed,
      );
      Future<List<int>> pixels() async {
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = picture.toImageSync(
          game.size.x.ceil(),
          game.size.y.ceil(),
        );
        picture.dispose();
        try {
          final bytes = await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          );
          return bytes!.buffer.asUint8List();
        } finally {
          image.dispose();
        }
      }

      final source = await pixels();
      await tap(t, 'sample-setting-reduced_motion');
      await until(
        t,
        () =>
            s.bottles.phase == SavePhase.clean &&
            s.patch.phase == SavePhase.clean,
      );
      expect(game.reduced, isTrue);
      expect(
        listEquals(await pixels(), source),
        isTrue,
        reason: 'unrevealed reduced idle must render the original source, not target',
      );
      s.patch.store.fault = (stage) {
        if (stage == 'reveal') throw StateError('full');
      };
      await tap(t, 'sample-place');
      await until(t, () => s.patch.phase == SavePhase.failed);
      expect(s.patch.progress.revealedPieces, isEmpty);
      expect(
        listEquals(await pixels(), source),
        isTrue,
        reason: 'failed reduced reveal must not draw a placed piece',
      );
      s.patch.store.fault = null;
      await t.runAsync(s.patch.retry);
      await until(t, () => s.patch.phase == SavePhase.clean);
    }),
  );
  testWidgets(
    'review: sample preference remains authoritative while patch storage is busy',
    (t) => app(t, (s) async {
      await tap(t, 'sample-setting-reduced_motion');
      await until(
        t,
        () =>
            s.bottles.phase == SavePhase.clean &&
            s.patch.phase == SavePhase.clean,
      );
      await tap(t, 'sample-patch');
      final game = t
          .widget<GameWidget<PatchSampleGame>>(
            find.byType(GameWidget<PatchSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'sample-complete');
      await until(
        t,
        () => s.patch.phase == SavePhase.clean && s.patch.current!.completed,
      );
      late Completer<void> entered, release;
      late Future<void> held;
      await t.runAsync(() async {
        entered = Completer<void>();
        release = Completer<void>();
        held = s.patch.store.db.transaction((_) async {
          entered.complete();
          await release.future;
        });
        await entered.future;
      });
      try {
        await tap(t, 'sample-place');
        expect(s.patch.phase, SavePhase.saving);
        await tap(t, 'sample-setting-reduced_motion');
        await until(t, () => s.bottles.phase == SavePhase.clean);
        expect(s.bottles.settings.reducedMotion, isFalse);
        expect(
          game.reduced,
          isFalse,
          reason: 'patch must use the visible sample-wide switch while its own store is busy',
        );
      } finally {
        release.complete();
        await t.runAsync(() => held);
      }
      await until(t, () => s.patch.phase == SavePhase.clean);
      game.cancel();
    }),
  );
  testWidgets(
    'review: blank canvas tap cancels selection without a move',
    (t) => app(t, (s) async {
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'flame-bottle-0');
      expect(s.bottles.selectedSource, 0);
      final canvas = find.byType(GameWidget<PourSampleGame>);
      await t.ensureVisible(canvas);
      await t.pump();
      await t.tapAt(t.getTopLeft(canvas) + const Offset(12, 12));
      await t.pump();
      expect(s.bottles.selectedSource, isNull);
      expect(s.bottles.current!.moveCount, 0);
    }),
  );
  testWidgets(
    'failed reveal stays at source; retry then flight cannot duplicate a saved reward',
    (t) => app(t, (s) async {
      await tap(t, 'sample-patch');
      await until(
        t,
        () => find.byType(GameWidget<PatchSampleGame>).evaluate().isNotEmpty,
      );
      final game = t
          .widget<GameWidget<PatchSampleGame>>(
            find.byType(GameWidget<PatchSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'sample-complete');
      await until(
        t,
        () => s.patch.phase == SavePhase.clean && s.patch.current!.completed,
      );
      expect(s.patch.progress.firstClears, 4);
      expect(s.patch.progress.pieces, ['color_studio:1']);
      s.patch.store.fault = (stage) {
        if (stage == 'reveal') throw StateError('full');
      };
      await tap(t, 'sample-place');
      await until(t, () => s.patch.phase == SavePhase.failed);
      await t.pump();
      expect(s.patch.progress.revealedPieces, isEmpty);
      expect(game.active, isFalse);
      expect(
        game.snapshot()['progress'],
        0,
        reason: 'failed placement must remain on the source card',
      );
      s.patch.store.fault = null;
      await tap(t, 'sample-retry');
      await until(t, () => s.patch.phase == SavePhase.clean);
      final receipts = s.patch.progress.receipts;
      await tap(t, 'sample-place');
      await t.pump(const Duration(milliseconds: 400));
      expect(game.active, isTrue);
      expect(s.patch.progress.revealedPieces, ['color_studio:1']);
      await t.pump(const Duration(milliseconds: 500));
      expect(
        game.status.value,
        'attach',
        reason: 'local scene response follows exact placement',
      );
      expect(game.snapshot()['progress'], 1);
      await tap(t, 'sample-place');
      await until(t, () => !game.active);
      expect(s.patch.progress.receipts, receipts);
      expect(s.patch.progress.firstClears, 4);
      final rect = game.targetRect;
      expect(rect.width, greaterThan(50));
      expect(
        rect.height,
        closeTo(rect.width, .001),
        reason: 'square PNG must fit inside its original SceneArt slot without stretching',
      );
      await tap(t, 'sample-bottles');
      await until(t, () => game.closed);
      expect(game.ownedImages, 0);
      await tap(t, 'sample-patch');
      await until(
        t,
        () => find.byType(GameWidget<PatchSampleGame>).evaluate().isNotEmpty,
      );
      final revisit = t
          .widget<GameWidget<PatchSampleGame>>(
            find.byType(GameWidget<PatchSampleGame>),
          )
          .game!;
      await until(t, () => revisit.assetsReady);
      expect(revisit.active, isFalse);
      expect(s.patch.progress.receipts, receipts);
    }),
  );
  testWidgets(
    'invalid action flashes briefly without a move; system reduction cancels an active visual',
    (t) => app(t, (s) async {
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      final before = s.bottles.current!.toJson();
      await tap(t, 'sample-invalid');
      expect(game.snapshot()['invalid_flash'], isTrue);
      expect(s.bottles.current!.toJson(), before);
      await t.pump(const Duration(milliseconds: 300));
      expect(game.snapshot()['invalid_flash'], isFalse);
      await tap(t, 'flame-bottle-0');
      await tap(t, 'flame-bottle-1');
      await until(t, () => s.bottles.phase == SavePhase.clean);
      expect(s.bottles.motion, isNotNull);
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await t.pump();
      await t.pump();
      expect(s.bottles.motion, isNull);
      expect(game.snapshot()['token'], isNull);
      expect(s.bottles.current!.revision, 1);
    }),
  );
  testWidgets(
    'each visible bottle has one actionable semantic node with busy state',
    (t) => app(t, (s) async {
      final handle = t.ensureSemantics();
      try {
        final game = t
            .widget<GameWidget<PourSampleGame>>(
              find.byType(GameWidget<PourSampleGame>),
            )
            .game!;
        await until(t, () => game.assetsReady);
        Finder label(int index) => find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label?.startsWith('Bottle $index.') ?? false),
        );
        final source = t.getSemantics(label(1));
        expect(
          source.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        t.binding.performSemanticsAction(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            nodeId: source.id,
            viewId: t.view.viewId,
          ),
        );
        await t.pump();
        expect(s.bottles.selectedSource, 0);
        final target = t.getSemantics(label(3));
        t.binding.performSemanticsAction(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            nodeId: target.id,
            viewId: t.view.viewId,
          ),
        );
        await t.pump();
        final busy = t.getSemantics(label(1)).getSemanticsData();
        expect(busy.flagsCollection.isEnabled, Tristate.isFalse);
        expect(s.bottles.current!.revision, 1);
        await until(t, () => s.bottles.phase == SavePhase.clean);
        game.abort(release: true);
        await t.pump();
        await t.pump();
        await until(t, () => !s.bottles.busy);
      } finally {
        handle.dispose();
      }
    }),
  );
  testWidgets(
    'background clears selection and transient effects rather than resuming them',
    (t) => app(t, (s) async {
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'flame-bottle-0');
      await t.pump(const Duration(milliseconds: 200));
      expect(s.bottles.selectedSource, 0);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(s.bottles.selectedSource, isNull);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(
        game.paused,
        isTrue,
        reason: 'no selection/effect should resume after foreground',
      );
      expect(s.bottles.current!.revision, 0);
    }),
  );
  testWidgets(
    'narrow 2x text retains real bottle targets, patch actions and reduced setting',
    (t) => app(t, (s) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pump();
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      for (final key in ['flame-bottle-0', 'flame-bottle-1']) {
        await t.ensureVisible(find.byKey(Key(key)));
        expect(
          t.getSize(find.byKey(Key(key))).shortestSide,
          greaterThanOrEqualTo(48),
        );
      }
      await tap(t, 'flame-bottle-0');
      await tap(t, 'flame-bottle-1');
      await until(t, () => !s.bottles.busy);
      expect(s.bottles.current!.revision, 1);
      await tap(t, 'sample-patch');
      await until(
        t,
        () => find.byType(GameWidget<PatchSampleGame>).evaluate().isNotEmpty,
      );
      final patch = t
          .widget<GameWidget<PatchSampleGame>>(
            find.byType(GameWidget<PatchSampleGame>),
          )
          .game!;
      await until(t, () => patch.assetsReady);
      await tap(t, 'sample-complete');
      await until(
        t,
        () => s.patch.phase == SavePhase.clean && s.patch.current!.completed,
      );
      await tap(t, 'sample-place');
      await until(t, () => !patch.active && s.patch.phase == SavePhase.clean);
      expect(s.patch.progress.revealedPieces, ['color_studio:1']);
      await tap(t, 'sample-setting-reduced_motion');
      await until(
        t,
        () =>
            s.bottles.phase == SavePhase.clean &&
            s.patch.phase == SavePhase.clean,
      );
      expect(s.bottles.settings.reducedMotion, isTrue);
      expect(t.takeException(), isNull);
    }),
  );
  testWidgets(
    'explicit reject demo stays illegal even after a four-unit pour',
    (t) => app(t, (s) async {
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      await tap(t, 'sample-units-4');
      await until(t, () => !s.bottles.busy);
      await tap(t, 'flame-bottle-0');
      await tap(t, 'flame-bottle-1');
      await until(t, () => !s.bottles.busy);
      final before = s.bottles.current!.toJson();
      await tap(t, 'sample-invalid');
      await until(t, () => s.bottles.phase == SavePhase.clean);
      expect(s.bottles.current!.toJson(), before);
    }),
  );
  testWidgets(
    'system Back waits for a failed save and Retry before closing the sample',
    (t) => app(t, (s) async {
      final game = t
          .widget<GameWidget<PourSampleGame>>(
            find.byType(GameWidget<PourSampleGame>),
          )
          .game!;
      await until(t, () => game.assetsReady);
      s.bottles.store.fault = (stage) {
        if (stage == 'snapshot') throw StateError('full');
      };
      await tap(t, 'flame-bottle-0');
      await tap(t, 'flame-bottle-1');
      await until(
        t,
        () => s.bottles.phase == SavePhase.failed && !s.bottles.busy,
      );
      var exits = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      });
      try {
        await t.binding.handlePopRoute();
        await t.pump();
        expect(exits, 0);
        expect(find.byKey(const Key('sample-save-failed')), findsOneWidget);
        s.bottles.store.fault = null;
        await tap(t, 'sample-retry');
        await until(t, () => s.bottles.phase == SavePhase.clean && exits == 1);
      } finally {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      }
    }),
  );
}
