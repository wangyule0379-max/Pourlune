import 'dart:convert';

const colors = {'O', 'G', 'P', 'B', 'R'};
typedef Board = List<List<String>>;
Board freezeBoard(Iterable<Iterable<String>> board) =>
    List.unmodifiable(board.map((b) => List<String>.unmodifiable(b)));
Never invalid(String message) => throw FormatException(message);
Map<String, Object?> object(Object? value) =>
    value is Map<String, Object?> ? value : invalid('Expected object');
int integer(Object? value, [int min = 0]) =>
    value is int && value >= min ? value : invalid('Expected integer >= $min');
String text(Object? value) => value is String && value.isNotEmpty
    ? value
    : invalid('Expected nonempty text');
void keys(
  Map<String, Object?> m,
  Set<String> required, [
  Set<String> optional = const {},
]) {
  if (!m.keys.toSet().containsAll(required) ||
      m.keys.any((k) => !required.contains(k) && !optional.contains(k))) {
    invalid('Unexpected or missing fields');
  }
}

/// JSON parser retaining lexical integer and duplicate-key constraints lost by jsonDecode.
Object? strictJson(String source) => _Json(source).decode();

class _Json {
  _Json(this.s);
  final String s;
  int i = 0;
  void ws() {
    while (i < s.length && ' \r\n\t'.contains(s[i])) {
      i++;
    }
  }

  Object? decode() {
    final v = value();
    ws();
    if (i != s.length) invalid('Trailing JSON');
    return v;
  }

  Object? value() {
    ws();
    if (i == s.length) invalid('Unexpected end');
    final ch = s[i];
    if (ch == '"') return string();
    if (ch == '{') {
      i++;
      ws();
      final m = <String, Object?>{};
      if (take('}')) return m;
      while (true) {
        ws();
        if (i >= s.length || s[i] != '"') invalid('Expected key');
        final k = string();
        if (m.containsKey(k)) invalid('Duplicate key: $k');
        ws();
        if (!take(':')) invalid('Expected colon');
        m[k] = value();
        ws();
        if (take('}')) return m;
        if (!take(',')) invalid('Expected comma');
      }
    }
    if (ch == '[') {
      i++;
      ws();
      final a = <Object?>[];
      if (take(']')) return a;
      while (true) {
        a.add(value());
        ws();
        if (take(']')) return a;
        if (!take(',')) invalid('Expected comma');
      }
    }
    for (final entry in const {
      'true': true,
      'false': false,
      'null': null,
    }.entries) {
      if (s.startsWith(entry.key, i)) {
        i += entry.key.length;
        return entry.value;
      }
    }
    final match = RegExp(r'-?(0|[1-9][0-9]*)').matchAsPrefix(s, i);
    if (match == null) invalid('Expected JSON value');
    i = match.end;
    if (i < s.length && !']}, \r\n\t'.contains(s[i])) {
      invalid('Only integer JSON tokens allowed');
    }
    final n = int.tryParse(match[0]!);
    if (n == null) invalid('Integer out of range');
    return n;
  }

  bool take(String c) {
    if (i < s.length && s[i] == c) {
      i++;
      return true;
    }
    return false;
  }

  String string() {
    final start = i++;
    while (i < s.length) {
      final c = s[i++];
      if (c == '\\') {
        if (i >= s.length) invalid('Invalid escape');
        i++;
      } else if (c == '"') {
        final v = jsonDecode(s.substring(start, i));
        return v as String;
      }
    }
    return invalid('Unterminated string');
  }
}

class PourMove {
  const PourMove(this.from, this.to);
  final int from, to;
  Map<String, Object?> toJson() => {'from_index': from, 'to_index': to};
}

