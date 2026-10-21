import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:sqflite/sqflite.dart';

Map<String, Object?> progressValues(LocalProgress p) => {
  'first': p.firstClears,
  'pieces': p.pieces,
  'unlocks': p.unlockedLevels,
  'counter': p.qualifyingClears,
  'receipts': p.receipts,
  'stamps': p.dailyStamps,
};
GameInstance finish(GameInstance s) {
  for (final m in s.puzzle.referenceMoves) {
    s = s.pour(m.from, m.to).state;
  }
  return s;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in ['won', 'wrong-origin']) {
    testWidgets(
      'B01-R01 native SQLite $kind history recovery and local unavailability',
      (t) async {
        final path =
            '${await getDatabasesPath()}/b01_r01_${DateTime.now().microsecondsSinceEpoch}.sqlite';
        var store = await GameStore.open(path);
        GameController? controller;
        try {
          final original = Puzzle.parse(
            await rootBundle.loadString(
              'assets/fixtures/main-001.reference.json',
            ),
          );
          for (var level = 1; level <= 10; level++) {
            final p = Puzzle.fromJson(
              original.toJson()
                ..['puzzle_id'] = 'main-${level.toString().padLeft(3, '0')}'
                ..['main_level'] = level,
            );
            await store.settle(
              finish(GameInstance.create(id: 'previous-$level', puzzle: p)),
              replace: true,
            );
          }
          final dailyPuzzle = Puzzle.fromJson(
            original.toJson()
              ..['puzzle_id'] = 'daily-r01'
              ..['mode'] = 'daily'
              ..['main_level'] = null,
          );
          final daily = GameInstance.create(
            id: 'daily-r01',
            puzzle: dailyPuzzle,
            slot: 'daily',
            puzzleDate: '2026-10-22',
            timeZone: 'Asia/Taipei',
            offsetMinutes: 480,
            catalogVersion: 1,
          ).pour(0, 2).state;
          await store.save(daily);
          final p = Puzzle.fromJson(
            original.toJson()
              ..['puzzle_id'] = 'main-012'
              ..['main_level'] = 12,
          );
          final initial = GameInstance.create(
                id: 'native-r01-$kind',
                puzzle: p,
              ),
              one = initial.pour(0, 2).state;
          await store.save(initial, replace: true);
          await store.save(one);
          final baseline = progressValues(await store.progress());
          final corrupt =
              jsonDecode(jsonEncode(one.toJson())) as Map<String, dynamic>;
          (corrupt['undo_history'] as List<dynamic>).first['board'] =
              kind == 'won'
              ? <List<String>>[
                  ['O', 'O', 'O', 'O'],
                  ['G', 'G', 'G', 'G'],
                  [],
                  [],
                ]
              : one.board;
          final bad = jsonEncode(corrupt);
          await store.db.update(
            'active_slots',
            {'payload': bad},
            where: 'slot = ?',
            whereArgs: ['ordinary'],
          );
          await store.close();
          store = await GameStore.open(path);
          expect((await store.load('ordinary')).recovered, isTrue);
          controller = GameController(store);
          await controller.initialize();
          controller.resume();
          await t.pumpWidget(
            app.PourluneApp(controller: controller, puzzles: [p]),
          );
          await t.pumpAndSettle();
          expect(
            find.textContaining('Recovered the last valid local snapshot'),
            findsOneWidget,
          );
          expect(
            t.widget<OutlinedButton>(find.byKey(const Key('undo'))).onPressed,
            isNull,
          );
          await controller.undo();
          expect(controller.current!.toJson(), initial.toJson());
          expect(controller.receipt, isNull);
          expect(progressValues(await store.progress()), baseline);
          // Verify the recovered instance can continue and replace the damaged primary.
          await controller.pour(0, 2);
          await t.pumpAndSettle();
          expect(
            (await store.load('ordinary')).instance!.toJson(),
            one.toJson(),
          );
          await t.pumpWidget(const SizedBox());
          controller.dispose();
          controller = null;
          // Neither candidate valid: refuse only this slot, retain daily and all grants.
          await store.db.update(
            'active_slots',
            {'payload': bad, 'backup_payload': bad},
            where: 'slot = ?',
            whereArgs: ['ordinary'],
          );
          await store.close();
          store = await GameStore.open(path);
          controller = GameController(store);
          await controller.initialize();
          controller.resume();
          await controller.undo();
          expect((await store.load('ordinary')).unavailable, isTrue);
          expect(controller.current, isNull);
          expect(controller.receipt, isNull);
          await t.pumpWidget(
            app.PourluneApp(controller: controller, puzzles: [p]),
          );
          await t.pumpAndSettle();
          expect(
            find.textContaining('ordinary save is unreadable'),
            findsOneWidget,
          );
          expect(
            (await store.load('daily')).instance!.toJson(),
            daily.toJson(),
          );
          expect(progressValues(await store.progress()), baseline);
          debugPrint(
            'B01_R01_NATIVE_PASS: kind=$kind; backup recovered; Undo grants unchanged; both-invalid unavailable; daily intact; progress=$baseline',
          );
        } finally {
          await t.pumpWidget(const SizedBox());
          controller?.dispose();
          await store.close();
          await deleteDatabase(path);
        }
      },
    );
  }
}
