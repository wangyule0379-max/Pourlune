import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late GameController c;
  late List<GameFeedback> feedback;
  late List<Completer<HintResult>> hints;
  var writes = 0, cancelled = 0;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('tap-reselect-');
    store = await GameStore.open(
      '${dir.path}/qa.db',
      factory: databaseFactoryFfi,
    );
    feedback = [];
    hints = [];
    writes = cancelled = 0;
    c = GameController(
      store,
      onFeedback: feedback.add,
      hintLauncher: (_) {
        final response = Completer<HintResult>();
        hints.add(response);
        return (
          result: response.future,
          cancel: () => cancelled++,
          released: Future<void>.value(),
        );
      },
    );
    await store.save(GameInstance.create(id: 'tap', puzzle: fixture(12)));
    await c.initialize();
    await c.resumeSlot('ordinary');
    store.fault = (stage) {
      if (stage == 'snapshot') writes++;
    };
  });
  tearDown(() async {
    c.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'full target reselects without rejection, state or snapshot effects',
    () async {
      final before = c.current!;
      await c.tapBottle(0);
      await c.tapBottle(1);
      expect(c.selectedSource, 1);
      expect(c.current, same(before));
      expect(c.rejection, isNull);
      expect(c.rejectedBottle, isNull);
      expect(c.motion, isNull);
      expect(writes, 0);
      expect(feedback, [GameFeedback.select, GameFeedback.select]);
      expect(
        (await store.load('ordinary')).instance!.toJson(),
        before.toJson(),
      );
      await c.tapBottle(1);
      expect(c.selectedSource, isNull);
      await c.tapBottle(3);
      await c.tapBottle(-1);
      await c.tapBottle(99);
      expect(c.selectedSource, isNull);
      expect(c.current, same(before));
      expect(writes, 0);
    },
  );

  test(
    'mismatch reselects then the next legal tap commits exactly once',
    () async {
      await c.pour(0, 2); // O2 into empty buffer; source1 still topped G.
      final before = c.current!;
      writes = 0;
      feedback.clear();
      await c.tapBottle(1);
      await c.tapBottle(2);
      expect(c.selectedSource, 2);
      expect(c.current, same(before));
      expect(c.rejection, isNull);
      expect(writes, 0);
      expect(feedback, [GameFeedback.select, GameFeedback.select]);
      await c.tapBottle(3);
      expect(c.current!.moveCount, before.moveCount + 1);
      expect(c.current!.revision, before.revision + 1);
      expect(c.current!.history.length, before.history.length + 1);
      expect(c.current!.board[2], isEmpty);
      expect(c.current!.board[3], ['O', 'O']);
      expect(writes, 1);
      expect(feedback.where((f) => f == GameFeedback.pour), hasLength(1));
      expect(
        (await store.load('ordinary')).instance!.toJson(),
        c.current!.toJson(),
      );
      await c.undo();
      expect(c.current!.board, before.board);
      expect(c.current!.moveCount, before.moveCount);
    },
  );

  test('manual reselect clears a found Hint and its source', () async {
    final pending = c.requestHint();
    hints.single.complete(
      const HintResult(HintStatus.found, move: PourMove(0, 2)),
    );
    await pending;
    expect(c.selectedSource, 0);
    expect(c.hint, isNotNull);
    await c.tapBottle(1);
    expect(c.selectedSource, 1);
    expect(c.hint, isNull);
    expect(c.hintSearching, isFalse);
    expect(c.rejection, isNull);
    expect(writes, 0);
  });

  test('cancelled Hint arriving late cannot steal manual reselect', () async {
    final pending = c.requestHint();
    expect(c.hintSearching, isTrue);
    await c.tapBottle(0);
    await c.tapBottle(1);
    expect(c.selectedSource, 1);
    expect(cancelled, 1);
    hints.single.complete(
      const HintResult(HintStatus.found, move: PourMove(0, 2)),
    );
    await pending;
    expect(c.selectedSource, 1);
    expect(c.hint, isNull);
    expect(c.current!.moveCount, 0);
    expect(writes, 0);
  });

  test('active pour lock cannot be bypassed by reselect', () async {
    c.attachMotionPresenter();
    await c.tapBottle(0);
    await c.tapBottle(2);
    expect(c.motion, isNotNull);
    final before = c.current!;
    final saved = writes;
    await c.tapBottle(1);
    expect(c.selectedSource, isNull);
    expect(c.current, same(before));
    expect(writes, saved);
    c.detachMotionPresenter();
  });

  test(
    'guided rejection remains a real constraint instead of reselect',
    () async {
      c.dispose();
      await store.save(
        GameInstance.create(id: 'guided', puzzle: fixture(), tutorial: true),
        replace: true,
      );
      c = GameController(store);
      await c.initialize();
      await c.resumeSlot('ordinary');
      final before = c.current!;
      writes = 0;
      await c.tapBottle(0);
      await c.tapBottle(1);
      expect(c.selectedSource, 0);
      expect(c.rejection, 'Follow the guided pour or Skip');
      expect(c.current, same(before));
      expect(writes, 0);
      await c.tapBottle(2);
      expect(c.current!.moveCount, 1);
      expect(c.current!.tutorial!.step, 1);
    },
  );

  test(
    'reselect preserves a pending snapshot failure and recovery state',
    () async {
      store.fault = (stage) {
        if (stage == 'snapshot') throw StateError('full disk');
      };
      await c.pour(0, 2);
      expect(c.phase, SavePhase.failed);
      final before = c.current!, notice = c.notice;
      await c.tapBottle(0);
      await c.tapBottle(1);
      expect(c.selectedSource, 1);
      expect(c.current, same(before));
      expect(c.phase, SavePhase.failed);
      expect(c.notice, notice);
      expect(c.rejection, isNull);
    },
  );
}
