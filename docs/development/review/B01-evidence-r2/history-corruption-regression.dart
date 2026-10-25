import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test('review reproduction: corrupt undo frame restores backup and cannot settle on undo', () async {
    final dir = Directory.systemTemp.createTempSync('pourlune-review-');
    final store = await GameStore.open('${dir.path}/review.db', factory: databaseFactoryFfi);
    try {
      final puzzle = Puzzle.parse(File('assets/fixtures/main-001.reference.json').readAsStringSync());
      final initial = GameInstance.create(id: 'history-corrupt', puzzle: puzzle);
      await store.save(initial);
      final one = initial.pour(0, 2).state;
      await store.save(one);
      final data = jsonDecode(jsonEncode(one.toJson())) as Map<String, dynamic>;
      data['undo_history'][0]['board'] = [
        ['O', 'O', 'O', 'O'], ['G', 'G', 'G', 'G'], <String>[], <String>[]
      ];
      await store.db.update('active_slots', {'payload': jsonEncode(data)}, where: 'slot = ?', whereArgs: ['ordinary']);
      final loaded = await store.load('ordinary');
      expect(loaded.recovered, true);
      final c = GameController(store);
      await c.initialize();
      c.resume();
      await c.undo();
      expect(c.current!.completed, false);
      expect(c.current!.moveCount, 0);
      expect(c.receipt, isNull);
      expect((await store.progress()).firstClears, 0);
      print('VERIFIED: malformed history rejected; valid backup restored; Undo cannot award a false completion.');
      c.dispose();
    } finally {
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
