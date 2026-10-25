import 'dart:collection';

import 'puzzle.dart';
import 'pour.dart';

enum HintStatus {
  found,
  provenUnsolvable,
  timeout,
  noMoves,
  alreadyComplete,
  cancelled,
}

class HintResult {
  const HintResult(
    this.status, {
    this.move,
    this.visited = 0,
    this.elapsed = Duration.zero,
  });
  final HintStatus status;
  final PourMove? move;
  final int visited;
  final Duration elapsed;
}

class _Node {
  const _Node(this.board, this.first, this.cost);
  final Board board;
  final PourMove? first;
  final int cost;
}

String _key(Puzzle puzzle, Board board) {
  final targets = <String>[], buffers = <String>[];
  for (var i = 0; i < board.length; i++) {
    final labeled = i < puzzle.targets.length && puzzle.targets[i] != null;
    (labeled ? targets : buffers).add(board[i].join());
  }
  // Buffer positions have no target or receiving restriction; their permutations
  // have the same remaining distance. Target positions always stay distinct.
  buffers.sort();
  return '${targets.join('|')};${buffers.join('|')}';
}

List<(PourMove, Board, int)> _moves(Puzzle p, Board board) {
  final result = <(PourMove, Board, int)>[];
  for (var from = 0; from < board.length; from++) {
    if (board[from].isEmpty) continue;
    for (var to = 0; to < board.length; to++) {
      final next = pourBoard(board, from, to);
      if (next.units == 0) continue;
      final target = to < p.targets.length ? p.targets[to] : null;
      final score =
          (target == board[from].last ? 6 : 0) +
          (board[to].isNotEmpty ? 3 : 0) +
          (next.board[from].isEmpty ? 2 : 0);
      result.add((PourMove(from, to), next.board, score));
    }
  }
  result.sort((a, b) => b.$3.compareTo(a.$3));
  return result;
}

// Every unanchored color group needs at least one pour. One pour can remove
// at most one such group, so this lower bound is admissible and consistent.
int _remainingGroups(Puzzle puzzle, Board board) {
  var groups = 0;
  for (var i = 0; i < board.length; i++) {
    final bottle = board[i];
    for (var j = 0; j < bottle.length; j++) {
      if (j == 0 || bottle[j] != bottle[j - 1]) groups++;
    }
    if (bottle.isNotEmpty &&
        i < puzzle.targets.length &&
        bottle.first == puzzle.targets[i]) {
      groups--;
    }
  }
  return groups;
}

/// A* returns a shortest-path first move, preventing repeated-hint cycles.
/// Fixed targets stay distinct; only unlabeled buffers are symmetric.
/// Only frontier exhaustion proves no solution; budget exhaustion is timeout.
HintResult solveHint(
  Puzzle puzzle,
  Board board, {
  bool extra = false,
  Duration budget = const Duration(seconds: 2),
  int maxStates = 50000,
}) {
  puzzle.validateBoard(board, extra: extra);
  final watch = Stopwatch()..start(), start = freezeBoard(board);
  HintResult result(HintStatus status, int visited, [PourMove? move]) =>
      HintResult(status, move: move, visited: visited, elapsed: watch.elapsed);
  if (puzzle.isWon(start)) return result(HintStatus.alreadyComplete, 0);
  final firstMoves = _moves(puzzle, start);
  if (firstMoves.isEmpty) return result(HintStatus.noMoves, 1);
  final startKey = _key(puzzle, start);
  final seen = <String, int>{startKey: 0};
  final frontier = SplayTreeMap<(int, int), _Node>((a, b) {
    final score = a.$1.compareTo(b.$1);
    return score != 0 ? score : a.$2.compareTo(b.$2);
  });
  final openKeys = <String, (int, int)>{};
  var serial = 0;
  void enqueue(Board next, PourMove? first, int cost, String key) {
    final old = openKeys[key];
    if (old != null) frontier.remove(old);
    final priority = (cost + _remainingGroups(puzzle, next), serial++);
    openKeys[key] = priority;
    frontier[priority] = _Node(next, first, cost);
  }

  enqueue(start, null, 0, startKey);
  while (frontier.isNotEmpty) {
    if (watch.elapsed >= budget || seen.length >= maxStates) {
      return result(HintStatus.timeout, seen.length);
    }
    final priority = frontier.firstKey()!;
    final node = frontier.remove(priority)!;
    openKeys.remove(_key(puzzle, node.board));
    if (puzzle.isWon(node.board)) {
      return result(HintStatus.found, seen.length, node.first);
    }
    for (final candidate in _moves(puzzle, node.board)) {
      final key = _key(puzzle, candidate.$2), cost = node.cost + 1;
      if (cost >= (seen[key] ?? 0x7fffffff)) continue;
      seen[key] = cost;
      if (seen.length >= maxStates) {
        return result(HintStatus.timeout, seen.length);
      }
      enqueue(candidate.$2, node.first ?? candidate.$1, cost, key);
    }
  }
  return result(HintStatus.provenUnsolvable, seen.length);
}
