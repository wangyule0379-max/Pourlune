// Native widget gestures and real sqflite. Same deterministic route before/after;
// milestone preparation is explicit test setup, not ordinary player progression.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/main.dart' as product;
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart' show b05Seed, b05Finish;

void qaExpect(Object? actual, Object? expected, {String? reason}) {
  final matcher = expected is Matcher ? expected : equals(expected);
  if (!matcher.matches(actual, <Object?, Object?>{})) {
    throw StateError('Motion check failed: $reason; actual=$actual');
  }
}

Future<void> main() async {
  if (!kDebugMode ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled') {
    throw StateError('QA only');
  }
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final tester = LiveWidgetController(binding);
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  const phase = String.fromEnvironment(
    'POURLUNE_MOTION_PHASE',
    defaultValue: 'before',
  );
  qaExpect(database, 'motion_runtime.sqlite');
  final base = await getDatabasesPath();
  await deleteDatabase(
    '$base/$database',
  ); // This isolated named test database only.
  final out = Directory('$base/motion-runtime-$phase');
  await out.create(recursive: true);
  final frames = <Map<String, int>>[];
  binding.addTimingsCallback((values) {
    for (final f in values) {
      frames.add({
        'build_us': f.buildDuration.inMicroseconds,
        'raster_us': f.rasterDuration.inMicroseconds,
        'total_us': f.totalSpan.inMicroseconds,
      });
    }
  });
  final previousError = FlutterError.onError;
  product.main();
  FlutterError.onError = previousError;
  await tester.pump(const Duration(milliseconds: 100));
  for (
    var i = 0;
    i < 150 && find.byType(product.PourluneApp).evaluate().isEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  qaExpect(find.byType(product.PourluneApp), findsOneWidget);
  final c = tester
      .widget<product.PourluneApp>(find.byType(product.PourluneApp))
      .controller;
  final steps = <Map<String, Object?>>[];
  Future<void> settled() async {
    for (var n = 0; n < 200 && (n < 20 || c.busy); n++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Test pacing for recorded comparison; not a product input delay.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
  }

  Future<void> record(String name) async {
    final saved = (await c.store.load(c.current?.slot ?? 'ordinary')).instance;
    steps.add({
      'name': name,
      'utc': DateTime.now().toUtc().toIso8601String(),
      'page': c.page.name,
      'phase': c.phase.name,
      'instance': c.current?.id,
      'revision': c.current?.revision,
      'saved_revision': saved?.revision,
      'first_clears': c.progress.firstClears,
      'pieces': c.progress.pieces,
    });
  }

  Future<void> tap(String key) async {
    // ignore: avoid_print
    print('MOTION_TAP:$key');
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await settled();
  }

  // ignore: avoid_print
  print('MOTION_READY');
  await settled();
  await Future<void>.delayed(const Duration(seconds: 8));
  frames.clear();
  await tap('sample-main-001');
  await tap('bottle-0');
  await tap('bottle-2');
  qaExpect(c.current!.revision, 1);
  qaExpect((await c.store.load('ordinary')).instance!.revision, 1);
  await record('legal-move-saved');
  await tap('pause');
  qaExpect(find.byKey(const Key('pause-card')), findsOneWidget);
  await tap('pause-home');
  await tap('chapters');
  await tap('home');
  await tap('settings');
  await tap('rules');
  await tap('home'); // Rules returns to Settings.
  await tap('home');
  await tap('daily');
  await tap('home');
  await tap('collection');
  await tap('scene-color_studio');
  await tap('collection-back');
  await tap('home');
  await tap('resume');
  await tap('pause');
  await tap('resume-pause');
  await record('navigation-and-resume');

  // Controlled existing-state setup, using actual settlement transactions.
  await b05Seed(c.store, c.library, 3);
  final puzzle = c.library.main[4]!;
  final instance = b05Finish(
    GameInstance.create(id: 'motion-native-main004', puzzle: puzzle),
    take: puzzle.referenceMoves.length - 1,
  );
  await c.store.save(instance, replace: true);
  await c.initialize();
  c.resume();
  await settled();
  await record('controlled-main004-before-final-move');
  final last = puzzle.referenceMoves.last;
  await tap('bottle-${last.from}');
  await tap('bottle-${last.to}');
  qaExpect(c.progress.firstClears, 4);
  qaExpect(c.progress.pieces, contains('color_studio:1'));
  await record('saved-completion');
  await tap('view-patch');
  await record('patch-reveal');
  await tap('next');
  qaExpect(c.current!.puzzle.mainLevel, 5);
  qaExpect(c.progress.firstClears, 4);
  qaExpect(c.progress.pieces.where((p) => p == 'color_studio:1').length, 1);
  await record('next-level-once');
  final report = jsonEncode({
    'phase_label': phase,
    'platform': Platform.operatingSystem,
    'mode': 'debug standalone LiveWidgetController native gestures',
    'steps': steps,
    'frame_timings': frames,
    'physical_performance_pass': false,
  });
  // Host captures this before the native test runner may remove its container.
  // ignore: avoid_print
  print('MOTION_ROUTE_JSON:$report');
  await File('${out.path}/route.json').writeAsString(
    jsonEncode({
      'phase_label': phase,
      'mode': 'debug standalone LiveWidgetController native gestures',
      'platform': Platform.operatingSystem,
      'steps': steps,
      'frame_timings': frames,
      'physical_performance_pass': false,
    }),
    flush: true,
  );
}
