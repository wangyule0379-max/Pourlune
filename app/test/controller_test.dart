import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  test('AC-09 failed save retains current board; Retry commits same result then navigates once', () async {
    final dir = Directory.systemTemp.createTempSync('flow-');
    final store = await GameStore.open(
      '${dir.path}/a.db',
      factory: databaseFactoryFfi,
    );
    final c = GameController(store);
    await c.initialize();
    await c.start(fixture());
    store.fault = (s) {
      if (s == 'snapshot') throw StateError('full disk');
    };
    await c.pour(0, 2);
    final failed = c.current!;
    expect(c.phase, SavePhase.failed);
    expect(failed.moveCount, 1);
    await c.goHome();
    expect(c.page, GamePage.board);
    c.stayHere();
    expect(c.phase, SavePhase.failed);
    await c.pour(1, 0);
    expect(c.current!.moveCount, 2);
    expect(c.phase, SavePhase.failed);
    await c.goHome();
    store.fault = null;
    var departures = 0;
    c.addListener(() {
      if (c.page == GamePage.home) departures++;
    });
    await c.retry();
    expect(c.page, GamePage.home);
    expect(departures, 1);
    expect(
      (await store.load('ordinary')).instance!.toJson(),
      c.current!.toJson(),
    );
    await c.retry();
    expect(departures, 1);
    await store.close();
    c.dispose();
    dir.deleteSync(recursive: true);
  });
  test('completion failure grants nothing until Retry and repeated Retry is idempotent', () async {
    final dir = Directory.systemTemp.createTempSync('settle-flow-');
    final store = await GameStore.open(
      '${dir.path}/a.db',
      factory: databaseFactoryFfi,
    );
    final c = GameController(store);
    await c.initialize();
    await c.start(fixture());
    final moves = c.current!.puzzle.referenceMoves;
    for (final m in moves.take(moves.length - 1)) {
      await c.pour(m.from, m.to);
    }
    store.fault = (s) {
      if (s == 'receipt') throw StateError('commit fault');
    };
    await c.pour(moves.last.from, moves.last.to);
    expect(c.current!.completed, isTrue);
    expect(c.receipt, isNull);
    expect(c.phase, SavePhase.failed);
    expect((await store.progress()).firstClears, 0);
    store.fault = null;
    await c.retry();
    expect(c.receipt!.firstClear, isTrue);
    await c.retry();
    expect((await store.progress()).firstClears, 1);
    await store.close();
    c.dispose();
    dir.deleteSync(recursive: true);
  });
  test('failed replacement freezes the old board until the same candidate is committed', () async {
    final dir = Directory.systemTemp.createTempSync('replace-flow-');
    final store = await GameStore.open(
      '${dir.path}/a.db',
      factory: databaseFactoryFfi,
    );
    final c = GameController(store);
    await c.initialize();
    await c.start(fixture());
    final old = c.current!;
    await c.goHome();
    store.fault = (s) {
      if (s == 'snapshot') throw StateError('disk full');
    };
    await c.start(fixture(12), replace: true);
    expect((await store.load('ordinary')).instance!.id, old.id);
    c.resume();
    await c.pour(0, 2);
    expect(c.page, GamePage.home);
    expect(c.current!.toJson(), old.toJson());
    store.fault = null;
    await c.retry();
    expect(c.current!.puzzle.mainLevel, 12);
    expect(c.page, GamePage.board);
    await store.close();
    c.dispose();
    dir.deleteSync(recursive: true);
  });
}
