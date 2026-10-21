import 'puzzle.dart';

class BoardPour {
  const BoardPour(this.board, this.units, this.rejection);
  final Board board;
  final int units;
  final String? rejection;
}

BoardPour pourBoard(Board board, int from, int to) {
  String? reason;
  if (from < 0 ||
      to < 0 ||
      from >= board.length ||
      to >= board.length ||
      from == to) {
    reason = 'Choose another bottle';
  } else if (board[from].isEmpty) {
    reason = 'Choose a bottle with liquid';
  } else if (board[to].length == 4) {
    reason = 'That bottle is full';
  } else if (board[to].isNotEmpty && board[to].last != board[from].last) {
    reason = 'Empty or matching top color only';
  }
  if (reason != null) return BoardPour(board, 0, reason);
  final color = board[from].last;
  var group = 0;
  for (final c in board[from].reversed) {
    if (c != color) break;
    group++;
  }
  final room = 4 - board[to].length, units = group < room ? group : room;
  final next = board.map((b) => b.toList()).toList();
  next[from].removeRange(next[from].length - units, next[from].length);
  next[to].addAll(List.filled(units, color));
  return BoardPour(freezeBoard(next), units, null);
}
