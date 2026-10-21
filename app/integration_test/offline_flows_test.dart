import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('B02 real Flutter/SQLite/isolate debug scenario flow', (t) async {
    const scenario = String.fromEnvironment('POURLUNE_SCENARIO');
    const filename = String.fromEnvironment('POURLUNE_DATABASE');
    expect(['flow', 'final', 'milestone'], contains(scenario));
    if (!filename.startsWith('b02_native_')) {
      throw StateError('Use an isolated b02_native_ database for this test');
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
    expect(find.byType(app.GameScreen), findsOneWidget);
    final c = t.widget<app.GameScreen>(find.byType(app.GameScreen)).controller;
    Future<void> wait() async {
      for (var i = 0; i < 400 && (c.busy || c.hintSearching); i++) {
        await t.pump(const Duration(milliseconds: 20));
      }
      await t.pumpAndSettle();
      expect(c.busy, isFalse);
      expect(c.hintSearching, isFalse);
    }

    Future<void> tap(String key) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump(const Duration(milliseconds: 40));
      await wait();
    }

    Future<void> reference({int skip = 0}) async {
      for (final m in c.current!.puzzle.referenceMoves.skip(skip)) {
        await tap('bottle-${m.from}');
        await tap('bottle-${m.to}');
      }
      expect(c.current!.completed, isTrue);
      expect(c.phase, SavePhase.clean);
    }

    Future<void> hint() async {
      final state = c.current!, watch = Stopwatch()..start();
      final f = find.byKey(const Key('hint'));
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump();
      final response = watch.elapsedMicroseconds;
      expect(c.hintSearching || c.hint != null, isTrue);
      await wait();
      expect(c.hint!.status, HintStatus.found);
      expect(c.current!.board, state.board);
      expect(c.current!.moveCount, state.moveCount);
      debugPrint(
        'B02_HINT_MEASURE: mode=debug simulator; scenario=$scenario; response_us=$response; worker_wall_us=${c.hint!.elapsed.inMicroseconds}; visited=${c.hint!.visited}; status=${c.hint!.status.name}; logical_size=${t.view.physicalSize / t.view.devicePixelRatio}',
      );
    }

    if (scenario == 'final') {
      expect(c.progress.firstClears, 59);
      await tap('resume');
      expect(c.current!.puzzle.mainLevel, 60);
      await reference();
      expect(c.progress.storyComplete, isTrue);
      expect(c.progress.pieces.length, 15);
      expect(c.progress.qualifyingClears, 50);
      expect(find.byKey(const Key('next')), findsNothing);
      expect(find.text('Story complete'), findsOneWidget);
      await tap('view-collection');
      expect(c.progress.revealedPieces, contains('seaside_corner:5'));
      await tap('home');
      expect(find.byKey(const Key('daily-primary')), findsOneWidget);
      await tap('replay-levels');
      await tap('level-1');
      expect(c.current!.isReplay, isTrue);
      expect(c.current!.tutorial, isNull);
      await tap('home');
      expect(find.textContaining('Continue replay'), findsOneWidget);
      await tap('resume');
      await reference();
      expect(c.settlementKind, SettlementKind.replay);
      expect(find.byKey(const Key('next')), findsNothing);
      expect(c.progress.pieces.length, 15);
      expect(c.progress.qualifyingClears, 50);
    } else if (scenario == 'milestone') {
      expect(c.progress.firstClears, 19);
      await tap('resume');
      await reference();
      expect(c.settlementKind, SettlementKind.chapter);
      expect(c.canCheckInterstitialOnNext, isFalse);
      expect(find.text('Continue'), findsOneWidget);
      await tap('next');
      expect(c.current!.puzzle.mainLevel, 21);
      expect(c.progress.revealedPieces, contains('color_studio:5'));
      expect(c.progress.qualifyingClears, 10);
    } else {
      await tap('sample-main-001');
      expect(c.current!.tutorial!.active, isTrue);
      await tap('bottle-0');
      await tap('bottle-2');
      expect((await c.store.load('ordinary')).instance!.tutorial!.step, 1);
      final preserved = c.current!.board;
      await tap('skip-tutorial');
      expect(c.current!.board, preserved);
      expect(await c.store.tutorialDone(), isTrue);
      await hint();
      await tap('bottle-${c.hint!.move!.to}');
      for (var i = 0; i < 20 && !c.current!.completed; i++) {
        await hint();
        await tap('bottle-${c.hint!.move!.to}');
      }
      expect(c.current!.completed, isTrue);
      for (var level = 2; level <= 4; level++) {
        await tap('next');
        expect(c.current!.puzzle.mainLevel, level);
        await reference();
      }
      await tap('view-patch');
      expect(c.progress.pieces, ['color_studio:1']);
      expect(c.progress.revealedPieces, isEmpty);
      await tap('view-collection');
      expect(c.progress.revealedPieces, ['color_studio:1']);
      await tap('home');
      await tap('settings');
      await tap('setting-music');
      expect((await c.store.readSettings()).music, isFalse);
      final ordinary = c.ordinary!.toJson();
      await tap('rules');
      await tap('demo-bottle-0');
      await tap('demo-bottle-2');
      expect(c.ordinary!.toJson(), ordinary);
      await tap('rules-back');
      await tap('home');
      await tap('daily');
      await tap('today');
      final oldDate = c.current!.puzzleDate!, oldId = c.current!.id;
      await tap('bottle-0');
      await tap('bottle-2');
      await tap('home');
      await tap('advance-test-day');
      await tap('daily');
      await tap('today');
      await t.tap(find.text('Keep playing'));
      await t.pumpAndSettle();
      expect(c.daily!.id, oldId);
      await tap('daily-resume');
      await reference(skip: 1);
      expect(c.progress.dailyStamps, [oldDate]);
      await tap('daily-calendar');
      c.failNextWrite();
      await tap('today');
      expect(c.phase, SavePhase.failed);
      expect((await c.store.load('daily')).instance!.id, oldId);
      await tap('retry');
      expect(c.current!.puzzleDate, isNot(oldDate));
      expect((await c.store.load('ordinary')).instance!.toJson(), ordinary);
      // Real worker cancellation through the Flutter lifecycle observer; no fake solver transport.
      final request = c.requestHint();
      expect(c.hintSearching, isTrue);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(c.hintSearching, isFalse);
      await request;
      expect(c.hint, isNull);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      await reference();
      expect(c.progress.dailyStamps.length, 2);
      expect(c.progress.firstClears, 4);
      expect(c.progress.qualifyingClears, 0);
      final today = c.current!.puzzleDate!;
      await tap('daily-calendar');
      await tap('date-$oldDate');
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining(
            'History is read-only. Past puzzles cannot be started.',
          ),
        ),
        findsOneWidget,
      );
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      final future = calendarDate(
        parseCalendarDate(today).add(const Duration(days: 1)),
      );
      if (parseCalendarDate(future).month != parseCalendarDate(today).month) {
        await t.tap(find.byTooltip('Next month'));
        await t.pumpAndSettle();
      }
      await tap('date-$future');
      expect(
        find.textContaining('Future dates cannot be played.'),
        findsOneWidget,
      );
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      await tap('today');
      expect(c.current!.isReplay, isTrue);
      await reference();
      expect(c.progress.dailyStamps.length, 2);
      expect(c.progress.pieces, ['color_studio:1']);
      expect(c.progress.qualifyingClears, 0);
    }
    debugPrint(
      'B02_NATIVE_PASS: scenario=$scenario; SQLite=${await c.store.db.rawQuery('SELECT sqlite_version() AS v')}; first=${c.progress.firstClears}; pieces=${c.progress.pieces}; stamps=${c.progress.dailyStamps}; counter=${c.progress.qualifyingClears}; receipts=${c.progress.receipts}',
    );
    expect(t.takeException(), isNull);
  });
}
