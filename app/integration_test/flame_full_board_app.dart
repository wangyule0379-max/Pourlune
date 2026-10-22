// Real normal main/Bootstrap + formal content + native SQLite. The engineering
// setup is confined to the exact disposable QA database, never production data.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as product;
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/bottle.dart' show BottleButton;
import 'package:pourlune_dev/presentation/knit_components.dart'
    show KnitIconButton;
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart' show b05Seed, b05Finish;

class _LifecycleProbe with WidgetsBindingObserver {
  _LifecycleProbe(this.record);
  final ValueChanged<AppLifecycleState> record;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => record(state);
}

void require(bool ok, String message) {
  if (!ok) throw StateError(message);
}

Future<void> main() async {
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  const phase = String.fromEnvironment(
    'POURLUNE_BOARD_PHASE',
    defaultValue: 'after',
  );
  if (!kDebugMode ||
      database != 'flame_full_board.sqlite' ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled' ||
      const String.fromEnvironment('POURLUNE_SCENARIO').isNotEmpty ||
      !{'before', 'after'}.contains(phase)) {
    throw StateError('Isolated full-board QA only');
  }
  final watch = Stopwatch()..start();
  product.main();
  final binding = WidgetsBinding.instance;
  final tester = LiveWidgetController(binding);
  final lifecycle = <Map<String, Object?>>[];
  Directory? lifecycleDirectory;
  GameController? activeController;
  Map<String, Object?>? Function() readVisual = () => null;
  // Register before GameScreen/Flame observers to record the actual pre-cancel
  // native lifecycle state. This observes events; it never synthesizes them.
  binding.addObserver(
    _LifecycleProbe((state) {
      final c = activeController;
      if (lifecycle.length < 100) {
        lifecycle.add({
          'pid': pid,
          'state': state.name,
          'utc': DateTime.now().toUtc().toIso8601String(),
          'token': c?.motion?.token,
          'instance': c?.current?.id,
          'revision': c?.current?.revision,
          'save_phase': c?.phase.name,
          'visual': readVisual(),
        });
        final folder = lifecycleDirectory;
        if (folder != null) {
          final temporary = File('${folder.path}/lifecycle-pending.json');
          temporary.writeAsStringSync(jsonEncode(lifecycle), flush: true);
          temporary.renameSync('${folder.path}/lifecycle.json');
        }
      }
    }),
  );
  int? firstFrame;
  binding.addPostFrameCallback((_) => firstFrame = watch.elapsedMicroseconds);
  final timings = <Map<String, int>>[];
  binding.addTimingsCallback((values) {
    for (final f in values) {
      if (timings.length < 20000) {
        timings.add({
          'build_us': f.buildDuration.inMicroseconds,
          'raster_us': f.rasterDuration.inMicroseconds,
          'total_us': f.totalSpan.inMicroseconds,
        });
      }
    }
  });
  Future<void> until(bool Function() ready, {int milliseconds = 10000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: milliseconds));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Native condition timed out');
      }
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  await until(
    () =>
        binding.rootElement != null &&
        find.byType(product.PourluneApp).evaluate().isNotEmpty,
    milliseconds: 40000,
  );
  final c = tester
      .widget<product.PourluneApp>(find.byType(product.PourluneApp))
      .controller;
  activeController = c;
  require(
    !c.library.engineering && c.library.main.length == 60,
    'normal main loads formal 60-level library',
  );
  require(c.store.db.path.endsWith('/$database'), 'exact isolated database');
  final out = Directory('${await getDatabasesPath()}/flame-full-board')
    ..createSync(recursive: true);
  lifecycleDirectory = out;
  File('${out.path}/lifecycle.json')
      .writeAsStringSync(jsonEncode(lifecycle), flush: true);
  Future<void> write(String name, Object? value) =>
      File('${out.path}/$name.json')
          .writeAsString(jsonEncode(value), flush: true);
  dynamic boardGame() {
    final all = find.byWidgetPredicate((w) => w is GameWidget).evaluate();
    return all.isEmpty ? null : (all.single.widget as GameWidget).game;
  }

  Map<String, Object?>? visualState() {
    if (phase == 'before' || boardGame() == null) return null;
    // QA reflection is intentionally outside production. The same harness also
    // compiles against the pre-Flame baseline, which has no such board class.
    final dynamic g = boardGame(), f = g.frame, flow = f.pour;
    return {
      'view_instance': f.state.id,
      'view_revision': f.state.revision,
      'counts': f.counts,
      'active_token': f.active?.token,
      'elapsed_geometry_ms': f.elapsedMs,
      'stage': flow?.stage ?? (f.active == null ? 'idle' : 'reduced'),
      'out': flow?.out,
      'arrived': flow?.delivered,
      'in_stream': flow?.inStream,
      'stream_start': flow == null
          ? null
          : [flow.streamStart.dx, flow.streamStart.dy],
      'stream_end': flow == null
          ? null
          : [flow.streamEnd.dx, flow.streamEnd.dy],
      'continuous_units': [
        for (final bands in f.bands)
          bands.fold<double>(
            0.0,
            (double n, dynamic b) => n + (b.units as double),
          ),
      ],
      'closed': g.closed,
      'paused': g.paused,
      'art_present': g.art != null,
      'canvas': [f.layout.width, f.layout.height],
      'cell_widths': [for (final rect in f.layout.cells) rect.width],
    };
  }

  readVisual = visualState;
  Future<Map<String, Object?>> state() async {
    final ordinary = (await c.store.load('ordinary')).instance;
    final daily = (await c.store.load('daily')).instance;
    return {
      'pid': pid,
      'utc': DateTime.now().toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
      'phase': phase,
      'mode': 'debug standalone normal main native gestures',
      'page': c.page.name,
      'save_phase': c.phase.name,
      'busy': c.busy,
      'motion': c.motion?.token,
      'instance': c.current?.toJson(),
      'saved_ordinary': ordinary?.toJson(),
      'saved_daily': daily?.toJson(),
      'settings': c.settings.toJson(),
      'first_clears': c.progress.firstClears,
      'receipts': c.progress.receipts,
      'pieces': c.progress.pieces,
      'revealed': c.progress.revealedPieces,
      'visual': visualState(),
      'lifecycle': lifecycle,
      'rss_bytes': ProcessInfo.currentRss,
      'live_board_pages': find.byType(BoardPage).evaluate().length,
      'board_views': find.byType(BoardView).evaluate().length,
      'flame_canvases': find
          .byWidgetPredicate((w) => w is GameWidget)
          .evaluate()
          .length,
    };
  }

  binding.scheduleFrame();
  await binding.endOfFrame;
  await write('startup-$pid', {
    'first_postframe_us': firstFrame,
    'dart_main_to_first_app_host_frame_us': watch.elapsedMicroseconds,
    'endpoint': 'first PourluneApp host frame after normal Bootstrap; not all intro effects completed',
    'excludes_native_pre_Dart': true,
    ...await state(),
  });

  var lastAction = 'startup';
  var lastPointerUpUs = 0;
  Future<void> tap(String key, {bool board = false}) async {
    lastAction = key;
    final finder = find.byKey(Key(key));
    await until(() => finder.evaluate().length == 1);
    require(finder.evaluate().length == 1, 'unique native key $key');
    if (board) await tester.ensureVisible(find.byType(BoardView));
    if (finder.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(finder);
    }
    await tester.pump();
    await until(() {
      final matches = finder.evaluate();
      if (matches.length != 1) return false;
      final w = matches.single.widget;
      final enabled = w is ButtonStyleButton
          ? w.onPressed != null
          : w is KnitIconButton
          ? w.onPressed != null
          : w is SwitchListTile
          ? w.onChanged != null
          : w is BottleButton
          ? w.onTap != null
          : true;
      return enabled && finder.hitTestable().evaluate().isNotEmpty;
    });
    await tester.pump(const Duration(milliseconds: 50));
    require(
      finder.hitTestable().evaluate().isNotEmpty,
      'painted native target $key',
    );
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await gesture.up();
    lastPointerUpUs = watch.elapsedMicroseconds;
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> readyBoard() async {
    await tester.pump();
    await until(() {
      final views = find.byType(BoardView).evaluate();
      return views.length == 1 &&
          (views.single.widget as BoardView).state.id == c.current?.id &&
          (views.single.widget as BoardView).state.revision ==
              c.current?.revision;
    });
    if (phase == 'after') {
      await until(
        () =>
            boardGame()?.art != null &&
            visualState()?['view_instance'] == c.current?.id &&
            visualState()?['view_revision'] == c.current?.revision,
      );
    } else {
      await until(() {
        final images = tester
            .widgetList<RawImage>(
              find.descendant(
                of: find.byType(BoardView),
                matching: find.byType(RawImage),
              ),
            )
            .toList();
        return images.isNotEmpty && images.every((w) => w.image != null);
      });
    }
    await tester.ensureVisible(find.byType(BoardView));
    await tester.pump();
    await until(() {
      final ancestors = find.ancestor(
        of: find.byType(BoardView),
        matching: find.byWidgetPredicate(
          (w) => w is Opacity || w is FadeTransition,
        ),
      );
      return tester
          .widgetList(ancestors)
          .every(
            (w) => w is Opacity
                ? w.opacity >= .99
                : w is FadeTransition
                ? w.opacity.value >= .99
                : true,
          );
    });
  }

  final pending = <(String, ui.Image, Map<String, Object?>)>[];
  Future<void> capture(String name) async {
    binding.scheduleFrame();
    await binding.endOfFrame;
    final element = find.byType(BoardView).evaluate().single;
    final boundary = element.renderObject! as RenderRepaintBoundary;
    pending.add((
      name,
      boundary.toImageSync(pixelRatio: 1),
      {
        'utc': DateTime.now().toUtc().toIso8601String(),
        'visual': visualState(),
        'page': c.page.name,
        'instance': c.current?.id,
        'revision': c.current?.revision,
        'motion': c.motion?.token,
      },
    ));
  }

  Future<void> flush() async {
    final folder = Directory('${out.path}/screens')
      ..createSync(recursive: true);
    while (pending.isNotEmpty) {
      final (name, image, metadata) = pending.removeAt(0);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${folder.path}/$name.png')
            .writeAsBytes(data!.buffer.asUint8List(), flush: true);
        await File('${folder.path}/$name.frame.json')
            .writeAsString(jsonEncode(metadata), flush: true);
      } finally {
        image.dispose();
      }
    }
  }

  Future<void> setup(
    int level, {
    bool extra = false,
    List<List<int>> prefix = const [],
  }) async {
    await until(() => c.phase == SavePhase.clean && !c.busy);
    await c.goHome();
    await until(
      () =>
          c.page == GamePage.home && find.byType(BoardView).evaluate().isEmpty,
    );
    var s = GameInstance.create(
      id: 'full-board-qa-$level-${DateTime.now().microsecondsSinceEpoch}',
      puzzle: c.library.main[level]!,
      isReplay: true,
    );
    for (final m in prefix) {
      final next = s.pour(m[0], m[1]);
      require(next.changed, 'legal prepared prefix');
      s = next.state;
    }
    if (extra) s = s.grantExtraBottle(); // Explicit QA entitlement seed, not an SDK reward.
    await c.store.save(s, replace: true);
    await c.initialize();
    c.resume();
    await until(() => c.page == GamePage.board && !c.busy);
    await readyBoard();
  }

  Future<Map<String, Object?>> move(
    int from,
    int to,
    String name, {
    bool shots = false,
    bool allowFailed = false,
  }) async {
    var baselineEndedBeforeCapture = false;
    await until(() => !c.busy);
    if (c.selectedSource != null) {
      await tap('bottle-${c.selectedSource}', board: true);
    }
    final before = c.current!;
    final expected = before.pour(from, to);
    require(expected.changed, 'requested native move is legal');
    await tap('bottle-$from', board: true);
    if (shots) {
      await tester.pump(const Duration(milliseconds: 130));
      await capture('$name-selected');
    }
    await tap('bottle-$to', board: true);
    require(
      c.current!.toJson().toString() == expected.state.toJson().toString(),
      'one complete native move matches core',
    );
    if (shots) {
      if (phase == 'after') {
        require(
          (visualState()!['counts'] as List).toString() ==
              before.board.map((b) => b.length).toList().toString(),
          'capacity does not jump to committed result before flow',
        );
      }
      await capture('$name-approach');
      if (phase == 'after') {
        await until(
          () =>
              ((visualState()?['in_stream'] as num?) ?? 0) > .02 &&
              ((visualState()?['out'] as num?) ?? 0) >= expected.units / 2,
        );
      } else {
        final motion = c.motion;
        baselineEndedBeforeCapture = motion == null;
        if (motion != null) {
          await tester.pump(
            Duration(
              milliseconds: (motion.duration.inMilliseconds * .45).round(),
            ),
          );
        }
      }
      await capture(
        baselineEndedBeforeCapture
            ? '$name-flow-ended-before-capture'
            : '$name-flow',
      );
    }
    await until(() => !c.busy && (allowFailed || c.phase == SavePhase.clean));
    await readyBoard();
    require(
      c.current!.id == before.id &&
          c.current!.moveCount == before.moveCount + 1,
      'single move no repeated callback',
    );
    if (shots) {
      await capture('$name-landed');
      await flush();
    }
    return {
      'name': name,
      'from': from,
      'to': to,
      'units': expected.units,
      'baseline_motion_ended_before_flow_capture': baselineEndedBeforeCapture,
      ...await state(),
    };
  }

  Future<Map<String, Object?>> route() async {
    for (final (_, image, _) in pending) {
      image.dispose();
    }
    pending.clear();
    final oldScreens = Directory('${out.path}/screens');
    if (oldScreens.existsSync()) await oldScreens.delete(recursive: true);
    await until(() => !c.busy && c.phase == SavePhase.clean);
    await c.resetProgress();
    await until(() => !c.busy && c.phase == SavePhase.clean);
    await tester.pump(const Duration(milliseconds: 350));
    timings.clear();
    final steps = <Map<String, Object?>>[];
    final hotEntries = <Map<String, Object?>>[];
    // Existing real UI starts normally; all later prefixes/settlements are explicitly QA setup.
    if (find.byKey(const Key('sample-main-001')).evaluate().isNotEmpty) {
      await tap('sample-main-001');
      await readyBoard();
      hotEntries.add({
        'target': 'normal-first-board',
        'pointer_up_to_ready_frame_us':
            watch.elapsedMicroseconds - lastPointerUpUs,
      });
      steps.add({'name': 'normal-welcome-start', ...await state()});
      await tap('pause');
      await tap('pause-home');
    }
    for (final entry in [(1, false), (5, false), (9, false), (9, true)]) {
      await setup(entry.$1, extra: entry.$2);
      final moves = c.current!.puzzle.referenceMoves;
      for (var n = 0; n < moves.length; n++) {
        final m = moves[n];
        steps.add(
          await move(
            m.from,
            m.to,
            'b${c.current!.board.length}-m$n',
            shots: n == 0 || n == 4,
          ),
        );
      }
      require(
        c.current!.completed,
        'formal reference reaches correct targets with buffers empty',
      );
      require(
        c.progress.firstClears == 0,
        'QA replay cannot award first clear',
      );
      require(
        find.byType(BoardPage).evaluate().isEmpty,
        'readonly settlement owns no live presenter',
      );
    }
    await setup(
      9,
      prefix: [
        [2, 4],
      ],
    );
    steps.add(await move(3, 2, 'partial-capacity', shots: true));
    require(
      c.current!.board[2].length == 4 && c.current!.board[3].length == 3,
      'one-unit capacity limit preserves source remainder',
    );
    await tap('undo');
    await until(() => !c.busy && c.phase == SavePhase.clean);
    require(c.current!.moveCount == 1, 'undo restores prepared legal prefix');
    await tap('restart');
    await tap('confirm-restart');
    await until(() => !c.busy && c.phase == SavePhase.clean);
    require(c.current!.moveCount == 0, 'restart clears action history');
    steps.add({'name': 'free-undo-restart', ...await state()});
    await setup(9, extra: true);
    await move(0, 6, 'extra-buffer');
    await tap('undo');
    await until(() => !c.busy && c.phase == SavePhase.clean);
    require(
      c.current!.extraBottleGranted && c.current!.board.length == 7,
      'undo retains QA-granted extra buffer',
    );
    steps.add({'name': 'extra-entitlement-undo', ...await state()});
    final sevenPrefix = c.library.main[9]!.referenceMoves
        .take(6)
        .map((m) => [m.from, m.to])
        .toList();
    await setup(9, extra: true, prefix: sevenPrefix);
    steps.add(await move(1, 6, 'seven-right-edge-four-units', shots: true));
    steps.add(await move(6, 0, 'seven-edge-cross-row-return', shots: true));
    await setup(9, extra: true);
    final beforeInvalid = c.current!.toJson().toString();
    await tap('bottle-0', board: true);
    await tap('bottle-0', board: true);
    require(c.selectedSource == null, 'same-source cancels');
    await tap('bottle-0', board: true);
    await tap('bottle-1', board: true);
    require(
      c.rejection != null && c.current!.toJson().toString() == beforeInvalid,
      'illegal full target cannot submit a move',
    );
    final b = find.byType(BoardView);
    await tester.ensureVisible(b);
    await tester.pump();
    await tester.tapAt(
      tester.getTopLeft(b) + Offset(tester.getSize(b).width / 2, 16),
    );
    await tester.pump();
    require(c.selectedSource == null, 'blank native area cancels selection');
    await tap('hint');
    await until(() => c.hintSearching || c.hint != null);
    await tap('cancel-hint');
    await tester.pump(const Duration(milliseconds: 2200));
    require(
      c.hint == null &&
          c.selectedSource == null &&
          c.current!.toJson().toString() == beforeInvalid,
      'cancelled worker cannot revive hint or move',
    );
    steps.add({'name': 'invalid-deselect-blank-hint-cancel', ...await state()});

    await setup(9, extra: true);
    await tap('bottle-0', board: true);
    await tap('bottle-4', board: true);
    require(c.motion != null, 'pause happens during active visual');
    final pausedState = c.current!.toJson().toString(),
        oldToken = c.motion!.token;
    await tap('pause');
    require(c.motion == null, 'pause cancels the old visual token');
    await tap('resume-pause');
    await readyBoard();
    await tester.pump(const Duration(milliseconds: 1100));
    require(
      c.current!.toJson().toString() == pausedState && c.motion == null,
      'cancelled effect never resubmits after resume',
    );
    steps.add({
      'name': 'active-pause-resume',
      'cancelled_token': oldToken,
      ...await state(),
    });

    await setup(9);
    c.failNextWrite();
    steps.add(await move(0, 4, 'save-failed-pour', allowFailed: true));
    require(c.phase == SavePhase.failed, 'actual SQLite rollback');
    await tap('home');
    require(c.page == GamePage.board, 'failed save blocks Home');
    await tap('retry');
    await until(() => c.phase == SavePhase.clean && c.page == GamePage.home);
    final savedAfterRetry = (await c.store.load('ordinary')).instance!;
    require(
      savedAfterRetry.toJson().toString() == c.current!.toJson().toString(),
      'Retry persisted the complete action',
    );
    steps.add({'name': 'failed-navigation-retry', ...await state()});

    await tap('daily');
    await tap('today');
    await readyBoard();
    require(c.current!.slot == 'daily', 'normal Daily starts independent slot');
    final ordinaryId = (await c.store.load('ordinary')).instance!.id;
    final dailyMove = c.current!.puzzle.referenceMoves.first;
    steps.add(await move(dailyMove.from, dailyMove.to, 'daily-free-move'));
    require(
      (await c.store.load('ordinary')).instance!.id == ordinaryId,
      'Daily never replaces ordinary',
    );
    await tap('pause');
    await tap('pause-home');
    await tap('resume');
    await readyBoard();
    require(
      c.current!.slot == 'ordinary' && c.current!.id == ordinaryId,
      'Home Continue preserves ordinary replay',
    );
    steps.add({'name': 'daily-home-ordinary-resume', ...await state()});

    // Real first-clear/patch receipt and Next through ordinary production UI.
    await c.goHome();
    await b05Seed(c.store, c.library, 3);
    final prepared = b05Finish(
      GameInstance.create(
        id: 'full-board-real-four-${DateTime.now().microsecondsSinceEpoch}',
        puzzle: c.library.main[4]!,
      ),
      take: c.library.main[4]!.referenceMoves.length - 1,
    );
    await c.store.save(prepared, replace: true);
    await c.initialize();
    c.resume();
    await readyBoard();
    final last = c.current!.puzzle.referenceMoves.last;
    steps.add(await move(last.from, last.to, 'formal-clear-four', shots: true));
    require(
      c.progress.firstClears == 4 && c.progress.pieces.length == 1,
      'real atomic main4 receipt',
    );
    require(
      find.byType(BoardPage).evaluate().isEmpty,
      'completion has no active presenter',
    );
    final receipts = c.progress.receipts;
    await tap('view-patch');
    await until(() => c.page == GamePage.reward);
    await tap('next');
    await until(() => c.page == GamePage.board && !c.busy);
    await readyBoard();
    hotEntries.add({
      'target': 'next-level-board',
      'pointer_up_to_ready_frame_us':
          watch.elapsedMicroseconds - lastPointerUpUs,
    });
    require(
      c.current!.puzzle.mainLevel == 5 &&
          c.current!.moveCount == 0 &&
          c.progress.receipts == receipts,
      'saved patch Next creates one instance and no repeat award',
    );
    steps.add({'name': 'real-reward-next-board', ...await state()});
    await c.goHome();
    await until(() => c.page == GamePage.home);
    await tap('settings');
    await until(() => c.page == GamePage.settings);
    for (final key in [
      'music',
      'sound',
      'haptics',
      'reduced_motion',
      'strong_contrast',
    ]) {
      await tap('setting-$key');
      await until(() => !c.busy && c.phase == SavePhase.clean);
    }
    require(
      !c.settings.music &&
          !c.settings.sound &&
          !c.settings.haptics &&
          c.settings.reducedMotion &&
          c.settings.strongContrast,
      'real native settings disable sound/haptics and enable reduced/high-contrast',
    );
    await tap('home');
    await tap('resume');
    await readyBoard();
    await setup(9, extra: true);
    steps.add(await move(0, 6, 'reduced-muted-seven'));
    require(
      c.motion == null && c.current!.extraBottleGranted,
      'reduced animation completes with entitlement intact',
    );
    await capture('reduced-contrast-seven');
    await flush();
    steps.add({
      'name': 'real-settings-reduced-muted-contrast',
      ...await state(),
    });
    await c.goHome();
    await until(() => c.page == GamePage.home);
    await tap('settings');
    await until(() => c.page == GamePage.settings);
    for (final key in [
      'music',
      'sound',
      'haptics',
      'reduced_motion',
      'strong_contrast',
    ]) {
      await tap('setting-$key');
      await until(() => !c.busy && c.phase == SavePhase.clean);
    }
    await tap('home');
    await tap('resume');
    await readyBoard();
    return {
      'ok': true,
      'phase': phase,
      'steps': steps,
      'hot_entries': hotEntries,
      'frame_timings': timings,
      'native_runner_pass': false,
      'physical_performance_pass': false,
      'scope': 'actual normal main + formal puzzles; explicitly prepared replay prefixes and extra-bottle QA entitlement',
    };
  }

  var running = false;
  Timer.periodic(const Duration(milliseconds: 50), (_) async {
    final command = File('${out.path}/command.json');
    if (running || !command.existsSync()) return;
    running = true;
    var id = 'invalid';
    try {
      final request = jsonDecode(await command.readAsString()) as Map;
      await command.delete();
      id = request['id'] as String;
      require(RegExp(r'^[a-z0-9_-]+$').hasMatch(id), 'safe command id');
      switch (request['action']) {
        case 'route':
          final result = await route();
          await flush();
          await write(id, result);
        case 'timed-moves':
          final steps = <Map<String, Object?>>[];
          await setup(9, extra: true);
          timings.clear();
          for (var run = 0; run < 3; run++) {
            if (run > 0) await setup(9, extra: true);
            final moves = c.current!.puzzle.referenceMoves;
            for (var n = 0; n < moves.length; n++) {
              steps.add(
                await move(moves[n].from, moves[n].to, 'timed-$run-$n'),
              );
            }
          }
          await write(id, {
            'ok': true,
            'phase': phase,
            'steps': steps,
            'frame_timings': timings,
            'scope': '27 real native pointer pours without PNG capture; debug Simulator/AVD diagnostics only',
          });
        case 'prepare-background':
          final prefix = c.library.main[9]!.referenceMoves
              .take(6)
              .map((m) => [m.from, m.to])
              .toList();
          await setup(9, extra: true, prefix: prefix);
          await write(id, {
            'ok': true,
            'next_native_pour': [1, 0],
            ...await state(),
          });
        case 'prepare-startup':
          await c.resetProgress();
          await until(() => !c.busy && c.phase == SavePhase.clean);
          await setup(9);
          await c.goHome();
          await until(() => c.page == GamePage.home);
          await write(id, {'ok': true, ...await state()});
        case 'prepare-restore':
          final prefix = c.library.main[9]!.referenceMoves
              .take(6)
              .map((m) => [m.from, m.to])
              .toList();
          await setup(9, extra: true, prefix: prefix);
          final m = c.current!.puzzle.referenceMoves[6];
          final planned = c.current!.pour(m.from, m.to);
          require(
            planned.units == 4 && !planned.state.completed,
            'four-unit nonwinning recovery setup',
          );
          await tap('bottle-${m.from}', board: true);
          await tap('bottle-${m.to}', board: true);
          await until(
            () =>
                c.phase == SavePhase.clean &&
                (phase == 'before'
                    ? c.motion != null
                    : ((visualState()?['in_stream'] as num? ?? 0) > .02 &&
                          (visualState()?['out'] as num? ?? 4) < 1)),
          );
          await write(id, {'ok': true, ...await state()});
        case 'resume':
          if (c.page != GamePage.board) await tap('resume');
          await readyBoard();
          await write(id, {'ok': true, ...await state()});
        case 'undo-restored':
          final expected = c.current!.undo();
          await tap('undo');
          await until(() => !c.busy && c.phase == SavePhase.clean);
          await readyBoard();
          require(
            c.current!.toJson().toString() == expected.toJson().toString(),
            'actual native Undo consumes restored history exactly once',
          );
          await write(id, {'ok': true, ...await state()});
        case 'capture':
          await readyBoard();
          await capture(id);
          await flush();
          await write(id, {'ok': true, ...await state()});
        case 'sample-start':
          timings.clear();
          await write(id, {'ok': true, ...await state()});
        case 'sample-end':
          await write(id, {
            'ok': true,
            'frame_timings': timings,
            ...await state(),
          });
        default:
          await write(id, {'ok': true, ...await state()});
      }
    } catch (error, stack) {
      Map<String, Object?> details;
      try {
        details = await state();
      } catch (diagnosticError) {
        details = {
          'pid': pid,
          'page': c.page.name,
          'save_phase': c.phase.name,
          'phase': phase,
          'diagnostic_error': diagnosticError.toString(),
        };
      }
      await write(id, {
        'ok': false,
        'error': error.toString(),
        'last_action': lastAction,
        'stack': stack.toString().substring(
          0,
          mathMin(stack.toString().length, 1500),
        ),
        ...details,
      });
    } finally {
      running = false;
    }
  });
}

int mathMin(int a, int b) => a < b ? a : b;
