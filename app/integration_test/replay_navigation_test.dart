import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'B02-R01 actual Replay buttons preserve first intent across SQLite failures',
    (t) async {
      const filename = String.fromEnvironment('POURLUNE_DATABASE');
      expect(const String.fromEnvironment('POURLUNE_SCENARIO'), 'flow');
      if (!filename.startsWith('b02_native_')) {
        throw StateError('Use an isolated b02_native_ database');
      }
      await deleteDatabase('${await getDatabasesPath()}/$filename');
      app.main();
      for (
        var i = 0;
        i < 400 && find.byType(app.GameScreen).evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 40));
      }
      final c = t
          .widget<app.GameScreen>(find.byType(app.GameScreen))
          .controller;
      Future<void> tap(String key) async {
        final f = find.byKey(Key(key));
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pump(const Duration(milliseconds: 40));
        for (var i = 0; i < 400 && c.busy; i++) {
          await t.pump(const Duration(milliseconds: 20));
        }
        expect(c.busy, isFalse);
        await t.pumpAndSettle();
      }

      Future<void> moves({bool fail = false}) async {
        final reference = c.current!.puzzle.referenceMoves;
        for (var i = 0; i < reference.length; i++) {
          if (fail && i == reference.length - 1) {
            c.store.fault = (stage) {
              if (stage == 'receipt') {
                throw StateError('B02-R01 receipt rollback');
              }
            };
          }
          await tap('bottle-${reference[i].from}');
          await tap('bottle-${reference[i].to}');
        }
        expect(c.current!.completed, isTrue);
        expect(c.phase, fail ? SavePhase.failed : SavePhase.clean);
      }

      await tap('sample-main-001');
      await tap('skip-tutorial');
      await moves();
      await tap('home');
      await tap('chapters');
      await tap('level-1');
      expect(c.current!.isReplay, isTrue);

      // Stay cancels Replay and its competing Home, while settlement still retries.
      await moves(fail: true);
      final cancelled = c.current!.id;
      await tap('replay-again');
      await tap('replay-again');
      await tap('home');
      await tap('stay');
      c.store.fault = null;
      await tap('retry');
      expect(c.current!.id, cancelled);
      expect(c.page, GamePage.completion);

      // A new Replay after Stay wins; the new-instance SQL write can itself roll back.
      await tap('replay-again');
      await moves(fail: true);
      final source = c.current!;
      await tap('home');
      await tap('stay');
      await tap('replay-again');
      await tap('replay-again');
      await tap('home');
      expect(c.current!.id, source.id);
      expect((await c.store.load('ordinary')).instance!.completed, isFalse);
      var writes = 0;
      c.store.fault = (stage) {
        if (stage == 'snapshot' && ++writes == 2) {
          throw StateError('B02-R01 candidate rollback');
        }
      };
      await tap('retry');
      expect(c.phase, SavePhase.failed);
      expect(c.current!.id, source.id);
      expect((await c.store.load('ordinary')).instance!.completed, isTrue);
      expect((await c.store.progress()).receipts, 3);
      await tap('retry');
      expect(writes, 3);
      expect(c.phase, SavePhase.clean);
      expect(c.page, GamePage.board);
      expect(c.current!.id, isNot(source.id));
      expect(c.current!.isReplay, isTrue);
      expect(c.current!.moveCount, 0);
      final replayId = c.current!.id;
      await c.retry();
      await c.store.settle(source);
      expect((await c.store.load('ordinary')).instance!.id, replayId);

      // Home selected first cannot be replaced by the enabled Replay button.
      c.store.fault = null;
      await moves(fail: true);
      final homeSource = c.current!.id;
      await tap('home');
      await tap('replay-again');
      c.store.fault = null;
      await tap('retry');
      expect(c.page, GamePage.home);
      expect(c.current!.id, homeSource);
      expect(c.current!.completed, isTrue);
      final p = await c.store.progress();
      expect(p.firstClears, 1);
      expect(p.receipts, 4);
      expect(p.pieces, isEmpty);
      expect(p.qualifyingClears, 0);
      expect(p.unlockedLevels, [1, 2]);
      expect(p.dailyStamps, isEmpty);
      expect(t.takeException(), isNull);
      debugPrint(
        'B02_R01_NATIVE_PASS: SQLite=${await c.store.db.rawQuery('SELECT sqlite_version() AS v')}; first=${p.firstClears}; receipts=${p.receipts}; pieces=${p.pieces}; counter=${p.qualifyingClears}; candidate_attempts=$writes; final=Home; Replay Retry/Stay/reselect/double/Home/candidate-rollback verified',
      );
    },
  );
}
