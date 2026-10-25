import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  for (final scale in [1.0, 3.2]) {
    testWidgets(
      'P09 original confirmation keeps real choice and entitlement $scale',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(375, 667);
        t.view.padding = const FakeViewPadding(top: 20);
        final dir = Directory.systemTemp.createTempSync('restart-design-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        var initial = GameInstance.create(
          id: 'restart-design',
          puzzle: fixture(),
        );
        initial = initial.grantExtraBottle();
        final move = initial.puzzle.referenceMoves.first;
        initial = initial.pour(move.from, move.to).state;
        final c = GameController(store);
        try {
          await t.runAsync(() async {
            await store.save(initial);
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          await t.pumpWidget(
            PourluneApp(
              controller: c,
              textScaler: TextScaler.linear(scale),
              // Exercise the real GameScreen confirmation callbacks, independently
              // of the canonical maximum-board defect tracked elsewhere.
              debugBoardPagePresentation: (page) => TextButton(
                onPressed: page.onRestart,
                child: const Text('Open actual Restart'),
              ),
            ),
          );
          await t.pumpAndSettle();
          Future<void> open() async {
            // The dialog-return continuation owns real SQLite work too.
            await t.runAsync(() => t.tap(find.text('Open actual Restart')));
            await t.pumpAndSettle();
            expect(find.byKey(const Key('restart-card')), findsOneWidget);
            expect(
              find.textContaining('Your extra bottle stays.'),
              findsOneWidget,
            );
            if (scale > 2) {
              final viewport = t.getRect(
                find.byKey(const Key('restart-context')),
              );
              final warning = t.getRect(
                find.textContaining('Your extra bottle stays.'),
              );
              expect(warning.top, greaterThanOrEqualTo(viewport.top));
              expect(warning.bottom, lessThanOrEqualTo(viewport.bottom + .01));
              expect(
                viewport.top,
                greaterThanOrEqualTo(
                  t.getRect(find.byKey(const Key('restart-close'))).bottom,
                ),
              );
            }
            final keep = find.byKey(const Key('restart-keep'));
            final confirm = find.byKey(const Key('confirm-restart'));
            expect(t.getRect(keep).bottom, lessThan(t.getRect(confirm).top));
            for (final action in [
              keep,
              confirm,
              find.byKey(const Key('restart-close')),
            ]) {
              final r = t.getRect(action);
              expect(action.hitTestable(), findsOneWidget);
              expect(r.width, greaterThanOrEqualTo(48));
              expect(r.height, greaterThanOrEqualTo(48));
              expect(r.bottom, lessThanOrEqualTo(667));
            }
            expect(t.getRect(keep).width, greaterThanOrEqualTo(200));
          }

          await open();
          await t.tap(find.byKey(const Key('restart-close')));
          await t.pumpAndSettle();
          expect(c.current!.toJson(), initial.toJson());
          await open();
          await t.tap(find.byKey(const Key('restart-keep')));
          await t.pumpAndSettle();
          expect(c.current!.toJson(), initial.toJson());
          await open();
          late Completer<void> savedAck;
          var started = false;
          void onWrite() {
            if (c.phase == SavePhase.saving) {
              started = true;
            } else if (started && !savedAck.isCompleted) {
              savedAck.complete();
            }
          }

          await t.runAsync(() async {
            savedAck = Completer<void>();
            c.addListener(onWrite);
            await t.tap(find.byKey(const Key('confirm-restart')));
          });
          await t.pumpAndSettle();
          try {
            await t.runAsync(
              () => savedAck.future.timeout(const Duration(seconds: 5)),
            );
          } finally {
            c.removeListener(onWrite);
          }
          await t.pumpAndSettle();
          expect(started, isTrue);
          expect(c.phase, SavePhase.clean);
          expect(c.current!.id, initial.id);
          expect(c.current!.extraBottleGranted, isTrue);
          expect(c.current!.moveCount, 0);
          expect(c.current!.board, [...initial.puzzle.initial, <String>[]]);
          final saved = (await t.runAsync(() => store.load('ordinary')))!
              .instance!;
          expect(saved.toJson(), c.current!.toJson());
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          t.view.reset();
          dir.deleteSync(recursive: true);
        }
      },
    );
  }
}
