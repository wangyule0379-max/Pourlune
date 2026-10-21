import 'puzzle.dart';
import 'pour.dart';
import 'tutorial.dart';

bool _sameBoard(Board a, Board b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].length != b[i].length) return false;
    for (var j = 0; j < a[i].length; j++) {
      if (a[i][j] != b[i][j]) return false;
    }
  }
  return true;
}

class UndoFrame {
  UndoFrame(Board board, this.moveCount) : board = freezeBoard(board);
  final Board board;
  final int moveCount;
  Map<String, Object?> toJson() => {'board': board, 'move_count': moveCount};
}

class PourResult {
  const PourResult(this.state, this.units, this.rejection);
  final GameInstance state;
  final int units;
  final String? rejection;
  bool get changed => units > 0;
}

class GameInstance {
  GameInstance._({
    required this.id,
    required this.puzzle,
    required this.slot,
    required this.isReplay,
    required Board board,
    required this.moveCount,
    required this.revision,
    required List<UndoFrame> history,
    required this.extraBottleGranted,
    required this.completed,
    this.puzzleDate,
    this.timeZone,
    this.offsetMinutes,
    this.catalogVersion,
    this.tutorial,
  }) : board = freezeBoard(board),
       history = List.unmodifiable(history);
  final String id, slot;
  final Puzzle puzzle;
  final bool isReplay, extraBottleGranted, completed;
  final Board board;
  final int moveCount, revision;
  final List<UndoFrame> history;
  final String? puzzleDate, timeZone;
  final int? offsetMinutes, catalogVersion;
  final Tutorial? tutorial;
  int get tutorialLength =>
      puzzle.referenceMoves.length < 3 ? puzzle.referenceMoves.length : 3;
  factory GameInstance.create({
    required String id,
    required Puzzle puzzle,
    String slot = 'ordinary',
    bool isReplay = false,
    String? puzzleDate,
    String? timeZone,
    int? offsetMinutes,
    int? catalogVersion,
    bool tutorial = false,
  }) => GameInstance.fromJson({
    'instance_schema_version': 2,
    'instance_id': id,
    'puzzle': puzzle.toJson(),
    'slot': slot,
    'is_replay': isReplay,
    'board': puzzle.initial,
    'move_count': 0,
    'board_revision': 0,
    'undo_history': <Object?>[],
    'extra_bottle_granted': false,
    'completed': puzzle.isWon(puzzle.initial),
    'puzzle_date': puzzleDate,
    'time_zone': timeZone,
    'offset_minutes': offsetMinutes,
    'catalog_version': catalogVersion,
    'tutorial': tutorial ? const Tutorial.start().toJson() : null,
  });
  factory GameInstance.parse(String source) =>
      GameInstance.fromJson(object(strictJson(source)));
  factory GameInstance.fromJson(Map<String, Object?> m) {
    keys(
      m,
      {
        'instance_schema_version',
        'instance_id',
        'puzzle',
        'slot',
        'is_replay',
        'board',
        'move_count',
        'board_revision',
        'undo_history',
        'extra_bottle_granted',
        'completed',
        'puzzle_date',
        'time_zone',
        'offset_minutes',
        'catalog_version',
      },
      {'tutorial'},
    );
    final schema = integer(m['instance_schema_version']);
    if (!{1, 2}.contains(schema) ||
        (schema == 2 && !m.containsKey('tutorial')) ||
        (schema == 1 && m.containsKey('tutorial'))) {
      invalid('Unknown instance schema');
    }
    final id = text(m['instance_id']),
        puzzle = Puzzle.fromJson(object(m['puzzle'])),
        slot = text(m['slot']);
    if (!{'ordinary', 'daily'}.contains(slot) ||
        (slot == 'daily') != (puzzle.mode == 'daily')) {
      invalid('Slot/mode mismatch');
    }
    for (final k in ['is_replay', 'extra_bottle_granted', 'completed']) {
      if (m[k] is! bool) invalid('Expected boolean');
    }
    final extra = m['extra_bottle_granted'] as bool,
        completed = m['completed'] as bool;
    final board = readBoard(m['board']);
    puzzle.validateBoard(board, extra: extra);
    if (completed != puzzle.isWon(board)) invalid('Completion flag mismatch');
    final moves = integer(m['move_count']),
        revision = integer(m['board_revision']);
    if (revision < moves) invalid('Revision precedes moves');
    final raw = m['undo_history'];
    if (raw is! List || raw.length != moves) invalid('Invalid undo history');
    final history = <UndoFrame>[];
    for (var i = 0; i < raw.length; i++) {
      final v = object(raw[i]);
      keys(v, {'board', 'move_count'});
      final b = readBoard(v['board']);
      if (b.length != puzzle.initial.length &&
          (!extra || b.length != puzzle.initial.length + 1)) {
        invalid('History bottle count');
      }
      puzzle.validateBoard(b, extra: b.length > puzzle.initial.length);
      if (integer(v['move_count']) != i) invalid('History move count');
      // Victory locks the instance, so a won board can never precede a move.
      if (puzzle.isWon(b)) invalid('Completed board in undo history');
      if (i == 0) {
        for (var bottle = 0; bottle < b.length; bottle++) {
          final initial = bottle < puzzle.initial.length
              ? puzzle.initial[bottle]
              : const <String>[];
          if (b[bottle].length != initial.length ||
              b[bottle].indexed.any((unit) => unit.$2 != initial[unit.$1])) {
            invalid('Undo history must start at original board');
          }
        }
      }
      history.add(UndoFrame(b, i));
    }
    final lesson = m['tutorial'] == null
        ? null
        : Tutorial.fromJson(
            m['tutorial'],
            puzzle.referenceMoves.length < 3 ? puzzle.referenceMoves.length : 3,
          );
    if (lesson != null &&
        (slot != 'ordinary' ||
            puzzle.mainLevel != 1 ||
            m['is_replay'] == true ||
            (lesson.active && lesson.step != moves))) {
      invalid('Tutorial instance mismatch');
    }
    if (lesson?.active ?? false) {
      Board prefix = freezeBoard([...puzzle.initial, if (extra) <String>[]]);
      for (var step = 0; step < lesson!.step; step++) {
        final frame = history[step].board;
        final normalized = frame.length < prefix.length
            ? freezeBoard([...frame, <String>[]])
            : frame;
        if (!_sameBoard(normalized, prefix)) {
          invalid('Tutorial history does not match guided step');
        }
        final move = puzzle.referenceMoves[step],
            next = pourBoard(prefix, move.from, move.to);
        if (next.units == 0) invalid('Invalid tutorial instruction');
        prefix = next.board;
      }
      if (!_sameBoard(board, prefix)) {
        invalid('Tutorial board does not match guided step');
      }
    }
    String? date, zone;
    int? offset, catalog;
    if (slot == 'daily') {
      date = text(m['puzzle_date']);
      final parsed = DateTime.tryParse(date);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          parsed == null ||
          parsed.toIso8601String().substring(0, 10) != date) {
        invalid('Invalid puzzle date');
      }
      zone = text(m['time_zone']);
      if (m['offset_minutes'] is! int ||
          (m['offset_minutes'] as int).abs() > 840) {
        invalid('Invalid time zone offset');
      }
      offset = m['offset_minutes'] as int;
      catalog = integer(m['catalog_version'], 1);
    } else if ([
      'puzzle_date',
      'time_zone',
      'offset_minutes',
      'catalog_version',
    ].any((k) => m[k] != null)) {
      invalid('Unexpected daily identity');
    }
    return GameInstance._(
      id: id,
      puzzle: puzzle,
      slot: slot,
      isReplay: m['is_replay'] as bool,
      board: board,
      moveCount: moves,
      revision: revision,
      history: history,
      extraBottleGranted: extra,
      completed: completed,
      puzzleDate: date,
      timeZone: zone,
      offsetMinutes: offset,
      catalogVersion: catalog,
      tutorial: lesson,
    );
  }
  GameInstance _next(
    Board b,
    int moves,
    List<UndoFrame> undo, {
    bool? extra,
    Tutorial? lesson,
  }) => GameInstance._(
    id: id,
    puzzle: puzzle,
    slot: slot,
    isReplay: isReplay,
    board: b,
    moveCount: moves,
    revision: revision + 1,
    history: undo,
    extraBottleGranted: extra ?? extraBottleGranted,
    completed: puzzle.isWon(b),
    puzzleDate: puzzleDate,
    timeZone: timeZone,
    offsetMinutes: offsetMinutes,
    catalogVersion: catalogVersion,
    tutorial: lesson ?? tutorial,
  );
  PourResult pour(int from, int to) {
    if (completed) return PourResult(this, 0, 'Puzzle complete');
    if (tutorial?.active ?? false) {
      final expected = puzzle.referenceMoves[tutorial!.step];
      if (from != expected.from || to != expected.to) {
        return PourResult(this, 0, 'Follow the guided pour or Skip');
      }
    }
    final result = pourBoard(board, from, to);
    if (result.units == 0) return PourResult(this, 0, result.rejection);
    return PourResult(
      _next(
        result.board,
        moveCount + 1,
        [...history, UndoFrame(board, moveCount)],
        lesson: (tutorial?.active ?? false)
            ? tutorial!.advance(tutorialLength)
            : null,
      ),
      result.units,
      null,
    );
  }

  GameInstance undo() {
    if (completed || history.isEmpty) return this;
    final previous = history.last;
    final b = previous.board.map((b) => b.toList()).toList();
    if (extraBottleGranted && b.length == puzzle.initial.length) b.add([]);
    return _next(
      b,
      previous.moveCount,
      history.sublist(0, history.length - 1),
      lesson: (tutorial?.active ?? false)
          ? Tutorial(previous.moveCount, TutorialStatus.active)
          : null,
    );
  }

  GameInstance restart() {
    if (completed) return this;
    return _next(
      [...puzzle.initial, if (extraBottleGranted) <String>[]],
      0,
      [],
      lesson: (tutorial?.active ?? false) ? const Tutorial.start() : null,
    );
  }

  GameInstance skipTutorial() {
    if (completed || !(tutorial?.active ?? false)) return this;
    return _next(board, moveCount, history, lesson: tutorial!.skip());
  }

  GameInstance grantExtraBottle() {
    if (completed || extraBottleGranted) return this;
    return _next([...board, <String>[]], moveCount, history, extra: true);
  }

  Map<String, Object?> toJson() => {
    'instance_schema_version': 2,
    'instance_id': id,
    'puzzle': puzzle.toJson(),
    'slot': slot,
    'is_replay': isReplay,
    'board': board,
    'move_count': moveCount,
    'board_revision': revision,
    'undo_history': history.map((h) => h.toJson()).toList(),
    'extra_bottle_granted': extraBottleGranted,
    'completed': completed,
    'puzzle_date': puzzleDate,
    'time_zone': timeZone,
    'offset_minutes': offsetMinutes,
    'catalog_version': catalogVersion,
    'tutorial': tutorial?.toJson(),
  };
}
