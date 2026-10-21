import 'dart:convert';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

import 'core_test.dart' show fixture;

Map<String, Object?> snapshot(GameInstance state) =>
    (jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
List<dynamic> history(Map<String, Object?> data) =>
    data['undo_history']! as List<dynamic>;
const won = <List<String>>[
  ['O', 'O', 'O', 'O'],
  ['G', 'G', 'G', 'G'],
  [],
  [],
];
void main() {
  for (final index in [0, 1]) {
    test('B01-R01 rejects completed undo frame at index $index', () {
      final s = GameInstance.create(
        id: 'won-history',
        puzzle: fixture(),
      ).pour(0, 2).state.pour(1, 0).state;
      final bad = snapshot(s);
      (history(bad)[index] as Map<String, dynamic>)['board'] = won;
      expect(() => GameInstance.fromJson(bad), throwsFormatException);
    });
  }
  for (final extra in [false, true]) {
    test(
      'B01-R01 rejects conserved non-original first frame (extra=$extra)',
      () {
        var s = GameInstance.create(id: 'origin-history', puzzle: fixture());
        if (extra) s = s.grantExtraBottle();
        s = s.pour(0, extra ? 4 : 2).state;
        final bad = snapshot(s);
        (history(bad).first as Map<String, dynamic>)['board'] = s.board;
        expect(() => GameInstance.fromJson(bad), throwsFormatException);
      },
    );
  }
  test('B01-R01 valid history before/after extra, restart and old embedded definition remains compatible', () {
    final old = fixture();
    final newer = Puzzle.fromJson(
      old.toJson()
        ..['content_version'] = 2
        ..['initial_bottom_to_top'] = [
          old.initial[1],
          old.initial[0],
          ...old.initial.skip(2),
        ],
    );
    expect(newer.contentVersion, 2);
    expect(newer.initial, isNot(old.initial));
    for (final timing in ['none', 'before', 'between']) {
      var s = GameInstance.create(id: 'compatible-$timing', puzzle: old);
      if (timing == 'before') s = s.grantExtraBottle();
      s = s.pour(0, 2).state;
      if (timing == 'between') s = s.grantExtraBottle();
      s = s.pour(1, 0).state;
      var loaded = GameInstance.parse(jsonEncode(s.toJson()));
      expect(loaded.toJson(), s.toJson());
      loaded = loaded.undo().undo();
      final initial = [...old.initial, if (timing != 'none') <String>[]];
      expect(loaded.board, initial);
      expect(loaded.completed, isFalse);
      final restarted = s.restart();
      expect(restarted.history, isEmpty);
      final afterRestart = restarted.pour(0, 2).state;
      final restored = GameInstance.parse(jsonEncode(afterRestart.toJson()));
      expect(restored.puzzle.contentVersion, 1);
      expect(restored.puzzle.initial, old.initial);
      expect(restored.history.single.board, initial);
      expect(restored.undo().board, initial);
      expect(restored.id, s.id);
    }
  });
}
