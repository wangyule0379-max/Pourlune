import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  Future<void> focusButton(WidgetTester t, Finder target) async {
    await t.ensureVisible(target);
    final button = t.widget<ButtonStyleButton>(target);
    final child = find
        .descendant(
          of: target,
          matching: find.byWidgetPredicate((w) => identical(w, button.child)),
        )
        .first;
    final node = Focus.of(t.element(child));
    node.requestFocus();
    await t.pump();
    expect(node.hasPrimaryFocus, isTrue);
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      testWidgets(
        'MS02 $platform ${key.keyLabel}: native Start/bottle persist once; disabled repeat, release and focus change add nothing',
        (t) async {
          debugDefaultTargetPlatformOverride = platform;
          final dir = Directory.systemTemp.createTempSync('motion-keys-');
          final store = (await t.runAsync(
            () => GameStore.open(
              '${dir.path}/keyboard.sqlite',
              factory: databaseFactoryFfi,
            ),
          ))!;
          final c = GameController(store, library: testLibrary());
          var snapshots = 0;
          final instances = <String>{};
          Completer<void>? blocked;
          Future<void>? held;
          Future<void> holdWriter() async {
            final entered = Completer<void>();
            blocked = Completer<void>();
            held = store.db.transaction((_) async {
              entered.complete();
              await blocked!.future;
            });
            await entered.future;
          }

          Future<void> releaseWriter() async {
            blocked?.complete();
            blocked = null;
            await held;
            held = null;
          }

          Future<void> finishWrite() async {
            for (var i = 0; i < 300 && c.phase == SavePhase.saving; i++) {
              await t.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 5)),
              );
              await t.pump();
            }
            expect(c.phase, SavePhase.clean);
          }

          void observe() {
            final id = c.current?.id;
            if (id != null) instances.add(id);
          }

          try {
            await t.runAsync(c.initialize);
            c.addListener(observe);
            store.fault = (stage) {
              if (stage == 'snapshot') snapshots++;
            };
            await t.pumpWidget(PourluneApp(controller: c));
            await t.pumpAndSettle();
            final start = find.byKey(const Key('sample-main-001'));
            await focusButton(t, start);
            await t.runAsync(holdWriter);
            await t.sendKeyDownEvent(key);
            await t.pump();
            expect(c.busy, isTrue);
            expect(c.current, isNull);
            expect(t.widget<ButtonStyleButton>(start).onPressed, isNull);
            await t.sendKeyRepeatEvent(key);
            FocusScope.of(t.element(start)).requestFocus();
            await t.pump();
            await t.sendKeyUpEvent(key);
            await t.sendKeyDownEvent(key);
            await t.sendKeyUpEvent(key);
            await t.pump();
            expect(c.current, isNull);
            expect(c.page, GamePage.home);
            await t.runAsync(releaseWriter);
            await finishWrite();
            await t.pumpAndSettle();
            expect(instances, hasLength(1));
            expect(snapshots, 1);
            final id = c.current!.id;
            expect(c.current!.moveCount, 0);
            expect(c.current!.revision, 0);
            expect(
              (await t.runAsync(() => store.load('ordinary')))!.instance!.id,
              id,
            );
            await waitForFlameArt(t);
            final move = c.current!.puzzle.referenceMoves.first;
            final source = find.byKey(Key('bottle-${move.from}'));
            final target = find.byKey(Key('bottle-${move.to}'));
            await focusButton(t, source);
            await t.sendKeyDownEvent(key);
            await t.sendKeyUpEvent(key);
            await t.pump();
            expect(c.selectedSource, move.from);
            expect(c.current!.moveCount, 0);
            await focusButton(t, target);
            await t.runAsync(holdWriter);
            await t.sendKeyDownEvent(key);
            await t.pump();
            expect(c.phase, SavePhase.saving);
            expect(c.busy, isTrue);
            expect(c.current!.moveCount, 1);
            expect(t.widget<ButtonStyleButton>(target).onPressed, isNull);
            await t.sendKeyRepeatEvent(key);
            FocusScope.of(t.element(target)).requestFocus();
            await t.pump();
            await t.sendKeyUpEvent(key);
            await t.sendKeyDownEvent(key);
            await t.sendKeyUpEvent(key);
            await t.pump();
            expect(c.current!.moveCount, 1);
            expect(c.current!.revision, 1);
            expect(c.selectedSource, isNull);
            await t.runAsync(releaseWriter);
            await finishWrite();
            // SQLite has completed and real art is decoded. Drive the actual
            // Flame ticker in Flutter's fake presentation clock, bounded to the
            // same 3s of simulated time. A host wall-clock deadline can expire
            // before this test has pumped the animation's presentation budget.
            await t.pumpAndSettle(
              const Duration(milliseconds: 16),
              EnginePhase.sendSemanticsUpdate,
              const Duration(seconds: 3),
            );
            expect(c.motion, isNull);
            expect(c.busy, isFalse);
            expect(c.current!.id, id);
            expect(c.current!.moveCount, 1);
            expect(c.current!.revision, 1);
            expect(c.current!.history, hasLength(1));
            expect(instances, {id});
            expect(snapshots, 2);
            final saved = (await t.runAsync(() => store.load('ordinary')))!
                .instance!;
            expect(saved.toJson(), c.current!.toJson());
            expect(t.takeException(), isNull);
          } finally {
            if (blocked != null) await t.runAsync(releaseWriter);
            await t.pumpWidget(const SizedBox());
            c.removeListener(observe);
            c.dispose();
            await t.runAsync(store.close);
            dir.deleteSync(recursive: true);
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  }
}
