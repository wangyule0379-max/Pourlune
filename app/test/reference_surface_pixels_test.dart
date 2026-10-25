import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/reference_extra_art.dart';

void main() {
  testWidgets('blank chapter cell contains no baked completion marker', (
    t,
  ) async {
    final boundaryKey = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: const SizedBox(
              width: 76,
              height: 64,
              child: ReferenceExtraSurface(
                kind: ExtraSurfaceKind.chapterCell,
                cornerRadius: 14,
                tileEdges: true,
              ),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(
      () => precacheImage(
        const AssetImage('assets/art/p05-reference/reference-entry.png'),
        t.element(find.byType(ReferenceExtraSurface)),
      ),
    );
    await t.pumpAndSettle();
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final data = (await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      } finally {
        image.dispose();
      }
    }))!;
    var opaque = 0;
    var green = 0;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      if (data.getUint8(i + 3) < 200) continue;
      opaque++;
      final r = data.getUint8(i),
          g = data.getUint8(i + 1),
          b = data.getUint8(i + 2);
      if (g > r + 15 && g > b + 15) green++;
    }
    expect(opaque, greaterThan(5000));
    expect(
      green,
      0,
      reason: 'Only native progress may draw a completion mark.',
    );
    await t.pumpWidget(const SizedBox());
  });
}
