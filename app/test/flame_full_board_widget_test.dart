import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/effects.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';
import 'package:pourlune_dev/presentation/bottle_foot_label.dart';

import 'support/flame_board_support.dart';
import 'support/flame_board_paint.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  Future<void> ready(WidgetTester t) async {
    for (var i = 0; i < 300; i++) {
      final games = find.byType(GameWidget<FlameBoardGame>);
      if (games.evaluate().isNotEmpty &&
          t.widget<GameWidget<FlameBoardGame>>(games).game!.art != null) {
        return;
      }
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await t.pump();
    }
    fail('real bottle assets did not become ready');
  }

  Widget shell(Widget child, {double textScale = 1}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
  testWidgets(
    'formal BoardView uses one Flame canvas with seven native bottle actions and all four color symbols',
    (t) async {
      final state = boardFixture(extra: true);
      final semantics = t.ensureSemantics();
      final tapped = <int>[];
      try {
        await t.pumpWidget(
          shell(BoardView(state: state, selected: null, onTap: tapped.add)),
        );
        await ready(t);
        expect(find.byType(GameWidget<FlameBoardGame>), findsOneWidget);
        for (var i = 0; i < 7; i++) {
          final f = find.byKey(Key('bottle-$i'));
          expect(f, findsOneWidget);
          final node = t.getSemantics(f).getSemanticsData();
          expect(node.label, contains('Bottle ${i + 1}'));
          expect(node.label, contains(i < 4 ? '4 of 4' : '0 of 4'));
        }
        for (var i = 0; i < 4; i++) {
          final target = t.widget<TargetCushion>(
            find.byKey(Key('bottle-target-$i')),
          );
          expect(target.target, state.puzzle.targets[i]);
          expect(target.symbolsEnabled, isTrue);
        }
        final bottle = find.byKey(const Key('bottle-6'));
        await t.ensureVisible(bottle);
        await t.tap(bottle);
        expect(tapped, [6]);
        final node = t.getSemantics(bottle);
        node.owner!.performAction(node.id, ui.SemanticsAction.tap);
        await t.pump();
        expect(tapped, [
          6,
          6,
        ], reason: 'one accessibility activation invokes one native action');
        await t.pumpWidget(
          shell(BoardView(state: state, selected: null, onTap: null)),
        );
        expect(
          t
              .getSemantics(bottle)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
      } finally {
        semantics.dispose();
        await t.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets(
    'failed art disables native and semantic actions and Retry restores real art',
    (t) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final semantics = t.ensureSemantics();
      final tapped = <int>[];
      messenger.setMockMessageHandler('flutter/assets', (_) async => null);
      try {
        await t.pumpWidget(
          shell(
            BoardView(
              state: boardFixture(extra: true),
              selected: null,
              onTap: tapped.add,
            ),
          ),
        );
        for (
          var n = 0;
          n < 100 && find.text('Could not load bottle art.').evaluate().isEmpty;
          n++
        ) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pump();
        }
        expect(find.text('Could not load bottle art.'), findsOneWidget);
        final bottle = find.byKey(const Key('bottle-0'));
        expect(t.widget<OutlinedButton>(bottle).onPressed, isNull);
        expect(
          t
              .getSemantics(bottle)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
        expect(
          find.bySemanticsLabel('Could not load bottle art.'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
        messenger.setMockMessageHandler('flutter/assets', null);
        await t.ensureVisible(find.text('Retry'));
        await t.tap(find.text('Retry'));
        await ready(t);
        await t.ensureVisible(bottle);
        await t.tap(bottle);
        expect(tapped, [0]);
      } finally {
        messenger.setMockMessageHandler('flutter/assets', null);
        await t.pumpWidget(const SizedBox());
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'unmount during byte loading disables actions and disposes late art',
    (t) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final delayed = Completer<ByteData?>();
      final bytes = (await t.runAsync(
        () => rootBundle.load('assets/art/bottles/back.png'),
      ))!;
      messenger.setMockMessageHandler('flutter/assets', (_) => delayed.future);
      try {
        await t.pumpWidget(
          shell(
            BoardView(
              state: boardFixture(),
              selected: null,
              onTap: (_) => fail('not loaded'),
            ),
          ),
        );
        final game = t
            .widget<GameWidget<FlameBoardGame>>(
              find.byType(GameWidget<FlameBoardGame>),
            )
            .game!;
        expect(
          t.widget<OutlinedButton>(find.byKey(const Key('bottle-0'))).onPressed,
          isNull,
        );
        await t.pumpWidget(const SizedBox());
        delayed.complete(bytes);
        messenger.setMockMessageHandler('flutter/assets', null);
        for (var n = 0; n < 100 && !game.closed; n++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pump();
        }
        expect(game.closed, isTrue);
        expect(game.art, isNull);
        expect(t.takeException(), isNull);
      } finally {
        if (!delayed.isCompleted) delayed.complete(bytes);
        messenger.setMockMessageHandler('flutter/assets', null);
      }
    },
  );
  testWidgets(
    'capacity labels stay at the before state through approach and snap together on background',
    (t) async {
      final move = boardMove(boardFixture(extra: true), 0, 6);
      final completed = <int>[];
      await t.pumpWidget(
        shell(
          BoardView(
            state: move.after,
            selected: null,
            onTap: null,
            motion: move.motion,
            onMotionComplete: completed.add,
          ),
        ),
      );
      await ready(t);
      await t.pump(const Duration(milliseconds: 60));
      expect(find.text('4/4').evaluate().length, 4);
      expect(
        t.widget<Text>(find.byKey(const Key('bottle-count-0'))).data,
        '4/4',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('bottle-count-6'))).data,
        '0/4',
      );
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(
        t.widget<Text>(find.byKey(const Key('bottle-count-0'))).data,
        '2/4',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('bottle-count-6'))).data,
        '2/4',
      );
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump(const Duration(seconds: 2));
      expect(completed, [move.motion.token]);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'instance replacement invalidates old effects and readonly preview owns no action callback',
    (t) async {
      final move = boardMove(boardFixture(), 0, 4);
      var completions = 0, taps = 0;
      await t.pumpWidget(
        shell(
          BoardView(
            state: move.after,
            selected: null,
            onTap: (_) => taps++,
            motion: move.motion,
            onMotionComplete: (_) => completions++,
          ),
        ),
      );
      await ready(t);
      final oldGame = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      final art = oldGame.art!;
      await t.pumpWidget(
        shell(
          BoardView(
            state: boardFixture(id: 'replacement'),
            selected: null,
            onTap: null,
            keyPrefix: 'readonly',
          ),
        ),
      );
      await t.pump(const Duration(seconds: 2));
      expect(completions, 0);
      await t.tap(find.byKey(const Key('readonly-0')));
      expect(taps, 0);
      await t.pumpWidget(const SizedBox());
      expect(oldGame.closed, isTrue);
      expect(art.disposed, isTrue);
    },
  );
  testWidgets(
    '320x568 with 2x real font keeps equal seven bottle targets and complete capacity text',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        shell(
          BoardView(
            state: boardFixture(extra: true),
            selected: null,
            onTap: (_) {},
            settings: const PlayerSettings(strongContrast: true),
          ),
          textScale: 2,
        ),
      );
      await ready(t);
      final widths = <double>[];
      for (var i = 0; i < 7; i++) {
        final f = find.byKey(Key('bottle-$i'));
        widths.add(t.getSize(f).width);
        expect(t.getSize(f).width, greaterThanOrEqualTo(48));
        await t.ensureVisible(f);
        await t.pump();
        expect(f.hitTestable(), findsOneWidget);
      }
      expect(widths.toSet(), hasLength(1));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'actual painter draws moving source after every stationary bottle in both cross-row directions',
    (t) async {
      final first = boardMove(boardFixture(extra: true), 0, 6);
      await t.pumpWidget(
        shell(
          BoardView(
            state: first.after,
            selected: null,
            onTap: null,
            motion: first.motion,
          ),
        ),
      );
      await ready(t);
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      final painter = PaintOrderProbe(game.art!);
      for (final move in [
        first,
        boardMove(boardMove(first.after, 1, 0, token: 2).after, 6, 1, token: 3),
      ]) {
        final frame = BoardVisualFrame(
          state: move.after,
          layout: BoardLayout(width: 288, count: 7),
          motion: move.motion,
          elapsedMs: 420,
        );
        final recorder = ui.PictureRecorder();
        painter.order.clear();
        painter.paint(
          Canvas(recorder),
          frame,
          const PlayerSettings(),
          press: List.filled(7, 0),
        );
        recorder.endRecording().dispose();
        expect(painter.order.toSet(), {0, 1, 2, 3, 4, 5, 6});
        expect(
          painter.order.last,
          move.motion.from,
          reason:
              'the real paint command must preserve moving mouth visibility',
        );
      }
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'captured old SequenceEffect completion cannot unlock a newer revision or a disposed board',
    (t) async {
      final old = boardMove(boardFixture(extra: true), 0, 6);
      final next = boardMove(old.after, 1, 0, token: 2);
      final released = <int>[];
      Widget view(({GameInstance after, PourMotion motion}) move) => shell(
        BoardView(
          state: move.after,
          selected: null,
          onTap: null,
          motion: move.motion,
          onMotionComplete: released.add,
        ),
      );
      await t.pumpWidget(view(old));
      await ready(t);
      await t.pump();
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      final oldCompletion = game.children
          .whereType<SequenceEffect>()
          .single
          .onComplete!;
      await t.pumpWidget(view(next));
      await t.pump();
      oldCompletion();
      expect(released, isEmpty);
      expect(game.frame.active?.token, 2);
      expect(game.frame.state.revision, next.after.revision);
      final newCompletion = game.children
          .whereType<SequenceEffect>()
          .where((e) => e.onComplete != null)
          .single
          .onComplete!;
      await t.pumpWidget(const SizedBox());
      oldCompletion();
      newCompletion();
      expect(game.closed, isTrue);
      expect(released, isEmpty);
    },
  );

  testWidgets(
    'system reduction toggles mid-flow snap all counts once and never restart the old stream',
    (t) async {
      final move = boardMove(boardFixture(extra: true), 0, 6);
      final released = <int>[];
      Widget view(bool reduced) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: BoardView(
              state: move.after,
              selected: null,
              onTap: null,
              motion: move.motion,
              onMotionComplete: released.add,
            ),
          ),
        ),
      );
      await t.pumpWidget(view(false));
      await ready(t);
      await t.pump(const Duration(milliseconds: 350));
      await t.pumpWidget(view(true));
      await t.pump();
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      expect(game.frame.active, isNull);
      expect(game.frame.pour, isNull);
      expect(game.frame.counts, [2, 4, 4, 4, 0, 0, 2]);
      expect(released, [move.motion.token]);
      await t.pumpWidget(view(false));
      await t.pump(const Duration(seconds: 2));
      expect(game.frame.active, isNull);
      expect(released, [move.motion.token]);
      await t.pumpWidget(const SizedBox());
    },
  );
}
