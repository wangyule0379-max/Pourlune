// Creates a fresh host-only QA database for the normal main/Bootstrap.
// Settled levels1–20 are fixtures, not human play evidence.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test('prepare only a fresh explicitly named optimization QA database', () async {
    final output = Platform.environment['POURLUNE_OPTIMIZATION_QA_OUTPUT'];
    if (output == null ||
        !output.startsWith(
          '/Volumes/data/App Development/Pourlune/build/optimization-20261028/',
        ) ||
        File(output).existsSync()) {
      throw StateError('Fresh isolated build output required');
    }
    final store = await GameStore.open(output, factory: databaseFactoryFfi);
    try {
      for (var n = 1; n <= 21; n++) {
        final p = Puzzle.parse(
          File('assets/puzzles/main/main-${n.toString().padLeft(3, '0')}.json')
              .readAsStringSync(),
        );
        var state = GameInstance.create(id: 'optimization-qa-$n', puzzle: p);
        if (n <= 20) {
          for (final m in p.referenceMoves) {
            state = state.pour(m.from, m.to).state;
          }
          await store.settle(state, replace: true);
        } else {
          await store.save(state, replace: true);
        }
      }
      expect((await store.progress()).firstClears, 20);
      expect((await store.load('ordinary')).instance!.board.length, 7);
    } finally {
      await store.close();
    }
  });
}
