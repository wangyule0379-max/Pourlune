// Native B03 evidence harness. This is automated acceptance evidence, not human play.
// Run from app/ without POURLUNE_SCENARIO:
// flutter test integration_test/b03_runtime_test.dart -d <device-id> \
//   --dart-define=POURLUNE_DATABASE=b03_runtime.sqlite
// JSON, log and actual Flutter PNGs remain in getDatabasesPath()/b03-evidence.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/bottle.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:sqflite/sqflite.dart';

const _captureKey = Key('b03-native-root-capture');
const _galleryCaptureKey = Key('b03-gallery-content');
const _scenes = ['color_studio', 'garden_nook', 'seaside_corner'];
const _representatives = {1, 5, 9, 12, 20, 21, 40, 41, 60};

GameInstance _referenceFinish(GameInstance state) {
  for (final move in state.puzzle.referenceMoves) {
    final result = state.pour(move.from, move.to);
    if (!result.changed) {
      throw StateError('Illegal setup reference ${state.puzzle.id}');
    }
    state = result.state;
  }
  if (!state.completed) {
    throw StateError('Unfinished setup reference ${state.puzzle.id}');
  }
  return state;
}

Map<String, Object?> _progress(LocalProgress p) => {
  'first_clears': p.firstClears,
  'completed_levels': p.completedLevels,
  'pieces': p.pieces,
  'revealed_pieces': p.revealedPieces,
  'daily_stamps': p.dailyStamps,
  'receipts': p.receipts,
};

/// Keeps the real Bootstrap mounted while displaying a controlled asset gallery.
/// No test routes, seeds or drawing hooks are added to production code.
class _EvidenceHost extends StatelessWidget {
  const _EvidenceHost(this.gallery);
  final ValueNotifier<Widget?> gallery;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
      key: _captureKey,
      child: ValueListenableBuilder<Widget?>(
        valueListenable: gallery,
        child: const app.Bootstrap(),
        builder: (context, overlay, bootstrap) => Stack(
          fit: StackFit.expand,
          children: [
            Offstage(offstage: overlay != null, child: bootstrap),
            ?overlay,
          ],
        ),
      ),
    ),
  );
}

