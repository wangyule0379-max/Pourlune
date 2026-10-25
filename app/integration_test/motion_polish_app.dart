// Isolated offline diagnostic. Product main/Bootstrap, real sqflite and formal
// content; no test runner or shipping controls. Keep before/after build modes equal.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as product;
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart' show b05Seed, b05Finish;

Future<void> main() async {
  if (!kDebugMode ||
      const String.fromEnvironment('POURLUNE_DATABASE') !=
          'motion_polish.sqlite' ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled' ||
      const bool.fromEnvironment('POURLUNE_FIREBASE_NATIVE_READY')) {
    throw StateError('Isolated offline motion diagnostic required');
  }
  const phase = String.fromEnvironment(
    'POURLUNE_MOTION_PHASE',
    defaultValue: 'before',
  );
  final startup = Stopwatch()..start();
  final began = DateTime.now().toUtc().toIso8601String();
  final frames = <Map<String, int>>[];
  int? firstFrame;
  product.main();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    firstFrame = startup.elapsedMicroseconds;
  });
  WidgetsBinding.instance.addTimingsCallback((values) {
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
  GameController? controller;
  void locate(Element e) {
    if (e.widget case final product.PourluneApp app) {
      controller = app.controller;
    }
    e.visitChildElements(locate);
  }

  for (var n = 0; n < 3000 && controller == null; n++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    WidgetsBinding.instance.rootElement?.visitChildElements(locate);
  }
  final c = controller;
  if (c == null) throw StateError('Bootstrap did not mount');
  await WidgetsBinding.instance.endOfFrame;
  final interactive = startup.elapsedMicroseconds;
  final out = Directory('${await getDatabasesPath()}/motion-polish');
  await out.create(recursive: true);
  Future<void> write(String name, Object value) async {
    await File('${out.path}/$name.json')
        .writeAsString(jsonEncode(value), flush: true);
  }

  Future<Map<String, Object?>> state() async {
    final saved = (await c.store.load(c.current?.slot ?? 'ordinary')).instance;
    return {
      'pid': pid,
      'phase_label': phase,
      'mode': 'debug Simulator/AVD diagnostic',
      'utc': DateTime.now().toUtc().toIso8601String(),
      'page': c.page.name,
      'save_phase': c.phase.name,
      'busy': c.busy,
      'motion': c.motion != null,
      'instance_id': c.current?.id,
      'revision': c.current?.revision,
      'saved_instance_id': saved?.id,
      'saved_revision': saved?.revision,
      'first_clears': c.progress.firstClears,
      'pieces': c.progress.pieces,
      'revealed': c.progress.revealedPieces,
      'receipts': c.progress.receipts,
      'firebase': c.services?.firebaseStatus,
      'reduced_motion': c.settings.reducedMotion,
      'frames': frames.length,
    };
  }

  await write('startup-$phase-$pid', {
    'began_utc': began,
    'dart_main_to_first_post_frame_us': firstFrame,
    'dart_main_to_home_interactive_sample_us': interactive,
    'interactive_sampling_resolution_us': 10000,
    'excludes_native_pre_Dart_launch': true,
    ...await state(),
  });
  var running = false;
  Timer.periodic(const Duration(milliseconds: 50), (_) async {
    final file = File('${out.path}/command.json');
    if (running || !file.existsSync()) return;
    running = true;
    var id = 'invalid';
    try {
      final command = jsonDecode(await file.readAsString()) as Map;
      await file.delete();
      final candidate = command['id'] as String;
      if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(candidate)) {
        throw StateError('Invalid ID');
      }
      id = candidate;
      final action = command['action'];
      if (action == 'sample-start') {
        frames.clear();
      } else if (action == 'sample-end') {
        await write(id, {'frame_timings': frames, ...await state()});
        return;
      } else if (action == 'prepare-milestone') {
        // Explicit setup only: real transactions, first3 reference clears and
        // main004 before its last move. Never presented as ordinary progression.
        await b05Seed(c.store, c.library, 3);
        final puzzle = c.library.main[4]!;
        final prepared = b05Finish(
          GameInstance.create(id: 'motion-qa-main004', puzzle: puzzle),
          take: puzzle.referenceMoves.length - 1,
        );
        await c.store.save(prepared, replace: true);
        await c.initialize();
        c.resume();
      } else if (action == 'reduced') {
        await c.updateSetting('reduced_motion', command['value'] == true);
      } else if (action == 'state') {
        // Read-only current state.
      } else {
        throw StateError('Unknown action');
      }
      await write(id, {'ok': true, ...await state()});
    } catch (_) {
      await write(id, {
        'ok': false,
        'category': 'motion_diagnostic_failed',
        ...await state(),
      });
    } finally {
      running = false;
    }
  });
}
