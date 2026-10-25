import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, daily;

void main() {
  sqfliteFfiInit();
  test('B04 nonempty schema3 upgrade retains slots receipts preferences and adds reward constraints', () async {
    final d = Directory.systemTemp.createTempSync('b04-v3-');
    final path = '${d.path}/g.db';
    final s = sample(
      'legacy-b04',
      level: 12,
    ).pour(0, 2).state.grantExtraBottle();
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          for (final sql in [
            'CREATE TABLE active_slots(slot TEXT PRIMARY KEY,payload TEXT NOT NULL,backup_payload TEXT)',
            'CREATE TABLE first_completions(puzzle_id TEXT PRIMARY KEY,main_level INTEGER NOT NULL)',
            'CREATE TABLE metadata(key TEXT PRIMARY KEY,value INTEGER NOT NULL)',
            'CREATE TABLE receipts(instance_id TEXT PRIMARY KEY,completion_id TEXT UNIQUE,puzzle_id TEXT,first_clear INTEGER,piece TEXT,next_instance_id TEXT)',
            'CREATE TABLE pieces(piece TEXT PRIMARY KEY)',
            'CREATE TABLE unlocks(level INTEGER PRIMARY KEY)',
            'CREATE TABLE daily_stamps(puzzle_date TEXT PRIMARY KEY)',
            'CREATE TABLE settings(key TEXT PRIMARY KEY,value INTEGER NOT NULL)',
            'CREATE TABLE revealed_pieces(piece TEXT PRIMARY KEY)',
          ]) {
            await db.execute(sql);
          }
        },
      ),
    );
    for (final state in [s, daily()]) {
      await old.insert('active_slots', {
        'slot': state.slot,
        'payload': jsonEncode(state.toJson()),
        'backup_payload': jsonEncode(state.toJson()),
      });
    }
    await old.insert('settings', {'key': 'music', 'value': 0});
    await old.insert('first_completions', {
      'puzzle_id': 'main-004',
      'main_level': 4,
    });
    await old.insert('pieces', {'piece': 'color_studio:1'});
    await old.insert('unlocks', {'level': 5});
    await old.insert('metadata', {
      'key': 'first_clears_since_interstitial',
      'value': 2,
    });
    await old.insert('metadata', {'key': 'tutorial_done', 'value': 1});
    await old.insert('receipts', {
      'instance_id': 'legacy-done',
      'completion_id': 'completion:legacy-done',
      'puzzle_id': 'main-004',
      'first_clear': 1,
      'piece': 'color_studio:1',
    });
    await old.close();
    final store = await GameStore.open(path, factory: databaseFactoryFfi);
    try {
      expect(await store.db.getVersion(), 5);
      expect((await store.load('ordinary')).instance!.toJson(), s.toJson());
      expect((await store.load('daily')).instance!.toJson(), daily().toJson());
      expect((await store.readSettings()).music, isFalse);
      expect((await store.progress()).qualifyingClears, 2);
      expect((await store.progress()).pieces, ['color_studio:1']);
      expect((await store.progress()).receipts, 1);
      final tables = (await store.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((r) => r['name']);
      expect(
        tables,
        containsAll([
          'reward_attempts',
          'reward_entitlements',
          'fullscreen_shows',
          'service_values',
          'service_events',
        ]),
      );
    } finally {
      await store.close();
      d.deleteSync(recursive: true);
    }
  });
}
