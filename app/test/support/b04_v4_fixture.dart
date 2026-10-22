// Literal schema4 fixture reused by host ffi and native sqflite checks.
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:pourlune_core/pourlune_core.dart';

Future<void> writeLegacyV4(
  String path,
  DatabaseFactory factory, {
  required GameInstance active,
  required GameInstance pending,
  required GameInstance dailyState,
}) async {
  final old = await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 4,
      onCreate: (db, _) async {
        for (final sql in [
          'CREATE TABLE active_slots(slot TEXT PRIMARY KEY,payload TEXT NOT NULL,backup_payload TEXT)',
          'CREATE TABLE first_completions(puzzle_id TEXT PRIMARY KEY,main_level INTEGER NOT NULL)',
          'CREATE TABLE metadata(key TEXT PRIMARY KEY,value INTEGER NOT NULL)',
          'CREATE TABLE receipts(instance_id TEXT PRIMARY KEY,completion_id TEXT NOT NULL UNIQUE,puzzle_id TEXT NOT NULL,first_clear INTEGER NOT NULL,piece TEXT,next_instance_id TEXT)',
          'CREATE TABLE pieces(piece TEXT PRIMARY KEY)',
          'CREATE TABLE unlocks(level INTEGER PRIMARY KEY CHECK(level BETWEEN 1 AND 60))',
          'CREATE TABLE daily_stamps(puzzle_date TEXT PRIMARY KEY)',
          'CREATE TABLE settings(key TEXT PRIMARY KEY,value INTEGER NOT NULL CHECK(value IN(0,1)))',
          'CREATE TABLE revealed_pieces(piece TEXT PRIMARY KEY)',
          "CREATE TABLE reward_attempts(attempt_id TEXT PRIMARY KEY,instance_id TEXT NOT NULL,slot TEXT NOT NULL CHECK(slot IN ('ordinary','daily')),snapshot TEXT NOT NULL,status TEXT NOT NULL CHECK(status IN ('open','closed','unconfirmed','pending_restore','done')),confirmed INTEGER NOT NULL DEFAULT 0 CHECK(confirmed IN(0,1)))",
          "CREATE UNIQUE INDEX one_reward_intent_per_slot ON reward_attempts(slot) WHERE status IN ('open','unconfirmed')",
          'CREATE TABLE reward_entitlements(instance_id TEXT PRIMARY KEY,attempt_id TEXT NOT NULL)',
          "CREATE TABLE fullscreen_shows(show_id TEXT PRIMARY KEY,kind TEXT NOT NULL CHECK(kind IN ('interstitial','rewarded')),shown_at INTEGER NOT NULL)",
          'CREATE TABLE service_values(key TEXT PRIMARY KEY,value TEXT NOT NULL)',
          'CREATE TABLE service_events(event_id TEXT PRIMARY KEY)',
        ]) {
          await db.execute(sql);
        }
      },
    ),
  );
  for (final s in [active, dailyState]) {
    await old.insert('active_slots', {
      'slot': s.slot,
      'payload': jsonEncode(s.toJson()),
      'backup_payload': jsonEncode(s.toJson()),
    });
  }
  for (var n = 11; n <= 13; n++) {
    await old.insert('first_completions', {
      'puzzle_id': 'main-${n.toString().padLeft(3, '0')}',
      'main_level': n,
    });
  }
  await old.insert('metadata', {
    'key': 'first_clears_since_interstitial',
    'value': 2,
  });
  await old.insert('metadata', {'key': 'tutorial_done', 'value': 1});
  await old.insert('settings', {'key': 'music', 'value': 0});
  await old.insert('pieces', {'piece': 'color_studio:3'});
  await old.insert('revealed_pieces', {'piece': 'color_studio:3'});
  await old.insert('unlocks', {'level': 14});
  await old.insert('receipts', {
    'instance_id': 'legacy-done',
    'completion_id': 'completion:legacy-done',
    'puzzle_id': 'main-013',
    'first_clear': 1,
    'piece': null,
  });
  await old.insert('reward_attempts', {
    'attempt_id': 'legacy-pending',
    'instance_id': pending.id,
    'slot': 'ordinary',
    'snapshot': jsonEncode(pending.toJson()),
    'status': 'pending_restore',
    'confirmed': 1,
  });
  await old.insert('reward_entitlements', {
    'instance_id': pending.id,
    'attempt_id': 'legacy-pending',
  });
  await old.insert('fullscreen_shows', {
    'show_id': 'legacy-shown',
    'kind': 'interstitial',
    'shown_at': 1000000,
  });
  await old.insert('service_values', {
    'key': 'last_fullscreen_ms',
    'value': '1000000',
  });
  await old.insert('service_values', {
    'key': 'fullscreen_intent',
    'value': jsonEncode({'id': 'legacy-uncertain', 'kind': 'interstitial'}),
  });
  await old.insert('service_values', {
    'key': 'privacy_choices',
    'value': jsonEncode({'analytics': false, 'crash': true}),
  });
  await old.insert('service_events', {'event_id': 'legacy-event'});
  await old.close();
}
