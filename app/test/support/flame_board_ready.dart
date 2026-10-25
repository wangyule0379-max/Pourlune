import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';

/// Image bytes/codec completion is real I/O. Keep fake presentation time still,
/// so callers can verify input during arrival instead of waiting out the effect.
Future<void> waitForFlameArt(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (true) {
    await tester.pump();
    final games = find.byType(GameWidget<FlameBoardGame>).evaluate();
    if (games.length == 1 &&
        (games.single.widget as GameWidget<FlameBoardGame>)
                .game!
                .artStatus
                .value ==
            BoardArtStatus.ready) {
      return;
    }
    if (DateTime.now().isAfter(deadline)) {
      fail('actual bottle art did not load');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}

/// Wait for actual decoded art and the production visual callback. A quiet
/// Flutter frame alone cannot certify that Flame's async loading has completed.
Future<void> settleFlameBoard(
  WidgetTester tester,
  GameController controller,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (true) {
    await tester.pump(const Duration(milliseconds: 16));
    final games = find.byType(GameWidget<FlameBoardGame>).evaluate();
    if (games.length == 1 &&
        (games.single.widget as GameWidget<FlameBoardGame>).game!.art != null &&
        !controller.busy) {
      return;
    }
    if (DateTime.now().isAfter(deadline)) {
      fail('Flame art/action did not reach the actual ready boundary');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}
