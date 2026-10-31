import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

Map<String, Object?> fiveColorDefinition() => {
  'schema_version': 1,
  'puzzle_id': 'main-021',
  'content_version': 4,
  'mode': 'main',
  'content_status': 'production_candidate',
  'main_level': 21,
  'capacity': 4,
  'initial_bottom_to_top': [
    ['O', 'O', 'R', 'R'],
    ['G', 'G', 'O', 'O'],
    ['P', 'P', 'G', 'G'],
    ['B', 'B', 'P', 'P'],
    ['R', 'R', 'B', 'B'],
    <String>[],
    <String>[],
  ],
  'target_labels': ['O', 'G', 'P', 'B', 'R', null, null],
  'reference_moves': [
    for (final pair in [(0, 5), (1, 0), (2, 1), (3, 2), (4, 3), (5, 4)])
      {'from_index': pair.$1, 'to_index': pair.$2},
  ],
  'difficulty_intent':
      'Independent five-color contract fixture, not a difficulty claim.',
};

void main() {
  test('five fixed targets replay to victory without an extra bottle', () {
    final puzzle = Puzzle.fromJson(fiveColorDefinition());
    var state = GameInstance.create(id: 'five', puzzle: puzzle);
    expect(state.board.length, 7);
    expect(state.completed, isFalse);
    for (final move in puzzle.referenceMoves) {
      final action = state.pour(move.from, move.to);
      expect(action.changed, isTrue);
      state = action.state;
    }
    expect(state.completed, isTrue);
    expect(state.board, [
      ['O', 'O', 'O', 'O'],
      ['G', 'G', 'G', 'G'],
      ['P', 'P', 'P', 'P'],
      ['B', 'B', 'B', 'B'],
      ['R', 'R', 'R', 'R'],
      <String>[],
      <String>[],
    ]);
  });

  test(
    'eighth bottle is once per instance and survives undo restart and parse',
    () {
      final puzzle = Puzzle.fromJson(fiveColorDefinition());
      var state = GameInstance.create(id: 'eight', puzzle: puzzle);
      state = state.pour(0, 5).state.grantExtraBottle();
      expect(state.board.length, 8);
      expect(identical(state.grantExtraBottle(), state), isTrue);
      state = state.pour(5, 7).state;
      expect(state.board[7], ['R', 'R']);
      final restored = GameInstance.parse(jsonEncode(state.toJson()));
      expect(restored.toJson(), state.toJson());
      expect(restored.undo().board[5], ['R', 'R']);
      expect(restored.undo().board[7], isEmpty);
      expect(restored.undo().undo().board, [...puzzle.initial, <String>[]]);
      expect(restored.restart().board, [...puzzle.initial, <String>[]]);
      expect(restored.restart().extraBottleGranted, isTrue);
    },
  );

  test(
    'five-color definitions still reject unknown colors counts and indexes',
    () {
      for (final corrupt in <void Function(Map<String, Object?>)>[
        (m) => (m['initial_bottom_to_top'] as List)[0][0] = 'Y',
        (m) => (m['initial_bottom_to_top'] as List)[0][0] = 'R',
        (m) => (m['target_labels'] as List)[4] = 'O',
        (m) {
          (m['initial_bottom_to_top'] as List).add(<String>[]);
          (m['target_labels'] as List).add(null);
        },
        (m) => (m['reference_moves'] as List)[0]['to_index'] = 7,
      ]) {
        final m = jsonDecode(
          jsonEncode(fiveColorDefinition()),
        ) as Map<String, Object?>;
        corrupt(m);
        expect(() => Puzzle.fromJson(m), throwsFormatException);
      }
    },
  );

  test(
    'nonempty old four-color instance keeps its own definition and extra',
    () {
      final old = Puzzle.parse(
        File(
          '../../docs/development/evidence/main60-five-color-difficulty/old-main/main-028.json',
        ).readAsStringSync(),
      );
      var state = GameInstance.create(id: 'old-four', puzzle: old);
      final move = old.referenceMoves.first;
      state = state.pour(move.from, move.to).state.grantExtraBottle();
      final restored = GameInstance.parse(jsonEncode(state.toJson()));
      expect(restored.toJson(), state.toJson());
      expect(restored.puzzle.initial.length, 6);
      expect(restored.restart().board, [...old.initial, <String>[]]);
      expect(restored.undo().extraBottleGranted, isTrue);
    },
  );
}
