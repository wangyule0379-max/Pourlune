// Copy to app/test/b03_review_audio_test.dart and run from app/.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  test('AC-11 completion sound waits for successful settlement', () async {
    final dir = Directory.systemTemp.createTempSync('b03-review-audio-');
    final store = await GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi);
    final feedback = <GameFeedback>[];
    final c = GameController(store, onFeedback: feedback.add);
    try {
      await c.initialize();
      final puzzle = fixture();
      await c.start(puzzle);
      c.attachMotionPresenter();
      for (final move in puzzle.referenceMoves.take(puzzle.referenceMoves.length - 1)) {
        await c.pour(move.from, move.to);
        c.completeMotion(c.motion!.token);
      }
      feedback.clear();
      store.fault = (stage) { if (stage == 'receipt') throw StateError('disk full'); };
      final last = puzzle.referenceMoves.last;
      await c.pour(last.from, last.to);
      expect(c.phase, SavePhase.failed);
      c.completeMotion(c.motion!.token);
      expect(c.receipt, isNull);
      expect((await store.progress()).firstClears, 0);
      expect(feedback.where((e) => e == GameFeedback.complete), isEmpty,
          reason: 'Failed receipt transaction must not play saved-success feedback');
      store.fault = null;
      await c.retry();
      expect(feedback.where((e) => e == GameFeedback.complete), hasLength(1));
    } finally {
      c.dispose();
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
