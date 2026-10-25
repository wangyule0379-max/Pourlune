import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Puzzle definition(int n, {bool old = false}) => Puzzle.parse(
  File(
    '${old ? '../docs/development/evidence/main60-content-redesign/old-main' : 'assets/puzzles/main'}/main-${n.toString().padLeft(3, '0')}.json',
  ).readAsStringSync(),
);

GameInstance finished(GameInstance value) {
  for (final m in value.puzzle.referenceMoves) {
    value = value.pour(m.from, m.to).state;
  }
  expect(value.completed, isTrue);
  return value;
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pourlune-main60-v2-');
    store = await GameStore.open(
      '${dir.path}/upgrade.sqlite',
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await store.close();
    dir.deleteSync(recursive: true);
  });
  Future<void> reopen() async {
    await store.close();
    store = await GameStore.open(
      '${dir.path}/upgrade.sqlite',
      factory: databaseFactoryFfi,
    );
  }

  for (final level in [13, 21]) {
    test(
      'DC04 real SQLite old$level nonempty snapshot survives new content and reopen',
      () async {
        final old = definition(level, old: true), latest = definition(level);
        var active = GameInstance.create(id: 'old-$level', puzzle: old);
        for (final m in old.referenceMoves.take(2)) {
          active = active.pour(m.from, m.to).state;
        }
        active = active.grantExtraBottle();
        await store.save(active);
        final daily = GameInstance.create(
          id: 'old-daily',
          slot: 'daily',
          puzzle: Puzzle.parse(
            File('assets/puzzles/daily/daily-013.json').readAsStringSync(),
          ),
          puzzleDate: '2026-10-23',
          timeZone: 'Asia/Taipei',
          offsetMinutes: 480,
          catalogVersion: 1,
        );
        await store.save(daily);
        expect(latest.contentVersion, old.contentVersion + 1);
        expect(latest.initial, isNot(old.initial));
        await reopen();
        final restored = (await store.load('ordinary')).instance!;
        expect(restored.toJson(), active.toJson());
        expect(restored.undo().undo().board, [...old.initial, <String>[]]);
        expect(restored.restart().board, [...old.initial, <String>[]]);
        expect((await store.load('daily')).instance!.toJson(), daily.toJson());
        expect(
          solveHint(restored.puzzle, restored.board, extra: true).status,
          HintStatus.found,
        );
        final first = await store.settle(finished(restored.restart()));
        expect(first.firstClear, isTrue);
        final before = await store.progress();
        final replay = GameInstance.create(
          id: 'new-$level',
          puzzle: latest,
          isReplay: true,
        );
        await store.save(replay, replace: true);
        final second = await store.settle(finished(replay));
        expect(second.firstClear, isFalse);
        expect(second.piece, isNull);
        final after = await store.progress();
        expect(after.firstClears, before.firstClears);
        expect(after.pieces, before.pieces);
        expect(after.qualifyingClears, before.qualifyingClears);
      },
    );
  }

  test('DC04 real sixty-level completion has fifteen pieces and no version replay awards', () async {
    for (var level = 1; level <= 60; level++) {
      final state = GameInstance.create(
        id: 'v2-$level',
        puzzle: definition(level),
      );
      final receipt = await store.settle(finished(state), replace: true);
      expect(receipt.firstClear, isTrue);
      expect(receipt.piece != null, level % 4 == 0);
    }
    await reopen();
    final complete = await store.progress();
    expect(complete.firstClears, 60);
    expect(complete.completedLevels, hasLength(60));
    expect(complete.pieces.toSet(), hasLength(15));
    expect(complete.storyComplete, isTrue);
    expect(complete.nextUnfinished, isNull);
    for (final level in [4, 12, 20, 40, 60]) {
      final replay = GameInstance.create(
        id: 'again-$level',
        puzzle: definition(level),
        isReplay: true,
      );
      final receipt = await store.settle(finished(replay), replace: true);
      expect(receipt.firstClear, isFalse);
      expect(receipt.piece, isNull);
    }
    expect((await store.progress()).pieces, complete.pieces);
    expect(
      (await store.progress()).qualifyingClears,
      complete.qualifyingClears,
    );
  });
}
