import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/fixtures/legacy13_fixture.dart';

void main() {
  sqfliteFfiInit();
  test(
    'original13 nonempty SQLite survives latest actions and reopen',
    () async {
      final directory = Directory.systemTemp.createTempSync('legacy13-compat-');
      final file = File('${directory.path}/legacy13.sqlite');
      file.writeAsBytesSync(legacy13FixtureBytes());
      var store = await GameStore.open(file.path, factory: databaseFactoryFfi);
      try {
        expect(await store.db.getVersion(), 5);
        expect((await store.progress()).completedLevels, [1, 2, 3]);
        expect((await store.readSettings()).music, isFalse);
        expect(await store.readServiceValue('privacy_choices'), {
          'analytics': false,
          'crash': false,
        });
        var active = (await store.load('ordinary')).instance!;
        expect(active.id, 'legacy13-fixture-main4');
        expect(active.puzzle.id, 'main-004');
        expect(active.puzzle.contentVersion, 2);
        expect(active.moveCount, 2);
        expect(active.board, [
          ['G', 'O', 'O'],
          ['O', 'G', 'O'],
          ['G', 'G'],
          <String>[],
          <String>[],
        ]);
        expect(active.extraBottleGranted, isTrue);
        final originalDefinition = active.puzzle.toJson();
        active = active.undo();
        expect(active.moveCount, 1);
        await store.save(active);
        await store.close();
        store = await GameStore.open(file.path, factory: databaseFactoryFfi);
        expect(
          (await store.load('ordinary')).instance!.toJson(),
          active.toJson(),
        );
        active = active.restart();
        expect(active.extraBottleGranted, isTrue);
        expect(active.board, [...active.puzzle.initial, <String>[]]);
        final move = active.puzzle.referenceMoves.first;
        active = active.pour(move.from, move.to).state;
        await store.save(active);
        await store.close();
        store = await GameStore.open(file.path, factory: databaseFactoryFfi);
        expect(
          (await store.load('ordinary')).instance!.toJson(),
          active.toJson(),
        );
        expect(active.puzzle.toJson(), originalDefinition);
        expect((await store.progress()).firstClears, 3);
        expect((await store.readSettings()).music, isFalse);
        expect(await store.db.query('reward_attempts'), isEmpty);
        expect(await store.db.query('reward_entitlements'), [
          {'instance_id': active.id, 'attempt_id': 'direct:${active.id}'},
        ]);
        // A repeated extra request cannot create another bottle or receipt.
        expect(
          (await store.grantDirectExtraBottle(active)).toJson(),
          active.toJson(),
        );
        expect(await store.db.query('reward_entitlements'), hasLength(1));
      } finally {
        await store.close();
        directory.deleteSync(recursive: true);
      }
    },
  );
}
