import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

const evidence = '../../docs/development/evidence/main60-five-color-difficulty';
Puzzle current(int level) => Puzzle.parse(
  File(
    '../../app/assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json',
  ).readAsStringSync(),
);

void main() {
  test('v4 all60 references, versions and owned extra remain valid', () {
    for (var n = 1; n <= 60; n++) {
      final p = current(n);
      final old = Puzzle.parse(
        File('$evidence/old-main/${p.id}.json').readAsStringSync(),
      );
      expect(
        p.initial.length,
        n <= 4
            ? 4
            : n <= 8
            ? 5
            : n <= 20
            ? 6
            : 7,
      );
      expect(p.contentVersion, old.contentVersion + (n >= 21 ? 1 : 0));
      var state = GameInstance.create(id: 'v4-${p.id}', puzzle: p);
      final first = p.referenceMoves.first;
      final active = state.pour(first.from, first.to).state.grantExtraBottle();
      final restored = GameInstance.parse(jsonEncode(active.toJson()));
      expect(restored.undo().board, [...p.initial, <String>[]]);
      expect(restored.restart().board, [...p.initial, <String>[]]);
      expect(restored.grantExtraBottle().toJson(), restored.toJson());
      for (final m in p.referenceMoves) {
        final action = state.pour(m.from, m.to);
        expect(action.changed, isTrue, reason: '${p.id} illegal reference');
        state = action.state;
      }
      expect(state.completed, isTrue, reason: p.id);
      expect(state.extraBottleGranted, isFalse);
      var previous = GameInstance.create(id: 'old-${p.id}', puzzle: old);
      previous = previous
          .pour(old.referenceMoves.first.from, old.referenceMoves.first.to)
          .state
          .grantExtraBottle();
      final snapshot = GameInstance.parse(jsonEncode(previous.toJson()));
      expect(snapshot.puzzle.toJson(), old.toJson());
      expect(snapshot.restart().board, [...old.initial, <String>[]]);
    }
  });
  test('v4 default hints on all60 openings, key middles and alternate choices', () {
    final measurements = <Map<String, Object?>>[];
    void measure(Puzzle p, Board board, String position) {
      final hint = solveHint(p, board);
      measurements.add({
        'id': p.id,
        'position': position,
        'status': hint.status.name,
        'visited': hint.visited,
        'elapsed_us': hint.elapsed.inMicroseconds,
        'board': board,
      });
      if (hint.move != null) {
        expect(
          pourBoard(board, hint.move!.from, hint.move!.to).units,
          greaterThan(0),
        );
      }
    }

    for (var n = 1; n <= 60; n++) {
      final p = current(n);
      measure(p, p.initial, 'opening');
      var state = GameInstance.create(id: 'hint-${p.id}', puzzle: p);
      for (final m in p.referenceMoves.take(p.referenceMoves.length ~/ 2)) {
        state = state.pour(m.from, m.to).state;
      }
      measure(p, state.board, 'reference_middle');
      if (n >= 21) {
        final card = jsonDecode(
          File('$evidence/levels/${p.id}.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final point = card['planning_point'] as Map;
        final board = (point['board'] as List)
            .map((b) => (b as String).split(''))
            .toList();
        for (final (i, raw) in (point['branches'] as List).indexed) {
          final first = (raw as Map)['first_move'] as Map;
          final after = pourBoard(
            board,
            first['from_index'] as int,
            first['to_index'] as int,
          ).board;
          measure(p, after, 'decision_branch_$i');
        }
      }
    }
    final output = Platform.environment['POURLUNE_MAIN60_V4_HINT_REPORT'];
    if (output != null) {
      File(output).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'budget_ms': 2000, 'max_states': 50000, 'scope': 'Actual Dart solveHint; no reference substitution or human/UI claim', 'measurements': measurements})}\n',
      );
    }
    final failures = measurements
        .where((r) => r['status'] != 'found')
        .map(
          (r) =>
              '${r['id']} ${r['position']}: ${r['status']} (${r['visited']})',
        )
        .toList();
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 8)));
}
