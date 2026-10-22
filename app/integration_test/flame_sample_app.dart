// Standalone real-native QA. Uses documented LiveWidgetController gestures,
// real sample Bootstrap and SQLite, without the flaky DDS integration runner.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/development/flame_sample/games.dart';
import 'package:pourlune_dev/development/flame_sample/session.dart';
import 'package:pourlune_dev/development/flame_sample_main.dart' as sample;
import 'package:sqflite/sqflite.dart';

void check(bool value, String reason) {
  if (!value) throw StateError(reason);
}

Future<void> main() async {
  if (!kDebugMode ||
      const String.fromEnvironment('POURLUNE_DATABASE') !=
          'flame_sample.sqlite') {
    throw StateError('QA only');
  }
  final watch = Stopwatch()..start();
  sample.main();
  final binding = WidgetsBinding.instance;
  int? firstFrame;
  binding.addPostFrameCallback((_) => firstFrame = watch.elapsedMicroseconds);
  final frames = <Map<String, int>>[];
  binding.addTimingsCallback((values) {
    for (final f in values) {
      if (frames.length < 20000) {
        frames.add({
          'build_us': f.buildDuration.inMicroseconds,
          'raster_us': f.rasterDuration.inMicroseconds,
          'total_us': f.totalSpan.inMicroseconds,
        });
      }
    }
  });
  final tester = LiveWidgetController(binding);
  FlameSampleSession? session;
  void locate(Element e) {
    if (e.widget case final sample.FlameSampleApp app) {
      session = app.session;
    }
    e.visitChildElements(locate);
  }

  for (var n = 0; n < 3000 && session == null; n++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    binding.rootElement?.visitChildElements(locate);
  }
  final s = session;
  if (s == null) throw StateError('Sample did not open');
  PourSampleGame? pourGame() {
    final matches = find.byType(GameWidget<PourSampleGame>).evaluate();
    return matches.isEmpty
        ? null
        : (matches.single.widget as GameWidget<PourSampleGame>).game;
  }

  PatchSampleGame? patchGame() {
    final matches = find.byType(GameWidget<PatchSampleGame>).evaluate();
    return matches.isEmpty
        ? null
        : (matches.single.widget as GameWidget<PatchSampleGame>).game;
  }

  Future<void> until(bool Function() ready, {int milliseconds = 10000}) async {
    final end = DateTime.now().add(Duration(milliseconds: milliseconds));
    while (!ready()) {
      if (DateTime.now().isAfter(end)) {
        throw StateError('Native wait timed out');
      }
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  await until(() => pourGame()?.assetsReady == true);
  await tester.pump();
  final readyUs = watch.elapsedMicroseconds;
  final out = Directory('${await getDatabasesPath()}/flame-sample');
  await out.create(recursive: true);
  Future<void> write(String name, Object? value) =>
      File('${out.path}/$name.json')
          .writeAsString(jsonEncode(value), flush: true);
  Future<Map<String, Object?>> controllerState(GameController c) async => {
    'instance': c.current?.toJson(),
    'saved': (await c.store.load('ordinary')).instance?.toJson(),
    'settings': c.settings.toJson(),
    'phase': c.phase.name,
    'page': c.page.name,
    'busy': c.busy,
    'motion': c.motion?.token,
    'first_clears': c.progress.firstClears,
    'receipts': c.progress.receipts,
    'pieces': c.progress.pieces,
    'revealed': c.progress.revealedPieces,
  };
  Future<Map<String, Object?>> state() async => {
    'pid': pid,
    'utc': DateTime.now().toUtc().toIso8601String(),
    'platform': Platform.operatingSystem,
    'mode': 'debug standalone native LiveWidgetController',
    'bottles': await controllerState(s.bottles),
    'patch': await controllerState(s.patch),
    'pour_view': pourGame()?.snapshot(),
    'patch_view': patchGame()?.snapshot(),
    'rss_bytes': ProcessInfo.currentRss,
    'frames': frames.length,
  };
  await write('startup-$pid', {
    'dart_main_to_first_post_frame_us': firstFrame,
    'dart_main_to_first_ready_bottle_frame_us': readyUs,
    'sampling_resolution_us': 10000,
    'excludes_native_pre_Dart_launch': true,
    ...await state(),
  });
  var lastPointerUpUs = 0;
  var lastAction = 'startup';
  Future<void> tap(String key, {int hold = 120}) async {
    lastAction = key;
    final any = find.byKey(Key(key));
    check(any.evaluate().length == 1, 'unique native key $key');
    if (key.startsWith('flame-bottle-')) {
      await tester.ensureVisible(find.byType(GameWidget<PourSampleGame>));
    } else if (any.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(any);
    }
    await tester.pump();
    await until(() {
      final widget = any.evaluate().single.widget;
      return widget is ButtonStyleButton
          ? widget.onPressed != null
          : widget is SwitchListTile
          ? widget.onChanged != null
          : true;
    });
    // A controller can become clean before its async QA reset has rebuilt the
    // native button. Never press a still-disabled recognizer or moving layout.
    await tester.pump(const Duration(milliseconds: 50));
    check(any.hitTestable().evaluate().isNotEmpty, 'native target $key');
    final gesture = await tester.startGesture(tester.getCenter(any));
    await Future<void>.delayed(Duration(milliseconds: hold));
    await gesture.up();
    lastPointerUpUs = watch.elapsedMicroseconds;
    await tester.pump(const Duration(milliseconds: 20));
  }

  final pendingCaptures = <(String, ui.Image, Map<String, Object?>)>[];
  Future<void> flushCaptures() async {
    final folder = Directory('${out.path}/screens');
    await folder.create(recursive: true);
    while (pendingCaptures.isNotEmpty) {
      final (name, image, painted) = pendingCaptures.removeAt(0);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${folder.path}/$name.frame.json')
            .writeAsString(jsonEncode(painted), flush: true);
        await File('${folder.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    }
  }

  Future<void> capture(String name) async {
    binding.scheduleFrame();
    await binding.endOfFrame;
    final boundary =
        find
                .byKey(const Key('flame-sample-capture'))
                .evaluate()
                .single
                .renderObject!
            as RenderRepaintBoundary;
    final painted = {
      'utc': DateTime.now().toUtc().toIso8601String(),
      'pour': pourGame()?.snapshot(),
      'patch': patchGame()?.snapshot(),
    };
    // Snapshot now, encode only after the action finishes. PNG encoding on
    // Android debug can otherwise skip the following short visual phase.
    pendingCaptures.add((name, boundary.toImageSync(pixelRatio: 1), painted));
  }

  Future<void> bottleTab() async {
    if (pourGame() == null) {
      await tap('sample-bottles');
      await until(() => pourGame()?.assetsReady == true);
    }
  }

  Future<void> onePour(int units, bool reverse, {bool shots = false}) async {
    await bottleTab();
    await until(() => s.bottles.phase == SavePhase.clean && !s.bottles.busy);
    await tap('sample-units-$units');
    await until(() => s.bottles.phase == SavePhase.clean && !s.bottles.busy);
    check(
      s.units == units && s.bottles.current!.moveCount == 0,
      'fresh requested fixture',
    );
    final g = pourGame()!;
    if (g.reverse != reverse) {
      await tap('sample-direction');
    }
    check(g.reverse == reverse, 'requested direction');
    final from = reverse ? 1 : 0, to = 1 - from;
    await tap('flame-bottle-$from');
    await tester.pump(const Duration(milliseconds: 160));
    if (shots) await capture('u$units-${reverse ? 'rl' : 'lr'}-selected');
    await tap('flame-bottle-$to');
    check(
      s.bottles.current!.moveCount == 1 &&
          s.bottles.current!.board[0].length == 4 - units &&
          s.bottles.current!.board[2].length == units,
      'one native move with the requested volume',
    );
    if (shots) {
      for (final stage in ['approach', 'pour', 'return']) {
        await until(() => g.status.value == stage, milliseconds: 4000);
        if (stage == 'pour') {
          await until(
            () =>
                (g.snapshot()['elapsed_ms'] as double) >=
                290 + g.geometry.flowMs * .35,
          );
        }
        await capture('u$units-${reverse ? 'rl' : 'lr'}-$stage');
      }
    }
    await until(() => !s.bottles.busy);
    check(
      s.bottles.current!.revision == 1 && s.bottles.progress.firstClears == 0,
      'no duplicate move or award',
    );
    if (shots) {
      await capture('u$units-${reverse ? 'rl' : 'lr'}-landed');
      await flushCaptures();
    }
  }

  Future<Map<String, Object?>> route() async {
    await bottleTab();
    final initialSettings = s.bottles.settings;
    if (initialSettings.reducedMotion) {
      await tap('sample-setting-reduced_motion');
      await until(
        () =>
            !s.bottles.settings.reducedMotion &&
            s.bottles.phase == SavePhase.clean &&
            s.patch.phase == SavePhase.clean,
      );
    }
    frames.clear();
    final steps = <Map<String, Object?>>[];
    final hotEntries = <Map<String, Object?>>[];
    for (final reverse in [false, true]) {
      for (var u = 1; u <= 4; u++) {
        await onePour(u, reverse, shots: u == 1 || u == 4);
        steps.add({'case': '$u-${reverse ? 'rl' : 'lr'}', ...await state()});
      }
    }
    await tap('sample-units-2');
    await until(() => !s.bottles.busy);
    final selected = pourGame()!.reverse ? 1 : 0;
    await tap('flame-bottle-$selected');
    await tap('flame-bottle-$selected');
    check(
      s.bottles.selectedSource == null && s.bottles.current!.moveCount == 0,
      'native deselection does not mutate',
    );
    await tap('sample-invalid');
    check(s.bottles.current!.moveCount == 0, 'invalid does not mutate');
    await capture('invalid');
    await tap('sample-fail-write');
    await tap('flame-bottle-1');
    await tap('flame-bottle-0');
    await until(() => s.bottles.phase == SavePhase.failed && !s.bottles.busy);
    await capture('save-failed');
    steps.add({'case': 'failed-pour', ...await state()});
    await tap('sample-retry');
    await until(() => s.bottles.phase == SavePhase.clean);
    await tap('sample-units-2');
    await until(() => !s.bottles.busy);
    final active = pourGame()!, source = active.reverse ? 1 : 0;
    await tap('flame-bottle-$source');
    await tap('flame-bottle-${1 - source}');
    await until(
      () => active.status.value == 'pour' && s.bottles.phase == SavePhase.clean,
    );
    final oldInstance = s.bottles.current!.id,
        oldToken = s.bottles.motion!.token;
    await tap('sample-reset');
    await until(() => s.bottles.phase == SavePhase.clean);
    await tester.pump(const Duration(milliseconds: 1200));
    check(
      s.bottles.current!.id != oldInstance &&
          s.bottles.current!.revision == 0 &&
          s.bottles.motion == null,
      'old motion cannot touch reset instance',
    );
    steps.add({
      'case': 'cancelled-motion',
      'cancelled_token': oldToken,
      ...await state(),
    });
    await tap('sample-patch');
    await until(() => patchGame()?.assetsReady == true);
    await tester.pump();
    hotEntries.add({
      'target': 'patch',
      'from_pointer_up_to_first_ready_frame_us':
          watch.elapsedMicroseconds - lastPointerUpUs,
    });
    await tap('sample-reward-reset');
    await until(
      () =>
          s.patch.current?.puzzle.mainLevel == 4 &&
          !s.patch.current!.completed &&
          s.patch.phase == SavePhase.clean,
    );
    await tap('sample-complete');
    await until(
      () => s.patch.current!.completed && s.patch.phase == SavePhase.clean,
    );
    check(
      s.patch.progress.firstClears == 4 && s.patch.progress.pieces.length == 1,
      'real reward receipt',
    );
    await capture('patch-saved-source');
    final receipts = s.patch.progress.receipts;
    await tap('sample-place');
    await until(() => patchGame()!.active);
    await tester.pump(const Duration(milliseconds: 300));
    await capture('patch-flight');
    await until(() => !patchGame()!.active);
    await capture('patch-attached');
    await flushCaptures();
    check(
      s.patch.progress.receipts == receipts &&
          s.patch.progress.revealedPieces.length == 1,
      'placement never reawards',
    );
    steps.add({'case': 'patch-saved-flight-landed', ...await state()});
    final old = patchGame()!;
    await tap('sample-bottles');
    await until(() => pourGame()?.assetsReady == true);
    await tester.pump();
    hotEntries.add({
      'target': 'bottles',
      'from_pointer_up_to_first_ready_frame_us':
          watch.elapsedMicroseconds - lastPointerUpUs,
    });
    check(old.closed && old.ownedImages == 0, 'patch images freed');
    await tap('sample-setting-reduced_motion');
    await until(
      () =>
          s.bottles.settings.reducedMotion &&
          s.bottles.phase == SavePhase.clean,
    );
    await tap('sample-units-1');
    await until(() => !s.bottles.busy);
    final reducedFrom = pourGame()!.reverse ? 1 : 0;
    await tap('flame-bottle-$reducedFrom');
    await tap('flame-bottle-${1 - reducedFrom}');
    await until(() => !s.bottles.busy);
    check(
      s.bottles.current!.moveCount == 1,
      'reduced motion still commits the requested move',
    );
    await capture('reduced-motion');
    await tap('sample-setting-reduced_motion');
    await until(
      () =>
          !s.bottles.settings.reducedMotion &&
          s.bottles.phase == SavePhase.clean,
    );
    steps.add({'case': 'reduced-motion-and-cleanup', ...await state()});
    for (final entry in [
      ('sound', () => s.bottles.settings.sound),
      ('music', () => s.bottles.settings.music),
      ('haptics', () => s.bottles.settings.haptics),
    ]) {
      if (entry.$2()) {
        await tap('sample-setting-${entry.$1}');
        await until(() => s.bottles.phase == SavePhase.clean);
      }
    }
    await until(() => s.bottles.phase == SavePhase.clean);
    await onePour(2, false);
    check(
      !s.bottles.settings.sound &&
          !s.bottles.settings.music &&
          !s.bottles.settings.haptics,
      'native switches saved',
    );
    steps.add({'case': 'muted-haptics-off-free-play', ...await state()});

    for (final entry in [
      ('sound', () => s.bottles.settings.sound, initialSettings.sound),
      ('music', () => s.bottles.settings.music, initialSettings.music),
      ('haptics', () => s.bottles.settings.haptics, initialSettings.haptics),
      (
        'reduced_motion',
        () => s.bottles.settings.reducedMotion,
        initialSettings.reducedMotion,
      ),
    ]) {
      if (entry.$2() != entry.$3) {
        await tap('sample-setting-${entry.$1}');
        await until(
          () =>
              s.bottles.phase == SavePhase.clean &&
              s.patch.phase == SavePhase.clean,
        );
      }
    }
    return {
      'ok': true,
      'restored_settings': s.bottles.settings.toJson(),
      'steps': steps,
      'hot_entries': hotEntries,
      'frame_timings': frames,
      'physical_performance_pass': false,
      'native_runner_pass': false,
      'scope': 'real native standalone pointer gestures + SQLite, controlled engineering/prepared-main004 setups',
    };
  }

  var running = false;
  Timer.periodic(const Duration(milliseconds: 50), (_) async {
    final file = File('${out.path}/command.json');
    if (running || !file.existsSync()) return;
    running = true;
    var id = 'invalid';
    try {
      final command = jsonDecode(await file.readAsString()) as Map;
      await file.delete();
      id = command['id'] as String;
      check(RegExp(r'^[a-z0-9_-]+$').hasMatch(id), 'safe output id');
      final action = command['action'];
      if (action == 'route') {
        final result = await route();
        await flushCaptures();
        await write(id, result);
      } else if (action == 'prepare-restore') {
        await bottleTab();
        await tap('sample-units-2');
        await until(() => !s.bottles.busy);
        final g = pourGame()!;
        final from = g.reverse ? 1 : 0;
        await tap('flame-bottle-$from');
        await tap('flame-bottle-${1 - from}');
        await until(
          () => g.status.value == 'pour' && s.bottles.phase == SavePhase.clean,
        );
        // Respond while the pour is active; screenshot encoding must not
        // postpone the host's real process kill beyond this short action.
        await write(id, {'ok': true, ...await state()});
      } else if (action == 'capture') {
        await capture(id);
        await flushCaptures();
        await write(id, {'ok': true, ...await state()});
      } else if (action == 'sample-start') {
        frames.clear();
        await write(id, {'ok': true, ...await state()});
      } else if (action == 'sample-end') {
        await write(id, {
          'ok': true,
          'frame_timings': frames,
          ...await state(),
        });
      } else {
        await write(id, {'ok': true, ...await state()});
      }
    } catch (error, stack) {
      await write(id, {
        'ok': false,
        'last_action': lastAction,
        'state': await state(),
        'stack': stack.toString().substring(
          0,
          mathMin(stack.toString().length, 1600),
        ),
        'error': error.toString().substring(
          0,
          mathMin(error.toString().length, 400),
        ),
      });
    } finally {
      running = false;
    }
  });
}

int mathMin(int a, int b) => a < b ? a : b;
