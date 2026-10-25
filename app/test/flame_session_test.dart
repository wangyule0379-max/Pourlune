import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/development/flame_sample/session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test('all projected fixtures keep four legal bottles and have a winning reference', () {
    for (var u = 1; u <= 4; u++) {
      final p = pourFixture(u);
      var s = GameInstance.create(id: 'qa-$u', puzzle: p, isReplay: true);
      expect(s.completed, isFalse);
      expect(s.board.length, 4);
      final first = s.pour(0, 2);
      expect(first.units, u);
      for (final move in p.referenceMoves) {
        final r = s.pour(move.from, move.to);
        expect(r.changed, isTrue);
        s = r.state;
      }
      expect(s.completed, isTrue);
    }
  });
  test('one accepted sample pour survives cancellation/reopen without a second write or award', () async {
    final dir = Directory.systemTemp.createTempSync('flame-session-');
    final store = await GameStore.open(
      '${dir.path}/sample.sqlite',
      factory: databaseFactoryFfi,
    );
    final c = GameController(store);
    try {
      await c.initialize();
      await c.start(pourFixture(3), replay: true);
      c.attachMotionPresenter();
      await c.pour(0, 2);
      final token = c.motion!.token, state = c.current!.toJson();
      await c.pour(0, 2);
      expect(c.current!.toJson(), state);
      c.setForeground(false);
      expect(c.motion, isNull);
      c.setForeground(true);
      await c.restart();
      await c.pour(0, 2);
      final newToken = c.motion!.token;
      c.completeMotion(token);
      expect(c.motion!.token, newToken);
      final persisted = (await store.load('ordinary')).instance!;
      expect(persisted.toJson(), c.current!.toJson());
      expect((await store.progress()).pieces, isEmpty);
      expect((await store.progress()).firstClears, 0);
      c.completeMotion(newToken);
      c.detachMotionPresenter();
      final other = await GameStore.open(
        store.db.path,
        factory: databaseFactoryFfi,
      );
      final restored = GameController(other);
      try {
        await restored.initialize();
        expect(restored.current!.toJson(), persisted.toJson());
        expect(restored.motion, isNull);
      } finally {
        restored.dispose();
        await other.close();
      }
    } finally {
      c.dispose();
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
