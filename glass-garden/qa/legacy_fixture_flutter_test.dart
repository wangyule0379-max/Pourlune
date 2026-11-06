// Host-only fixture made by the unchanged old GameStore/core. No device, SDK or
// old app files are changed; the generated database belongs solely to this QA.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('create nonempty old60 schema5 with real moves, undo, receipts, daily and explicit settings', () async {
    sqfliteFfiInit();
    final directory = Directory('../glass-garden/build/legacy-fixture-2')
        .absolute;
    expect(
      directory.existsSync(),
      isFalse,
      reason: 'Frozen fixtures are never overwritten',
    );
    directory.createSync();
    final path = directory.path + '/pourlune_dev.sqlite';
    final store = await GameStore.open(path, factory: databaseFactoryFfi);
    try {
      Puzzle main(int n) => Puzzle.parse(
        File(
          'assets/puzzles/main/main-' + n.toString().padLeft(3, '0') + '.json',
        ).readAsStringSync(),
      );
      String? previous;
      for (var n = 1; n <= 20; n++) {
        var round = GameInstance.create(
          id: 'legacy-migration-main-' + n.toString(),
          puzzle: main(n),
        );
        await store.save(round, replace: true, afterCompletion: previous);
        for (final move in round.puzzle.referenceMoves) {
          round = round.pour(move.from, move.to).state;
        }
        expect(round.completed, isTrue);
        await store.settle(round);
        previous = round.id;
      }
      var active = GameInstance.create(
        id: 'legacy-migration-main-21',
        puzzle: main(21),
      );
      await store.save(active, replace: true, afterCompletion: previous);
      for (final move in active.puzzle.referenceMoves.take(2)) {
        active = active.pour(move.from, move.to).state;
        await store.save(active);
      }
      await store.beginReward('legacy-migration-reward-21', active);
      await store.confirmReward('legacy-migration-reward-21');
      final old = (await store.load('ordinary')).instance!;
      expect(old.extraBottleGranted, isTrue);
      expect(old.undo().undo().board, [...old.puzzle.initial, <String>[]]);
      final daily = GameInstance.create(
        id: 'legacy-migration-daily-13',
        slot: 'daily',
        puzzle: Puzzle.parse(
          File('assets/puzzles/daily/daily-013.json').readAsStringSync(),
        ),
        puzzleDate: '2026-11-06',
        timeZone: 'UTC',
        offsetMinutes: 0,
        catalogVersion: 1,
      );
      await store.save(daily);
      await store.saveSettings(
        const PlayerSettings(
          sound: false,
          music: true,
          haptics: true,
          reducedMotion: true,
          colorSymbols: false,
          strongContrast: true,
        ),
      );
      await store.writeServiceValue('privacy_choices', {
        'analytics': false,
        'crash': true,
      });
      await store.writeServiceValue(
        'last_fullscreen_ms',
        DateTime.now().millisecondsSinceEpoch - 60000,
      );
      expect(
        (await store.progress()).completedLevels,
        List.generate(20, (i) => i + 1),
      );
      expect(await store.db.query('reward_entitlements'), hasLength(1));
      expect((await store.readSettings()).sound, isFalse);
    } finally {
      await store.close();
    }
    expect(File(path).lengthSync(), greaterThan(0));
  });
}
