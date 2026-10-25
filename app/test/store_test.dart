import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Puzzle fixture([int level = 1, int version = 1]) {
  final m = jsonDecode(
    File('assets/fixtures/main-001.reference.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  m['puzzle_id'] = 'main-${level.toString().padLeft(3, '0')}';
  m['main_level'] = level;
  m['content_version'] = version;
  return Puzzle.fromJson(m);
}

GameInstance sample(String id, {int level = 1, bool replay = false}) =>
    GameInstance.create(id: id, puzzle: fixture(level), isReplay: replay);
GameInstance finish(GameInstance s) {
  for (final m in s.puzzle.referenceMoves) {
    s = s.pour(m.from, m.to).state;
  }
  return s;
}

GameInstance daily() {
  final m = fixture().toJson()
    ..['puzzle_id'] = 'daily-test'
    ..['mode'] = 'daily'
    ..['main_level'] = null;
  return GameInstance.create(
    id: 'daily-instance',
    puzzle: Puzzle.fromJson(m),
    slot: 'daily',
    puzzleDate: '2026-10-22',
    timeZone: 'Asia/Taipei',
    offsetMinutes: 480,
    catalogVersion: 1,
  );
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late GameStore store;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pourlune-sqlite-');
    path = '${dir.path}/game.sqlite';
    store = await GameStore.open(path, factory: databaseFactoryFfi);
  });
  tearDown(() async {
    await store.close();
    dir.deleteSync(recursive: true);
  });
  Future<void> reopen() async {
    await store.close();
    store = await GameStore.open(path, factory: databaseFactoryFfi);
  }

  test(
    'AC-23 actual file reopen restores moves, original version, extra and undo',
    () async {
      var s = sample('old').pour(0, 2).state.grantExtraBottle();
      await store.save(s);
      s = s.pour(1, 0).state;
      await store.save(s);
      await reopen();
      final restored = (await store.load('ordinary')).instance!;
      expect(restored.toJson(), s.toJson());
      expect(restored.puzzle.contentVersion, 1);
      expect(fixture(1, 2).contentVersion, 2);
      expect(restored.undo().undo().board, [
        ...restored.puzzle.initial,
        <String>[],
      ]);
      expect(restored.restart().extraBottleGranted, isTrue);
      expect(
        (await store.db.rawQuery('SELECT sqlite_version() AS v')).single['v'],
        isA<String>(),
      );
    },
  );
  test(
    'AC-24 recovery uses valid backup only, isolates daily and progress',
    () async {
      final initial = sample('a');
      await store.save(initial);
      await store.save(initial.pour(0, 2).state);
      await store.save(daily());
      await store.db.update(
        'active_slots',
        {'payload': 'corrupt'},
        where: 'slot = ?',
        whereArgs: ['ordinary'],
      );
      await reopen();
      final recovery = await store.load('ordinary');
      expect(recovery.recovered, isTrue);
      expect(recovery.instance!.revision, 0);
      await store.save(recovery.instance!.pour(0, 2).state);
      await store.db.update(
        'active_slots',
        {'payload': 'bad', 'backup_payload': 'bad'},
        where: 'slot = ?',
        whereArgs: ['ordinary'],
      );
      expect((await store.load('ordinary')).unavailable, isTrue);
      expect((await store.load('daily')).instance!.puzzleDate, '2026-10-22');
      expect((await store.progress()).firstClears, 0);
    },
  );
  test(
    'replacement failure rolls back prior slot and rejects stale snapshots',
    () async {
      final a = sample('a');
      await store.save(a);
      final one = a.pour(0, 2).state;
      await store.save(one);
      await expectLater(store.save(a), throwsStateError);
      store.fault = (stage) {
        if (stage == 'snapshot') throw StateError('disk fault');
      };
      await expectLater(
        store.save(sample('b'), replace: true),
        throwsStateError,
      );
      store.fault = null;
      await reopen();
      expect((await store.load('ordinary')).instance!.toJson(), one.toJson());
    },
  );
  test('AC-09/10 atomic settlement rollback at every write boundary', () async {
    final s = sample('milestone', level: 12);
    await store.save(s);
    for (final point in [
      'snapshot',
      'completion',
      'unlock',
      'piece',
      'counter',
      'receipt',
    ]) {
      store.fault = (stage) {
        if (stage == point) throw StateError(point);
      };
      await expectLater(
        store.settle(finish(s)),
        throwsStateError,
        reason: point,
      );
      store.fault = null;
      await reopen();
      final p = await store.progress();
      expect(p.firstClears, 0, reason: point);
      expect(p.pieces, isEmpty);
      expect(p.unlockedLevels, [1]);
      expect(p.receipts, 0);
      expect(p.qualifyingClears, 0);
      expect((await store.load('ordinary')).instance!.completed, isFalse);
    }
    final receipt = await store.settle(finish(s));
    expect(receipt.firstClear, isTrue);
    expect(receipt.piece, 'color_studio:3');
    await reopen();
    expect((await store.settle(finish(s))).toJson(), receipt.toJson());
    final p = await store.progress();
    expect(p.firstClears, 1);
    expect(p.pieces, ['color_studio:3']);
    expect(p.unlockedLevels, [1, 13]);
    expect(p.receipts, 1);
  });
  test('AC-11/12 count first ten protection, replay/version idempotence and daily isolation', () async {
    for (var i = 1; i <= 16; i++) {
      await store.settle(
        finish(sample('instance-$i', level: i)),
        replace: true,
      );
    }
    expect((await store.progress()).qualifyingClears, 6);
    await store.settle(
      finish(sample('replay', level: 20, replay: true)),
      replace: true,
    );
    await store.settle(finish(sample('again', level: 12)), replace: true);
    await store.settle(finish(daily()), replace: true);
    await reopen();
    final p = await store.progress();
    expect(p.firstClears, 16);
    expect(p.qualifyingClears, 6);
    expect(p.pieces.length, 4);
    expect(p.dailyStamps, ['2026-10-22']);
    // An old receipt retried after a newer slot must never replace the newer instance.
    await store.settle(finish(sample('instance-12', level: 12)));
    expect((await store.load('ordinary')).instance!.id, 'again');
  });
  test('completed snapshot corruption recovers a completed board without reopening rewards', () async {
    final s = sample('completed-corrupt');
    await store.save(s);
    var pending = s;
    for (final m in s.puzzle.referenceMoves.take(4)) {
      pending = pending.pour(m.from, m.to).state;
    }
    await store.save(pending);
    await store.settle(finish(s));
    await store.db.update(
      'active_slots',
      {'payload': 'corrupt'},
      where: 'slot = ?',
      whereArgs: ['ordinary'],
    );
    await reopen();
    final restored = (await store.load('ordinary')).instance!;
    expect(restored.completed, isTrue);
    expect((await store.settle(restored)).firstClear, isTrue);
    expect((await store.progress()).firstClears, 1);
  });
  test(
    'persisted entitlement cannot be revoked by a newer malformed producer',
    () async {
      final a = sample('entitlement');
      await store.save(a.grantExtraBottle());
      final newer = GameInstance.fromJson(a.toJson()..['board_revision'] = 2);
      await expectLater(store.save(newer), throwsStateError);
    },
  );
  test('AC-07/24 persisted extra entitlement survives primary corruption immediately after grant', () async {
    for (final saveBeforeGrant in [true, false]) {
      final initial = sample('grant-$saveBeforeGrant');
      if (saveBeforeGrant) await store.save(initial, replace: true);
      await store.save(initial.grantExtraBottle(), replace: true);
      await store.db.update(
        'active_slots',
        {'payload': 'broken'},
        where: 'slot = ?',
        whereArgs: ['ordinary'],
      );
      await reopen();
      final loaded = await store.load('ordinary');
      expect(loaded.recovered, isTrue);
      final restored = loaded.instance!;
      expect(restored.extraBottleGranted, isTrue);
      expect(restored.board.length, 5);
      expect(identical(restored.grantExtraBottle(), restored), isTrue);
      expect(restored.restart().board.length, 5);
    }
  });
  test('AC-33 nonempty v1 migration preserves both slots, history, counts and derives rewards', () async {
    await store.close();
    await databaseFactoryFfi.deleteDatabase(path);
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE active_slots(slot TEXT PRIMARY KEY, payload TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE first_completions(puzzle_id TEXT PRIMARY KEY, main_level INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE metadata(key TEXT PRIMARY KEY, value INTEGER NOT NULL)',
          );
        },
      ),
    );
    final s = sample('legacy').pour(0, 2).state;
    for (final v in [s, daily()]) {
      await old.insert('active_slots', {
        'slot': v.slot,
        'payload': jsonEncode(v.toJson()),
      });
    }
    await old.insert('first_completions', {
      'puzzle_id': 'main-004',
      'main_level': 4,
    });
    await old.insert('metadata', {
      'key': 'first_clears_since_interstitial',
      'value': 2,
    });
    await old.close();
    store = await GameStore.open(path, factory: databaseFactoryFfi);
    expect((await store.load('ordinary')).instance!.toJson(), s.toJson());
    expect((await store.load('daily')).instance!.id, 'daily-instance');
    final p = await store.progress();
    expect(p.firstClears, 1);
    expect(p.pieces, ['color_studio:1']);
    expect(p.unlockedLevels, [1, 5]);
    expect(p.qualifyingClears, 2);
  });
}
