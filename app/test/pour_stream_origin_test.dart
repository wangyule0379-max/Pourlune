import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

import 'support/flame_board_support.dart';

void main() {
  test('flow and waterline meet the opening measured in the actual art', () {
    // Measured from the 166x309 material at (736,211): the dark opening is
    // x=52..114, y=8..24. Its side lip is at (113,16), not old (96,31).
    // These bounds deliberately do not use BottleShape.lip to derive a want.
    for (final count in [7, 8]) {
      final layout = BoardLayout(width: 370, count: count, maxHeight: 480);
      for (final route in [(2, count - 1), (count - 1, 0), (0, 3)]) {
        for (final units in [1, 4]) {
          final geometry = PourGeometry(
            shape: layout.shape,
            sourceMouth: layout.mouths[route.$1],
            targetMouth: layout.mouths[route.$2],
            units: units,
            sourceUnits: 4,
            bounds: layout.flightBounds,
          );
          for (final fraction in [.15, .5, .8]) {
            final flow = geometry.frame(290 + geometry.flowMs * fraction);
            final delta =
                (flow.streamStart - flow.source.mouth) / flow.source.scale;
            final c = math.cos(flow.source.angle);
            final s = math.sin(flow.source.angle);
            final x = (delta.dx * c + delta.dy * s) / layout.shape.width + .5;
            final y =
                (-delta.dx * s + delta.dy * c) / layout.shape.height + .10;
            expect(y * 309, inInclusiveRange(8, 24));
            expect(
              x * 166,
              flow.source.angle > 0
                  ? inInclusiveRange(110, 115)
                  : inInclusiveRange(51, 56),
            );
            final surface = waterline(
              layout.shape.worldHull(flow.source),
              (4 - flow.out) *
                  layout.shape.unitArea *
                  flow.source.scale *
                  flow.source.scale,
            );
            expect(surface, closeTo(flow.streamStart.dy, .05));
          }
        }
      }
    }
  });

  testWidgets('stream passes behind the actual opaque source mouth cuff', (
    t,
  ) async {
    final art = (await t.runAsync(BottleArt.load))!;
    try {
      final painter = FlameBoardPainter(art);
      const settings = PlayerSettings();
      final initial = boardFixture(colors: 5, extra: true);
      final layout = BoardLayout(width: 370, count: 8, maxHeight: 480);
      var totalCovered = 0;
      for (final route in [(2, 7), (7, 2)]) {
        final from = route.$1, to = route.$2;
        // Mirror the real four-unit core transfer for both directions.
        final move = from == 2
            ? boardMove(initial, from, to)
            : boardMove(boardMove(initial, 2, 7).after, from, to);
        final geometry = geometryFor(layout, move.motion);
        final frame = BoardVisualFrame(
          state: move.after,
          layout: layout,
          motion: move.motion,
          elapsedMs: 290 + geometry.flowMs * .10,
        );
        Future<ui.Image> render(bool sourceOnly) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          if (sourceOnly) {
            painter.paintBottle(
              canvas,
              from,
              frame.poses[from],
              frame.bands[from],
              layout.shape,
              settings,
              highlighted: false,
              fixedTarget: from < 5 ? initial.puzzle.targets[from] : null,
            );
          } else {
            painter.paint(canvas, frame, settings, press: List.filled(8, 0));
          }
          final picture = recorder.endRecording();
          final image = (await t.runAsync(() => picture.toImage(370, 480)))!;
          picture.dispose();
          return image;
        }

        final base = await render(true), actual = await render(false);
        try {
          final bytes = (await t.runAsync(
            () => base.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          final painted = (await t.runAsync(
            () => actual.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          final pose = frame.poses[from];
          var covered = 0, overwritten = 0;
          for (var y = 0; y < 480; y++) {
            for (var x = 0; x < 370; x++) {
              if ((x - frame.pour!.streamStart.dx).abs() > 1 ||
                  y < frame.pour!.streamStart.dy + 1) {
                continue;
              }
              final delta = (Offset(x + .5, y + .5) - pose.mouth) / pose.scale;
              final localY =
                  -delta.dx * math.sin(pose.angle) +
                  delta.dy * math.cos(pose.angle);
              if (localY < -layout.shape.height * .10 ||
                  localY > layout.shape.height * .05) {
                continue;
              }
              final i = (y * 370 + x) * 4;
              if (bytes.getUint8(i + 3) != 255) continue;
              covered++;
              if (bytes.getUint32(i) != painted.getUint32(i)) {
                overwritten++;
              }
            }
          }
          totalCovered += covered;
          expect(
            overwritten,
            0,
            reason: 'The stream must not paint over opaque knit stitches.',
          );
        } finally {
          base.dispose();
          actual.dispose();
        }
      }
      expect(totalCovered, greaterThan(2));
    } finally {
      art.dispose();
    }
  });
}
