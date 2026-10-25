// Explicit QA state preparation, never imported by the production entrypoint.
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/support/b05_support.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('prepare normal-entry daily final move and no-moves QA states', (
    t,
  ) async {
    final output = Platform.environment['POURLUNE_NORMAL_QA_OUTPUT'];
    if (output == null ||
        !output.startsWith('/Volumes/data/App Development/Pourlune/build/') ||
        Directory(output).existsSync()) {
      throw StateError('Fresh explicit QA output required');
    }
    Directory(output).createSync(recursive: true);
    final library = (await t.runAsync(b05Library))!;
    final store = (await t.runAsync(
      () => GameStore.open('$output/daily.sqlite', factory: databaseFactoryFfi),
    ))!;
    final c = GameController(
      store,
      library: library,
      clock: () => LocalDay('2026-10-25', 'Asia/Taipei', 480),
    );
    try {
      await t.runAsync(() async {
        await c.initialize();
        await c.startToday();
        final moves = c.current!.puzzle.referenceMoves;
        for (final m in moves.take(moves.length - 1)) {
          await c.pour(m.from, m.to);
        }
        File('$output/daily-last-move.json').writeAsStringSync(
          jsonEncode({
            'from': moves.last.from,
            'to': moves.last.to,
            'puzzle': c.current!.puzzle.id,
            'snapshot': c.current!.toJson(),
          }),
        );
      });
      expect(c.current!.completed, false);
    } finally {
      c.dispose();
      await t.runAsync(store.close);
    }
    final deadStore = (await t.runAsync(
      () => GameStore.open(
        '$output/no-moves.sqlite',
        factory: databaseFactoryFfi,
      ),
    ))!;
    try {
      final p = Puzzle.parse(
        File('assets/fixtures/main-012.reference.json').readAsStringSync(),
      );
      final raw = GameInstance.create(id: 'parent-no-moves', puzzle: p).toJson()
        ..['board'] = [
          ['O', 'O', 'O', 'P'],
          ['G', 'G', 'G', 'P'],
          ['B', 'B', 'P', 'P'],
          ['O'],
          ['G'],
          ['B', 'B'],
        ]
        ..['board_revision'] = 1;
      await t.runAsync(() async {
        await deadStore.save(GameInstance.fromJson(raw));
      });
    } finally {
      await t.runAsync(deadStore.close);
    }
  });
}