class _AssetGallery extends StatelessWidget {
  const _AssetGallery({
    required this.title,
    required this.child,
    this.textScale = 1,
    this.reduced = false,
  });
  final String title;
  final Widget child;
  final double textScale;
  final bool reduced;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(fontFamily: 'Nunito', scaffoldBackgroundColor: cream),
    builder: (context, body) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduced,
      ),
      child: body!,
    ),
    home: Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _galleryCaptureKey,
          child: ColoredBox(
            color: cream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Controlled native asset gallery — not gameplay or an ad reward.',
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('B03 default90 native gameplay, milestones and layered art evidence', (
    t,
  ) async {
    const scenario = String.fromEnvironment('POURLUNE_SCENARIO');
    const filename = String.fromEnvironment('POURLUNE_DATABASE');
    if (scenario.isNotEmpty || filename != 'b03_runtime.sqlite') {
      throw StateError(
        'B03 requires no POURLUNE_SCENARIO and exact isolated POURLUNE_DATABASE=b03_runtime.sqlite',
      );
    }
    final databaseRoot = await getDatabasesPath();
    final databasePath = '$databaseRoot/$filename';
    final output = Directory('$databaseRoot/b03-evidence');
    if (await output.exists()) await output.delete(recursive: true);
    await output.create(recursive: true);
    // Only this explicitly isolated test DB is cleared. Keep it after the run.
    await deleteDatabase(databasePath);
    final gallery = ValueNotifier<Widget?>(null);
    GameController? controller;
    final events = <Map<String, Object?>>[];
    final screenshots = <Map<String, Object?>>[];
    final report = <String, Object?>{
      'status': 'running',
      'scope': 'Automated native integration; no human play, subjective assessment, acoustic measurement or process-restart claim.',
      'database': databasePath,
      'evidence_directory': output.path,
      'scenario': scenario,
      'runtime': Platform.operatingSystemVersion,
      'started_at': DateTime.now().toIso8601String(),
      'events': events,
      'screenshots': screenshots,
    };
    Future<void> flush() async {
      await File('${output.path}/runtime.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
        flush: true,
      );
      await File('${output.path}/runtime.log')
          .writeAsString(events.map(jsonEncode).join('\n'), flush: true);
    }

    Future<void> record(String kind, Map<String, Object?> values) async {
      events.add({
        'kind': kind,
        'at': DateTime.now().toIso8601String(),
        ...values,
      });
      debugPrint('B03_EVENT: ${jsonEncode(events.last)}');
      await flush();
    }

    void noFlutterError(String context) {
      final error = t.takeException();
      if (error != null) throw StateError('$context: $error');
    }

    Future<void> until(
      bool Function() condition,
      String reason, {
      int milliseconds = 100,
    }) async {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 600 && !condition(); i++) {
        if (watch.elapsed > const Duration(seconds: 45)) break;
        await t.pump(Duration(milliseconds: milliseconds));
        noFlutterError(reason);
      }
      expect(condition(), isTrue, reason: reason);
    }

    Future<void> ready() async {
      await until(
        () => !controller!.busy && !controller.hintSearching,
        'native controller did not finish save/motion/hint',
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(controller!.phase, SavePhase.clean, reason: controller.error);
      noFlutterError('ready');
    }

    Future<void> tap(String key, {bool wait = true}) async {
      final finder = find.byKey(Key(key));
      expect(finder, findsOneWidget, reason: 'Missing actionable $key');
      await t.ensureVisible(finder);
      await t.tap(finder);
      if (wait) {
        await t.pump(const Duration(milliseconds: 100));
        await ready();
      }
    }

    Future<void> capture(
      String name, {
      Key boundaryKey = _captureKey,
      String setup = 'actual default Bootstrap UI',
      bool immediate = false,
    }) async {
      if (!immediate) {
        await t.pump(const Duration(milliseconds: 100));
        // Await actual bundled image decoding, rather than screenshot a placeholder.
        final images = find.byType(Image).evaluate().toList();
        for (final element in images) {
          final widget = element.widget as Image;
          Object? decodeError;
          await precacheImage(
            widget.image,
            element,
            onError: (e, stack) => decodeError = e,
          );
          if (decodeError != null) {
            throw StateError('$name asset decode failed: $decodeError');
          }
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      noFlutterError('capture $name');
      final finder = find.byKey(boundaryKey);
      expect(finder, findsOneWidget);
      final boundary = t.renderObject<RenderRepaintBoundary>(finder);
      final motionAtCapture = controller!.motion;
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw StateError('PNG encoding failed: $name');
        await File('${output.path}/$name.png')
            .writeAsBytes(png.buffer.asUint8List(), flush: true);
        final c = controller!;
        screenshots.add({
          'file': '$name.png',
          'setup': setup,
          'logical_size': [boundary.size.width, boundary.size.height],
          'png_size': [image.width, image.height],
          'capture_pixel_ratio': 2,
          'page': c.page.name,
          'instance_id': c.current?.id,
          'puzzle_id': c.current?.puzzle.id,
          'revision': c.current?.revision,
          'motion_active_at_capture': motionAtCapture != null,
          'motion_from': motionAtCapture?.from,
          'motion_to': motionAtCapture?.to,
          'capture_skipped_additional_frames': immediate,
          'settings': c.settings.toJson(),
        });
      } finally {
        image.dispose();
      }
      await flush();
    }

    Future<void> referenceUI({int skip = 0}) async {
      final c = controller!, puzzle = controller.current!.puzzle;
      for (final move in puzzle.referenceMoves.skip(skip)) {
        final before = c.current!;
        await tap('bottle-${move.from}');
        await tap('bottle-${move.to}');
        expect(c.current!.moveCount, before.moveCount + 1);
        expect(c.current!.revision, before.revision + 1);
        puzzle.validateBoard(c.current!.board, extra: false);
      }
      expect(c.current!.completed, isTrue, reason: puzzle.id);
      expect(c.phase, SavePhase.clean);
      expect(
        (await c.store.load(c.current!.slot)).instance!.toJson(),
        c.current!.toJson(),
      );
    }

    Future<void> sceneState(String scene, int count) async {
      final c = controller!;
      await c.navigate(GamePage.scene, scene: scene);
      await ready();
      expect(find.byType(ScenePage), findsOneWidget);
      expect(
        c.progress.pieces.where((p) => p.startsWith('$scene:')),
        hasLength(count),
      );
      for (var piece = 1; piece <= 5; piece++) {
        expect(
          find.byKey(Key('scene-$scene-piece-$piece')),
          piece <= count ? findsOneWidget : findsNothing,
        );
      }
      await capture('scene-$scene-progress-$count');
      await capture(
        'scene-$scene-progress-$count-composition',
        boundaryKey: Key('scene-$scene-composition'),
        setup: 'actual ScenePage composition RepaintBoundary; same native widget as scene UI',
      );
      await record('scene_progress', {'scene': scene, 'count': count});
    }

    try {
      debugPrint('B03_EVIDENCE_DIRECTORY=${output.path}');
      await t.pumpWidget(_EvidenceHost(gallery));
      await until(
        () => find.byType(app.GameScreen).evaluate().isNotEmpty,
        'Real default Bootstrap failed to open',
      );
      controller = t
          .widget<app.GameScreen>(find.byType(app.GameScreen))
          .controller;
      final c = controller;
      await ready();
      expect(c.library.engineering, isFalse);
      expect(c.library.main.keys.toSet(), {for (var i = 1; i <= 60; i++) i});
      expect(c.library.daily!.puzzles, hasLength(30));
      expect(c.library.daily!.version, 1);
      expect(c.library.daily!.engineering, isFalse);
      expect(
        t.widget<app.GameScreen>(find.byType(app.GameScreen)).advanceTestDay,
        isNull,
      );
      expect(
        t.widget<app.GameScreen>(find.byType(app.GameScreen)).audio,
        isNotNull,
      );
      await record('bootstrap', {
        'main_count': c.library.main.length,
        'daily_count': c.library.daily!.puzzles.length,
        'catalog_version': c.library.daily!.version,
        'epoch': calendarDate(c.library.daily!.epoch),
        'engineering': c.library.engineering,
        'definitions': [...c.library.main.values, ...c.library.daily!.puzzles]
            .map(
              (p) => {
                'id': p.id,
                'version': p.contentVersion,
                'status': p.contentStatus,
                'colors': p.initial.expand((b) => b).toSet().length,
              },
            )
            .toList(),
      });
      await capture('default-welcome');
      for (final scene in _scenes) {
        await sceneState(scene, 0);
      }
      await c.goHome();
      await ready();
      await tap('sample-main-001');
      expect(c.current!.tutorial!.active, isTrue);
      await capture('main001-tutorial-initial');
      final original = c.current!,
          first = c.current!.puzzle.referenceMoves.first;
      await tap('bottle-${first.from}');
      await tap('bottle-${first.to}', wait: false);
      // Observe the real committed-motion object before scheduling more frames.
      expect(c.motion, isNotNull);
      final committed = c.current!;
      expect(committed.board, original.pour(first.from, first.to).state.board);
      expect(committed.revision, original.revision + 1);
      await c.tapBottle(
        1,
      ); // Controller must reject input while presenter owns motion.
      expect(c.current!.revision, committed.revision);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump(const Duration(milliseconds: 100));
      expect(c.motion, isNull);
      expect(c.current!.board, committed.board);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await ready();
      expect((await c.store.load('ordinary')).instance!.board, committed.board);
      await capture('main001-lifecycle-snap-complete-board');
      await record('lifecycle_motion_snap', {
        'motion_observed_before_inactive': true,
        'revisions_committed': 1,
        'whole_board_saved': true,
        'scope':
            'real WidgetsBinding lifecycle notification; not a process kill',
      });
      await tap('undo');
      expect(c.current!.board, original.board);
      expect(c.current!.tutorial!.step, 0);
      for (final move in original.puzzle.referenceMoves.take(3)) {
        await tap('bottle-${move.from}');
        await tap('bottle-${move.to}');
      }
      expect(c.current!.tutorial!.finished, isTrue);
      expect(await c.store.tutorialDone(), isTrue);
      final beforeHint = c.current!;
      await tap('hint');
      expect(c.hint!.status, HintStatus.found);
      expect(c.current!.toJson(), beforeHint.toJson());
      final hint = c.hint!;
      await capture('main001-real-isolate-hint');
      await tap('bottle-${hint.move!.to}', wait: false);
      expect(c.motion, isNotNull);
      await until(
        () => c.phase != SavePhase.saving,
        'Hint action snapshot save',
        milliseconds: 50,
      );
      await tap('pause', wait: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(c.motion, isNull);
      final pauseCard = find.byKey(const Key('pause-card'));
      expect(pauseCard.hitTestable(), findsOneWidget);
      final pauseCopy = AppLocalizations.of(t.element(pauseCard));
      expect(c.phase, SavePhase.clean);
      expect(
        find.descendant(
          of: pauseCard,
          matching: find.text(pauseCopy.pauseTitle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pauseCard,
          matching: find.text(pauseCopy.pauseSaved),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pauseCard,
          matching: find.text(pauseCopy.pauseMemory),
        ),
        findsNothing,
      );
      for (final action in [
        ('resume-pause', pauseCopy.resumeGame),
        ('pause-restart', pauseCopy.restart),
        ('pause-home', pauseCopy.home),
      ]) {
        final button = find.descendant(
          of: pauseCard,
          matching: find.byKey(Key(action.$1)),
        );
        expect(button.hitTestable(), findsOneWidget, reason: action.$1);
        expect(t.widget<ButtonStyleButton>(button).onPressed, isNotNull);
        expect(
          find.descendant(of: button, matching: find.text(action.$2)),
          findsOneWidget,
        );
      }
      expect(c.current!.moveCount, beforeHint.moveCount + 1);
      expect(
        (await c.store.load('ordinary')).instance!.toJson(),
        c.current!.toJson(),
      );
      await capture('main001-pause-complete-state');
      await tap('resume-pause');
      await tap('undo');
      expect(c.current!.board, beforeHint.board);
      await record('tutorial_hint_undo_pause', {
        'guided_steps': 3,
        'hint_status': hint.status.name,
        'worker_microseconds': hint.elapsed.inMicroseconds,
        'visited': hint.visited,
        'hint_did_not_mutate': true,
        'undo_returned_to_reference_prefix': 3,
        'pause_snapped_whole_move': true,
      });
      await referenceUI(skip: 3);
      await capture('main001-complete');
      await record('representative_ui_play', {
        'level': 1,
        'kind': 'actual bottle taps with tutorial/undo/isolate hint/pause/lifecycle',
        'progress': _progress(c.progress),
      });

      // Real settings controls and SQLite persistence; no fake audio transport.
      await c.goHome();
      await ready();
      await tap('settings');
      await tap('setting-music');
      await tap('setting-sound');
      expect(c.settings.music, isFalse);
      expect(c.settings.sound, isFalse);
      expect((await c.store.readSettings()).music, isFalse);
      expect((await c.store.readSettings()).sound, isFalse);
      await capture('settings-native-audio-off');
      final reloaded = GameController(c.store, library: c.library);
      await reloaded.initialize();
      expect(reloaded.settings.music, isFalse);
      expect(reloaded.settings.sound, isFalse);
      reloaded.dispose();
      await record('audio_settings', {
        'music': false,
        'sound': false,
        'sqlite_reload': true,
        'native_audio_connected': true,
        'acoustic_output_measured': false,
        'reload_scope':
            'new controller reads native SQLite; not process restart',
      });

      // Preserve the recovered original12 instance when an updated catalog entry differs.
      final previousOrdinary = c.ordinary!;
      final old12 = Puzzle.parse(
        await rootBundle.loadString('assets/fixtures/main-012.reference.json'),
      );
      expect(old12.initial, [
        ['B', 'P', 'G', 'O'],
        ['G', 'O', 'B', 'P'],
        ['P', 'B', 'O', 'G'],
        ['O', 'G', 'P', 'B'],
        <String>[],
        <String>[],
      ]);
      expect(old12.referenceMoves, hasLength(15));
      final oldState =
          GameInstance.create(
                id: 'b03-original12-previous-instance',
                puzzle: old12,
              )
              .pour(
                old12.referenceMoves.first.from,
                old12.referenceMoves.first.to,
              )
              .state;
      await c.store.save(oldState, replace: true);
      final library = c.library;
      final updated12 = Puzzle.fromJson(
        c.library.main[40]!.toJson()
          ..['puzzle_id'] = 'main-012'
          ..['main_level'] = 12
          ..['content_version'] = 2,
      );
      c.library = ContentLibrary(
        main: {...library.main, 12: updated12},
        daily: library.daily,
      );
      await c.initialize();
      await c.resumeSlot('ordinary');
      await ready();
      expect(c.current!.puzzle.toJson(), old12.toJson());
      await tap('undo');
      expect(c.current!.board, old12.initial);
      await c.restart();
      await ready();
      expect(c.current!.puzzle.contentVersion, 1);
      expect(c.current!.board, old12.initial);
      await capture('original12-old-instance-retained');
      await record('old_original12', {
        'setup': 'explicit controlled legacy snapshot plus test-local v2 catalog substitution; no gameplay/reward claimed',
        'original_reference_steps': 15,
        'instance_version': 1,
        'catalog_entry_version': 2,
        'undo_and_restart_preserve_original_definition': true,
      });
      c.library = library;
      await c.store.save(previousOrdinary, replace: true);
      await c.initialize();

      // Use real local clock/catalog. No test-day injection and no fixture daily IDs.
      await c.goHome();
      await ready();
      await tap('daily');
      await tap('today');
      final actualDay = c.today.date, dailyId = c.current!.id;
      expect(c.current!.puzzle.id, c.library.daily!.forDate(actualDay).id);
      expect(c.current!.catalogVersion, 1);
      expect(c.current!.puzzle.contentStatus, 'production_candidate');
      final ordinarySnapshot = c.ordinary!.toJson();
      await capture('daily-real-local-catalog-initial');
      await c.startToday();
      await ready();
      expect(c.current!.id, dailyId);
      await referenceUI();
      await capture('daily-real-local-complete');
      expect(c.progress.dailyStamps, contains(actualDay));
      expect(c.ordinary!.toJson(), ordinarySnapshot);
      await tap('daily-calendar');
      await capture('daily-real-local-calendar');
      await record('daily_catalog', {
        'actual_local_date': actualDay,
        'puzzle_id': c.daily!.puzzle.id,
        'catalog_version': c.daily!.catalogVersion,
        'same_day_resume_same_instance': true,
        'ordinary_slot_unchanged': true,
        'first_clears': c.progress.firstClears,
        'clock': 'unmodified LocalDay.now from real Bootstrap',
      });

      // Unlock sequentially through true core solutions and real SQLite settlements.
      // Non-representatives are explicitly automated setup, never human or UI play.
      for (var level = 2; level <= 60; level++) {
        final uiPlayed = _representatives.contains(level) || level % 4 == 0;
        await c.goHome();
        await ready();
        if (uiPlayed) {
          expect(await c.startLevel(level), isTrue);
          await ready();
          expect(
            c.current!.puzzle.id,
            'main-${level.toString().padLeft(3, '0')}',
          );
          await capture('main-${level.toString().padLeft(3, '0')}-initial');
          if (level == 5) {
            final revision = c.current!.revision;
            await tap('bottle-0');
            await tap('bottle-1', wait: false);
            await t.pump(const Duration(milliseconds: 100));
            expect(c.current!.revision, revision);
            expect(c.rejection, isNotNull);
            await capture('main005-illegal-pour-rejection');
            c.clearSelection();
          }
          if (level == 12) {
            final initial = c.current!;
            final move = initial.puzzle.referenceMoves.first;
            await tap('bottle-${move.from}');
            await tap('bottle-${move.to}', wait: false);
            await until(
              () => c.phase != SavePhase.saving,
              'mid-pour committed SQLite state',
              milliseconds: 50,
            );
            await t.pump(const Duration(milliseconds: 350));
            expect(
              c.motion,
              isNotNull,
              reason: 'capture must show a live native pour',
            );
            await capture(
              'main012-native-mid-pour-stream',
              immediate: true,
              setup: 'actual BoardView active pour after350ms presentation frame; assets predecoded by initial screenshot',
            );
            await ready();
            await tap('undo');
            expect(c.current!.board, initial.board);
            await record('mid_pour_native_capture', {
              'level': 12,
              'presentation_frame_ms': 350,
              'motion_live_at_capture': true,
              'undo_restored_reference_origin': true,
              'scope': 'actual normal-motion BoardView stream/tilt; subjective appearance requires screenshot inspection',
            });
          }
          await referenceUI();
          await capture('main-${level.toString().padLeft(3, '0')}-complete');
          await record('actual_ui_reference', {
            'level': level,
            'representative': _representatives.contains(level),
            'milestone': level % 4 == 0,
            'actions': c.current!.moveCount,
            'note': 'automated taps on actual BottleButton controls, not human play',
          });
        } else {
          final state = _referenceFinish(
            GameInstance.create(
              id: 'b03-automated-setup-$level',
              puzzle: c.library.main[level]!,
            ),
          );
          await c.store.settle(state, replace: true);
          await c.initialize();
          await ready();
          await record('automated_progress_setup', {
            'level': level,
            'reference_steps': state.moveCount,
            'method': 'real core reference replay and native GameStore.settle; not UI/human gameplay',
          });
        }
        expect(c.progress.firstClears, level);
        if (level % 4 == 0) {
          final piece = c.receipt!.piece!;
          expect(c.progress.pieces, hasLength(level ~/ 4));
          await c.viewPatch();
          await ready();
          expect(find.byType(RewardPage), findsOneWidget);
          await t.pump(const Duration(milliseconds: 800));
          await capture('milestone-${level.toString().padLeft(3, '0')}-reward');
          await c.acknowledgeReveal();
          await ready();
          expect(c.progress.revealedPieces, contains(piece));
          await sceneState(
            piece.split(':').first,
            int.parse(piece.split(':').last),
          );
          await record('milestone', {
            'level': level,
            'piece': piece,
            'receipt': c.receipt!.toJson(),
            'progress': _progress(c.progress),
            'actual_native_settlement': true,
            'reward_and_scene_rendered': true,
          });
        }
      }
      expect(c.progress.storyComplete, isTrue);
      expect(c.progress.pieces, hasLength(15));
      expect(events.where((e) => e['kind'] == 'milestone'), hasLength(15));
      expect(events.where((e) => e['kind'] == 'scene_progress'), hasLength(18));
      await c.goHome();
      await ready();
      await capture('story60-home-daily-entry');

      // Same real Bootstrap/GameScreen at constrained 320 logical pixels and 2x text.
      await c.updateSetting('reduced_motion', true);
      await ready();
      expect((await c.store.readSettings()).reducedMotion, isTrue);
      final originalPhysicalSize = t.view.physicalSize;
      final originalPixelRatio = t.view.devicePixelRatio;
      t.view.physicalSize = Size(
        320 * originalPixelRatio,
        900 * originalPixelRatio,
      );
      t.platformDispatcher.textScaleFactorTestValue = 2;
      try {
        expect(await c.startLevel(60), isTrue);
        await ready();
        final boardContext = t.element(find.byType(BoardView));
        expect(MediaQuery.sizeOf(boardContext).width, 320);
        expect(MediaQuery.textScalerOf(boardContext).scale(16), 32);
        expect(MediaQuery.disableAnimationsOf(boardContext), isTrue);
        await capture(
          'narrow320-text2x-reduced-real-board',
          setup: 'actual Bootstrap board; test view constrained320x900/text2x; persisted reduced motion',
        );
        final firstReduced = c.current!.puzzle.referenceMoves.first;
        await tap('bottle-${firstReduced.from}');
        await tap('bottle-${firstReduced.to}', wait: false);
        expect(c.motion?.reducedMotion, isTrue);
        await ready();
        await capture('narrow320-text2x-reduced-after-pour');
        await record('narrow_accessibility', {
          'logical_width': 320,
          'logical_height': 900,
          'text_scale': 2,
          'persisted_reduced_motion': true,
          'actual_board_pour': true,
          'scope': 'native rendering with explicit test view constraints; not a physical320px device certification',
        });
        await c.goHome();
        await ready();

        final six = GameInstance.create(
          id: 'controlled-gallery-six',
          puzzle: c.library.main[12]!,
        );
        final seven = six.grantExtraBottle();
        double? sixWidth;
        for (final entry in [('six', six), ('seven', seven)]) {
          final prefix = 'native-${entry.$1}';
          gallery.value = _AssetGallery(
            title: '${entry.$1} bottles · 320 / text2x',
            textScale: 2,
            reduced: true,
            child: BoardView(
              state: entry.$2,
              selected: null,
              onTap: (_) {},
              keyPrefix: prefix,
              settings: const PlayerSettings(reducedMotion: true),
            ),
          );
          await t.pump(const Duration(milliseconds: 200));
          final buttons = find.byWidgetPredicate(
            (w) => w is BottleButton && w.key == Key('$prefix-0'),
          );
          final width = t.widget<BottleButton>(buttons).width;
          final rendered = t.getSize(buttons);
          expect(rendered.width, width);
          expect(rendered.height, 184);
          expect(width, greaterThanOrEqualTo(48));
          if (sixWidth == null) {
            sixWidth = width;
          } else {
            expect(width, sixWidth);
          }
          await capture(
            'native-gallery-${entry.$1}-320-text2x',
            boundaryKey: _galleryCaptureKey,
            setup: 'controlled actual BoardView; seven uses test-only core entitlement seed, no ad reward claim',
          );
          await record('equal_bottle_size', {
            'bottles': entry.$2.board.length,
            'width': width,
            'height': rendered.height,
            'canvas_width': 320,
            'setup': 'actual BoardView controlled input; seventh empty bottle is test seed only',
          });
        }
        final cases = <(String, List<String>, String?)>[
          ('empty', [], 'O'),
          ('one', ['O'], 'O'),
          ('two', ['G', 'G'], 'G'),
          ('three', ['P', 'P', 'P'], 'P'),
          ('four', ['B', 'B', 'B', 'B'], 'B'),
          ('mixed', ['O', 'G', 'P', 'B'], 'O'),
          ('wrong label', ['O', 'O', 'O', 'O'], 'G'),
        ];
        final tapped = <int>[];
        gallery.value = _AssetGallery(
          title: 'Native bottle assets / controlled',
          textScale: 2,
          reduced: true,
          child: Wrap(
            spacing: 8,
            runSpacing: 16,
            children: [
              for (var i = 0; i < cases.length; i++)
                SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      Text(cases[i].$1, style: const TextStyle(fontSize: 12)),
                      BottleButton(
                        key: Key('asset-case-$i'),
                        index: i,
                        liquid: cases[i].$2,
                        target: cases[i].$3,
                        selected: i == 5,
                        width: 72,
                        onTap: () => tapped.add(i),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
        await t.pump(const Duration(milliseconds: 200));
        await capture(
          'native-gallery-empty-1-2-3-4-mixed-mismatch',
          boundaryKey: _galleryCaptureKey,
          setup: 'actual production BottleButton and painter; deliberately controlled visual states, not a playable puzzle',
        );
        await t.ensureVisible(find.byKey(const Key('asset-case-6')));
        await t.tap(find.byKey(const Key('asset-case-6')));
        expect(tapped, [6]);
        await record('bottle_gallery', {
          'cases': cases.map((c) => c.$1).toList(),
          'actual_control_tap_received': true,
          'real_png_layers_and_CustomPainter': true,
          'width': 320,
          'text_scale': 2,
          'setup': 'controlled visual gallery only',
        });
      } finally {
        gallery.value = null;
        t.view.physicalSize = originalPhysicalSize;
        t.platformDispatcher.clearTextScaleFactorTestValue();
        await t.pump(const Duration(milliseconds: 200));
      }
      await c.goHome();
      await ready();
      expect(c.settings.music, isFalse);
      expect(c.settings.sound, isFalse);
      expect((await c.store.readSettings()).music, isFalse);
      report['status'] = 'passed';
      report['final_progress'] = _progress(await c.store.progress());
      report['completed_at'] = DateTime.now().toIso8601String();
      report['limitations'] = [
        'Automated reference play and explicitly labelled setup; no human difficulty/subjective visual approval.',
        'Lifecycle notifications and SQLite/controller reload are not a real process kill/relaunch.',
        'Native audio transport connected and settings persisted; no acoustic loudness/output measurement.',
        '320/text2x are native-rendered test constraints; external device coverage remains separate.',
        'Gallery seventh bottle is an explicit core seed, not an AdMob reward.',
      ];
      await flush();
      debugPrint(
        'B03_NATIVE_PASS: screenshots=${screenshots.length}; evidence=${output.path}; milestones=15; scene_states=18; main=60; daily=30',
      );
      noFlutterError('final');
    } catch (error, stack) {
      report['status'] = 'failed';
      report['error'] = '$error';
      report['stack'] = '$stack';
      await flush();
      rethrow;
    } finally {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      gallery.value = null;
      controller?.cancelHint();
      // Bootstrap may still be offstage if a controlled gallery failed.
      final screens = find.byType(app.GameScreen, skipOffstage: false);
      final audio = screens.evaluate().isEmpty
          ? null
          : t.widget<app.GameScreen>(screens.first).audio;
      try {
        await audio?.stop().timeout(const Duration(seconds: 5));
      } catch (error) {
        events.add({'kind': 'cleanup_audio', 'error': '$error'});
      }
      // Await plugin disposal before Bootstrap's synchronous widget teardown,
      // including when stop failed; no FramePositionUpdater may outlive the tree.
      await audio?.dispose().timeout(const Duration(seconds: 5));
      await flush();
      await File('${output.path}/COMPLETE.json').writeAsString(
        jsonEncode({
          'status': report['status'],
          'report': 'runtime.json',
          'screenshots': screenshots.length,
          'directory': output.path,
        }),
        flush: true,
      );
      debugPrint('B03_RUNTIME_REPORT: ${jsonEncode(report)}');
      debugPrint('B03_EVIDENCE_COMPLETE=${output.path}/COMPLETE.json');
      // The host watcher copies this native sandbox before flutter test removes
      // the app on exit. Deliberately bounded and before Bootstrap disposal.
      await Future<void>.delayed(const Duration(seconds: 2));
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(milliseconds: 200));
      gallery.dispose();
      await flush();
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
