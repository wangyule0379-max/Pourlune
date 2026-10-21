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
  const _Node(this.board, this.first);
  final Board board;
  final PourMove? first;
}

String _key(Board board) => board.map((b) => b.join()).join('|');
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
  result.sort((a, b) => a.$3.compareTo(b.$3));
  return result;
}

/// Exact labeled bottle states. Only exhaustive frontier exhaustion proves no solution.
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
  final seen = {_key(start)}, stack = [_Node(start, null)];
  while (stack.isNotEmpty) {
    if (watch.elapsed >= budget || seen.length >= maxStates) {
      return result(HintStatus.timeout, seen.length);
    }
    final node = stack.removeLast();
    for (final candidate in _moves(puzzle, node.board)) {
      final first = node.first ?? candidate.$1;
      if (puzzle.isWon(candidate.$2)) {
        return result(HintStatus.found, seen.length, first);
      }
      if (seen.add(_key(candidate.$2))) {
        if (seen.length >= maxStates) {
          return result(HintStatus.timeout, seen.length);
        }
        stack.add(_Node(candidate.$2, first));
      }
    }
  }
  return result(HintStatus.provenUnsolvable, seen.length);
}
