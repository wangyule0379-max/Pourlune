// Standalone debug QA: actual Flutter gestures, bundled content and sqflite.
// Only page_transitions.sqlite is disposable. No SDK rewards or business mocks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/main.dart' as product;
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart' show b05Seed, b05Finish, b05Capture;

void verify(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  if (!kDebugMode ||
      database != 'page_transitions.sqlite' ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled') {
    throw StateError('Isolated transition QA only');
  }
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final tester = LiveWidgetController(binding);
  final base = await getDatabasesPath();
  await deleteDatabase('$base/$database');
  final out = Directory('$base/page-transitions')..createSync(recursive: true);
  final capture = GlobalKey();
  final steps = <Map<String, Object?>>[];
  final errors = <String>[];
  final previousError = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    previousError?.call(details);
  };
  runApp(RepaintBoundary(key: capture, child: const product.Bootstrap()));
  await tester.pump(const Duration(milliseconds: 100));
  GameController? controller;
  Future<void> settled() async {
    for (var n = 0; n < 240 && (n < 10 || controller?.busy == true); n++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    // A pour can finish on this very frame and only now start the page switch.
    // This is QA observation time, never an input or product navigation delay.
    await tester.pump(const Duration(milliseconds: 320));
  }

  Future<void> record(String name, {bool screenshot = false}) async {
    final c = controller!;
    steps.add({
      'name': name,
      'page': c.page.name,
      'phase': c.phase.name,
      'instance': c.current?.id,
      'revision': c.current?.revision,
      'first_clears': c.progress.firstClears,
      'pieces': c.progress.pieces,
    });
    if (screenshot) await b05Capture(capture, '${out.path}/$name.png');
  }

  Future<void> tapFinder(Finder finder) async {
    verify(finder.evaluate().length == 1, 'Unique pointer target: $finder');
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(finder);
    await settled();
  }

  Future<void> tap(String key) async {
    final from = controller?.page.name;
    await tapFinder(find.byKey(Key(key)));
    steps.add({
      'action': key,
      'from': from,
      'page': controller?.page.name,
      'phase': controller?.phase.name,
      'instance': controller?.current?.id,
    });
  }

  Future<void> close() => tapFinder(find.text('Close').last);
  try {
    for (
      var n = 0;
      n < 300 && find.byType(product.PourluneApp).evaluate().isEmpty;
      n++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    verify(
      find.byType(product.PourluneApp).evaluate().length == 1,
      'Offline bootstrap',
    );
    final c = controller = tester
        .widget<product.PourluneApp>(find.byType(product.PourluneApp))
        .controller;
    await settled();
    await record('startup-home', screenshot: true);
    // Host starts recording before this bounded QA pacing, never product delay.
    await Future<void>.delayed(const Duration(seconds: 3));
    await tap('sample-main-001');
    await record('welcome-start-board');
    await tap('pause');
    await tap('pause-home');
    await tap('chapters');
    await record('home-chapters');
    await tap('level-1');
    await record('chapters-board');
    await tap('pause');
    await record('pause', screenshot: true);
    await tap('resume-pause');
    await tap('pause');
    await tap('pause-restart');
    await tap('confirm-restart');
    await record('restart-same-instance');
    await tap('pause');
    await tap('pause-home');
    await record('board-home');
    await tap('settings');
    await tap('rules');
    await record('settings-rules', screenshot: true);
    await tap('home');
    verify(c.page == GamePage.settings, 'Rules back to Settings');
    await tap('privacy');
    await record('privacy', screenshot: true);
    await close();
    await tap('reset-progress');
    await tapFinder(find.text('Keep progress'));
    await record('reset-cancel');
    await tap('licenses');
    verify(
      find.byType(LicensePage).evaluate().isNotEmpty,
      'Actual license route',
    );
    await record('licenses', screenshot: true);
    final package = find.text('animations');
    if (package.evaluate().isNotEmpty) {
      await tapFinder(package);
      await record('license-detail', screenshot: true);
      await tapFinder(find.byType(BackButton).last);
      await settled();
    }
    // Framework route and detail return are exercised using actual native back.
    await tapFinder(find.byType(BackButton).last);
    await settled();
    await tap('home');
    await tap('progress');
    await record('progress');
    await tap('home');
    await tap('collection');
    await tap('scene-color_studio');
    await record('scene', screenshot: true);
    await tap('scene-continue');
    await record('scene-continue-board');
    await tap('pause');
    await tap('pause-home');
    await tap('collection');
    await tap('scene-color_studio');
    await tap('collection-back');
    await record('scene-collection');
    await tap('home');
    await tap('daily');
    final today = parseCalendarDate(c.today.date);
    for (final delta in [-1, 1]) {
      final date = calendarDate(today.add(Duration(days: delta)));
      if (parseCalendarDate(date).month == today.month) {
        await tap('date-$date');
        await record(
          delta < 0 ? 'daily-history' : 'daily-future',
          screenshot: true,
        );
        await close();
      }
    }
    await tap('today');
    await record('daily-board');
    await tap('pause');
    await tap('pause-home');
    await tap('resume');
    await record('ordinary-resume');
    // Full settlement transactions prepare formal content boundaries. These are
    // controlled QA progress, not natural player progression or ad evidence.
    for (final level in [2, 4, 20, 60]) {
      await c.goHome();
      await settled();
      await b05Seed(c.store, c.library, level - 1);
      final puzzle = c.library.main[level]!;
      await c.store.save(
        b05Finish(
          GameInstance.create(id: 'transitions-main$level', puzzle: puzzle),
          take: puzzle.referenceMoves.length - 1,
        ),
        replace: true,
      );
      await c.initialize();
      c.resume();
      await settled();
      await record('controlled-main$level');
      final move = puzzle.referenceMoves.last;
      await tap('bottle-${move.from}');
      await tap('bottle-${move.to}');
      verify(
        c.page == GamePage.completion && c.phase == SavePhase.clean,
        'Saved completion $level',
      );
      await record('completion-$level', screenshot: true);
      if (level == 2) {
        await tap('next');
        verify(c.current!.puzzle.mainLevel == 3, 'Ordinary next');
        await record('ordinary-next');
      } else if (level == 4) {
        await tap('view-patch');
        await record('reward', screenshot: true);
        await tap('view-collection');
        await record('reward-scene');
        await c.resumeSlot('ordinary');
        await settled();
        await tap('view-patch');
        await record('saved-patch-revisit');
        await tap('next');
        verify(c.current!.puzzle.mainLevel == 5, 'Next once');
        await record('next-board');
        await tap('extra-bottle');
        await record('extra-explanation', screenshot: true);
        await tapFinder(find.text('Not now'));
      } else if (level == 20) {
        await tap('view-collection');
        await record('chapter-scene');
      } else {
        verify(
          find.byKey(const Key('next')).evaluate().isEmpty,
          'No final Next',
        );
        await tap('daily-final');
        await record('final-daily');
      }
    }
    // Daily completion and replay use their own slot and retain ordinary state.
    await c.startToday();
    await settled();
    var state = c.current!;
    for (final move in state.puzzle.referenceMoves) {
      await c.pour(move.from, move.to);
      await settled();
    }
    verify(c.current!.completed, 'Daily completed');
    await record('daily-completion', screenshot: true);
    await tap('daily-calendar');
    await tap('today');
    await record('daily-replay-board');
    await c.goHome();
    await settled();
    await c.startLevel(1, replace: true);
    await settled();
    state = c.current!;
    for (final move in state.puzzle.referenceMoves) {
      await c.pour(move.from, move.to);
      await settled();
    }
    await record('replay-completion');
    await tap('replay-again');
    await record('replay-new-instance');
    // Actual SQLite failure hook: no navigation before successful retry.
    c.store.fault = (stage) {
      if (stage == 'snapshot') throw StateError('QA disk full');
    };
    final move = c.current!.puzzle.referenceMoves.first;
    await c.pour(move.from, move.to);
    await c.goHome();
    await settled();
    verify(
      c.page == GamePage.board && c.phase == SavePhase.failed,
      'Save failure blocks Home',
    );
    await record('save-failed', screenshot: true);
    c.store.fault = null;
    await tap('retry');
    verify(
      c.page == GamePage.home && c.phase == SavePhase.clean,
      'Retry then Home',
    );
    await tap('settings');
    await c.updateSetting('reduced_motion', true);
    await settled();
    await tap('rules');
    await record('reduced-rules', screenshot: true);
    await tap('home');
    await tap('home');
    verify(errors.isEmpty, 'No Flutter errors: $errors');
  } catch (error, stack) {
    errors.add('$error\n$stack');
  } finally {
    final report = {
      'platform': Platform.operatingSystem,
      'mode': 'debug standalone LiveWidgetController',
      'database': database,
      'controlled_progress': [2, 4, 20, 60],
      'steps': steps,
      'errors': errors,
      'physical_performance_pass': false,
    };
    await File('${out.path}/route.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      flush: true,
    );
    // ignore: avoid_print
    print('PAGE_TRANSITIONS_DONE:${errors.isEmpty}:${steps.length}');
    FlutterError.onError = previousError;
  }
}
