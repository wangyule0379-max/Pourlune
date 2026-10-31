import 'package:flame/game.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  for (final reduced in [false, true]) {
    for (final units in [1, 4]) {
      for (final cancel in [false, true]) {
        testWidgets(
          'water follows actual flow and stops on ${cancel ? 'background' : 'drain end'} ($units units, reduced=$reduced)',
          (t) async {
            final definition = boardFixture(colors: 2).puzzle.toJson()
              ..['initial_bottom_to_top'] = [
                [...List.filled(4 - units, 'O'), ...List.filled(units, 'G')],
                [...List.filled(4 - units, 'G'), ...List.filled(units, 'O')],
                <String>[],
                <String>[],
              ];
            final before = GameInstance.create(
              id: 'water-$units',
              puzzle: Puzzle.fromJson(definition),
            );
            final moved = boardMove(before, 0, 2);
            final events = <String>[];
            late FlameBoardGame game;
            Widget view({bool moving = false}) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: BoardView(
                  state: moving ? moved.after : before,
                  selected: null,
                  settings: PlayerSettings(reducedMotion: reduced),
                  onTap: (_) {},
                  motion: moving ? moved.motion : null,
                  onFlowStart: () =>
                      events.add('start:${game.frame.pour?.stage}'),
                  onFlowEnd: () => events.add('end'),
                ),
              ),
            );
            await t.pumpWidget(view());
            await waitForFlameArt(t);
            game = t
                .widget<GameWidget<FlameBoardGame>>(
                  find.byType(GameWidget<FlameBoardGame>),
                )
                .game!;
            await t.pumpWidget(view(moving: true));
            game.pauseEngine();
            for (var n = 0; n < (reduced ? 0 : 20); n++) {
              game.update(.01);
            }
            expect(
              events,
              isEmpty,
              reason: 'approach and alignment are silent',
            );
            for (var n = 0; n < 20 && events.isEmpty; n++) {
              game.update(.01);
            }
            final start = reduced ? 'start:null' : 'start:pour';
            expect(events, [start]);
            if (cancel) {
              game.lifecycleStateChange(AppLifecycleState.inactive);
              expect(events, [start, 'end']);
              game.lifecycleStateChange(AppLifecycleState.resumed);
            } else {
              for (var n = 0; n < 300 && events.length == 1; n++) {
                game.update(.01);
              }
              expect(events, [start, 'end']);
              if (!reduced) expect(game.frame.pour?.stage, 'return');
            }
            await t.pumpWidget(const SizedBox());
            expect(events, [
              start,
              'end',
            ], reason: 'cleanup must not duplicate or restart water');
          },
        );
      }
    }
  }
}
