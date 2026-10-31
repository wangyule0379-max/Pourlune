import 'dart:convert';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:sqflite/sqflite.dart';

import 'player_settings.dart';
import 'scenes.dart';
import 'reward_attempt.dart';

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
    this.piece, {
    this.nextInstanceId,
  });
  final String instanceId, puzzleId;
  final bool firstClear;
  final String? piece, nextInstanceId;
  factory CompletionReceipt.row(Map<String, Object?> row) => CompletionReceipt(
    row['instance_id']! as String,
    row['puzzle_id']! as String,
    row['first_clear'] == 1,
    row['piece'] as String?,
    nextInstanceId: row['next_instance_id'] as String?,
  );
  Map<String, Object?> toJson() => {
    'instance_id': instanceId,
    'puzzle_id': puzzleId,
    'first_clear': firstClear,
    'piece': piece,
    'next_instance_id': nextInstanceId,
  };
}

class LocalProgress {
  LocalProgress(
    this.firstClears,
    this.pieces,
    this.unlockedLevels,
    this.qualifyingClears,
    this.receipts,
    this.dailyStamps, {
    this.completedLevels = const [],
    this.revealedPieces = const [],
  });
  final int firstClears, qualifyingClears, receipts;
  final List<String> pieces, dailyStamps;
  final List<int> unlockedLevels, completedLevels;
  final List<String> revealedPieces;
  bool get storyComplete =>
      List.generate(60, (i) => i + 1).every(completedLevels.contains);
  int? get nextUnfinished {
    for (final level in unlockedLevels) {
      if (!completedLevels.contains(level)) return level;
    }
    return null;
  }
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
        version: 5,
        onCreate: (db, _) async {
          await _v1(db);
          await _v2(db);
          await _v3(db);
          await _v4(db);
          await _v5(db);
        },
        onUpgrade: (db, old, version) async {
          if (!{1, 2, 3, 4}.contains(old)) {
            throw StateError('Unsupported schema $old');
          }
          if (old == 1) await _v2(db);
          if (old <= 2) await _v3(db);
          if (old <= 3) await _v4(db);
          await _v5(db);
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

  static Future<void> _v3(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE receipts ADD COLUMN next_instance_id TEXT');
    await db.execute(
      'CREATE TABLE settings(key TEXT PRIMARY KEY,value INTEGER NOT NULL CHECK(value IN (0,1)))',
    );
    await db.execute('CREATE TABLE revealed_pieces(piece TEXT PRIMARY KEY)');
    for (final entry in const PlayerSettings().toJson().entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value ? 1 : 0,
      });
    }
    final completed = await db.query(
      'first_completions',
      where: 'puzzle_id = ?',
      whereArgs: ['main-001'],
    );
    await db.insert('metadata', {
      'key': 'tutorial_done',
      'value': completed.isEmpty ? 0 : 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> _v4(DatabaseExecutor db) async {
    await db.execute(
      "CREATE TABLE reward_attempts(attempt_id TEXT PRIMARY KEY,instance_id TEXT NOT NULL,slot TEXT NOT NULL CHECK(slot IN ('ordinary','daily')),snapshot TEXT NOT NULL,status TEXT NOT NULL CHECK(status IN ('open','closed','unconfirmed','pending_restore','done')),confirmed INTEGER NOT NULL DEFAULT 0 CHECK(confirmed IN (0,1)))",
    );
    await db.execute(
      "CREATE UNIQUE INDEX one_reward_intent_per_slot ON reward_attempts(slot) WHERE status IN ('open','unconfirmed')",
    );
    await db.execute(
      'CREATE TABLE reward_entitlements(instance_id TEXT PRIMARY KEY,attempt_id TEXT NOT NULL)',
    );
    await db.execute(
      "CREATE TABLE fullscreen_shows(show_id TEXT PRIMARY KEY,kind TEXT NOT NULL CHECK(kind IN ('interstitial','rewarded')),shown_at INTEGER NOT NULL)",
    );
    await db.execute(
      'CREATE TABLE service_values(key TEXT PRIMARY KEY,value TEXT NOT NULL)',
    );
    await db.execute('CREATE TABLE service_events(event_id TEXT PRIMARY KEY)');
  }

  static Future<void> _v5(DatabaseExecutor db) async {
    await db.execute(
      "CREATE TABLE fullscreen_attempts(show_id TEXT PRIMARY KEY,kind TEXT NOT NULL CHECK(kind IN ('interstitial','rewarded')),qualifying_boundary INTEGER NOT NULL CHECK(qualifying_boundary >= 0))",
    );
    // Keep the exact legacy outstanding count as the initial ordinal. Previously
    // consumed clears need not be reconstructed. Ordinals never rewind on Reset.
    await db.rawInsert(
      "INSERT INTO metadata(key,value) SELECT 'qualifying_clear_total',value FROM metadata WHERE key='first_clears_since_interstitial'",
    );
    await db.insert('metadata', {
      'key': 'qualifying_consumed_total',
      'value': 0,
    });
  }

  static String? _piece(int level) => level % 4 != 0
      ? null
      : '${sceneIds[(level - 1) ~/ 20]}:${((level - 1) % 20) ~/ 4 + 1}';
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
                      true) &&
              (!(s.tutorial?.finished ?? false) ||
                  (_decode(row['backup_payload'], s.slot)?.tutorial?.finished ??
                      false))) {
            return;
          }
        }
        // A backup belongs to this instance, never the discarded previous game.
        if (old.id == s.id) backup = jsonEncode(old.toJson());
      }
    }
    await tx.update(
      'reward_attempts',
      {'snapshot': json},
      where: 'instance_id = ?',
      whereArgs: [s.id],
    );
    // Recovery may roll back moves, but never an already committed entitlement.
    if ((s.extraBottleGranted &&
            _decode(backup, s.slot)?.extraBottleGranted != true) ||
        ((s.tutorial?.finished ?? false) &&
            !(_decode(backup, s.slot)?.tutorial?.finished ?? false))) {
      backup = json;
    }
    await tx.insert('active_slots', {
      'slot': s.slot,
      'payload': json,
      'backup_payload': backup,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    fault?.call('snapshot');
    if ((s.tutorial?.finished ?? false) ||
        (s.completed && s.puzzle.mainLevel == 1 && !s.isReplay)) {
      await tx.rawUpdate(
        "UPDATE metadata SET value = ? WHERE key = 'tutorial_done' AND value = 0",
        [s.tutorial?.status == TutorialStatus.skipped ? 2 : 1],
      );
      fault?.call('tutorial');
    }
  }

  Future<void> save(
    GameInstance s, {
    bool replace = false,
    String? afterCompletion,
  }) => db.transaction((tx) async {
    if (afterCompletion != null) {
      final receipts = await tx.query(
        'receipts',
        where: 'instance_id = ?',
        whereArgs: [afterCompletion],
      );
      if (receipts.isEmpty || receipts.single['first_clear'] != 1) {
        throw StateError('No first-clear transition');
      }
      final previousTarget = receipts.single['next_instance_id'];
      if (previousTarget != null) {
        if (previousTarget == s.id) return;
        throw StateError('Completion transition already consumed');
      }
      final sourceRows = await tx.query(
        'active_slots',
        where: 'slot = ?',
        whereArgs: ['ordinary'],
      );
      final old = sourceRows.isEmpty
          ? null
          : (_decode(sourceRows.single['payload'], 'ordinary') ??
                _decode(sourceRows.single['backup_payload'], 'ordinary'));
      if (old == null ||
          old.id != afterCompletion ||
          !old.completed ||
          old.isReplay ||
          old.puzzle.mainLevel == 60 ||
          s.slot != 'ordinary' ||
          s.puzzle.mainLevel != old.puzzle.mainLevel! + 1) {
        throw StateError('Invalid Next transition');
      }
    }
    await _write(tx, s, replace);
    if (afterCompletion != null) {
      await tx.update(
        'receipts',
        {'next_instance_id': s.id},
        where: 'instance_id = ?',
        whereArgs: [afterCompletion],
      );
      fault?.call('transition');
    }
  });
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
          if (level >= 11) {
            await tx.rawUpdate(
              "UPDATE metadata SET value = value + 1 WHERE key IN ('first_clears_since_interstitial','qualifying_clear_total')",
            );
          }
          fault?.call('counter');
        }
      } else if (s.slot == 'daily' && !s.isReplay) {
        await tx.insert('daily_stamps', {
          'puzzle_date': s.puzzleDate,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        fault?.call('stamp');
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
      completedLevels: (await tx.query(
        'first_completions',
        orderBy: 'main_level',
      )).map((r) => r['main_level']! as int).toList(),
      revealedPieces: (await tx.query(
        'revealed_pieces',
        orderBy: 'piece',
      )).map((r) => r['piece']! as String).toList(),
    ),
  );
  Future<bool> tutorialDone() async =>
      (await db.query(
        'metadata',
        where: 'key = ?',
        whereArgs: ['tutorial_done'],
      )).single['value'] !=
      0;
  Future<PlayerSettings> readSettings() async {
    final values = const PlayerSettings().toJson();
    for (final row in await db.query('settings')) {
      final key = row['key']! as String, value = row['value'];
      if (!values.containsKey(key)) continue;
      if (value != 0 && value != 1) throw StateError('Unreadable settings');
      values[key] = value == 1;
    }
    return PlayerSettings.fromJson(values);
  }

  Future<void> saveSettings(PlayerSettings settings) =>
      db.transaction((tx) async {
        for (final entry in settings.toJson().entries) {
          await tx.insert('settings', {
            'key': entry.key,
            'value': entry.value ? 1 : 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        fault?.call('settings');
      });
  Future<void> markRevealed(String piece) => db.transaction((tx) async {
    if ((await tx.query(
      'pieces',
      where: 'piece = ?',
      whereArgs: [piece],
    )).isEmpty) {
      throw StateError('Unowned piece');
    }
    await tx.insert('revealed_pieces', {
      'piece': piece,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    fault?.call('reveal');
  });
  Future<void> resetProgress() => db.transaction((tx) async {
    for (final table in [
      'active_slots',
      'first_completions',
      'receipts',
      'revealed_pieces',
      'pieces',
      'unlocks',
      'daily_stamps',
      'reward_attempts',
      'reward_entitlements',
    ]) {
      await tx.delete(table);
    }
    await tx.rawUpdate(
      "UPDATE metadata SET value = 0 WHERE key IN ('tutorial_done','first_clears_since_interstitial')",
    );
    await tx.rawUpdate(
      "UPDATE metadata SET value = (SELECT value FROM metadata WHERE key='qualifying_clear_total') WHERE key='qualifying_consumed_total'",
    );
    await tx.insert('unlocks', {'level': 1});
    fault?.call('reset');
  });

  /// Local entitlement for builds with ads disabled; never records an ad view.
  /// Keep the entitlement and board atomic, including retries after a commit.
  Future<GameInstance> grantDirectExtraBottle(GameInstance origin) =>
      db.transaction((tx) async {
        if (origin.completed ||
            (origin.slot != 'daily' && origin.puzzle.mainLevel! < 4)) {
          throw StateError('Extra bottle unavailable');
        }
        final rows = await tx.query(
          'active_slots',
          where: 'slot = ?',
          whereArgs: [origin.slot],
        );
        final saved = rows.isEmpty
            ? null
            : _decode(rows.single['payload'], origin.slot);
        if (saved == null || saved.id != origin.id || saved.completed) {
          throw StateError('Original instance is no longer active');
        }
        if (saved.extraBottleGranted) return saved;
        if (jsonEncode(saved.toJson()) != jsonEncode(origin.toJson())) {
          throw StateError('Origin must be saved');
        }
        if ((await tx.query(
          'reward_attempts',
          where:
              "slot = ? AND status IN ('open','unconfirmed','pending_restore')",
          whereArgs: [origin.slot],
        )).isNotEmpty) {
          throw StateError('Resolve the original ad request first');
        }
        await tx.insert('reward_entitlements', {
          'instance_id': origin.id,
          'attempt_id': 'direct:${origin.id}',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        final granted = saved.grantExtraBottle();
        await _write(tx, granted, false);
        fault?.call('reward_grant');
        return granted;
      });

  Future<RewardAttempt> beginReward(String attemptId, GameInstance origin) =>
      db.transaction((tx) async {
        if (attemptId.isEmpty ||
            origin.completed ||
            origin.extraBottleGranted) {
          throw StateError('Reward unavailable');
        }
        final slot = await tx.query(
          'active_slots',
          where: 'slot = ?',
          whereArgs: [origin.slot],
        );
        final saved = slot.isEmpty
            ? null
            : _decode(slot.single['payload'], origin.slot);
        if (saved == null ||
            jsonEncode(saved.toJson()) != jsonEncode(origin.toJson())) {
          throw StateError('Origin must be saved');
        }
        if ((await tx.query(
          'reward_entitlements',
          where: 'instance_id = ?',
          whereArgs: [origin.id],
        )).isNotEmpty) {
          throw StateError('Already entitled');
        }
        if ((await tx.query(
          'reward_attempts',
          where: "slot = ? AND status = 'pending_restore'",
          whereArgs: [origin.slot],
        )).isNotEmpty) {
          throw StateError('Resolve the confirmed original reward first');
        }
        final attempt = RewardAttempt(
          id: attemptId,
          origin: origin,
          status: 'open',
          confirmed: false,
        );
        await tx.insert('reward_attempts', attempt.toRow());
        fault?.call('reward_intent');
        return attempt;
      });

  Future<void> closeReward(String attemptId) => db.transaction((tx) async {
    await tx.update(
      'reward_attempts',
      {'status': 'closed'},
      where: "attempt_id = ? AND status = 'open' AND confirmed = 0",
      whereArgs: [attemptId],
    );
    fault?.call('reward_close');
  });

  /// No historical reward query exists in GMA. An interrupted intent is never proof.
  Future<void> recoverRewardIntents() async {
    await db.update('reward_attempts', {
      'status': 'unconfirmed',
    }, where: "status = 'open' AND confirmed = 0");
  }

  Future<List<RewardAttempt>> pendingRewards() async => (await db.query(
    'reward_attempts',
    where: "status IN ('unconfirmed','pending_restore')",
    orderBy: 'attempt_id',
  )).map(RewardAttempt.row).toList();

  Future<RewardAttempt?> rewardAttempt(String id) async {
    final rows = await db.query(
      'reward_attempts',
      where: 'attempt_id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : RewardAttempt.row(rows.single);
  }

  Future<void> dismissUnconfirmedReward(String id) async {
    await db.update(
      'reward_attempts',
      {'status': 'closed'},
      where: "attempt_id = ? AND status = 'unconfirmed' AND confirmed = 0",
      whereArgs: [id],
    );
  }

  /// Confirmation, unique entitlement and any active-board grant commit together.
  /// Callers serialize this with gameplay writes; retries use the same attempt ID.
  Future<RewardAttempt?> confirmReward(String id) => db.transaction((tx) async {
    final rows = await tx.query(
      'reward_attempts',
      where: 'attempt_id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null; // Reset or an unrelated/stale SDK callback.
    final attempt = RewardAttempt.row(rows.single);
    if (attempt.confirmed) return attempt;
    final slot = await tx.query(
      'active_slots',
      where: 'slot = ?',
      whereArgs: [attempt.origin.slot],
    );
    final active = slot.isEmpty
        ? null
        : (_decode(slot.single['payload'], attempt.origin.slot) ??
              _decode(slot.single['backup_payload'], attempt.origin.slot));
    var origin = active?.id == attempt.origin.id ? active! : attempt.origin;
    final existing = await tx.query(
      'reward_entitlements',
      where: 'instance_id = ?',
      whereArgs: [origin.id],
    );
    var status = 'done';
    if (existing.isEmpty) {
      await tx.insert('reward_entitlements', {
        'instance_id': origin.id,
        'attempt_id': id,
      });
      fault?.call('reward_confirmation');
      final completed =
          origin.completed ||
          (await tx.query(
            'receipts',
            where: 'instance_id = ?',
            whereArgs: [origin.id],
          )).isNotEmpty;
      if (!completed) {
        origin = origin.grantExtraBottle();
        if (active?.id == origin.id) {
          await _write(tx, origin, false);
        } else {
          status = 'pending_restore';
        }
      }
    }
    // Other attempts may have a callback later; they cannot grant a second bottle.
    await tx.update(
      'reward_attempts',
      {'snapshot': jsonEncode(origin.toJson())},
      where: 'instance_id = ?',
      whereArgs: [origin.id],
    );
    await tx.update(
      'reward_attempts',
      {'confirmed': 1, 'status': status},
      where: 'attempt_id = ?',
      whereArgs: [id],
    );
    fault?.call('reward_grant');
    return RewardAttempt(
      id: id,
      origin: origin,
      status: status,
      confirmed: true,
    );
  });

  Future<void> restoreReward(
    String id, {
    required String? replacingInstance,
  }) => db.transaction((tx) async {
    final rows = await tx.query(
      'reward_attempts',
      where: 'attempt_id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) throw StateError('Unknown reward');
    final attempt = RewardAttempt.row(rows.single);
    if (!attempt.needsRestore || !attempt.confirmed) return;
    final slot = await tx.query(
      'active_slots',
      where: 'slot = ?',
      whereArgs: [attempt.origin.slot],
    );
    final active = slot.isEmpty
        ? null
        : (_decode(slot.single['payload'], attempt.origin.slot) ??
              _decode(slot.single['backup_payload'], attempt.origin.slot));
    if (active?.id != replacingInstance) {
      throw StateError('Replacement changed; confirm again');
    }
    await _write(tx, attempt.origin, true);
    await tx.update(
      'reward_attempts',
      {'status': 'done'},
      where: "instance_id = ? AND status = 'pending_restore' AND confirmed = 1",
      whereArgs: [attempt.origin.id],
    );
    fault?.call('reward_restore');
  });

  Future<int?> lastFullscreenMillis() async {
    final raw = await readServiceValue('last_fullscreen_ms');
    return raw is int && raw >= 0 ? raw : null;
  }

  /// Durable qualification boundary while gameplay is locked, before SDK show.
  /// Preparing is not evidence of display and never consumes qualification.
  Future<void> prepareFullscreen(String showId, String kind) =>
      db.transaction((tx) async {
        if (showId.isEmpty || !{'interstitial', 'rewarded'}.contains(kind)) {
          throw ArgumentError('Invalid fullscreen request');
        }
        final total =
            (await tx.query(
                  'metadata',
                  where: 'key=?',
                  whereArgs: ['qualifying_clear_total'],
                )).single['value']!
                as int;
        await tx.rawInsert(
          'INSERT OR IGNORE INTO fullscreen_attempts(show_id,kind,qualifying_boundary) VALUES(?,?,?)',
          [showId, kind, total],
        );
        final attempt = (await tx.query(
          'fullscreen_attempts',
          where: 'show_id=?',
          whereArgs: [showId],
        )).single;
        if (attempt['kind'] != kind) {
          throw StateError('Fullscreen identity conflict');
        }
        await tx.insert('service_values', {
          'key': 'fullscreen_intent',
          'value': jsonEncode({'id': showId, 'kind': kind}),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        fault?.call('service_value');
        fault?.call('fullscreen_prepare');
      });

  Future<void> recordFullscreen(String showId, String kind, int millis) =>
      db.transaction((tx) async {
        if (millis < 0) throw ArgumentError.value(millis);
        await tx.rawInsert(
          'INSERT OR IGNORE INTO fullscreen_shows(show_id,kind,shown_at) VALUES(?,?,?)',
          [showId, kind, millis],
        );
        final changed =
            Sqflite.firstIntValue(await tx.rawQuery('SELECT changes()')) == 1;
        if (!changed) return;
        final attempt = await tx.query(
          'fullscreen_attempts',
          where: 'show_id=?',
          whereArgs: [showId],
        );
        if (attempt.isEmpty || attempt.single['kind'] != kind) {
          throw StateError('Fullscreen request was not prepared');
        }
        final previous = await tx.query(
          'service_values',
          where: 'key=?',
          whereArgs: ['last_fullscreen_ms'],
        );
        final oldTime = previous.isEmpty
            ? null
            : jsonDecode(previous.single['value']! as String);
        await tx.insert('service_values', {
          'key': 'last_fullscreen_ms',
          'value': jsonEncode(
            oldTime is int && oldTime > millis ? oldTime : millis,
          ),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        if (kind == 'interstitial') {
          await tx.rawUpdate(
            "UPDATE metadata SET value = MAX(value,?) WHERE key='qualifying_consumed_total'",
            [attempt.single['qualifying_boundary']],
          );
          await tx.rawUpdate(
            "UPDATE metadata SET value = (SELECT value FROM metadata WHERE key='qualifying_clear_total') - (SELECT value FROM metadata WHERE key='qualifying_consumed_total') WHERE key='first_clears_since_interstitial'",
          );
        }
        final intent = await tx.query(
          'service_values',
          where: 'key=?',
          whereArgs: ['fullscreen_intent'],
        );
        if (intent.isNotEmpty) {
          final value = jsonDecode(intent.single['value']! as String);
          if (value is Map && value['id'] == showId) {
            await tx.delete('service_values', where: "key='fullscreen_intent'");
          }
        }
        fault?.call('fullscreen');
      });

  Future<void> clearFullscreenIntent(String id) => db.transaction((tx) async {
    final rows = await tx.query(
      'service_values',
      where: 'key = ?',
      whereArgs: ['fullscreen_intent'],
    );
    if (rows.isNotEmpty) {
      final value = jsonDecode(rows.single['value']! as String);
      if (value is Map && value['id'] == id) {
        await tx.delete(
          'service_values',
          where: 'key = ?',
          whereArgs: ['fullscreen_intent'],
        );
      }
    }
  });

  Future<Object?> readServiceValue(String key) async {
    final rows = await db.query(
      'service_values',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.single['value']! as String);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeServiceValue(String key, Object? value) =>
      db.transaction((tx) async {
        await tx.insert('service_values', {
          'key': key,
          'value': jsonEncode(value),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        fault?.call('service_value');
      });

  /// Claim before best-effort dispatch. Analytics is never a player entitlement.
  Future<bool> claimServiceEvent(String id) => db.transaction((tx) async {
    await tx.rawInsert(
      'INSERT OR IGNORE INTO service_events(event_id) VALUES(?)',
      [id],
    );
    return Sqflite.firstIntValue(await tx.rawQuery('SELECT changes()')) == 1;
  });

  Future<void> close() => db.close();
}
