import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

void main() {
  test('8px whole-bottle selection stays in bounded boards and outside fixed readouts', () {
    for (final c in [
      (width: 416.0, height: 569.0, scale: 32.94117647058824 / 14),
      (width: 351.0, height: 430.0, scale: 1.0),
      (width: 296.0, height: 284.0, scale: 2.0),
    ]) {
      for (var count = 4; count <= 7; count++) {
        final layout = BoardLayout(
          width: c.width,
          count: count,
          maxHeight: c.height,
          textScale: c.scale,
        );
        for (var i = 0; i < count; i++) {
          final body = layout.shape.worldOutline(
            BottlePose(layout.mouths[i] - const Offset(0, 8), 0),
          );
          expect(body.getBounds().top, greaterThanOrEqualTo(0));
          expect(body.getBounds().bottom, lessThanOrEqualTo(layout.height));
          final hit = layout.hitRect(i);
          // Raster material is restricted to imageRect. Path.getBounds also
          // includes Bézier control points outside the painted bottle.
          final sprite = layout.shape.visibleRect.shift(
            layout.mouths[i] - const Offset(0, 8),
          );
          expect(hit.top, lessThanOrEqualTo(sprite.top));
          expect(hit.bottom, greaterThanOrEqualTo(sprite.bottom));
          for (var other = 0; other < count; other++) {
            if (other != i) {
              expect(hit.overlaps(layout.hitRect(other)), isFalse);
            }
          }
          for (var label = 0; label < count; label++) {
            final overlap = Path.combine(
              PathOperation.intersect,
              body,
              Path()..addRect(layout.labelRect(label)),
            );
            expect(
              overlap.computeMetrics(),
              isEmpty,
              reason:
                  '$count/$i/${c.width}/${c.scale}: selected body must not cross fixed readout $label',
            );
          }
        }
      }
    }
  });
}
