import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/bottle.dart';

void main() {
  testWidgets(
    'AC-07 tilted horizontal liquid preserves visible area at low and full volumes',
    (t) async {
      const key = Key('liquid-volume-capture');
      Future<int> greenPixels(double units, double angle) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 240,
                    height: 250,
                    child: Center(
                      child: Transform.rotate(
                        angle: angle,
                        alignment: const Alignment(0, .135135),
                        child: CustomPaint(
                          size: const Size(84, 148),
                          painter: BottlePainter(
                            const [],
                            null,
                            false,
                            showSymbols: false,
                            visualLiquid: [(color: 'G', units: units)],
                            angle: angle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
        return (await t.runAsync(() async {
          final picture = await boundary.toImage(pixelRatio: 4);
          try {
            final data = await picture.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final bytes = data!.buffer.asUint8List();
            var count = 0;
            for (var i = 0; i < bytes.length; i += 4) {
              if (bytes[i + 3] > 200 &&
                  bytes[i + 1] > bytes[i] + 5 &&
                  bytes[i + 1] > bytes[i + 2] + 5) {
                count++;
              }
            }
            return count;
          } finally {
            picture.dispose();
          }
        }))!;
      }

      for (final units in [.5, 1.0, 2.0, 3.0, 4.0]) {
        final upright = await greenPixels(units, 0);
        for (final angle in [-1.05, .6, 1.05, 0.0]) {
          final tilted = await greenPixels(units, angle);
          expect(
            (tilted - upright).abs() / upright,
            lessThan(.04),
            reason:
                '$units units, angle$angle must preserve drawn liquid, not just model units',
          );
        }
      }
      await t.pumpWidget(const SizedBox());
    },
  );
}
