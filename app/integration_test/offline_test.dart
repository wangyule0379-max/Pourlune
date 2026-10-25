import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:pourlune_dev/application/game_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native SQLite offline play, failure, settlement and cold-start preparation',
    (t) async {
      app.main();
      for (
        var i = 0;
        i < 300 && find.byType(app.GameScreen).evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(app.GameScreen), findsOneWidget);
      final c = t
          .widget<app.GameScreen>(find.byType(app.GameScreen))
          .controller;
      Future<void> tap(String key) async {
        final f = find.byKey(Key(key));
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pump(const Duration(milliseconds: 100));
        for (var i = 0; i < 300 && c.busy; i++) {
          await t.pump(const Duration(milliseconds: 30));
        }
        await t.pumpAndSettle();
        expect(c.busy, isFalse);
      }

      await tap('sample-main-001');
      if (find.byKey(const Key('confirm-replace')).evaluate().isNotEmpty) {
        await tap('confirm-replace');
      }
      await tap('bottle-0');
      await tap('bottle-2');
      expect(c.current!.moveCount, 1);
      await tap('undo');
      expect(c.current!.moveCount, 0);
      await tap('pause');
      await tap('resume-pause');
      await tap('fail-next');
      await tap('bottle-0');
      await tap('bottle-2');
      expect(c.phase, SavePhase.failed);
      await tap('home');
      expect(c.page, GamePage.board);
      await tap('stay');
      await tap('retry');
      expect(c.phase, SavePhase.clean);
      for (final m in c.current!.puzzle.referenceMoves.skip(1)) {
        await tap('bottle-${m.from}');
        await tap('bottle-${m.to}');
      }
      expect(c.current!.completed, isTrue);
      expect(c.receipt, isNotNull);
      final progress = await c.store.progress();
      expect(progress.firstClears, greaterThanOrEqualTo(1));
      await tap('home');
      await tap('development-tools');
      await tap('engineering-main-012');
      for (final m in c.current!.puzzle.referenceMoves.take(2)) {
        await tap('bottle-${m.from}');
        await tap('bottle-${m.to}');
      }
      expect(c.current!.moveCount, 2);
      expect(c.phase, SavePhase.clean);
      final stored = (await c.store.load('ordinary')).instance!;
      expect(stored.toJson(), c.current!.toJson());
      debugPrint(
        'B01_NATIVE_SQLITE: ${await c.store.db.rawQuery('SELECT sqlite_version() AS version')}',
      );
      debugPrint(
        'B01_COLD_RESTART_EXPECT: id=${stored.id}; puzzle=${stored.puzzle.id}; moves=${stored.moveCount}; revision=${stored.revision}; board=${stored.board}; history=${stored.history.length}',
      );
    },
  );
}
