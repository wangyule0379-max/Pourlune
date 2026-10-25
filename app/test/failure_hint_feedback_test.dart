import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  for (final screen in [
    (const Size(375, 667), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 2.0),
    (const Size(375, 667), 2.0),
  ]) {
    testWidgets(
      'dirty Hint remains visible, cancellable and revision-safe ${screen.$1}/${screen.$2}',
      (t) async {
        final semantics = t.ensureSemantics();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = screen.$1;
        t.view.padding = const FakeViewPadding(top: 20);
        final dir = Directory.systemTemp.createTempSync('dirty-hint-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final puzzle = Puzzle.parse(
          File('assets/puzzles/main/main-012.json').readAsStringSync(),
        );
        var initial = GameInstance.create(id: 'dirty-hint', puzzle: puzzle);
        for (final m in puzzle.referenceMoves.take(11)) {
          initial = initial.pour(m.from, m.to).state;
        }
        initial = initial.grantExtraBottle().pour(0, 5).state;
        final answers = <Completer<HintResult>>[];
        final c = GameController(
          store,
          library: ContentLibrary(main: {12: puzzle}),
          hintLauncher: (_) {
            final pending = Completer<HintResult>();
            answers.add(pending);
            return (
              result: pending.future,
              cancel: () {},
              released: Future<void>.value(),
            );
          },
        );
        Future<void> tap(String key) async {
          await t.runAsync(() => t.tap(find.byKey(Key(key))));
          await t.pumpAndSettle();
        }

        Future<void> retry({required bool fails}) async {
          late Completer<void> release, done;
          late Future<void> held;
          var started = false;
          void changed() {
            if (c.phase == SavePhase.saving) {
              started = true;
            } else if (started && !done.isCompleted) {
              done.complete();
            }
          }

          await t.runAsync(() async {
            release = Completer<void>();
            done = Completer<void>();
            final locked = Completer<void>();
            held = store.db.transaction((_) async {
              locked.complete();
              await release.future;
            });
            await locked.future;
            c.addListener(changed);
            await t.tap(find.byKey(const Key('retry')));
          });
          try {
            await t.pumpAndSettle();
            expect(c.phase, SavePhase.saving);
            expect(find.text('Progress not saved'), findsOneWidget);
            expect(
              t.widget<FilledButton>(find.byKey(const Key('retry'))).onPressed,
              isNull,
            );
            await t.runAsync(() async {
              release.complete();
              await held;
              await done.future.timeout(const Duration(seconds: 5));
            });
          } finally {
            c.removeListener(changed);
            if (!release.isCompleted) release.complete();
          }
          await t.pumpAndSettle();
          expect(c.phase, fails ? SavePhase.failed : SavePhase.clean);
        }

        try {
          await t.runAsync(() async {
            await store.save(initial);
            await c.initialize();
            await c.resumeSlot('ordinary');
            c.failNextWrite();
            await c.pour(0, 3);
            c.stayHere();
            await c.undo();
          });
          expect(c.phase, SavePhase.failed);
          await t.pumpWidget(
            PourluneApp(
              controller: c,
              textScaler: TextScaler.linear(screen.$2),
            ),
          );
          await t.pumpAndSettle();
          await settleFlameBoard(t, c);
          final stable = {
            for (var i = 0; i < 7; i++)
              i: t.getRect(find.byKey(Key('bottle-count-$i'))),
          };
          void checkBoard() {
            expect(find.byKey(const Key('save-failed')), findsOneWidget);
            final viewport = t.getRect(
              find.byKey(const PageStorageKey('board-viewport-dirty-hint')),
            );
            for (var i = 0; i < 7; i++) {
              final count = t.getRect(find.byKey(Key('bottle-count-$i')));
              expect(count, stable[i]);
              expect(count.bottom, lessThanOrEqualTo(viewport.bottom + .01));
              expect(
                t.getRect(find.byKey(Key('bottle-$i'))).height,
                greaterThanOrEqualTo(48),
              );
            }
            for (final key in ['retry', 'stay', 'hint']) {
              final control = find.byKey(Key(key));
              expect(control.hitTestable(), findsOneWidget);
              expect(
                t.getRect(control).bottom,
                lessThanOrEqualTo(screen.$1.height),
              );
            }
          }

          if (screen.$2 == 2.0) {
            debugPrint(
              'C22 layout ${screen.$1}: warning=${t.getRect(find.byKey(const Key('save-failed')))} feedback=${t.getRect(find.byKey(const Key('board-feedback')))} hint=${t.getRect(find.byKey(const Key('hint')))} viewport=${t.getRect(find.byKey(const PageStorageKey('board-viewport-dirty-hint')))}',
            );
          }
          checkBoard();
          await tap('pause');
          final close = t.getRect(find.byKey(const Key('pause-close')));
          if (screen.$2 <= 1.3) {
            final title = t.getRect(find.text('Progress not saved').last);
            expect(title.top, greaterThanOrEqualTo(close.bottom));
          }
          for (final key in ['pause-retry', 'pause-stay', 'resume-pause']) {
            expect(find.byKey(Key(key)).hitTestable(), findsOneWidget);
          }
          expect(t.takeException(), isNull);
          await tap('pause-close');
          checkBoard();
          await tap('hint');
          expect(c.hintSearching, isTrue);
          expect(find.text('Finding a move…'), findsOneWidget);
          expect(
            find.byKey(const Key('cancel-hint')).hitTestable(),
            findsOneWidget,
          );
          checkBoard();
          await t.runAsync(() async {
            answers.last.complete(
              const HintResult(HintStatus.found, move: PourMove(0, 3)),
            );
            await Future<void>.delayed(Duration.zero);
          });
          await t.pumpAndSettle();
          await settleFlameBoard(t, c);
          expect(find.text('Bottle 1 → 4'), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('Bottle 1.*Suggested source')),
            findsOneWidget,
          );
          checkBoard();
          await tap('cancel-hint');
          expect(c.hint, isNull);
          expect(c.phase, SavePhase.failed);
          checkBoard();
          // A late result after an actual dirty action must never regain authority.
          await tap('hint');
          final stale = answers.last;
          await t.runAsync(() => c.pour(0, 3));
          await settleFlameBoard(t, c);
          stale.complete(
            const HintResult(HintStatus.found, move: PourMove(0, 3)),
          );
          await t.pumpAndSettle();
          expect(c.hint, isNull);
          expect(c.hintSearching, isFalse);
          expect(find.byKey(const Key('cancel-hint')), findsNothing);
          expect(c.current!.moveCount, 13);
          expect(c.phase, SavePhase.failed);
          checkBoard();
          expect(
            (await t.runAsync(() => store.load('ordinary')))!.instance!
                .toJson(),
            initial.toJson(),
          );
          c.failNextWrite();
          await retry(fails: true);
          checkBoard();
          await retry(fails: false);
          expect(find.byKey(const Key('save-failed')), findsNothing);
          expect(
            (await t.runAsync(() => store.load('ordinary')))!.instance!
                .toJson(),
            c.current!.toJson(),
          );
          expect(t.takeException(), isNull);
        } finally {
          for (final a in answers) {
            if (!a.isCompleted) {
              a.complete(const HintResult(HintStatus.cancelled));
            }
          }
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          semantics.dispose();
          t.view.reset();
          dir.deleteSync(recursive: true);
        }
      },
    );
  }
}
