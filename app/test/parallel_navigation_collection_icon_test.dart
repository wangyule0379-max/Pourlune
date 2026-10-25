import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/parallel_navigation/home_collection_art.dart';

void main() {
  testWidgets(
    'P02 collection crop preserves its transparent surrounding layer',
    (t) async {
      const boundaryKey = Key('collection-raster');
      const backdrop = Color(0xff82dff1);
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ColoredBox(
                    color: backdrop,
                    child: Center(child: HomeCollectionArt()),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.runAsync(
        () => precacheImage(
          const AssetImage('assets/art/p05-reference/reference-entry.png'),
          t.element(find.byType(HomeCollectionArt)),
        ),
      );
      await t.pumpAndSettle();
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final pixels = (await t.runAsync(() async {
        final raster = await boundary.toImage(pixelRatio: 1);
        try {
          return await raster.toByteData(format: ui.ImageByteFormat.rawRgba);
        } finally {
          raster.dispose();
        }
      }))!;
      Color pixel(int x, int y) {
        final offset = (y * 100 + x) * 4;
        return Color.fromARGB(
          pixels.getUint8(offset + 3),
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2),
        );
      }

      for (final point in [
        const Offset(4, 4),
        const Offset(95, 4),
        const Offset(4, 95),
        const Offset(95, 95),
      ]) {
        expect(pixel(point.dx.toInt(), point.dy.toInt()), backdrop);
      }
      var purple = 0, green = 0;
      for (var y = 25; y < 75; y++) {
        for (var x = 24; x < 76; x++) {
          final offset = (y * 100 + x) * 4;
          final r = pixels.getUint8(offset),
              g = pixels.getUint8(offset + 1),
              b = pixels.getUint8(offset + 2);
          if (r > g * 1.1 && b > g * 1.1) purple++;
          if (g > r * 1.1 && g > b * 1.1) green++;
        }
      }
      expect(purple, greaterThan(5));
      expect(green, greaterThan(5));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
