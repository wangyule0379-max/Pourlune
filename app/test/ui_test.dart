import 'dart:io';

import 'package:flutter/semantics.dart';
import 'package:pourlune_dev/presentation/bottle.dart';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'real UI fixture to completion, free actions, failure Retry and local progress',
    (t) async {
      final d = Directory.systemTemp.createTempSync('ui-');
      final store = (await t.runAsync(
        () => GameStore.open('${d.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store);
      await t.runAsync(c.initialize);
      await t.pumpWidget(PourluneApp(controller: c, puzzles: [fixture()]));
      Future<void> tap(Key key) async {
        await t.ensureVisible(find.byKey(key));
        await t.tap(find.byKey(key));
        await t.pump();
        await t.runAsync(() async {
          await store.db.rawQuery('SELECT 1');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          for (var i = 0; i < 1000 && c.busy; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
        });
        await t.pumpAndSettle();
      }

      await tap(const Key('sample-main-001'));
      expect(find.byKey(const Key('bottle-0')), findsOneWidget);
      await tap(const Key('bottle-0'));
      await tap(const Key('bottle-2'));
      expect(c.current!.moveCount, 1);
      await tap(const Key('undo'));
      expect(c.current!.moveCount, 0);
      await tap(const Key('bottle-0'));
      await tap(const Key('bottle-2'));
      await tap(const Key('restart'));
      expect(find.text('Restart this sample?'), findsOneWidget);
      await tap(const Key('confirm-restart'));
      expect(c.current!.moveCount, 0);
      await tap(const Key('pause'));
      expect(find.text('Paused'), findsOneWidget);
      await tap(const Key('resume-pause'));
      c.failNextWrite();
      await tap(const Key('bottle-0'));
      await tap(const Key('bottle-2'));
      expect(find.byKey(const Key('save-failed')), findsOneWidget);
      await tap(const Key('pause'));
      expect(
        find.text(
          'Some changes are only in memory. Resume and Retry before leaving.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Each completed action is saved locally'),
        findsNothing,
      );
      await tap(const Key('resume-pause'));
      await tap(const Key('home'));
      expect(c.page, GamePage.board);
      await tap(const Key('stay'));
      await tap(const Key('retry'));
      expect(c.phase, SavePhase.clean);
      for (final m in c.current!.puzzle.referenceMoves.skip(1)) {
        await tap(Key('bottle-${m.from}'));
        await tap(Key('bottle-${m.to}'));
      }
      expect(find.text('Sample complete'), findsOneWidget);
      expect(c.receipt, isNotNull);
      await tap(const Key('home'));
      await tap(const Key('progress'));
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await t.pumpAndSettle();
      expect(find.textContaining('First clears: 1'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      d.deleteSync(recursive: true);
    },
  );
  testWidgets(
    '320px large text board and seven bottles retain equal geometry and semantics',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 800));
      final d = Directory.systemTemp.createTempSync('ui-size-');
      final store = (await t.runAsync(
        () => GameStore.open('${d.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store);
      await t.runAsync(c.initialize);
      // Entitlement supplied by persisted domain state; there is no pretend ad reward button.
      final raw = File('assets/fixtures/main-012.reference.json')
          .readAsStringSync();
      await t.runAsync(() async {
        await c.start(Puzzle.parse(raw));
        c.current = c.current!.grantExtraBottle();
        await store.save(c.current!);
      });
      await t.pumpWidget(
        PourluneApp(
          controller: c,
          puzzles: [],
          textScaler: TextScaler.linear(2),
        ),
      );
      final semantics = t.ensureSemantics();
      for (var i = 0; i < 7; i++) {
        expect(find.byKey(Key('bottle-$i')), findsOneWidget);
      }
      expect(
        t.getSize(find.byKey(const Key('bottle-0'))),
        t.getSize(find.byKey(const Key('bottle-6'))),
      );
      expect(find.bySemanticsLabel(RegExp('Bottle 7.*Buffer')), findsOneWidget);
      expect(t.takeException(), isNull);
      semantics.dispose();
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      d.deleteSync(recursive: true);
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'bottle semantic activation invokes action once; disabled bottle has no action',
    (t) async {
      final handle = t.ensureSemantics();
      var taps = 0;
      Widget bottle(VoidCallback? onTap) => MaterialApp(
        home: Scaffold(
          body: BottleButton(
            index: 0,
            liquid: const ['O'],
            target: 'O',
            selected: false,
            width: 84,
            onTap: onTap,
          ),
        ),
      );
      await t.pumpWidget(bottle(() => taps++));
      final node = t.getSemantics(find.byType(BottleButton));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await t.pump();
      expect(taps, 1);
      await t.pumpWidget(bottle(null));
      expect(
        t
            .getSemantics(find.byType(BottleButton))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(taps, 1);
      handle.dispose();
    },
  );
}
