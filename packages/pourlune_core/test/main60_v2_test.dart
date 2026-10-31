// Historical v2/v3 acceptance remains pinned to its released definition.
// Current v4 definitions and hint/upgrade contracts live in main60_v4_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

Puzzle current(int level) => Puzzle.parse(
  File(
    '../../docs/development/evidence/main60-five-color-difficulty/old-main/main-${level.toString().padLeft(3, '0')}.json',
  ).readAsStringSync(),
);
Puzzle previous(int level) => Puzzle.parse(
  File(
    '../../docs/development/evidence/main60-content-redesign/old-main/main-${level.toString().padLeft(3, '0')}.json',
  ).readAsStringSync(),
);

final revisedLevels =
    (jsonDecode(
              File('../../docs/content/design/main60-rebalance-v3.json')
                  .readAsStringSync(),
            )['levels']
            as List)
        .map((e) => e['level'] as int)
        .toSet();

int revisionsSinceV1(int level) => revisedLevels.contains(level) ? 2 : 1;

void main() {
  test(
    'UI-actual consecutive hints finish each representative without cycling',
    () {
      for (final setup in [
        for (final level in [13, 20, 21, 28, 40, 41, 53, 60])
          for (final extra in [false, true]) (level, extra),
      ]) {
        final level = setup.$1;
        final p = current(level);
        var state = GameInstance.create(id: 'continuous-${p.id}', puzzle: p);
        if (setup.$2) state = state.grantExtraBottle();
        final seen = <String>{};
        for (var step = 0; !state.completed && step < 80; step++) {
          expect(
            seen.add(jsonEncode(state.board)),
            isTrue,
            reason: '${p.id} hint cycle at step $step',
          );
          final hint = solveHint(
            p,
            state.board,
            extra: state.extraBottleGranted,
          );
          expect(hint.status, HintStatus.found, reason: '${p.id} step $step');
          final action = state.pour(hint.move!.from, hint.move!.to);
          expect(action.changed, isTrue);
          state = action.state;
        }
        expect(state.completed, isTrue, reason: p.id);
      }
    },
  );

  test('DC04 representative hints handle non-reference legal branches', () {
    final rows = <Map<String, Object?>>[];
    for (final level in [13, 20, 21, 28, 40, 41, 53, 60]) {
      final p = current(level);
      final card = jsonDecode(
        File(
          '../../docs/development/evidence/${revisedLevels.contains(level) ? 'difficulty-direct-bottle' : 'main60-content-redesign'}/levels/${p.id}.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      var reference = GameInstance.create(id: 'reference', puzzle: p);
      final referenceBoards = {jsonEncode(reference.board)};
      for (final move in p.referenceMoves) {
        reference = reference.pour(move.from, move.to).state;
        referenceBoards.add(jsonEncode(reference.board));
      }
      final checked = <String>{};
      for (final raw in card['opening_branches'] as List) {
        final branch = raw as Map;
        if (!branch.containsKey('replay')) continue;
        var state = GameInstance.create(id: 'branch-${p.id}', puzzle: p);
        for (final rawStep in (branch['replay'] as Map)['steps'] as List) {
          final step = rawStep as Map;
          final action = state.pour(
            step['from_index'] as int,
            step['to_index'] as int,
          );
          expect(action.changed, isTrue);
          state = action.state;
          final key = jsonEncode(state.board);
          if (checked.length >= 2 ||
              state.completed ||
              referenceBoards.contains(key) ||
              !checked.add(key)) {
            continue;
          }
          final hint = solveHint(p, state.board);
          rows.add({
            'id': p.id,
            'board': state.board,
            'status': hint.status.name,
            'visited': hint.visited,
            'elapsed_us': hint.elapsed.inMicroseconds,
          });
          expect(
            hint.status,
            HintStatus.found,
            reason: '${p.id} off-reference branch',
          );
          expect(state.pour(hint.move!.from, hint.move!.to).changed, isTrue);
        }
      }
      expect(
        checked.length,
        2,
        reason: '${p.id} needs two actual non-reference states',
      );
    }
    final output = Platform.environment['POURLUNE_MAIN60_BRANCH_HINT_REPORT'];
    if (output != null) {
      File(output).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'default_budget_ms': 2000, 'max_states': 50000, 'scope': 'Actual Dart solveHint on legal off-reference branches; no human play claim', 'measurements': rows})}\n',
      );
    }
  });

  test('DC03 all60 retain colour progression and explicit per-definition version increments', () {
    for (var level = 1; level <= 60; level++) {
      final p = current(level), old = previous(level);
      expect(p.id, old.id);
      expect(p.mainLevel, level);
      if ([1, 12].contains(level)) {
        expect(p.toJson(), old.toJson());
      } else {
        expect(
          p.contentVersion,
          old.contentVersion + revisionsSinceV1(level),
          reason: p.id,
        );
        expect(p.initial.length, level <= 4 ? 4 : (level <= 8 ? 5 : 6));
      }
    }
  });

  test('DC04 old13 and old21 snapshots retain board, undo, extra, restart and hints', () {
    for (final level in [13, 21]) {
      final old = previous(level), replacement = current(level);
      var state = GameInstance.create(id: 'old-$level', puzzle: old);
      final first = old.referenceMoves.first;
      state = state.pour(first.from, first.to).state.grantExtraBottle();
      final saved = jsonEncode(state.toJson());
      expect(
        replacement.contentVersion,
        old.contentVersion + revisionsSinceV1(level),
      );
      expect(replacement.initial, isNot(old.initial));
      final restored = GameInstance.parse(saved);
      expect(restored.puzzle.toJson(), old.toJson());
      expect(restored.toJson(), state.toJson());
      expect(restored.undo().board, [...old.initial, <String>[]]);
      expect(restored.restart().board, [...old.initial, <String>[]]);
      expect(restored.restart().extraBottleGranted, isTrue);
      final hint = solveHint(
        restored.puzzle,
        restored.board,
        extra: restored.extraBottleGranted,
      );
      expect(hint.status, HintStatus.found);
      expect(restored.pour(hint.move!.from, hint.move!.to).changed, isTrue);
    }
  });

  test('DC04 all60 hints at initial, two middle states and near completion', () {
    final rows = <Map<String, Object?>>[];
    for (var level = 1; level <= 60; level++) {
      final p = current(level);
      final positions = {
        0,
        p.referenceMoves.length ~/ 3,
        p.referenceMoves.length * 2 ~/ 3,
        p.referenceMoves.length - 1,
      };
      var state = GameInstance.create(id: 'v2-${p.id}', puzzle: p);
      for (var step = 0; step < p.referenceMoves.length; step++) {
        if (positions.contains(step)) {
          final hint = solveHint(p, state.board);
          rows.add({
            'id': p.id,
            'after_moves': step,
            'status': hint.status.name,
            'visited': hint.visited,
            'elapsed_us': hint.elapsed.inMicroseconds,
          });
          expect(hint.status, HintStatus.found, reason: '${p.id} step$step');
          expect(state.pour(hint.move!.from, hint.move!.to).changed, isTrue);
        }
        final m = p.referenceMoves[step];
        final action = state.pour(m.from, m.to);
        expect(action.changed, isTrue, reason: '${p.id} step$step');
        state = action.state;
      }
      expect(state.completed, isTrue, reason: p.id);
    }
    final output = Platform.environment['POURLUNE_MAIN60_HINT_REPORT'];
    if (output != null) {
      File(output).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'default_budget_ms': 2000, 'max_states': 50000, 'scope': 'Actual core hints and reference replay, not blind human play or UI', 'measurements': rows})}\n',
      );
    }
  });
}
