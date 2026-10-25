import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/parallel_collection/collection_visuals.dart';

void main() {
  for (final transparent in [false, true]) {
    testWidgets(
      'collection art preserves outside pixels / transparent=$transparent',
      (t) async {
        final boundaryKey = GlobalKey();
        const background = Color(0xff1565c0);
        await t.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Nunito'),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox(
                    width: 320,
                    height: 240,
                    child: Stack(
                      children: [
                        if (!transparent)
                          const Positioned.fill(
                            child: ColoredBox(color: background),
                          ),
                        const Positioned(
                          left: 20,
                          top: 15,
                          width: 80,
                          height: 80,
                          child: CollectionCelebrationHero(
                            child: SizedBox.expand(),
                          ),
                        ),
                        const Positioned(
                          left: 120,
                          top: 120,
                          width: 160,
                          height: 60,
                          child: CollectionActionLabel('Next'),
                        ),
                        const Positioned(
                          left: 20,
                          top: 140,
                          width: 80,
                          height: 60,
                          child: CollectionActionLabel('Back', leading: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final pixels = (await t.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 1);
          try {
            return await rendered.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
          } finally {
            rendered.dispose();
          }
        }))!;
        for (final point in [
          const Offset(2, 2),
          const Offset(300, 5),
          const Offset(310, 220),
          const Offset(8, 225),
        ]) {
          final at = (point.dy.toInt() * 320 + point.dx.toInt()) * 4;
          final actual = List.generate(4, (i) => pixels.getUint8(at + i));
          expect(
            actual,
            transparent ? [0, 0, 0, 0] : [21, 101, 192, 255],
            reason: '$point',
          );
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}
