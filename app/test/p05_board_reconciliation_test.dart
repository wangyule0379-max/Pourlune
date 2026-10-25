import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  testWidgets(
    'saved extra bottle never mixes six-frame data with seven controls',
    (t) async {
      var state = boardFixture();
      late StateSetter rebuild;
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SizedBox(
                  width: 351,
                  height: 430,
                  child: BoardView(state: state, selected: null, onTap: (_) {}),
                );
              },
            ),
          ),
        ),
      );
      await waitForFlameArt(t);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('bottle-6')), findsNothing);
      rebuild(() => state = state.grantExtraBottle());
      await t.pump();
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('bottle-6')).hitTestable(), findsOneWidget);
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      expect(game.frame.state.extraBottleGranted, isTrue);
      expect(game.frame.counts.length, 7);
      expect(game.frame.layout.cells.length, 7);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
