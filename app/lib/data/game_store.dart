import 'dart:convert';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:sqflite/sqflite.dart';

class LoadedInstance {
  const LoadedInstance(
    this.instance, {
    this.recovered = false,
    this.unavailable = false,
  });
  final GameInstance? instance;
  final bool recovered, unavailable;
}

class CompletionReceipt {
  CompletionReceipt(
    this.instanceId,
    this.puzzleId,
    this.firstClear,
    this.piece,
  );
  final String instanceId, puzzleId;
  final bool firstClear;
  final String? piece;
  factory CompletionReceipt.row(Map<String, Object?> row) => CompletionReceipt(
    row['instance_id']! as String,
    row['puzzle_id']! as String,
    row['first_clear'] == 1,
    row['piece'] as String?,
  );
  Map<String, Object?> toJson() => {
    'instance_id': instanceId,
    'puzzle_id': puzzleId,
    'first_clear': firstClear,
    'piece': piece,
  };
}

class LocalProgress {
  LocalProgress(
    this.firstClears,
    this.pieces,
    this.unlockedLevels,
    this.qualifyingClears,
    this.receipts,
    this.dailyStamps,
  );
  final int firstClears, qualifyingClears, receipts;
  final List<String> pieces, dailyStamps;
  final List<int> unlockedLevels;
}

/// All mutating operations use one SQLite transaction; no UI owns reward writes.
class GameStore {
  GameStore._(this.db);
  final Database db;

