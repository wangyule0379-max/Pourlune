import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  testWidgets(
    'Level6 fixed target badges cannot paint stickers over the moving bottle',
    (t) async {
      await t.binding.setSurfaceSize(const Size(370, 580));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final before = GameInstance.create(
        id: 'real-main006-layer',
        puzzle: Puzzle.fromJson(
          jsonDecode(
            File('assets/puzzles/main/main-006.json').readAsStringSync(),
          ) as Map<String, dynamic>,
        ),
        isReplay: true,
      );
      final move = boardMove(before, 1, 3);
      const key = Key('actual-board-raster');
      Widget scene(bool moving) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: BoardView(
              state: moving ? move.after : before,
              selected: null,
              onTap: (_) {},
              motion: moving ? move.motion : null,
            ),
          ),
        ),
      );
      await t.pumpWidget(scene(false));
      await waitForFlameArt(t);
      // The player acts after the real board-arrival opacity has completed.
      await t.pump(const Duration(seconds: 1));
      await t.pumpWidget(scene(true));
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      game.pauseEngine();
      game.update(.12);
      game.stepEngine(stepTime: 0);
      await t.pump();
      final frame = game.frame;
      expect(frame.elapsedMs, inInclusiveRange(100, 140));
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final actual = (await t.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
      final recorder = ui.PictureRecorder();
      FlameBoardPainter(game.art!).paintBottle(
        Canvas(recorder),
        1,
        frame.poses[1],
        frame.bands[1],
        frame.layout.shape,
        const PlayerSettings(),
        highlighted: false,
        fixedTarget: 'G',
      );
      final picture = recorder.endRecording();
      final source = (await t.runAsync(() => picture.toImage(370, 580)))!;
      final a = (await t.runAsync(
        () => actual.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final s = (await t.runAsync(
        () => source.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final evidence = Platform.environment['POURLUNE_EVIDENCE_DIR'];
      if (evidence != null) {
        for (final entry in {'actual': actual, 'source': source}.entries) {
          final bytes = (await t.runAsync(
            () => entry.value.toByteData(format: ui.ImageByteFormat.png),
          ))!;
          File('$evidence/layer-${entry.key}.png')
              .writeAsBytesSync(bytes.buffer.asUint8List());
        }
      }
      var covered = 0, coveredMismatch = 0, outside = 0, outsideMismatch = 0;
      final caption = frame.layout.labelRect(1);
      for (var y = 0; y < 580; y++) {
        for (var x = 0; x < 370; x++) {
          final i = (y * 370 + x) * 4;
          if (s.getUint8(i + 3) < 254) continue;
          final mismatch = List.generate(
            3,
            (c) => (a.getUint8(i + c) - s.getUint8(i + c)).abs(),
          ).any((d) => d > 8);
          if (caption.contains(Offset(x + .5, y + .5))) {
            covered++;
            if (mismatch) coveredMismatch++;
          } else {
            outside++;
            if (mismatch) outsideMismatch++;
          }
        }
      }
      actual.dispose();
      source.dispose();
      picture.dispose();
      await t.pumpWidget(const SizedBox());
      expect(outside, greaterThan(100));
      expect(
        outsideMismatch / outside,
        lessThan(.02),
        reason: 'The real GameWidget must have painted the same moving pose.',
      );
      expect(
        covered,
        greaterThan(30),
        reason: 'This transition must actually cross its stationary caption.',
      );
      expect(
        coveredMismatch / covered,
        lessThan(.02),
        reason:
            'Opaque moving art must occlude fixed target/number pixels; '
            'they cannot become stickers on top of the glass.',
      );
    },
  );
}
