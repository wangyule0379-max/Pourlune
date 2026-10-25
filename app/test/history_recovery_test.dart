import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, finish, daily;

Map<String, Object?> progressValues(LocalProgress p) => {
  'first': p.firstClears,
  'pieces': p.pieces,
  'unlocks': p.unlockedLevels,
  'counter': p.qualifyingClears,
  'receipts': p.receipts,
  'stamps': p.dailyStamps,
};
String damagedHistory(GameInstance s, String kind) {
  final m = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
  (m['undo_history'] as List<dynamic>)[0]['board'] = kind == 'won'
      ? <List<String>>[
          ['O', 'O', 'O', 'O'],
          ['G', 'G', 'G', 'G'],
          [],
          [],
        ]
      : s.board;
  return jsonEncode(m);
}

void main() {
  sqfliteFfiInit();
  for (final kind in ['won', 'wrong-origin']) {
    for (final backupValid in [true, false]) {
      test(
        'B01-R01 $kind history / valid backup $backupValid never awards on Undo and isolates other records',
        () async {
          final dir = Directory.systemTemp.createTempSync('history-recovery-');
          final path = '${dir.path}/history.db';
          var store = await GameStore.open(path, factory: databaseFactoryFfi);
          GameController? c;
          try {
            // Make erroneous main-012 completion observable in pieces AND the post-ten counter.
            for (var i = 1; i <= 10; i++) {
              await store.settle(
                finish(sample('prior-$i', level: i)),
                replace: true,
              );
            }
            final dailyState = daily().pour(0, 2).state;
            await store.save(dailyState);
            final initial = sample('corrupt-main-012', level: 12),
                one = initial.pour(0, 2).state;
            await store.save(initial, replace: true);
            await store.save(one);
            final before = progressValues(await store.progress());
            final bad = damagedHistory(one, kind);
            await store.db.update(
              'active_slots',
              {'payload': bad, if (!backupValid) 'backup_payload': bad},
              where: 'slot = ?',
              whereArgs: ['ordinary'],
            );
            await store.close();
            store = await GameStore.open(path, factory: databaseFactoryFfi);
            final loaded = await store.load('ordinary');
            c = GameController(store);
            await c.initialize();
            c.resume();
            await c.undo();
            expect(
              {
                'recovered': loaded.recovered,
                'unavailable': loaded.unavailable,
                'active': c.current?.toJson(),
                'receipt': c.receipt?.toJson(),
                'progress': progressValues(await store.progress()),
                'daily': (await store.load('daily')).instance!.toJson(),
              },
              {
                'recovered': backupValid,
                'unavailable': !backupValid,
                'active': backupValid ? initial.toJson() : null,
                'receipt': null,
                'progress': before,
                'daily': dailyState.toJson(),
              },
            );
            expect(c.recoveryNotice, isNotNull);
            if (backupValid) {
              // First normal action replaces the rejected primary using the valid backup.
              await c.pour(0, 2);
              expect(c.current!.completed, isFalse);
              expect((await store.load('ordinary')).recovered, isFalse);
              expect(
                (await store.load('ordinary')).instance!.toJson(),
                one.toJson(),
              );
            }
            expect(progressValues(await store.progress()), before);
          } finally {
            c?.dispose();
            await store.close();
            dir.deleteSync(recursive: true);
          }
        },
      );
    }
  }
}