  /// Development/test fault injection occurs after real SQL writes, before COMMIT.
  void Function(String stage)? fault;
  static Future<GameStore> open(String path, {DatabaseFactory? factory}) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await _v1(db);
          await _v2(db);
        },
        onUpgrade: (db, old, version) async {
          if (old == 1) {
            await _v2(db);
          } else {
            throw StateError('Unsupported schema $old');
          }
        },
        onDowngrade: (db, old, version) async =>
            throw StateError('Cannot downgrade schema $old to $version'),
      ),
    );
    return GameStore._(db);
  }

  static Future<void> _v1(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE active_slots(slot TEXT PRIMARY KEY, payload TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE first_completions(puzzle_id TEXT PRIMARY KEY, main_level INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE metadata(key TEXT PRIMARY KEY, value INTEGER NOT NULL)',
    );
  }

  static Future<void> _v2(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE active_slots ADD COLUMN backup_payload TEXT');
    await db.execute(
      'CREATE TABLE receipts(instance_id TEXT PRIMARY KEY, completion_id TEXT NOT NULL UNIQUE, puzzle_id TEXT NOT NULL, first_clear INTEGER NOT NULL, piece TEXT)',
    );
    await db.execute('CREATE TABLE pieces(piece TEXT PRIMARY KEY)');
    await db.execute(
      'CREATE TABLE unlocks(level INTEGER PRIMARY KEY CHECK(level BETWEEN 1 AND 60))',
    );
    await db.execute('CREATE TABLE daily_stamps(puzzle_date TEXT PRIMARY KEY)');
    await db.insert('unlocks', {
      'level': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('metadata', {
      'key': 'first_clears_since_interstitial',
      'value': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    for (final row in await db.query('first_completions')) {
      await _awardMilestone(db, row['main_level']! as int);
    }
  }

  static String? _piece(int level) => level % 4 != 0
      ? null
      : '${['color_studio', 'garden_nook', 'seaside_corner'][(level - 1) ~/ 20]}:${((level - 1) % 20) ~/ 4 + 1}';
  static Future<void> _awardMilestone(DatabaseExecutor db, int level) async {
    if (level < 60) {
      await db.insert('unlocks', {
        'level': level + 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final piece = _piece(level);
    if (piece != null) {
      await db.insert('pieces', {
        'piece': piece,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static GameInstance? _decode(Object? raw, String slot) {
    if (raw is! String) return null;
    try {
      final s = GameInstance.parse(raw);
      return s.slot == slot ? s : null;
    } on FormatException {
      return null;
    }
  }

  Future<LoadedInstance> load(String slot) async {
    final rows = await db.query(
      'active_slots',
      where: 'slot = ?',
      whereArgs: [slot],
    );
    if (rows.isEmpty) return const LoadedInstance(null);
    final row = rows.single, current = _decode(row['payload'], slot);
    if (current != null) return LoadedInstance(current);
    final backup = _decode(row['backup_payload'], slot);
    return LoadedInstance(
      backup,
      recovered: backup != null,
      unavailable: backup == null,
    );
  }

  Future<void> _write(DatabaseExecutor tx, GameInstance s, bool replace) async {
    final rows = await tx.query(
      'active_slots',
      where: 'slot = ?',
      whereArgs: [s.slot],
    );
    final json = jsonEncode(s.toJson());
    String? backup;
    if (rows.isNotEmpty) {
      final row = rows.single,
          old =
              _decode(row['payload'], s.slot) ??
              _decode(row['backup_payload'], s.slot);
      if (old != null) {
        if (old.id != s.id && !replace) {
          throw StateError('Replacement needs confirmation');
        }
        if (old.id == s.id) {
          if (old.extraBottleGranted && !s.extraBottleGranted) {
            throw StateError('Cannot revoke extra bottle entitlement');
          }
          if (jsonEncode(old.puzzle.toJson()) !=
                  jsonEncode(s.puzzle.toJson()) ||
              old.isReplay != s.isReplay ||
              old.puzzleDate != s.puzzleDate ||
              old.timeZone != s.timeZone ||
              old.offsetMinutes != s.offsetMinutes ||
              old.catalogVersion != s.catalogVersion) {
            throw StateError('Instance definition changed');
          }
          if (s.revision < old.revision || (old.completed && !s.completed)) {
            throw StateError('Stale snapshot');
          }
          if (s.revision == old.revision && json != jsonEncode(old.toJson())) {
            throw StateError('Conflicting revision');
          }
          if (json == row['payload'] &&
              (!s.extraBottleGranted ||
                  _decode(row['backup_payload'], s.slot)?.extraBottleGranted ==
                      true)) {
            return;
          }
        }
        // A backup belongs to this instance, never the discarded previous game.
        if (old.id == s.id) backup = jsonEncode(old.toJson());
      }
    }
    // Recovery may roll back moves, but never an already committed entitlement.
    if (s.extraBottleGranted &&
        _decode(backup, s.slot)?.extraBottleGranted != true) {
      backup = json;
    }
    await tx.insert('active_slots', {
      'slot': s.slot,
      'payload': json,
      'backup_payload': backup,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    fault?.call('snapshot');
  }

  Future<void> save(GameInstance s, {bool replace = false}) =>
      db.transaction((tx) => _write(tx, s, replace));
  Future<CompletionReceipt> settle(
    GameInstance s, {
    bool replace = false,
  }) async {
    if (!s.completed) throw StateError('Incomplete instance');
    return db.transaction((tx) async {
      final existing = await tx.query(
        'receipts',
        where: 'instance_id = ?',
        whereArgs: [s.id],
      );
      if (existing.isNotEmpty) {
        final r = CompletionReceipt.row(existing.single);
        if (r.puzzleId != s.puzzle.id) {
          throw StateError('Receipt identity conflict');
        }
        return r;
      }
      await _write(tx, s, replace);
      var first = false;
      String? piece;
      if (s.slot == 'ordinary' && !s.isReplay) {
        final prior = await tx.query(
          'first_completions',
          where: 'puzzle_id = ?',
          whereArgs: [s.puzzle.id],
        );
        if (prior.isEmpty) {
          final count = Sqflite.firstIntValue(
            await tx.rawQuery('SELECT COUNT(*) FROM first_completions'),
          )!;
          final level = s.puzzle.mainLevel!;
          await tx.insert('first_completions', {
            'puzzle_id': s.puzzle.id,
            'main_level': level,
          });
          first = true;
          fault?.call('completion');
          if (level < 60) {
            await tx.insert('unlocks', {
              'level': level + 1,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          fault?.call('unlock');
          piece = _piece(level);
          if (piece != null) {
            await tx.insert('pieces', {
              'piece': piece,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          fault?.call('piece');
          if (count >= 10) {
            await tx.rawUpdate(
              "UPDATE metadata SET value = value + 1 WHERE key = 'first_clears_since_interstitial'",
            );
          }
          fault?.call('counter');
        }
      } else if (s.slot == 'daily' && !s.isReplay) {
        await tx.insert('daily_stamps', {
          'puzzle_date': s.puzzleDate,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final r = CompletionReceipt(s.id, s.puzzle.id, first, piece);
      await tx.insert('receipts', {
        'instance_id': s.id,
        'completion_id': 'completion:${s.id}',
        'puzzle_id': s.puzzle.id,
        'first_clear': first ? 1 : 0,
        'piece': piece,
      });
      // Completed recovery must stay locked even if the primary payload is damaged.
      await tx.update(
        'active_slots',
        {'backup_payload': jsonEncode(s.toJson())},
        where: 'slot = ?',
        whereArgs: [s.slot],
      );
      fault?.call('receipt');
      return r;
    });
  }

  Future<LocalProgress> progress() => db.transaction(
    (tx) async => LocalProgress(
      Sqflite.firstIntValue(
        await tx.rawQuery('SELECT COUNT(*) FROM first_completions'),
      )!,
      (await tx.query(
        'pieces',
        orderBy: 'piece',
      )).map((r) => r['piece']! as String).toList(),
      (await tx.query(
        'unlocks',
        orderBy: 'level',
      )).map((r) => r['level']! as int).toList(),
      (await tx.query(
            'metadata',
            where: 'key = ?',
            whereArgs: ['first_clears_since_interstitial'],
          )).single['value']!
          as int,
      Sqflite.firstIntValue(
        await tx.rawQuery('SELECT COUNT(*) FROM receipts'),
      )!,
      (await tx.query(
        'daily_stamps',
        orderBy: 'puzzle_date',
      )).map((r) => r['puzzle_date']! as String).toList(),
    ),
  );
  Future<void> close() => db.close();
}
