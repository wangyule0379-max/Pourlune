// Native R01 UI evidence. No scenario; only b03_r01_runtime.sqlite is cleared.
// flutter test integration_test/b03_r01_design_test.dart -d <device-id> \
//   --dart-define=POURLUNE_DATABASE=b03_r01_runtime.sqlite
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:pourlune_dev/presentation/bottle.dart';
import 'package:sqflite/sqflite.dart';

const _root = Key('r01-native-capture');
const _narrow = Key('r01-native-320-capture');

/// Controlled viewport uses the real app/controller, while Bootstrap stays alive.
class _Host extends StatelessWidget {
  const _Host(this.overlay);
  final ValueNotifier<Widget?> overlay;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
      key: _root,
      child: ValueListenableBuilder<Widget?>(
        valueListenable: overlay,
        child: const app.Bootstrap(),
        builder: (_, view, bootstrap) => Stack(
          fit: StackFit.expand,
          children: [
            Offstage(offstage: view != null, child: bootstrap),
            ?view,
          ],
        ),
      ),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('R01 native original-layout gameplay and controlled 320px/2x', (
    t,
  ) async {
    const filename = String.fromEnvironment('POURLUNE_DATABASE');
    const scenario = String.fromEnvironment('POURLUNE_SCENARIO');
    if (filename != 'b03_r01_runtime.sqlite' || scenario.isNotEmpty) {
      throw StateError('Require exact b03_r01_runtime.sqlite and no scenario');
    }
    final path = await getDatabasesPath();
    final output = Directory('$path/b03-r01-evidence');
    await output.create(recursive: true);
    await deleteDatabase('$path/$filename');
    final overlay = ValueNotifier<Widget?>(null);
    GameController? controller;
    var controlled = false;
    var setup = 'default Bootstrap; actual player navigation and bottle taps';
    final shots = <Map<String, Object?>>[];
    final report = <String, Object?>{
      'status': 'running',
      'scenario': scenario,
      'database': '$path/$filename',
      'scope': 'Native rendering and automated play; no visual acceptance, human play or process-restart claim.',
      'screenshots': shots,
    };
    Future<void> flush() async {
      await File('${output.path}/runtime.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
        flush: true,
      );
    }

    Future<void> ready() async {
      for (var i = 0; i < 450; i++) {
        await t.pump(const Duration(milliseconds: 100));
        expect(t.takeException(), isNull);
        if (controller != null &&
            !controller.busy &&
            !controller.hintSearching) {
          break;
        }
      }
      final c = controller!;
      expect(c.busy, isFalse);
      expect(c.phase, SavePhase.clean, reason: c.error);
    }

    Future<void> tap(String key) async {
      final finder = find.byKey(Key(key));
      expect(finder, findsOneWidget, reason: key);
      await t.ensureVisible(finder);
      expect(finder.hitTestable(), findsOneWidget, reason: key);
      await t.tap(finder);
      await ready();
    }

    Future<void> capture(String name, {bool top = true}) async {
      if (top) {
        for (final element in find.byType(Scrollable).evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          if (state.position.axis == Axis.vertical) state.position.jumpTo(0);
        }
      }
      await t.pump(const Duration(milliseconds: 900));
      for (final element in find.byType(Image).evaluate()) {
        Object? error;
        await precacheImage(
          (element.widget as Image).image,
          element,
          onError: (e, _) => error = e,
        );
        expect(error, isNull, reason: name);
      }
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(controlled ? _narrow : _root),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${output.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        final c = controller!;
        shots.add({
          'file': '$name.png',
          'setup': setup,
          'viewport': controlled
              ? 'controlled 320 logical pixels / text2x / real app'
              : 'normal Bootstrap',
          'logical_size': [boundary.size.width, boundary.size.height],
          'png_size': [image.width, image.height],
          'page': c.page.name,
          'puzzle_id': c.current?.puzzle.id,
          'instance': c.current?.id,
          'revision': c.current?.revision,
          'board': c.current?.board,
          'completed': c.current?.completed,
          'first_clears': c.progress.firstClears,
          'pieces': c.progress.pieces,
          'today': c.today.date,
          'unlocked_levels': c.progress.unlockedLevels,
        });
      } finally {
        image.dispose();
      }
      await flush();
    }

    Future<void> solve() async {
      final c = controller!;
      final puzzle = c.current!.puzzle;
      for (final move in puzzle.referenceMoves) {
        final revision = c.current!.revision;
        await tap('bottle-${move.from}');
        await tap('bottle-${move.to}');
        expect(c.current!.revision, revision + 1);
      }
      expect(c.current!.completed, isTrue);
      expect(
        (await c.store.load('ordinary')).instance!.toJson(),
        c.current!.toJson(),
      );
    }

    Future<void> bottles(int count) async {
      expect(find.byType(BottleButton), findsNWidgets(count));
      final sizes = [
        for (var i = 0; i < count; i++) t.getSize(find.byKey(Key('bottle-$i'))),
      ];
      for (final size in sizes) {
        expect(size, sizes.first);
      }
      for (final key in ['undo', 'hint', 'pause']) {
        final finder = find.byKey(Key(key));
        await t.ensureVisible(finder);
        expect(finder.hitTestable(), findsOneWidget, reason: key);
      }
      report['${controlled ? 'narrow' : 'normal'}_bottle_sizes_$count'] = [
        for (final s in sizes) [s.width, s.height],
      ];
    }

    Future<void> narrow(bool enabled) async {
      controlled = enabled;
      final c = controller!;
      final audio = t.widget<app.GameScreen>(find.byType(app.GameScreen)).audio;
      overlay.value = enabled
          ? Center(
              child: SizedBox(
                width: 320,
                child: RepaintBoundary(
                  key: _narrow,
                  child: app.PourluneApp(
                    controller: c,
                    audio: audio,
                    textScaler: TextScaler.linear(2),
                  ),
                ),
              ),
            )
          : null;
      await ready();
    }

    try {
      debugPrint('B03_R01_EVIDENCE_DIRECTORY=${output.path}');
      await t.pumpWidget(_Host(overlay));
      for (
        var i = 0;
        i < 450 && find.byType(app.GameScreen).evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final screen = t.widget<app.GameScreen>(find.byType(app.GameScreen));
      controller = screen.controller;
      final c = controller;
      expect(c.library.engineering, isFalse);
      expect(screen.advanceTestDay, isNull);
      expect(screen.audio, isNotNull);
      await ready();
      await capture('01-welcome');
      await narrow(true);
      await capture('01-welcome-320-text2');
      await narrow(false);
      await tap('sample-main-001');
      await capture('02-tutorial');
      await tap('skip-tutorial');
      await capture('03-board-main1');
      await tap('pause');
      await capture('04-pause-main1');
      await tap('resume-pause');
      await solve();
      await capture('05-completion-main1');
      await tap('home');
      await capture('06-progressed-home');
      await tap('sample-main-002');
      for (var level = 2; level <= 4; level++) {
        expect(c.current!.puzzle.mainLevel, level);
        await solve();
        if (level < 4) await tap('next');
      }
      expect(c.progress.pieces, ['color_studio:1']);
      await tap('view-patch');
      await capture('07-patch-reveal');
      await tap('view-collection');
      await capture('08-scene');
      await tap('home');
      await capture('09-home-one-patch');
      await narrow(true);
      await capture('09-home-one-patch-320-text2');
      await narrow(false);
      await tap('collection');
      await capture('10-collection');
      await tap('scene-color_studio');
      await capture('11-scene-revisit');
      await tap('home');
      await tap('daily');
      await capture('12-daily');
      await narrow(true);
      await capture('12-daily-320-text2');
      await narrow(false);
      for (final count in [6, 7]) {
        setup = 'explicit QA controller.start(main12, replace:true); not unlocked gameplay';
        final progressBefore = c.progress.firstClears;
        await c.start(c.library.main[12]!, replace: true);
        await ready();
        if (count == 7) {
          // Existing B03 QA geometry method: core entitlement + normal SQL save.
          // No SDK confirmation, ad reward, unlock or player progress is claimed.
          setup += '; core grantExtraBottle + SQL save/reload solely for seven-bottle QA geometry; not an ad reward';
          await c.store.save(c.current!.grantExtraBottle(), replace: true);
          await c.initialize();
          await c.resumeSlot('ordinary');
          await ready();
        }
        expect(c.progress.firstClears, progressBefore);
        expect(c.current!.board, hasLength(count));
        await bottles(count);
        await capture('13-qa-$count-bottle-board');
        await tap('pause');
        await capture('14-qa-$count-bottle-pause');
        await tap('resume-pause');
        await narrow(true);
        await bottles(count);
        await capture('15-qa-$count-bottle-320-text2');
        await t.ensureVisible(find.byKey(const Key('hint')));
        await capture('15-qa-$count-bottle-actions-320-text2', top: false);
        await tap('pause');
        await capture('16-qa-$count-bottle-pause-320-text2');
        await tap('resume-pause');
        await narrow(false);
      }
      report['status'] = 'passed';
    } catch (e, stack) {
      report.addAll({'status': 'failed', 'error': '$e', 'stack': '$stack'});
      rethrow;
    } finally {
      // Await the real plugin shutdown before LiveTest checks transient frames.
      // Bootstrap.dispose is synchronous and otherwise leaves this async work queued.
      final screens = find.byType(app.GameScreen);
      if (screens.evaluate().isNotEmpty) {
        final audio = t.widget<app.GameScreen>(screens.first).audio;
        await audio?.stop();
        await audio?.dispose();
      }
      await t.pumpWidget(const SizedBox());
      overlay.dispose();
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
      await flush();
      await File('${output.path}/COMPLETE.json').writeAsString(
        jsonEncode({'status': report['status'], 'screenshots': shots.length}),
        flush: true,
      );
      debugPrint('B03_R01_EVIDENCE_COMPLETE=${output.path}/COMPLETE.json');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
