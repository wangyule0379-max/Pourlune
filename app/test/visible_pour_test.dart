import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  testWidgets(
    'incoming water remains visible inside glass down to its surface',
    (t) async {
      final art = (await t.runAsync(BottleArt.load))!;
      try {
        final move = boardMove(boardFixture(colors: 5, extra: true), 2, 7);
        final layout = BoardLayout(width: 370, count: 8, maxHeight: 480);
        final geometry = geometryFor(layout, move.motion);
        final frame = BoardVisualFrame(
          state: move.after,
          layout: layout,
          motion: move.motion,
          elapsedMs: 290 + geometry.flowMs / 2,
        );
        final recorder = ui.PictureRecorder();
        FlameBoardPainter(art).paint(
          Canvas(recorder),
          frame,
          const PlayerSettings(),
          press: List.filled(8, 0),
        );
        final picture = recorder.endRecording();
        final image = (await t.runAsync(() => picture.toImage(370, 480)))!;
        final pixels = (await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final pose = frame.poses[7];
        final level = waterline(
          layout.shape.worldHull(pose),
          frame.pour!.delivered * layout.shape.unitArea,
        );
        var coloredRows = 0;
        for (
          var y = (pose.mouth.dy + layout.shape.height * .2).ceil();
          y < level - 4;
          y++
        ) {
          var visible = false;
          for (
            var x = pose.mouth.dx.round() - 1;
            x <= pose.mouth.dx.round() + 1;
            x++
          ) {
            final i = (y * 370 + x) * 4;
            final color = HSVColor.fromColor(
              Color.fromARGB(
                255,
                pixels.getUint8(i),
                pixels.getUint8(i + 1),
                pixels.getUint8(i + 2),
              ),
            );
            visible |=
                color.hue > 260 && color.hue < 310 && color.saturation > .28;
          }
          if (visible) coloredRows++;
        }
        expect(
          coloredRows,
          greaterThanOrEqualTo(20),
          reason: 'Water cannot vanish at the rim and reappear in the pool.',
        );
        image.dispose();
        picture.dispose();
      } finally {
        art.dispose();
      }
    },
  );
  test(
    'normal seven/eight bottle pours leave visible air between the lips',
    () {
      for (final count in [7, 8]) {
        final layout = BoardLayout(width: 370, count: count, maxHeight: 480);
        for (final route in [(0, count - 1), (count - 1, 0), (3, 0), (0, 3)]) {
          for (final units in [1, 4]) {
            final geometry = PourGeometry(
              shape: layout.shape,
              sourceMouth: layout.mouths[route.$1],
              targetMouth: layout.mouths[route.$2],
              units: units,
              sourceUnits: 4,
              bounds: layout.flightBounds,
            );
            final flowing = geometry.frame(290 + geometry.flowMs / 2);
            expect(flowing.inStream, greaterThan(0));
            expect(
              flowing.streamEnd.dy - flowing.streamStart.dy,
              greaterThanOrEqualTo(18),
              reason:
                  'The stream must extend beyond the overlapping knit rims.',
            );
            var readableMs = 0;
            for (var ms = 0.0; ms < geometry.totalMs; ms += 10) {
              final frame = geometry.frame(ms);
              if (frame.delivered > units * .05 && frame.out < units * .95) {
                readableMs += 10;
              }
              expect(
                4 - frame.out + frame.delivered + frame.inStream,
                closeTo(4, 1e-8),
              );
            }
            expect(readableMs, greaterThanOrEqualTo(250));
          }
        }
      }
    },
  );

  for (final units in [1, 4]) {
    testWidgets(
      'real Flame clock keeps $units-unit transfer visible in mid-flow',
      (t) async {
        final initial = boardFixture(colors: 5, extra: true);
        final data = initial.puzzle.toJson();
        data['initial_bottom_to_top'] = [
          ['O', 'O', 'O', 'G'],
          ['G', 'G', 'G', 'O'],
          ...initial.board.skip(2).take(5),
        ];
        final single = GameInstance.create(
          id: 'single-layer',
          puzzle: Puzzle.fromJson(data),
          isReplay: true,
        ).grantExtraBottle();
        // Four-unit bottle or one top layer, both through the real core move.
        final move = units == 4
            ? boardMove(initial, 2, 7)
            : boardMove(single, 0, 7);
        expect(move.motion.units, units);
        final released = <int>[];
        final game = FlameBoardGame(onMotionComplete: released.add);
        final layout = BoardLayout(width: 370, count: 8, maxHeight: 480);
        game.show(
          state: move.after,
          layout: layout,
          settings: const PlayerSettings(),
          systemReduced: false,
          motion: move.motion,
        );
        await t.pumpWidget(MaterialApp(home: GameWidget(game: game)));
        await waitForFlameArt(t);
        game.pauseEngine();
        var readableMs = 0;
        for (var n = 0; n < 200; n++) {
          game.update(.01);
          final flow = game.frame.pour;
          if (flow != null &&
              flow.delivered > units * .05 &&
              flow.out < units * .95) {
            readableMs += 10;
          }
        }
        expect(
          readableMs,
          greaterThanOrEqualTo(250),
          reason: 'The live effect must not compress the continuous transfer.',
        );
        expect(released, [move.motion.token]);
        expect(game.frame.active, isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
