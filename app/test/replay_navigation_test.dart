import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  for (final scenario in [
    'retry',
    'stay',
    'stay-reselect',
    'home-first',
    'candidate-failure',
  ]) {
    testWidgets(
      'B02-R01 actual Replay again failed-save navigation: $scenario',
      (t) async {
        final dir = Directory.systemTemp.createTempSync('b02-r01-replay-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/game.db',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final c = GameController(store, library: testLibrary());
        Future<void> tap(String key) async {
          final f = find.byKey(Key(key));
          await t.ensureVisible(f);
          await t.tap(f);
          await t.pump();
          for (var i = 0; i < 500 && c.busy; i++) {
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 5)),
            );
            await t.pump(const Duration(milliseconds: 5));
          }
          expect(c.busy, isFalse);
          await t.pumpAndSettle();
        }

        try {
          await t.runAsync(() async {
            await c.initialize();
            await c.start(fixture());
            for (final move in c.current!.puzzle.referenceMoves) {
              await c.pour(move.from, move.to);
            }
            await c.startLevel(1);
            for (final move in c.current!.puzzle.referenceMoves.take(
              c.current!.puzzle.referenceMoves.length - 1,
            )) {
              await c.pour(move.from, move.to);
            }
          });
          final oldId = c.current!.id,
              last = c.current!.puzzle.referenceMoves.last;
          store.fault = (stage) {
            if (stage == 'receipt') {
              throw StateError('B02-R01 actual transaction rollback');
            }
          };
          await t.pumpWidget(PourluneApp(controller: c));
          await tap('bottle-${last.from}');
          await tap('bottle-${last.to}');
          expect(c.phase, SavePhase.failed);
          expect(c.settlementKind, SettlementKind.replay);
          final completed = c.current!;
          expect(
            (await t.runAsync(() => store.load('ordinary')))!
                .instance!
                .completed,
            isFalse,
          );
          expect(
            t
                .widget<FilledButton>(find.byKey(const Key('replay-again')))
                .onPressed,
            isNotNull,
          );
          if (scenario == 'home-first' || scenario == 'stay-reselect') {
            await tap('home');
          } else {
            await tap('replay-again');
          }
          if (scenario == 'stay' || scenario == 'stay-reselect') {
            await tap('stay');
          }
          if (scenario == 'stay-reselect') await tap('replay-again');
          if (scenario != 'stay') {
            await tap('replay-again');
            await tap('home');
          }
          expect(c.current!.id, oldId);
          expect(c.phase, SavePhase.failed);
          var snapshotWrites = 0;
          store.fault = (stage) {
            if (stage == 'snapshot') {
              snapshotWrites++;
              if (scenario == 'candidate-failure' && snapshotWrites == 2) {
                throw StateError('B02-R01 next replay snapshot rollback');
              }
            }
          };
          await tap('retry');
          if (scenario == 'candidate-failure') {
            expect(c.phase, SavePhase.failed);
            expect(c.current!.id, oldId);
            expect(
              (await t.runAsync(() => store.load('ordinary')))!
                  .instance!
                  .completed,
              isTrue,
            );
            expect((await t.runAsync(store.progress))!.receipts, 2);
            await tap('retry');
          }
          expect(c.phase, SavePhase.clean);
          final stays = scenario == 'stay' || scenario == 'home-first';
          expect(
            c.page,
            scenario == 'home-first'
                ? GamePage.home
                : stays
                ? GamePage.completion
                : GamePage.board,
          );
          expect(c.current!.id, stays ? oldId : isNot(oldId));
          expect(c.current!.isReplay, isTrue);
          expect(c.current!.completed, stays);
          expect(
            snapshotWrites,
            stays
                ? 1
                : scenario == 'candidate-failure'
                ? 3
                : 2,
          );
          final finalId = c.current!.id;
          await t.runAsync(c.retry);
          await t.runAsync(() => store.settle(completed));
          final progress = (await t.runAsync(store.progress))!;
          expect(progress.firstClears, 1);
          expect(progress.pieces, isEmpty);
          expect(progress.unlockedLevels, [1, 2]);
          expect(progress.qualifyingClears, 0);
          expect(progress.receipts, 2);
          expect(
            (await t.runAsync(() => store.load('ordinary')))!.instance!.id,
            finalId,
          );
          expect(c.current!.id, finalId);
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      },
    );
  }
}
