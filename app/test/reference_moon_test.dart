import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/reference_play_art.dart';

void main() {
  testWidgets('moon has no cyan square on the high contrast white page', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: Key('moon-pixels'),
            child: SizedBox(
              width: 48,
              height: 48,
              child: ColoredBox(color: Colors.white, child: ReferenceMoonArt()),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(
      () => precacheImage(
        const AssetImage('assets/art/p05-reference/reference-play.png'),
        t.element(find.byType(ReferenceMoonArt)),
      ),
    );
    await t.pumpAndSettle();
    final image = (await t.runAsync(
      () => t
          .renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('moon-pixels')),
          )
          .toImage(),
    ))!;
    final bytes = (await t.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    for (final p in [
      const Offset(0, 0),
      const Offset(47, 0),
      const Offset(47, 47),
      const Offset(0, 47),
    ]) {
      final i = (p.dy.toInt() * image.width + p.dx.toInt()) * 4;
      for (var channel = 0; channel < 3; channel++) {
        expect(bytes.getUint8(i + channel), 255);
      }
    }
    var purple = 0;
    for (var i = 0; i < bytes.lengthInBytes; i += 4) {
      if (bytes.getUint8(i) > 120 &&
          bytes.getUint8(i + 2) > 150 &&
          bytes.getUint8(i + 1) < 160) {
        purple++;
      }
    }
    expect(purple, greaterThan(300));
    image.dispose();
  });
}
