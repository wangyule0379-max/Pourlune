import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

void main() {
  test('large board distributes spare height without a lower blank slab or changing bottle size', () {
    final natural = BoardLayout(width: 408, count: 7);
    final tall = BoardLayout(width: 408, maxHeight: 700, count: 7);
    expect(tall.shape.width, natural.shape.width);
    expect(700 - tall.height, lessThan(65));
    expect(tall.cells.last.top - tall.labelRect(0).bottom, greaterThan(30));
    expect(tall.height, lessThanOrEqualTo(700));
  });
  test(
    'reference top-row transport stays visible and continuous into flow',
    () {
      final layout = BoardLayout(width: 343, maxHeight: 430, count: 6);
      final geometry = PourGeometry(
        shape: layout.shape,
        sourceMouth: layout.mouths[2],
        targetMouth: layout.mouths[0],
        units: 1,
        sourceUnits: 4,
        bounds: layout.flightBounds,
      );
      for (var ms = 0.0; ms <= geometry.totalMs; ms += 5) {
        final frame = geometry.frame(ms);
        for (final corner in [
          layout.shape.visibleRect.topLeft,
          layout.shape.visibleRect.topRight,
          layout.shape.visibleRect.bottomLeft,
          layout.shape.visibleRect.bottomRight,
        ]) {
          final world = frame.source.transform(corner);
          expect(world.dx, inInclusiveRange(-.01, layout.width + .01));
          expect(
            world.dy,
            inInclusiveRange(-.01, layout.height + .01),
            reason: 'at $ms',
          );
        }
        if (frame.inStream > .000001) {
          expect(frame.streamStart.dx, closeTo(frame.streamEnd.dx, .001));
          expect(frame.streamStart.dy, lessThan(frame.streamEnd.dy));
        }
      }
      final before = geometry.frame(289), after = geometry.frame(290);
      expect(
        (before.source.mouth - after.source.mouth).distance,
        lessThan(1.2),
      );
      expect((before.source.scale - after.source.scale).abs(), lessThan(.01));
    },
  );
  test(
    'reference play uses visible bottle bounds and nearby lower captions',
    () {
      final layout = BoardLayout(width: 358, maxHeight: 470, count: 6);
      // Reference material is a directly measured 166×309 component, not
      // the earlier generated PNG canvas with transparent margins.
      final shape = layout.shape;
      final visible = Rect.fromLTWH(
        -shape.width / 2,
        -shape.height * .10,
        shape.width,
        shape.height,
      );
      expect(shape.height / shape.width, closeTo(309 / 166, .00001));
      expect(visible.width, greaterThanOrEqualTo(78));
      for (var i = 0; i < 6; i++) {
        final physical = visible.shift(layout.mouths[i]);
        final caption = layout.labelRect(i);
        expect(physical.left, greaterThanOrEqualTo(0));
        expect(physical.right, lessThanOrEqualTo(358));
        expect(caption.top - physical.bottom, inInclusiveRange(4, 8));
        expect(caption.bottom, lessThanOrEqualTo(470.001));
        expect(layout.cells[i].contains(physical.center), isTrue);
      }
    },
  );

  test('actual Hint curve and arrowhead avoid every glass window and capacity caption', () {
    for (final width in [288.0, 343.0, 390.0, 768.0]) {
      for (var count = 4; count <= 7; count++) {
        for (final scale in [1.0, 1.65, 2.0]) {
          final layout = BoardLayout(
            width: width,
            count: count,
            textScale: scale,
          );
          final glass = [
            for (final mouth in layout.mouths)
              Path()..addPolygon(
                layout.shape.worldHull(BottlePose(mouth, 0)),
                true,
              ),
          ];
          void clear(Offset point, String reason) {
            for (final delta in const [
              Offset.zero,
              Offset(3, 0),
              Offset(-3, 0),
              Offset(0, 3),
              Offset(0, -3),
            ]) {
              final p = point + delta;
              expect(p.dx, inInclusiveRange(-.01, width + .01), reason: reason);
              expect(p.dy, greaterThanOrEqualTo(-.01), reason: reason);
              for (var i = 0; i < count; i++) {
                expect(
                  glass[i].contains(p),
                  isFalse,
                  reason: '$reason crosses glass$i',
                );
                expect(
                  layout.labelRect(i).contains(p),
                  isFalse,
                  reason:
                      '$reason at $p covers caption$i ${layout.labelRect(i)}',
                );
              }
            }
          }

          for (var from = 0; from < count; from++) {
            for (var to = 0; to < count; to++) {
              if (from == to) continue;
              final metric = layout.hintPath(from, to).computeMetrics().single;
              final reason = '$width/$count/$scale $from→$to';
              for (var d = 0.0; d < metric.length; d += 2) {
                clear(metric.getTangentForOffset(d)!.position, reason);
              }
              final tip = metric.getTangentForOffset(metric.length)!;
              clear(tip.position, reason);
              for (final turn in [-.65, .65]) {
                final wing =
                    tip.position -
                    Offset.fromDirection(tip.vector.direction + turn, 9);
                for (var step = 0; step <= 10; step++) {
                  clear(Offset.lerp(tip.position, wing, step / 10)!, reason);
                }
              }
            }
          }
        }
      }
    }
  });

  test('cross-row Hint ends beside destination neck as one continuous arc', () {
    final layout = BoardLayout(width: 351, maxHeight: 430, count: 6);
    final metric = layout.hintPath(0, 3).computeMetrics().single;
    final end = metric.getTangentForOffset(metric.length)!;
    expect(
      end.position.dx,
      greaterThan(layout.mouths[3].dx + layout.shape.width * .25),
      reason: 'tip should point to outer destination neck, not run as a right-angle line over capacity captions',
    );
    expect(end.position.dy, greaterThan(layout.cells[3].top));
    var axial = 0;
    for (var i = 1; i < 80; i++) {
      final tangent = metric.getTangentForOffset(metric.length * i / 80)!;
      if (tangent.vector.dx.abs() < .01 || tangent.vector.dy.abs() < .01) {
        axial++;
      }
    }
    expect(
      axial,
      lessThan(8),
      reason: 'continuous curved pour guidance, not a nearly rectangular elbow',
    );
  });
}
