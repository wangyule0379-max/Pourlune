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
    this.bounds,
  });
  final BottleShape shape;
  final Offset sourceMouth, targetMouth;
  final int units, sourceUnits;
  final double initialLift;
  final Rect? bounds;
  double get flowMs => 230 + 70.0 * units;
  double get totalMs => 200 + 90 + flowMs + 210 + 100;
  PourFrame frame(double elapsedMs) {
    final t = elapsedMs.clamp(0.0, totalMs);
    var direction = targetMouth.dx > sourceMouth.dx ? 1.0 : -1.0;
    final area = bounds;
    if (area != null) {
      // Near an edge the bottle body must tilt toward the available interior,
      // including cross-row targets which are only slightly left/right.
      final reach = shape.height + shape.width * .1;
      if (targetMouth.dx - area.left < reach) {
        direction = -1;
      } else if (area.right - targetMouth.dx < reach) {
        direction = 1;
      }
    }
    final initialAngle = pourAngle(shape, sourceUnits.toDouble()) * direction;
    final finalAngle =
        pourAngle(shape, (sourceUnits - units).toDouble()) * direction;
    Offset aligned(double angle) =>
        targetMouth +
        Offset(
          0,
          -(bounds == null ? 35.0 : math.max(14.0, shape.width * .22)),
        ) -
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
            math.min(selected.dy, approachEnd.dy) -
                (bounds == null ? 65 : shape.width * .42),
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
          math.min(from.dy, sourceMouth.dy) -
              (bounds == null ? 55 : shape.width * .35),
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
    if (area != null && stage != 'pour' && stage != 'drain') {
      final corners = [
        shape.imageRect.topLeft,
        shape.imageRect.topRight,
        shape.imageRect.bottomLeft,
        shape.imageRect.bottomRight,
      ].map(source.transform).toList();
      final left = corners.map((p) => p.dx).reduce(math.min);
      final right = corners.map((p) => p.dx).reduce(math.max);
      final top = corners.map((p) => p.dy).reduce(math.min);
      final bottom = corners.map((p) => p.dy).reduce(math.max);
      final dx = left < area.left
          ? area.left - left
          : right > area.right
          ? area.right - right
          : 0.0;
      final dy = top < area.top
          ? area.top - top
          : bottom > area.bottom
          ? area.bottom - bottom
          : 0.0;
      source = BottlePose(
        source.mouth + Offset(dx, dy),
        source.angle,
        scale: source.scale,
      );
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

/// Quantized capacity is one coupled view of the same continuous transport.
/// Midpoint rounding counts half of the in-flight amount at each end. Never
/// round the two bottles independently, which can invent/drop an integer unit.
({int source, int target}) transferCounts({
  required int sourceBefore,
  required int targetBefore,
  required double out,
  required double arrived,
}) {
  final transferred = ((out + arrived) / 2)
      .round()
      .clamp(0, math.min(sourceBefore, 4 - targetBefore))
      .toInt();
  return (
    source: sourceBefore - transferred,
    target: targetBefore + transferred,
  );
}

class BoardLayout {
  BoardLayout({
    required this.width,
    required this.count,
    double textScale = 1,
    double maxHeight = double.infinity,
    this.preview = false,
  }) {
    assert(count >= 4 && count <= 7);
    final bounded = maxHeight.isFinite;
    labelHeight = bounded
        ? math.max(40.0, 32 * textScale + 8)
        : math.max(52.0, 32 * textScale + 14);
    if (preview && bounded && textScale <= 1.4) {
      final cellWidth = width / count;
      shape = BottleShape(math.min(48, cellWidth - 8));
      topRowCount = count;
      mouths = [];
      cells = [];
      for (var i = 0; i < count; i++) {
        final cell = Rect.fromLTWH(
          i * cellWidth,
          labelHeight,
          cellWidth,
          shape.height,
        );
        cells.add(cell);
        mouths.add(Offset(cell.center.dx, cell.top + shape.height * .148));
      }
      height = cells.last.bottom + 4;
      return;
    }
    final preferred = ((width - 24) / 4).clamp(48.0, 84.0);
    shape = BottleShape(
      bounded
          ? math.min(
              preferred,
              math.max(
                preview ? 32 : 48,
                (maxHeight - labelHeight * 2 - (preview ? 12 : 32)) /
                    (preview ? 3 : 3.85),
              ),
            )
          : preferred,
    );
    final rows = switch (count) {
      4 => [2, 2],
      5 => [3, 2],
      6 => [3, 3],
      _ => [4, 3],
    };

    // Captions frame the entire flight area rather than forming a barrier
    // between rows. All labels remain at their own column, next to their row.
    final gutter = preview
        ? labelHeight
        : bounded
        ? labelHeight + shape.width * .85 + 12
        : labelHeight + math.max(72.0, shape.width * .95) + 20;
    final stride =
        shape.height +
        (preview
            ? labelHeight + 8
            : bounded
            ? 8
            : 64);
    topRowCount = rows.first;
    final cellWidth = preferred + 6;
    mouths = [];
    cells = [];
    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < rows[row]; column++) {
        final left = (width - rows[row] * cellWidth) / 2 + column * cellWidth;
        final top = gutter + row * stride;
        mouths.add(Offset(left + cellWidth / 2, top + shape.height * .148));
        cells.add(Rect.fromLTWH(left, top, cellWidth, shape.height));
      }
    }
    height = (preview ? cells.last.bottom : labelRect(count - 1).bottom) + 4;
  }
  final double width;
  final int count;
  final bool preview;
  late final int topRowCount;
  late final BottleShape shape;
  late final double height, labelHeight;
  late final List<Offset> mouths;
  late final List<Rect> cells;
  Rect get flightBounds =>
      Rect.fromLTRB(0, labelHeight + 12, width, labelRect(count - 1).top - 8);
  Rect labelRect(int index) => Rect.fromLTWH(
    cells[index].left,
    preview
        ? cells[index].top - labelHeight
        : index < topRowCount
        ? 8
        : cells[index].top + shape.height + 8,
    cells[index].width,
    labelHeight,
  );
}
