import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

void main() {
  test('DC01 offline measuring rules match real Dart maximal pours and fixed targets', () {
    final corpus = jsonDecode(
      File(
        '../../docs/development/evidence/main60-content-redesign/rule-corpus.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final row in corpus['cases'] as List) {
      final data = row as Map<String, dynamic>;
      final puzzle = Puzzle.fromJson(data['puzzle'] as Map<String, dynamic>);
      final board = (data['board'] as List)
          .map((b) => (b as List).cast<String>())
          .toList();
      puzzle.validateBoard(board, extra: false);
      expect(
        puzzle.isWon(board),
        data['won'],
        reason: '${data['id']} fixed targets',
      );
      for (final raw in data['operations'] as List) {
        final op = raw as Map<String, dynamic>;
        final result = pourBoard(board, op['from'] as int, op['to'] as int);
        expect(
          result.units,
          op['units'],
          reason: '${data['id']} ${op['from']}->${op['to']}',
        );
        expect(result.board, op['after']);
      }
    }
  });

  test('DC02 review references and alternate branches replay without an extra bottle', () {
    const folder =
        '../../docs/development/evidence/main60-content-redesign/levels';
    for (final level in [13, 20, 21, 28, 40, 41, 53, 60]) {
      final id = 'main-${level.toString().padLeft(3, '0')}';
      final puzzle = Puzzle.parse(
        File('$folder/$id.runtime.json').readAsStringSync(),
      );
      final old = Puzzle.parse(
        File(
          '../../docs/development/evidence/main60-content-redesign/old-main/$id.json',
        ).readAsStringSync(),
      );
      final card = jsonDecode(
        File('$folder/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(puzzle.id, old.id);
      expect(puzzle.contentVersion, old.contentVersion + 1);
      final installed = Puzzle.parse(
        File('../../app/assets/puzzles/main/$id.json').readAsStringSync(),
      );
      final finalCandidate = Puzzle.parse(
        File(
          '../../docs/development/evidence/main60-content-redesign/full60/levels/$id.runtime.json',
        ).readAsStringSync(),
      );
      // Preserve the v2 proof against its frozen definition. Explicit v3
      // replacements have their own current-content and upgrade checks.
      expect(finalCandidate.initial, puzzle.initial);
      expect(finalCandidate.targets, puzzle.targets);
      expect(finalCandidate.contentVersion, puzzle.contentVersion);
      expect(
        finalCandidate.referenceMoves.map((m) => m.toJson()).toList(),
        puzzle.referenceMoves.map((m) => m.toJson()).toList(),
      );
      final baseline = File(
        '../../docs/development/evidence/difficulty-direct-bottle/v2-baseline/$id.json',
      );
      if (baseline.existsSync()) {
        expect(
          Puzzle.parse(baseline.readAsStringSync()).toJson(),
          finalCandidate.toJson(),
        );
        expect(installed.contentVersion, finalCandidate.contentVersion + 1);
      } else {
        expect(installed.toJson(), finalCandidate.toJson());
      }
      final traces = [
        card['reference_replay'],
        for (final branch in card['opening_branches'] as List)
          if ((branch as Map).containsKey('replay')) branch['replay'],
        if (card['capacity_truncation_alternative'] != null)
          (card['capacity_truncation_alternative'] as Map)['replay'],
      ];
      for (final raw in traces) {
        var board = puzzle.initial;
        for (final step in (raw as Map)['steps'] as List) {
          final record = step as Map;
          expect(puzzle.isWon(board), isFalse);
          final moved = pourBoard(
            board,
            record['from_index'] as int,
            record['to_index'] as int,
          );
          expect(
            moved.units,
            record['units'],
            reason: '$id step${record['step']}',
          );
          expect(moved.board.map((b) => b.join()).toList(), record['after']);
          board = moved.board;
          puzzle.validateBoard(board, extra: false);
        }
        expect(
          puzzle.isWon(board),
          isTrue,
          reason: '$id true fixed-label victory',
        );
        expect(board.length, 6);
      }
    }
  });

  test('DC03 v3 challenge mistakes have a real one-bottle recovery route', () {
    final input = jsonDecode(
      File('../../docs/content/design/main60-rebalance-v3.json')
          .readAsStringSync(),
    );
    var rescued = 0;
    for (final row in input['levels'] as List) {
      final rescue = row['extra_rescue'];
      if (rescue == null) continue;
      final level = row['level'] as int;
      final puzzle = Puzzle.parse(
        File(
          '../../app/assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json',
        ).readAsStringSync(),
      );
      var state = GameInstance.create(id: 'rescue-$level', puzzle: puzzle);
      for (final step in rescue['route'] as List) {
        final result = state.pour(
          step['from_index'] as int,
          step['to_index'] as int,
        );
        expect(result.changed, isTrue);
        state = result.state;
      }
      expect(state.completed, isFalse);
      for (var a = 0; a < state.board.length; a++) {
        for (var b = 0; b < state.board.length; b++) {
          expect(state.pour(a, b).changed, isFalse);
        }
      }
      state = state.grantExtraBottle();
      for (final step in rescue['recovery']['moves'] as List) {
        final result = state.pour(
          step['from_index'] as int,
          step['to_index'] as int,
        );
        expect(result.changed, isTrue);
        state = result.state;
      }
      expect(state.completed, isTrue);
      rescued++;
    }
    expect(rescued, greaterThanOrEqualTo(10));
  });
}
