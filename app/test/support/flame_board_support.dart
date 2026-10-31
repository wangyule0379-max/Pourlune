import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';

// Hand-checked engineering data for rendering tests only. Never imported by
// application code or used as an ad/first-clear reward confirmation.
GameInstance boardFixture({
  int colors = 4,
  bool extra = false,
  String id = 'full-board',
}) {
  const palette = ['O', 'G', 'P', 'B', 'R'];
  final state = GameInstance.create(
    id: id,
    isReplay: true,
    puzzle: Puzzle.fromJson({
      'schema_version': 1,
      'puzzle_id': 'main-001',
      'content_version': 700 + colors,
      'mode': 'main',
      'content_status': 'reference_fixture',
      'main_level': 1,
      'capacity': 4,
      'initial_bottom_to_top': [
        ['O', 'O', 'G', 'G'],
        ['G', 'G', 'O', 'O'],
        for (var n = 2; n < colors; n++) List.filled(4, palette[n]),
        <String>[],
        <String>[],
      ],
      'target_labels': [...palette.take(colors), null, null],
      'reference_moves': [
        {'from_index': 0, 'to_index': colors},
        {'from_index': 1, 'to_index': 0},
        {'from_index': 1, 'to_index': colors},
        {'from_index': colors, 'to_index': 1},
      ],
      'difficulty_intent': 'rendering-test-only',
      'source_reference': 'test/support/flame_board_support.dart',
    }),
  );
  return extra ? state.grantExtraBottle() : state;
}

({GameInstance after, PourMotion motion}) boardMove(
  GameInstance before,
  int from,
  int to, {
  int token = 1,
}) {
  final result = before.pour(from, to);
  if (!result.changed) throw StateError('Invalid rendering test setup');
  return (
    after: result.state,
    motion: PourMotion(
      token: token,
      from: from,
      to: to,
      units: result.units,
      before: before.board,
      after: result.state.board,
      instanceId: before.id,
      revision: result.state.revision,
      reducedMotion: false,
    ),
  );
}
