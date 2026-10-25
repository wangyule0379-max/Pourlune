import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

void main() {
  testWidgets(
    'empty purple-cuff bottle has no baked purple liquid below its live window',
    (t) async {
      final art = (await t.runAsync(BottleArt.load))!;
      try {
        const shape = BottleShape(100);
        const pose = BottlePose(Offset(60, 35), 0);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        FlameBoardPainter(art).paintBottle(
          canvas,
          2,
          pose,
          [],
          shape,
          const PlayerSettings(),
          highlighted: false,
          fixedTarget: 'P',
        );
        final picture = recorder.endRecording();
        final image = await t.runAsync(() => picture.toImage(120, 230));
        final bytes = (await t.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        var stalePurple = 0;
        for (
          var y = (35 + (.865 - .10) * shape.height).ceil();
          y < (35 + (.89 - .10) * shape.height).floor();
          y++
        ) {
          for (var x = 52; x < 68; x++) {
            final i = (y * 120 + x) * 4;
            final r = bytes.getUint8(i),
                g = bytes.getUint8(i + 1),
                b = bytes.getUint8(i + 2),
                a = bytes.getUint8(i + 3);
            if (a > 150 && r > 100 && r > g + 15 && b > g + 25) stalePurple++;
          }
        }
        image!.dispose();
        picture.dispose();
        expect(
          stalePurple,
          0,
          reason: 'Only actual liquid may occupy clear glass; knitted cuff starts below this center band.',
        );
      } finally {
        art.dispose();
      }
    },
  );
  testWidgets('selection halo follows cap, shoulder, outer side and base', (
    t,
  ) async {
    final art = (await t.runAsync(BottleArt.load))!;
    try {
      Future<List<int>> sample(bool selected) async {
        final recorder = ui.PictureRecorder();
        FlameBoardPainter(art).paintBottle(
          Canvas(recorder),
          0,
          const BottlePose(Offset(60, 35), 0),
          [],
          const BottleShape(100),
          const PlayerSettings(),
          highlighted: selected,
        );
        final picture = recorder.endRecording();
        final image = (await t.runAsync(() => picture.toImage(120, 230)))!;
        final bytes = (await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final counts = <int>[];
        for (final rect in const [
          Rect.fromLTRB(45, 11, 75, 17),
          Rect.fromLTRB(6, 67, 12, 83),
          Rect.fromLTRB(6, 90, 11, 150),
          Rect.fromLTRB(35, 203, 85, 209),
        ]) {
          var count = 0;
          for (var y = rect.top.toInt(); y < rect.bottom; y++) {
            for (var x = rect.left.toInt(); x < rect.right; x++) {
              final i = (y * 120 + x) * 4;
              if (bytes.getUint8(i + 3) > 45 &&
                  bytes.getUint8(i + 1) > 170 &&
                  bytes.getUint8(i + 2) > 180) {
                count++;
              }
            }
          }
          counts.add(count);
        }
        image.dispose();
        picture.dispose();
        return counts;
      }

      final normal = await sample(false), selected = await sample(true);
      for (var i = 0; i < normal.length; i++) {
        expect(
          selected[i] - normal[i],
          greaterThan(15),
          reason:
              'outer cap/shoulder/side/base region $i must glow, not only interior polygon',
        );
      }
    } finally {
      art.dispose();
    }
  });
}
