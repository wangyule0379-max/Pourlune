import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:ui' as ui;

import 'package:pourlune_dev/presentation/bottle_foot_label.dart';

void main() {
  testWidgets('normal target pictograms retain distinct matching color hues', (
    t,
  ) async {
    for (final target in ['O', 'G', 'P', 'B']) {
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const Key('target-pixels'),
              child: TargetCushion(
                size: 60,
                target: target,
                symbolsEnabled: true,
                strongContrast: false,
              ),
            ),
          ),
        ),
      );
      final image = (await t.runAsync(
        () => t
            .renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('target-pixels')),
            )
            .toImage(),
      ))!;
      final pixels = (await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final offset = (30 * image.width + 30) * 4;
      final color = Color.fromARGB(
        255,
        pixels.getUint8(offset),
        pixels.getUint8(offset + 1),
        pixels.getUint8(offset + 2),
      );
      final hsv = HSVColor.fromColor(color);
      final expectedHue = {
        'O': 27.0,
        'G': 113.0,
        'P': 277.0,
        'B': 209.0,
      }[target]!;
      expect(
        hsv.hue,
        closeTo(expectedHue, 15),
        reason: '$target must match its target bottle color family',
      );
      expect(
        hsv.value,
        greaterThan(.45),
        reason: 'Normal mode must retain a visible color identity',
      );
      image.dispose();
    }
  });
  testWidgets(
    'target is an independent cushion; buffer has no target and count stays separate',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Row(
            children: [
              SizedBox(
                width: 90,
                height: 56,
                child: BottleFootLabel(
                  index: 0,
                  target: 'G',
                  count: 3,
                  prefix: 'bottle',
                  symbolsEnabled: true,
                  strongContrast: false,
                ),
              ),
              SizedBox(
                width: 90,
                height: 56,
                child: BottleFootLabel(
                  index: 4,
                  target: null,
                  count: 0,
                  prefix: 'bottle',
                  symbolsEnabled: true,
                  strongContrast: false,
                ),
              ),
            ],
          ),
        ),
      );
      final badge = t.getRect(find.byKey(const Key('bottle-target-0')));
      expect(badge.width, greaterThanOrEqualTo(34));
      expect(find.byKey(const Key('bottle-target-4')), findsNothing);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('0/4'), findsOneWidget);
      expect(
        badge.overlaps(t.getRect(find.byKey(const Key('bottle-count-0')))),
        isFalse,
      );
      expect(t.takeException(), isNull);
    },
  );
}
