import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

void main() {
  final oldRows =
      jsonDecode(
            File('../../docs/content/design/main60-five-color-v4.json')
                .readAsStringSync(),
          )['levels']
          as List;
  Puzzle current(int n) => Puzzle.parse(
    File(
      '../../app/assets/puzzles/main/main-${n.toString().padLeft(3, '0')}.json',
    ).readAsStringSync(),
  );

  test('v5 keeps all fixed identities and old active snapshots with extra', () {
    for (var n = 1; n <= 60; n++) {
      final old = Puzzle.fromJson(
        Map<String, dynamic>.from(oldRows[n - 1]['puzzle'] as Map),
      );
      final latest = current(n);
      if (n <= 20) {
        expect(latest.toJson(), old.toJson());
        continue;
      }
      expect(latest.contentVersion, old.contentVersion + 1);
      expect(latest.initial.length, 7);
      expect(latest.targets, old.targets);
      var active = GameInstance.create(id: 'old-$n', puzzle: old);
      for (final move in old.referenceMoves.take(2)) {
        active = active.pour(move.from, move.to).state;
      }
      active = active.grantExtraBottle();
      final restored = GameInstance.parse(jsonEncode(active.toJson()));
      expect(restored.toJson(), active.toJson());
      expect(restored.undo().undo().board, [...old.initial, <String>[]]);
      expect(restored.restart().puzzle.toJson(), old.toJson());
      expect(restored.restart().board, [...old.initial, <String>[]]);
    }
  });

  test(
    'v5 actual stuck boards are rescued by one extra bottle and a real route',
    () {
      final rows =
          jsonDecode(
                File(
                  '../../docs/development/evidence/optimization-20261028/extra-rescue.json',
                ).readAsStringSync(),
              )['levels']
              as List;
      expect(rows.map((r) => r['level']), [50, 60]);
      for (final row in rows) {
        final p = current(row['level'] as int);
        var state = GameInstance.create(id: 'rescue-${p.id}', puzzle: p);
        for (final m in row['prefix'] as List) {
          final action = state.pour(
            m['from_index'] as int,
            m['to_index'] as int,
          );
          expect(action.changed, isTrue);
          state = action.state;
        }
        expect(state.board.map((b) => b.join()).toList(), row['board']);
        expect(state.completed, isFalse);
        for (var a = 0; a < 7; a++) {
          for (var b = 0; b < 7; b++) {
            expect(pourBoard(state.board, a, b).units, 0);
          }
        }
        state = state.grantExtraBottle();
        expect(solveHint(p, state.board, extra: true).status, HintStatus.found);
        for (final m in row['extra_moves'] as List) {
          final action = state.pour(
            m['from_index'] as int,
            m['to_index'] as int,
          );
          expect(action.changed, isTrue);
          state = action.state;
        }
        expect(state.completed, isTrue);
        expect(state.board.length, 8);
      }
    },
  );
}