class Puzzle {
  Puzzle._(
    this.id,
    this.contentVersion,
    this.mode,
    this.contentStatus,
    this.mainLevel,
    this.initial,
    this.targets,
    this.referenceMoves,
    this.difficultyIntent,
    this.sourceReference,
  );
  final String id, mode, contentStatus, difficultyIntent;
  final String? sourceReference;
  final int contentVersion;
  final int? mainLevel;
  final Board initial;
  final List<String?> targets;
  final List<PourMove> referenceMoves;
  factory Puzzle.parse(String source) =>
      Puzzle.fromJson(object(strictJson(source)));
  factory Puzzle.fromJson(Map<String, Object?> m) {
    keys(
      m,
      {
        'schema_version',
        'puzzle_id',
        'content_version',
        'mode',
        'content_status',
        'main_level',
        'capacity',
        'initial_bottom_to_top',
        'target_labels',
        'reference_moves',
        'difficulty_intent',
      },
      {'source_reference'},
    );
    if (integer(m['schema_version']) != 1 || integer(m['capacity']) != 4) {
      invalid('Unsupported version or capacity');
    }
    final id = text(m['puzzle_id']),
        version = integer(m['content_version'], 1),
        mode = text(m['mode']),
        status = text(m['content_status']);
    if (!{'main', 'daily'}.contains(mode) ||
        !{'reference_fixture', 'production_candidate'}.contains(status)) {
      invalid('Unknown mode/status');
    }
    final level = m['main_level'] == null ? null : integer(m['main_level'], 1);
    if (mode == 'main'
        ? (level == null ||
              level > 60 ||
              id != 'main-${level.toString().padLeft(3, '0')}')
        : (level != null || !RegExp(r'^daily-[a-z0-9-]+$').hasMatch(id))) {
      invalid('ID/level/mode mismatch');
    }
    final raw = m['initial_bottom_to_top'];
    if (raw is! List) invalid('Expected board');
    final board = readBoard(raw);
    final rawTargets = m['target_labels'];
    if (rawTargets is! List || rawTargets.length != board.length) {
      invalid('Invalid targets');
    }
    final targets = <String?>[
      for (final t in rawTargets)
        if (t == null)
          null
        else if (t is String && colors.contains(t))
          t
        else
          invalid('Unknown target'),
    ];
    final present = board.expand((b) => b).toSet();
    if (present.length < 2 ||
        present.length > 5 ||
        board.length != present.length + 2) {
      invalid('Invalid color/bottle count');
    }
    if (board.where((b) => b.isEmpty).length != 2 ||
        targets.where((t) => t == null).length != 2) {
      invalid('Require two empty buffers');
    }
    for (var i = 0; i < targets.length; i++) {
      if ((targets[i] == null) != board[i].isEmpty) {
        invalid('Initial buffers must be empty');
      }
    }
    for (final c in present) {
      if (board.expand((b) => b).where((x) => x == c).length != 4 ||
          targets.where((t) => t == c).length != 1) {
        invalid('Color/target quantity mismatch');
      }
    }
    if (targets.whereType<String>().any((c) => !present.contains(c))) {
      invalid('Unknown target color');
    }
    final rawMoves = m['reference_moves'];
    if (rawMoves is! List || rawMoves.isEmpty) {
      invalid('Expected reference moves');
    }
    final moves = <PourMove>[];
    for (final v in rawMoves) {
      final move = object(v);
      keys(move, {'from_index', 'to_index'});
      final from = integer(move['from_index']), to = integer(move['to_index']);
      if (from >= board.length || to >= board.length || from == to) {
        invalid('Move index out of range');
      }
      moves.add(PourMove(from, to));
    }
    return Puzzle._(
      id,
      version,
      mode,
      status,
      level,
      board,
      List.unmodifiable(targets),
      List.unmodifiable(moves),
      text(m['difficulty_intent']),
      m.containsKey('source_reference') ? text(m['source_reference']) : null,
    );
  }
  bool isWon(Board board) {
    if (board.length < targets.length) return false;
    for (var i = 0; i < board.length; i++) {
      final t = i < targets.length ? targets[i] : null;
      if (t == null) {
        if (board[i].isNotEmpty) return false;
      } else if (board[i].length != 4 || board[i].any((c) => c != t)) {
        return false;
      }
    }
    return true;
  }

  void validateBoard(Board board, {required bool extra}) {
    if (board.length != initial.length + (extra ? 1 : 0) ||
        board.any((b) => b.length > 4)) {
      invalid('Snapshot capacity/count');
    }
    final expected = initial.expand((b) => b).toList(),
        actual = board.expand((b) => b).toList();
    if (actual.length != expected.length ||
        actual.any((c) => !colors.contains(c))) {
      invalid('Snapshot colors');
    }
    for (final c in colors) {
      if (actual.where((x) => x == c).length !=
          expected.where((x) => x == c).length) {
        invalid('Snapshot conservation');
      }
    }
  }

  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'puzzle_id': id,
    'content_version': contentVersion,
    'mode': mode,
    'content_status': contentStatus,
    'main_level': mainLevel,
    'capacity': 4,
    'initial_bottom_to_top': initial,
    'target_labels': targets,
    'reference_moves': referenceMoves.map((m) => m.toJson()).toList(),
    'difficulty_intent': difficultyIntent,
    if (sourceReference != null) 'source_reference': sourceReference,
  };
}

Board readBoard(Object? value) {
  if (value is! List) invalid('Expected board array');
  return freezeBoard(
    value.map((b) {
      if (b is! List || b.length > 4) invalid('Invalid bottle');
      return b.map(
        (c) =>
            c is String && colors.contains(c) ? c : invalid('Invalid liquid'),
      );
    }),
  );
}
