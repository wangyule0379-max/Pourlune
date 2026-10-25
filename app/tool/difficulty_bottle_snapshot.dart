// Offline QA preparation only; the normal main/Bootstrap opens this named copy.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test(
    'prepare a new isolated level20 QA database using real settlements',
    () async {
      final output = Platform.environment['POURLUNE_DIFFICULTY_QA_OUTPUT'];
      if (output == null ||
          !output.startsWith('/Volumes/data/App Development/Pourlune/build/') ||
          File(output).existsSync()) {
        throw StateError('Fresh explicit QA output required');
      }
      final store = await GameStore.open(output, factory: databaseFactoryFfi);
      try {
        for (var n = 1; n <= 20; n++) {
          final p = Puzzle.parse(
            File(
              'assets/puzzles/main/main-${n.toString().padLeft(3, '0')}.json',
            ).readAsStringSync(),
          );
          var s = GameInstance.create(id: 'difficulty-v3-qa-$n', puzzle: p);
          if (n < 20) {
            for (final m in p.referenceMoves) {
              s = s.pour(m.from, m.to).state;
            }
            await store.settle(s, replace: true);
          } else {
            await store.save(s, replace: true);
          }
        }
        expect((await store.progress()).firstClears, 19);
        expect(
          (await store.load('ordinary')).instance!.extraBottleGranted,
          false,
        );
      } finally {
        await store.close();
      }
    },
  );
}
