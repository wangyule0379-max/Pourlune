import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/development/flame_sample/games.dart';
import 'package:pourlune_dev/development/flame_sample/session.dart';
import 'package:pourlune_dev/development/flame_sample_main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'FS-M01 sample labels and semantics retain pre-flow units while the complete move is already saved',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('flame-counts-');
      final session = (await t.runAsync(() async {
        final a = await GameStore.open(
          '${dir.path}/bottles.sqlite',
          factory: databaseFactoryFfi,
        );
        final b = await GameStore.open(
          '${dir.path}/patch.sqlite',
          factory: databaseFactoryFfi,
        );
        final bottles = GameController(a), patch = GameController(b);
        await bottles.initialize();
        await patch.initialize();
        await bottles.start(pourFixture(2), replay: true);
        bottles.settings = const PlayerSettings(
          music: false,
          sound: false,
          haptics: false,
        );
        return FlameSampleSession(bottles, patch);
      }))!;
      final semantics = t.ensureSemantics();
      try {
        await t.pumpWidget(FlameSampleApp(session: session));
        final game = t
            .widget<GameWidget<PourSampleGame>>(
              find.byType(GameWidget<PourSampleGame>),
            )
            .game!;
        for (var i = 0; i < 300 && !game.assetsReady; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pump();
        }
        expect(game.assetsReady, isTrue);
        await t.runAsync(() => session.bottles.pour(0, 2));
        expect(session.bottles.current!.board[0].length, 2);
        expect(session.bottles.current!.board[2].length, 2);
        expect(
          (await t.runAsync(() => session.bottles.store.load('ordinary')))!
              .instance!
              .board[2]
              .length,
          2,
        );
        await t.pump(const Duration(milliseconds: 40));
        expect(game.snapshot()['stage'], 'approach');
        expect(
          find.text('1 · ▲ G · 4/4'),
          findsOneWidget,
          reason: 'labels must follow pre-flow liquid, not the already committed after-board',
        );
        expect(find.text('3 · — Buffer · 0/4'), findsOneWidget);
        expect(
          t
              .getSemantics(find.byKey(const Key('flame-bottle-0')))
              .getSemanticsData()
              .label,
          contains('4 of 4'),
        );
        session.bottles.setForeground(false);
        await t.pump();
        expect(find.text('1 · ▲ G · 2/4'), findsOneWidget);
        expect(find.text('3 · — Buffer · 2/4'), findsOneWidget);
      } finally {
        semantics.dispose();
        await t.pumpWidget(const SizedBox());
        await t.runAsync(session.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
}
