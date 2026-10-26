import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

void main() {
  testWidgets('actual rotated knit rims leave visible air during transfer', (
    t,
  ) async {
    final art = (await t.runAsync(BottleArt.load))!;
    try {
      final painter = FlameBoardPainter(art);
      final layout = BoardLayout(width: 370, count: 8, maxHeight: 480);
      Future<Rect> rimPixels(BottlePose pose, String? target) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final shape = layout.shape;
        // The original painter uses the top 15% for colored cuffs and 17%
        // for neutral cuffs. Sample those actual art pixels, independently
        // of the geometry's proposed rim envelope.
        final clip = Rect.fromLTWH(
          -shape.width / 2,
          -shape.height * .10,
          shape.width,
          shape.height * .17,
        );
        canvas.clipPath(
          Path()..addPolygon([
            pose.transform(clip.topLeft),
            pose.transform(clip.topRight),
            pose.transform(clip.bottomRight),
            pose.transform(clip.bottomLeft),
          ], true),
        );
        painter.paintBottle(
          canvas,
          0,
          pose,
          const [],
          shape,
          const PlayerSettings(),
          highlighted: false,
          fixedTarget: target,
        );
        final picture = recorder.endRecording();
        final image = (await t.runAsync(() => picture.toImage(370, 480)))!;
        final bytes = (await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        var left = 370, right = 0, top = 480, bottom = 0;
        for (var y = 0; y < 480; y++) {
          for (var x = 0; x < 370; x++) {
            if (bytes.getUint8((y * 370 + x) * 4 + 3) >= 180) {
              left = math.min(left, x);
              right = math.max(right, x);
              top = math.min(top, y);
              bottom = math.max(bottom, y);
            }
          }
        }
        image.dispose();
        picture.dispose();
        expect(right, greaterThan(left));
        return Rect.fromLTRB(
          left.toDouble(),
          top.toDouble(),
          right + 1.0,
          bottom + 1.0,
        );
      }

      for (final route in [(4, 7), (7, 4), (5, 3)]) {
        for (final units in [1, 4]) {
          final geometry = PourGeometry(
            shape: layout.shape,
            sourceMouth: layout.mouths[route.$1],
            targetMouth: layout.mouths[route.$2],
            units: units,
            sourceUnits: 4,
            bounds: layout.flightBounds,
          );
          for (final progress in [.1, .5, .9]) {
            final frame = geometry.frame(290 + geometry.flowMs * progress);
            final source = await rimPixels(frame.source, 'O');
            final target = await rimPixels(frame.target, null);
            expect(
              target.top - source.bottom,
              greaterThanOrEqualTo(8),
              reason:
                  '${route.$1}->${route.$2} $units units at $progress: '
                  'the rendered knit rims must be visibly separate',
            );
          }
        }
      }
    } finally {
      art.dispose();
    }
  });
}
