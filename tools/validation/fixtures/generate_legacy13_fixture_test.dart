import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'original13 store serializes nonempty explicit compatibility fixture',
    () async {
      final output = Platform.environment['POURLUNE_LEGACY13_OUTPUT']!;
      expect(File(output).existsSync(), isFalse);
      final store = await GameStore.open(output, factory: databaseFactoryFfi);
      Puzzle puzzle(int n) => Puzzle.parse(
        File('assets/puzzles/main/main-${n.toString().padLeft(3, '0')}.json')
            .readAsStringSync(),
      );
      for (var n = 1; n <= 3; n++) {
        var value = GameInstance.create(
          id: 'legacy13-fixture-clear-$n',
          puzzle: puzzle(n),
        );
        for (final move in value.puzzle.referenceMoves) {
          value = value.pour(move.from, move.to).state;
        }
        expect(value.completed, isTrue);
        await store.settle(value, replace: true);
      }
      var active = GameInstance.create(
        id: 'legacy13-fixture-main4',
        puzzle: puzzle(4),
      );
      for (final move in active.puzzle.referenceMoves.take(2)) {
        active = active.pour(move.from, move.to).state;
      }
      expect(active.completed, isFalse);
      expect(active.moveCount, 2);
      await store.save(active, replace: true);
      active = await store.grantDirectExtraBottle(active);
      expect(active.extraBottleGranted, isTrue);
      await store.saveSettings(const PlayerSettings(music: false));
      await store.writeServiceValue('privacy_choices', {
        'analytics': false,
        'crash': false,
      });
      expect((await store.progress()).firstClears, 3);
      expect(
        (await store.load('ordinary')).instance!.toJson(),
        active.toJson(),
      );
      await store.close();
      // Pure local synthetic data; no device, SDK client, or network was used.
    },
  );
}
