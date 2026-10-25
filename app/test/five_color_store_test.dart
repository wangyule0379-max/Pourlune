import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test('five-color direct grant rollback Retry eighth pour Undo Restart and reopen are atomic', () async {
    final dir = Directory.systemTemp.createTempSync('pourlune-five-color-');
    var store = await GameStore.open(
      '${dir.path}/main60_five_color.sqlite',
      factory: databaseFactoryFfi,
    );
    var c = GameController(store);
    try {
      await c.initialize();
      final p = Puzzle.parse(
        File('assets/puzzles/main/main-021.json').readAsStringSync(),
      );
      await c.start(p);
      final before = c.current!.toJson();
      store.fault = (stage) {
        if (stage == 'reward_grant') {
          throw StateError('controlled transaction failure');
        }
      };
      await c.watchExtraBottle();
      expect(c.phase, SavePhase.failed);
      expect(c.current!.toJson(), before);
      expect((await store.load('ordinary')).instance!.toJson(), before);
      expect(await store.db.query('reward_entitlements'), isEmpty);
      store.fault = null;
      await c.retry();
      expect(c.phase, SavePhase.clean);
      expect(c.current!.board, hasLength(8));
      await c.watchExtraBottle();
      expect(await store.db.query('reward_entitlements'), hasLength(1));
      for (final table in [
        'reward_attempts',
        'fullscreen_attempts',
        'fullscreen_shows',
      ]) {
        expect(await store.db.query(table), isEmpty);
      }
      await c.pour(0, 7);
      expect(c.current!.board[7], isNotEmpty);
      final saved = c.current!.toJson();
      c.dispose();
      await store.close();
      store = await GameStore.open(
        '${dir.path}/main60_five_color.sqlite',
        factory: databaseFactoryFfi,
      );
      c = GameController(store);
      await c.initialize();
      c.resume();
      expect(c.current!.toJson(), saved);
      await c.undo();
      expect(c.current!.board, [...p.initial, <String>[]]);
      expect(c.current!.extraBottleGranted, isTrue);
      await c.restart();
      expect(c.current!.board, [...p.initial, <String>[]]);
      for (final move in p.referenceMoves) {
        await c.pour(move.from, move.to);
      }
      expect(c.current!.completed, isTrue);
      expect(c.receipt!.firstClear, isTrue);
      final progress = await store.progress();
      await c.start(p, replay: true, replace: true);
      for (final move in p.referenceMoves) {
        await c.pour(move.from, move.to);
      }
      expect(c.receipt!.firstClear, isFalse);
      final repeated = await store.progress();
      expect(repeated.firstClears, progress.firstClears);
      expect(repeated.pieces, progress.pieces);
      expect(repeated.qualifyingClears, progress.qualifyingClears);
    } finally {
      c.dispose();
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
