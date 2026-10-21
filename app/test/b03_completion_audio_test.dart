import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture, sample;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late GameController c;
  late List<
    ({String? instance, String? receipt, SavePhase phase, GamePage page})
  >
  completions;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b03-completion-audio-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    completions = [];
    c = GameController(
      store,
      onFeedback: (event) {
        if (event == GameFeedback.complete) {
          completions.add((
            instance: c.current?.id,
            receipt: c.receipt?.instanceId,
            phase: c.phase,
            page: c.page,
          ));
        }
      },
    );
    await c.initialize();
    await c.start(fixture());
  });
  tearDown(() async {
    c.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> beforeLast({bool presenter = true, bool reduced = false}) async {
    if (presenter) c.attachMotionPresenter();
    if (reduced) await c.updateSetting('reduced_motion', true);
    final moves = c.current!.puzzle.referenceMoves;
    for (final move in moves.take(moves.length - 1)) {
      await c.pour(move.from, move.to);
      if (c.motion != null) c.completeMotion(c.motion!.token);
    }
    expect(completions, isEmpty);
  }

  Future<void> lastMove() {
    final move = c.current!.puzzle.referenceMoves.last;
    return c.pour(move.from, move.to);
  }

  Future<({Future<void> held, Completer<void> release})> holdDatabase() async {
    final entered = Completer<void>(), release = Completer<void>();
    final held = store.db.transaction((_) async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    return (held: held, release: release);
  }

  void expectSavedSound(String instance) {
    expect(completions, [
      (
        instance: instance,
        receipt: instance,
        phase: SavePhase.clean,
        page: GamePage.completion,
      ),
    ]);
  }

  for (final mode in ['normal', 'reduced', 'no-presenter']) {
    test('AC-11 $mode sound waits when final SQL outlasts motion', () async {
      await beforeLast(
        presenter: mode != 'no-presenter',
        reduced: mode == 'reduced',
      );
      final instance = c.current!.id;
      final block = await holdDatabase();
      final write = lastMove();
      final token = c.motion?.token;
      try {
        expect(c.phase, SavePhase.saving);
        if (token != null) {
          if (mode == 'reduced') expect(c.motion!.reducedMotion, isTrue);
          c.completeMotion(token);
          c.completeMotion(token);
        }
        expect(c.current!.completed, isTrue);
        expect(c.receipt, isNull);
        expect(completions, isEmpty);
      } finally {
        block.release.complete();
        await block.held;
        await write;
      }
      expectSavedSound(instance);
      if (token != null) c.completeMotion(token);
      await c.retry();
      c.resume();
      expectSavedSound(instance);
      expect((await store.progress()).receipts, 1);
      expect((await store.progress()).firstClears, 1);
    });
  }

  test(
    'AC-11 no presenter receipt rollback stays silent until Retry',
    () async {
      await beforeLast(presenter: false);
      final instance = c.current!.id;
      store.fault = (stage) {
        if (stage == 'receipt') throw StateError('disk full');
      };
      await lastMove();
      expect(c.phase, SavePhase.failed);
      expect(c.page, GamePage.completion);
      expect(c.receipt, isNull);
      expect((await store.progress()).firstClears, 0);
      expect(completions, isEmpty);
      store.fault = null;
      await c.retry();
      expectSavedSound(instance);
      await c.retry();
      expectSavedSound(instance);
      expect((await store.progress()).receipts, 1);
    },
  );

  test(
    'AC-11 successful Retry waits for remaining motion then emits once',
    () async {
      await beforeLast();
      final instance = c.current!.id;
      store.fault = (stage) {
        if (stage == 'receipt') throw StateError('disk full');
      };
      await lastMove();
      final token = c.motion!.token;
      expect(completions, isEmpty);
      store.fault = null;
      await c.retry();
      expect(c.phase, SavePhase.clean);
      expect(c.receipt!.instanceId, instance);
      expect(completions, isEmpty);
      c.completeMotion(token);
      c.completeMotion(token);
      expectSavedSound(instance);
      expect((await store.progress()).receipts, 1);
    },
  );

  test(
    'AC-11 saved final move waits for matching callback and ignores duplicates',
    () async {
      await beforeLast();
      final instance = c.current!.id;
      await lastMove();
      final token = c.motion!.token;
      expect(completions, isEmpty);
      c.completeMotion(token - 1);
      expect(c.motion!.token, token);
      expect(completions, isEmpty);
      c.completeMotion(token);
      c.completeMotion(token);
      c.setForeground(false);
      c.setForeground(true);
      expectSavedSound(instance);
    },
  );

  for (final timing in ['saving', 'saved', 'failed']) {
    test('AC-11 leaving $timing completion cancels pending sound', () async {
      await beforeLast();
      final block = timing == 'saving' ? await holdDatabase() : null;
      if (timing == 'failed') {
        store.fault = (stage) {
          if (stage == 'receipt') throw StateError('disk full');
        };
      }
      final write = lastMove();
      if (block == null) await write;
      final token = c.motion!.token;
      try {
        await c.goHome();
        c.completeMotion(token);
        expect(completions, isEmpty);
      } finally {
        if (block != null) {
          block.release.complete();
          await block.held;
          await write;
        }
        if (timing == 'failed') {
          store.fault = null;
          await c.retry();
        }
      }
      expect(c.page, GamePage.home);
      expect(c.phase, SavePhase.clean);
      expect(completions, isEmpty);
      c.resume();
      c.completeMotion(token);
      expect(completions, isEmpty);
      expect((await store.progress()).receipts, 1);
    });
  }

  for (final presenter in [true, false]) {
    test(
      'AC-11 background cancels delayed sound with presenter=$presenter',
      () async {
        await beforeLast(presenter: presenter);
        final block = await holdDatabase();
        final write = lastMove();
        try {
          c.setForeground(false);
          c.setForeground(true);
          expect(completions, isEmpty);
        } finally {
          block.release.complete();
          await block.held;
          await write;
        }
        expect(c.phase, SavePhase.clean);
        expect(completions, isEmpty);
        expect((await store.progress()).firstClears, 1);
      },
    );
  }

  test(
    'AC-11 old callback cannot sound for another current instance',
    () async {
      await beforeLast();
      await lastMove();
      final completed = c.current!;
      final token = c.motion!.token;
      c.current = sample('another-current-instance');
      c.completeMotion(token);
      expect(c.page, GamePage.board);
      expect(completions, isEmpty);
      c.current = completed;
      c.completeMotion(token);
      expect(completions, isEmpty);
      expect((await store.progress()).receipts, 1);
    },
  );
}
