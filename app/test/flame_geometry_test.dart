import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/development/flame_sample/geometry.dart';

void main() {
  test('horizontal fill represents exact area at every tilt and does not cross walls', () {
    const shape = BottleShape(150);
    for (final angle in [0.0, .5, 1.0, 1.5, -.5, -1.5]) {
      final hull = shape.worldHull(BottlePose(const Offset(100, 120), angle));
      for (final units in [.1, 1.0, 2.5, 4.0]) {
        final level = waterline(hull, units * shape.unitArea);
        expect(areaBelow(hull, level), closeTo(units * shape.unitArea, .01));
      }
    }
    expect(shape.unitArea, greaterThan(100));
    expect(pourAngle(shape, 1), greaterThan(pourAngle(shape, 4)));
  });
  test('left and right pours conserve bottle plus stream volume and share exact mouth transforms', () {
    const shape = BottleShape(150);
    for (final left in [true, false]) {
      for (final units in [1, 2, 3, 4]) {
        final g = PourGeometry(
          shape: shape,
          sourceMouth: Offset(left ? 90 : 280, 150),
          targetMouth: Offset(left ? 280 : 90, 150),
          units: units,
          sourceUnits: 4,
        );
        var previous = 0.0;
        var flowing = 0;
        for (var ms = 0.0; ms <= g.totalMs; ms += 5) {
          final f = g.frame(ms);
          expect(f.out, greaterThanOrEqualTo(previous - .00001));
          previous = f.out;
          expect(f.delivered, inInclusiveRange(0, units.toDouble()));
          expect(f.inStream, greaterThanOrEqualTo(-.00001));
          expect(4 - f.out + f.delivered + f.inStream, closeTo(4, .00001));
          if (f.inStream > .00001) {
            flowing++;
            final actualLip = f.source.transform(shape.lip(left ? 1 : -1));
            expect((actualLip - f.streamStart).distance, lessThan(.001));
            expect(
              (f.target.transform(Offset.zero) - f.streamEnd).distance,
              lessThan(.001),
            );
            expect((f.streamStart.dx - f.streamEnd.dx).abs(), lessThan(.001));
            expect(f.streamEnd.dy, greaterThan(f.streamStart.dy));
          }
        }
        expect(flowing, greaterThan(10));
        final finalFrame = g.frame(g.totalMs);
        expect(finalFrame.out, units.toDouble());
        expect(finalFrame.delivered, units.toDouble());
        expect(
          (finalFrame.source.mouth - g.sourceMouth).distance,
          lessThan(.001),
        );
        expect(finalFrame.source.angle, closeTo(0, math.pi / 10000));
      }
    }
  });
}
