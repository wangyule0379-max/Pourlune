import 'dart:math' as math;
import 'dart:ui';

/// Geometry in the sample canvas. Mouth is the transform origin, rather than
/// a separately guessed point used only by the stream.
class BottlePose {
  const BottlePose(this.mouth, this.angle, {this.scale = 1});
  final Offset mouth;
  final double angle, scale;
  Offset transform(Offset local) =>
      mouth +
      Offset(
        (local.dx * math.cos(angle) - local.dy * math.sin(angle)) * scale,
        (local.dx * math.sin(angle) + local.dy * math.cos(angle)) * scale,
      );
}

class BottleShape {
  const BottleShape(this.width);
  final double width;
  double get height => width * 1.5;
  Rect get imageRect =>
      Rect.fromLTWH(-width / 2, -height * .148, width, height);
  List<Offset> get interior => [
    for (final p in const [
      Offset(.42, .15),
      Offset(.58, .15),
      Offset(.59, .265),
      Offset(.71, .32),
      Offset(.72, .82),
      Offset(.69, .856),
      Offset(.31, .856),
      Offset(.28, .82),
      Offset(.29, .32),
      Offset(.41, .265),
    ])
      Offset((p.dx - .5) * width, (p.dy - .148) * height),
  ];
  double get unitArea => areaBelow(interior, (.34 - .148) * height) / 4;
  List<Offset> worldHull(BottlePose pose) =>
      interior.map(pose.transform).toList();
  Offset lip(double direction) => Offset(direction * .08 * width, 0);
}

double polygonArea(List<Offset> polygon) {
  if (polygon.length < 3) return 0;
  var cross = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i], b = polygon[(i + 1) % polygon.length];
    cross += a.dx * b.dy - b.dx * a.dy;
  }
  return cross.abs() / 2;
}

double areaBelow(List<Offset> polygon, double y) {
  if (polygon.isEmpty) return 0;
  final clipped = <Offset>[];
  var previous = polygon.last;
  for (final point in polygon) {
    if ((point.dy >= y) != (previous.dy >= y)) {
      final fraction = (y - previous.dy) / (point.dy - previous.dy);
      clipped.add(Offset(previous.dx + fraction * (point.dx - previous.dx), y));
    }
    if (point.dy >= y) clipped.add(point);
    previous = point;
  }
  return polygonArea(clipped);
}

double waterline(List<Offset> polygon, double volumeArea) {
  var low = polygon.map((p) => p.dy).reduce(math.min);
  var high = polygon.map((p) => p.dy).reduce(math.max);
  if (volumeArea <= 0) return high;
  if (volumeArea >= polygonArea(polygon)) return low;
  for (var n = 0; n < 28; n++) {
    final mid = (low + high) / 2;
    if (areaBelow(polygon, mid) > volumeArea) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (low + high) / 2;
}

double pourAngle(BottleShape shape, double units) {
  var low = 0.0, high = 1.72;
  final volume = units.clamp(.001, 4) * shape.unitArea;
  for (var i = 0; i < 25; i++) {
    final mid = (low + high) / 2;
    final pose = BottlePose(Offset.zero, mid);
    final retained = areaBelow(
      shape.worldHull(pose),
      pose.transform(shape.lip(1)).dy,
    );
    if (retained > volume) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (low + high) / 2;
}

double _ease(double t) {
  final v = t.clamp(0.0, 1.0);
  return v * v * (3 - 2 * v);
}

Offset _arc(Offset from, Offset control, Offset to, double t) =>
    from * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + to * (t * t);

class PourFrame {
  const PourFrame({
    required this.source,
    required this.target,
    required this.out,
    required this.delivered,
    required this.streamStart,
    required this.streamEnd,
    required this.streamHead,
    required this.streamTail,
    required this.stage,
  });
  final BottlePose source, target;
  final double out, delivered, streamHead, streamTail;
  final Offset streamStart, streamEnd;
  final String stage;
  double get inStream => out - delivered;
}

class PourGeometry {
  const PourGeometry({
    required this.shape,
    required this.sourceMouth,
    required this.targetMouth,
    required this.units,
    required this.sourceUnits,
    this.initialLift = 0,
  });
  final BottleShape shape;
  final Offset sourceMouth, targetMouth;
  final int units, sourceUnits;
  final double initialLift;
  double get flowMs => 230 + 70.0 * units;
  double get totalMs => 200 + 90 + flowMs + 210 + 100;
  PourFrame frame(double elapsedMs) {
    final t = elapsedMs.clamp(0.0, totalMs);
    final direction = targetMouth.dx > sourceMouth.dx ? 1.0 : -1.0;
    final initialAngle = pourAngle(shape, sourceUnits.toDouble()) * direction;
    final finalAngle =
        pourAngle(shape, (sourceUnits - units).toDouble()) * direction;
    Offset aligned(double angle) =>
        targetMouth +
        const Offset(0, -35) -
        BottlePose(Offset.zero, angle).transform(shape.lip(direction));
    final selected = sourceMouth + Offset(0, -initialLift);
    final approachEnd = aligned(initialAngle * .65);
    var out = 0.0, delivered = 0.0, head = 0.0, tail = 0.0;
    late BottlePose source;
    late String stage;
    if (t < 200) {
      final p = _ease(t / 200);
      source = BottlePose(
        _arc(
          selected,
          Offset(
            (sourceMouth.dx + approachEnd.dx) / 2,
            math.min(selected.dy, approachEnd.dy) - 65,
          ),
          approachEnd,
          p,
        ),
        initialAngle * .65 * p,
      );
      stage = 'approach';
    } else if (t < 290) {
      final p = _ease((t - 200) / 90), angle = initialAngle * (.65 + .35 * p);
      source = BottlePose(aligned(angle), angle);
      stage = 'align';
    } else if (t < 290 + flowMs) {
      final f = t - 290;
      const lag = 26.0;
      out = units * _ease(f / (flowMs - lag));
      delivered = units * _ease((f - lag) / (flowMs - lag));
      final angle = pourAngle(shape, sourceUnits - out) * direction;
      source = BottlePose(aligned(angle), angle);
      head = (f / lag).clamp(0.0, 1.0);
      tail = ((f - (flowMs - lag)) / lag).clamp(0.0, 1.0);
      stage = tail > 0 ? 'drain' : 'pour';
    } else {
      out = delivered = units.toDouble();
      final p = _ease((t - 290 - flowMs) / 210);
      final from = aligned(finalAngle);
      final landed = _arc(
        from,
        Offset(
          (from.dx + sourceMouth.dx) / 2,
          math.min(from.dy, sourceMouth.dy) - 55,
        ),
        sourceMouth,
        p,
      );
      final settle = ((t - 290 - flowMs - 210) / 100).clamp(0.0, 1.0);
      source = BottlePose(
        landed + Offset(0, math.sin(settle * math.pi) * 1.4),
        finalAngle * (1 - p),
      );
      stage = p < 1 ? 'return' : 'settle';
    }
    final target = BottlePose(targetMouth, 0);
    return PourFrame(
      source: source,
      target: target,
      out: out,
      delivered: delivered,
      streamStart: source.transform(shape.lip(direction)),
      streamEnd: target.transform(Offset.zero),
      streamHead: head,
      streamTail: tail,
      stage: stage,
    );
  }
}
