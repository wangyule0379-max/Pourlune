import 'dart:convert';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

import 'core_test.dart' show fixture;

void main() {
  test(
    'Every hint reduces exact BFS distance, including interchangeable buffers',
    () {
      final p = fixture();
      for (final extra in [false, true]) {
        String key(Board board) => jsonEncode(board);
        final initial = freezeBoard([...p.initial, if (extra) <String>[]]);
        final boards = <String, Board>{key(initial): initial};
        final reverse = <String, Set<String>>{};
        final queue = <Board>[initial];
        for (var head = 0; head < queue.length; head++) {
          final board = queue[head], source = key(board);
          for (var from = 0; from < board.length; from++) {
            for (var to = 0; to < board.length; to++) {
              final next = pourBoard(board, from, to);
              if (next.units == 0) continue;
              final target = key(next.board);
              reverse.putIfAbsent(target, () => <String>{}).add(source);
              if (!boards.containsKey(target)) {
                boards[target] = next.board;
                queue.add(next.board);
              }
            }
          }
        }
        expect(boards.length, extra ? 135 : 53);
        final distance = <String, int>{
          for (final entry in boards.entries)
            if (p.isWon(entry.value)) entry.key: 0,
        };
        final pending = distance.keys.toList();
        for (var head = 0; head < pending.length; head++) {
          final solved = pending[head];
          for (final previous in reverse[solved] ?? <String>{}) {
            if (distance.containsKey(previous)) continue;
            distance[previous] = distance[solved]! + 1;
            pending.add(previous);
          }
        }
        expect(distance.length, boards.length);
        for (final entry in boards.entries) {
          if (p.isWon(entry.value)) continue;
          final hint = solveHint(p, entry.value, extra: extra);
          expect(hint.status, HintStatus.found);
          final next = pourBoard(entry.value, hint.move!.from, hint.move!.to);
          expect(
            distance[key(next.board)],
            distance[entry.key]! - 1,
            reason: entry.key,
          );
        }
      }
    },
  );

  test('B02-03 current-state one-step solve with/without extra, never initial reference', () {
    final p = fixture();
    for (final extra in [false, true]) {
      final board = <List<String>>[
        [],
        ['G', 'G', 'G', 'G'],
        ['O', 'O', 'O', 'O'],
        [],
        if (extra) [],
      ];
      final r = solveHint(p, board, extra: extra);
      expect(r.status, HintStatus.found);
      expect(r.move!.from, 2);
      expect(r.move!.to, 0);
      final poured = pourBoard(board, r.move!.from, r.move!.to);
      expect(poured.units, 4);
      expect(p.isWon(poured.board), isTrue);
    }
  });
  test(
    'B02-03 fixed target positions are not interchangeable solved states',
    () {
      final p = fixture();
      final r = solveHint(p, [
        ['G', 'G', 'G', 'G'],
        ['O', 'O', 'O', 'O'],
        [],
        [],
      ]);
      expect(r.status, HintStatus.found);
      expect(r.move, isNotNull);
    },
  );
  test('B02-03 no moves, exact 12-state unsatisfiable graph and budget exhaustion differ', () {
    final p = fixture('012');
    final dead = <List<String>>[
      ['O', 'O', 'O', 'P'],
      ['G', 'G', 'G', 'P'],
      ['B', 'B', 'P', 'P'],
      ['O'],
      ['G'],
      ['B', 'B'],
    ];
    expect(solveHint(p, dead).status, HintStatus.noMoves);
    // Independent Python exhaustive graph records 12 exact labeled states, none winning.
    final impossible = <List<String>>[
      ['P', 'B', 'B', 'G'],
      ['G', 'O', 'O', 'O'],
      ['P', 'B', 'B', 'P'],
      ['G', 'O'],
      ['P'],
      ['G'],
    ];
    final proven = solveHint(p, impossible, maxStates: 1000);
    expect(proven.status, HintStatus.provenUnsolvable);
    expect(proven.visited, 12);
    expect(solveHint(p, impossible, maxStates: 1).status, HintStatus.timeout);
    expect(
      solveHint(p, p.initial, budget: Duration.zero).status,
      HintStatus.timeout,
    );
  });
}
