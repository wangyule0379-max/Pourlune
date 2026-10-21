import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, fixture, finish, daily;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late GameStore store;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b02-store-');
    path = '${dir.path}/g.db';
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

  test('B02-02 tutorial skip and snapshot atomically retry, reopen and replay remain free', () async {
    var s = GameInstance.create(
      id: 'tutorial',
      puzzle: fixture(),
      tutorial: true,
    );
    await store.save(s);
    s = s.pour(0, 2).state;
    await store.save(s);
    final skipped = s.skipTutorial();
    store.fault = (stage) {
      if (stage == 'tutorial') throw StateError('tutorial fault');
    };
    await expectLater(store.save(skipped), throwsStateError);
    store.fault = null;
    expect(await store.tutorialDone(), isFalse);
    expect((await store.load('ordinary')).instance!.tutorial!.step, 1);
    await store.save(skipped);
    await reopen();
    expect(await store.tutorialDone(), isTrue);
    expect((await store.load('ordinary')).instance!.toJson(), skipped.toJson());
    final replay = GameInstance.create(
      id: 'replay',
      puzzle: fixture(),
      isReplay: true,
    );
    await store.save(replay, replace: true);
    expect((await store.load('ordinary')).instance!.tutorial, isNull);
  });
  test('B02-01/07 once-only Next commits new instance and receipt transition together', () async {
    final won = finish(sample('done'));
    await store.settle(won);
    final next = sample('next', level: 2);
    store.fault = (stage) {
      if (stage == 'transition') throw StateError('transition fault');
    };
    await expectLater(
      store.save(next, replace: true, afterCompletion: won.id),
      throwsStateError,
    );
    store.fault = null;
    expect((await store.load('ordinary')).instance!.id, won.id);
    await store.save(next, replace: true, afterCompletion: won.id);
    await reopen();
    await store.save(next, replace: true, afterCompletion: won.id);
    await expectLater(
      store.save(
        sample('duplicate', level: 2),
        replace: true,
        afterCompletion: won.id,
      ),
      throwsStateError,
    );
    expect((await store.load('ordinary')).instance!.id, next.id);
    expect((await store.progress()).firstClears, 1);
  });
  test('B02-06 daily stamp is atomic, once/date across instances, keeps ordinary/rewards', () async {
    final main = sample('main');
    await store.save(main);
    final d = daily();
    await store.save(d);
    final complete = finish(d);
    store.fault = (stage) {
      if (stage == 'stamp') throw StateError('stamp fault');
    };
    await expectLater(store.settle(complete), throwsStateError);
    store.fault = null;
    expect((await store.progress()).dailyStamps, isEmpty);
    expect((await store.progress()).receipts, 0);
    await store.settle(complete);
    await reopen();
    await store.settle(complete);
    final again = GameInstance.create(
      id: 'another-daily',
      puzzle: d.puzzle,
      slot: 'daily',
      puzzleDate: d.puzzleDate,
      timeZone: 'Other-zone',
      offsetMinutes: -300,
      catalogVersion: 2,
    );
    await store.settle(finish(again), replace: true);
    final p = await store.progress();
    expect(p.dailyStamps, ['2026-10-22']);
    expect(p.firstClears, 0);
    expect(p.pieces, isEmpty);
    expect(p.qualifyingClears, 0);
    expect(p.receipts, 2);
    expect((await store.load('ordinary')).instance!.toJson(), main.toJson());
  });
  test('B02-07 reveal acknowledgement separate, failure never changes ownership or repeats it', () async {
    final s = finish(sample('piece', level: 4));
    await store.settle(s);
    expect((await store.progress()).revealedPieces, isEmpty);
    store.fault = (stage) {
      if (stage == 'reveal') throw StateError('reveal fault');
    };
    await expectLater(store.markRevealed('color_studio:1'), throwsStateError);
    store.fault = null;
    await reopen();
    expect((await store.progress()).pieces, ['color_studio:1']);
    expect((await store.progress()).revealedPieces, isEmpty);
    await store.markRevealed('color_studio:1');
    await store.markRevealed('color_studio:1');
    await reopen();
    expect((await store.progress()).revealedPieces, ['color_studio:1']);
    await expectLater(store.markRevealed('garden_nook:1'), throwsStateError);
  });
  test('B02-08 preferences atomic; game reset keeps preferences and rolls back on failure', () async {
    final settings = const PlayerSettings()
        .withValue('music', false)
        .withValue('strong_contrast', true);
    await store.saveSettings(settings);
    await store.settle(finish(sample('a', level: 4)));
    await store.save(daily());
    await reopen();
    expect((await store.readSettings()).toJson(), settings.toJson());
    store.fault = (stage) {
      if (stage == 'reset') throw StateError('reset fault');
    };
    await expectLater(store.resetProgress(), throwsStateError);
    store.fault = null;
    expect((await store.progress()).pieces, ['color_studio:1']);
    await store.resetProgress();
    await reopen();
    expect((await store.progress()).pieces, isEmpty);
    expect((await store.progress()).unlockedLevels, [1]);
    expect((await store.load('daily')).instance, isNull);
    expect((await store.readSettings()).toJson(), settings.toJson());
  });
  test('B02-09 nonempty B01 schema2 migration preserves legacy snapshots, extra, daily, receipt and awards', () async {
    await store.close();
    await databaseFactoryFfi.deleteDatabase(path);
    final legacy = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          for (final sql in [
            'CREATE TABLE active_slots(slot TEXT PRIMARY KEY,payload TEXT NOT NULL,backup_payload TEXT)',
            'CREATE TABLE first_completions(puzzle_id TEXT PRIMARY KEY,main_level INTEGER NOT NULL)',
            'CREATE TABLE metadata(key TEXT PRIMARY KEY,value INTEGER NOT NULL)',
            'CREATE TABLE receipts(instance_id TEXT PRIMARY KEY,completion_id TEXT UNIQUE,puzzle_id TEXT,first_clear INTEGER,piece TEXT)',
            'CREATE TABLE pieces(piece TEXT PRIMARY KEY)',
            'CREATE TABLE unlocks(level INTEGER PRIMARY KEY)',
            'CREATE TABLE daily_stamps(puzzle_date TEXT PRIMARY KEY)',
          ]) {
            await db.execute(sql);
          }
        },
      ),
    );
    final active = sample('legacy').pour(0, 2).state.grantExtraBottle(),
        d = daily().pour(0, 2).state;
    String v1(GameInstance s) => jsonEncode(
      s.toJson()
        ..['instance_schema_version'] = 1
        ..remove('tutorial'),
    );
    for (final s in [active, d]) {
      await legacy.insert('active_slots', {
        'slot': s.slot,
        'payload': v1(s),
        'backup_payload': v1(s),
      });
    }
    await legacy.insert('metadata', {
      'key': 'first_clears_since_interstitial',
      'value': 2,
    });
    for (final level in [1, 4]) {
      await legacy.insert('first_completions', {
        'puzzle_id': 'main-${level.toString().padLeft(3, '0')}',
        'main_level': level,
      });
    }
    await legacy.insert('unlocks', {'level': 1});
    await legacy.insert('unlocks', {'level': 5});
    await legacy.insert('pieces', {'piece': 'color_studio:1'});
    await legacy.insert('receipts', {
      'instance_id': 'done4',
      'completion_id': 'completion:done4',
      'puzzle_id': 'main-004',
      'first_clear': 1,
      'piece': 'color_studio:1',
    });
    await legacy.close();
    store = await GameStore.open(path, factory: databaseFactoryFfi);
    expect((await store.load('ordinary')).instance!.toJson(), active.toJson());
    expect((await store.load('daily')).instance!.toJson(), d.toJson());
    final p = await store.progress();
    expect(p.completedLevels, [1, 4]);
    expect(p.pieces, ['color_studio:1']);
    expect(p.qualifyingClears, 2);
    expect(p.receipts, 1);
    expect(p.revealedPieces, isEmpty);
    expect(await store.tutorialDone(), isTrue);
    expect((await store.readSettings()).music, isTrue);
  });
  for (final finishLesson in [false, true]) {
    test(
      'B02-02 completed/skipped tutorial survives primary corruption (completed=$finishLesson)',
      () async {
        var s = GameInstance.create(
          id: 'lesson-corrupt',
          puzzle: fixture(),
          tutorial: true,
        );
        await store.save(s);
        if (finishLesson) {
          for (final m in s.puzzle.referenceMoves.take(3)) {
            s = s.pour(m.from, m.to).state;
            await store.save(s);
          }
        } else {
          s = s.skipTutorial();
          await store.save(s);
        }
        await store.db.update(
          'active_slots',
          {'payload': 'broken'},
          where: 'slot = ?',
          whereArgs: ['ordinary'],
        );
        await reopen();
        final recovered = (await store.load('ordinary')).instance!;
        expect(
          recovered.tutorial!.status,
          finishLesson ? TutorialStatus.completed : TutorialStatus.skipped,
        );
        expect(recovered.board, s.board);
        expect(await store.tutorialDone(), isTrue);
      },
    );
  }
}
