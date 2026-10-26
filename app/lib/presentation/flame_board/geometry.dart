import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';

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
  const BottleShape(this.width, {this.aspectRatio = 309 / 166});
  final double width, aspectRatio;
  double get height => width * aspectRatio;
  Rect get imageRect => Rect.fromLTWH(-width / 2, -height * .10, width, height);
  Rect get visibleRect => imageRect;
  List<Offset> get interior => [
    for (final p in const [
      Offset(.38, .10),
      Offset(.62, .10),
      Offset(.64, .19),
      Offset(.78, .245),
      Offset(.82, .30),
      Offset(.82, .79),
      Offset(.76, .86),
      Offset(.24, .86),
      Offset(.18, .79),
      Offset(.18, .30),
      Offset(.22, .245),
      Offset(.36, .19),
    ])
      Offset((p.dx - .5) * width, (p.dy - .10) * height),
  ];
  Path get outline {
    Offset point(double x, double y) =>
        Offset((x - .5) * width, (y - .10) * height);
    return Path()
      ..moveTo(point(.23, .04).dx, point(.23, .04).dy)
      ..cubicTo(
        point(.23, -.005).dx,
        point(.23, -.005).dy,
        point(.77, -.005).dx,
        point(.77, -.005).dy,
        point(.77, .04).dx,
        point(.77, .04).dy,
      )
      ..lineTo(point(.76, .13).dx, point(.76, .13).dy)
      ..cubicTo(
        point(.76, .18).dx,
        point(.76, .18).dy,
        point(.98, .18).dx,
        point(.98, .18).dy,
        point(.98, .32).dx,
        point(.98, .32).dy,
      )
      ..lineTo(point(.98, .90).dx, point(.98, .90).dy)
      ..cubicTo(
        point(.98, 1.05).dx,
        point(.98, 1.05).dy,
        point(.02, 1.05).dx,
        point(.02, 1.05).dy,
        point(.02, .90).dx,
        point(.02, .90).dy,
      )
      ..lineTo(point(.02, .32).dx, point(.02, .32).dy)
      ..cubicTo(
        point(.02, .18).dx,
        point(.02, .18).dy,
        point(.24, .18).dx,
        point(.24, .18).dy,
        point(.24, .13).dx,
        point(.24, .13).dy,
      )
      ..close();
  }

  Path worldOutline(BottlePose pose) {
    final c = math.cos(pose.angle) * pose.scale;
    final s = math.sin(pose.angle) * pose.scale;
    return outline.transform(
      Float64List.fromList([
        c,
        s,
        0,
        0,
        -s,
        c,
        0,
        0,
        0,
        0,
        1,
        0,
        pose.mouth.dx,
        pose.mouth.dy,
        0,
        1,
      ]),
    );
  }

  double get unitArea => areaBelow(interior, (.29 - .10) * height) / 4;
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
  double get flowMs => 460 + 100.0 * units;
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
    final rimClearance =
        -shape.imageRect.top + (shape.width * .14).clamp(8.0, 16.0);
    double rimDrop(double angle) {
      final turn = BottlePose(Offset.zero, angle);
      // The top 17% of the original material contains the knit rim/seam.
      // Its rotated lower edge, not the stream's lip point, needs clearance
      // above the receiving rim. The envelope includes the widening neck.
      final rim = Rect.fromLTRB(
        -shape.width * .32,
        -shape.height * .10,
        shape.width * .32,
        shape.height * .07,
      );
      final bottom = [
        rim.topLeft,
        rim.topRight,
        rim.bottomLeft,
        rim.bottomRight,
      ].map((p) => turn.transform(p).dy).reduce(math.max);
      return bottom - turn.transform(shape.lip(direction)).dy;
    }

    double transportScale(double angle) {
      if (area == null) return 1;
      final turn = BottlePose(Offset.zero, angle);
      final lip = turn.transform(shape.lip(direction));
      final anchor = targetMouth - Offset(0, rimClearance);
      var scale = 1.0;
      for (final corner in [
        shape.visibleRect.topLeft,
        shape.visibleRect.topRight,
        shape.visibleRect.bottomLeft,
        shape.visibleRect.bottomRight,
      ]) {
        // The rim's extension scales with the transported bottle too, so
        // clearance and canvas fitting share one linear transform.
        final delta = turn.transform(corner) - lip - Offset(0, rimDrop(angle));
        if (delta.dx < 0) {
          scale = math.min(scale, (anchor.dx - area.left) / -delta.dx);
        }
        if (delta.dx > 0) {
          scale = math.min(scale, (area.right - anchor.dx) / delta.dx);
        }
        if (delta.dy < 0) {
          scale = math.min(scale, (anchor.dy - area.top) / -delta.dy);
        }
        if (delta.dy > 0) {
          scale = math.min(scale, (area.bottom - anchor.dy) / delta.dy);
        }
      }
      return scale.clamp(.01, 1);
    }

    Offset aligned(double angle) {
      final scale = transportScale(angle);
      final gap = area == null ? 35.0 : rimClearance + rimDrop(angle) * scale;
      return targetMouth -
          Offset(0, gap) -
          BottlePose(
            Offset.zero,
            angle,
            scale: scale,
          ).transform(shape.lip(direction));
    }

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
        scale: 1 + (transportScale(initialAngle * .65) - 1) * p,
      );
      stage = 'approach';
    } else if (t < 290) {
      final p = _ease((t - 200) / 90), angle = initialAngle * (.65 + .35 * p);
      source = BottlePose(aligned(angle), angle, scale: transportScale(angle));
      stage = 'align';
    } else if (t < 290 + flowMs) {
      final f = t - 290;
      const lag = 60.0;
      out = units * _ease(f / (flowMs - lag));
      delivered = units * _ease((f - lag) / (flowMs - lag));
      final angle = pourAngle(shape, sourceUnits - out) * direction;
      source = BottlePose(aligned(angle), angle, scale: transportScale(angle));
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
        scale:
            transportScale(finalAngle) + (1 - transportScale(finalAngle)) * p,
      );
      stage = p < 1 ? 'return' : 'settle';
    }
    if (area != null && stage != 'pour' && stage != 'drain') {
      final corners = [
        shape.visibleRect.topLeft,
        shape.visibleRect.topRight,
        shape.visibleRect.bottomLeft,
        shape.visibleRect.bottomRight,
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
    this.footLabels = true,
    this.bottomCaptionsExternal = false,
  }) {
    assert(count >= 4 && count <= 8);
    final rows = switch (count) {
      4 => [2, 2],
      5 => [3, 2],
      6 => [3, 3],
      7 => [4, 3],
      _ => [4, 4],
    };
    compactLabels = textScale <= 1.3 && width / rows.first - 12 >= 80;
    // Target cushions sit above a separate number/capacity row.
    final targetLine = math.max(34.0, 12 * textScale + 12);
    labelHeight = footLabels ? targetLine + 3 + 14 * 1.2 * textScale + 1 : 0;
    _labelWidth = math.max(52.0, 38 * textScale);
    topRowCount = rows.first;
    const visibleAspect = 309 / 166;
    final columnWidth = math.min(106.0, width / rows.first - 12);
    final preferred = count == 6 && textScale <= 1.3
        ? math.min(columnWidth, (width + 24) * 166 / 676)
        : columnWidth;
    // Eight-pixel lift plus the three-sigma cyan halo must fit before the
    // canvas edge. Keep the minimum touch rows on the shortest dense board.
    var topPadding = preview
        ? 12.0
        : footLabels || maxHeight >= 2 * 48 + 10 + 24
        ? 24.0
        : 9.0;
    final captionGap = footLabels ? 5.0 : 0.0;
    // Nine pixels of raised-cap hit coverage need a disjoint gutter too.
    var rowGap = footLabels ? (compactLabels ? 12.0 : 16.0) : 10.0;
    final captionRows = bottomCaptionsExternal ? 1 : 2;
    final fitting = maxHeight.isFinite
        ? (maxHeight -
                  topPadding -
                  rowGap -
                  captionRows * (labelHeight + captionGap)) /
              (2 * visibleAspect)
        : preferred;
    final visibleWidth = math.min(
      preferred,
      // The 48px minimum applies to the touch cell's height, not bottle
      // width. Preserve two rows when large labels consume the small screen.
      math.max(preview ? 20.0 : 48.0 / visibleAspect, fitting),
    );
    shape = BottleShape(visibleWidth);
    final visible = shape.visibleRect;
    if (maxHeight.isFinite) {
      final spare = math.max(
        0.0,
        maxHeight -
            topPadding -
            rowGap -
            2 * visible.height -
            captionRows * (captionGap + labelHeight),
      );
      // Distribute genuinely spare room above/between/below the two rows.
      // Bottle proportions and the minimum caption gap remain unchanged.
      topPadding += spare * .24;
      rowGap += spare * .52;
    }
    final cellWidth = math.max(48.0, columnWidth + 8);
    final stride = visible.height + captionGap + labelHeight + rowGap;
    mouths = [];
    cells = [];
    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < rows[row]; column++) {
        final left = (width - rows[row] * cellWidth) / 2 + column * cellWidth;
        final top = topPadding + row * stride;
        mouths.add(Offset(left + cellWidth / 2, top - visible.top));
        cells.add(Rect.fromLTWH(left, top, cellWidth, visible.height));
      }
    }
    height = footLabels && !bottomCaptionsExternal
        ? labelRect(count - 1).bottom
        : cells.last.bottom;
  }
  final double width;
  final int count;
  final bool preview, footLabels, bottomCaptionsExternal;
  late final int topRowCount;
  late final bool compactLabels;
  late final BottleShape shape;
  late final double height, labelHeight;
  late final double _labelWidth;
  late final List<Offset> mouths;
  late final List<Rect> cells;

  /// Stable hit coverage includes the raised cap without moving any readout.
  Rect hitRect(int index) => Rect.fromLTRB(
    cells[index].left,
    cells[index].top - 9, // 8px lift plus the visible cap edge.
    cells[index].right,
    cells[index].bottom,
  );

  /// Static Hint cue stays in the gutters; no game state or motion timer.
  List<Offset> hintRoute(int from, int to) {
    assert(from != to && from >= 0 && to >= 0 && from < count && to < count);
    final start = Offset(mouths[from].dx, cells[from].top - 6);
    final end = Offset(mouths[to].dx, cells[to].top - 1);
    if (count == 6 && compactLabels && from < 3 && to >= 3) {
      final source = shape.visibleRect.shift(mouths[from]);
      final direction = from == 2 || from > to - 3 ? -1.0 : 1.0;
      final gutter = mouths[from].dx + direction * cells[from].width / 2;
      final flank = Offset(
        direction < 0 ? source.left - 4 : source.right + 4,
        source.bottom - 6,
      );
      return [
        flank,
        Offset(gutter, flank.dy + 6),
        Offset(gutter, end.dy - 3),
        Offset(end.dx, end.dy - 3),
        end,
      ];
    }
    if ((cells[from].top - cells[to].top).abs() < .01) {
      return [
        start,
        Offset(start.dx, start.dy - 2),
        Offset(end.dx, end.dy - 3),
        end,
      ];
    }
    // Cross-row cues go around the outside instead of crossing another
    // bottle's liquid or the upper row's caption band.
    final side = start.dx + end.dx < width ? 3.0 : width - 3;
    return [
      start,
      Offset(start.dx, start.dy - 2),
      Offset(side, start.dy - 2),
      Offset(side, end.dy - 3),
      Offset(end.dx, end.dy - 3),
      end,
    ];
  }

  Path hintPath(int from, int to) {
    if (count == 6 && compactLabels && from < 3 && to >= 3) {
      final source = shape.visibleRect.shift(mouths[from]);
      final column = to - 3;
      final direction = from == 2 || from > column ? -1.0 : 1.0;
      final start = Offset(
        direction < 0 ? source.left - 4 : source.right + 4,
        source.bottom - 6,
      );
      final targetSide = from == column ? direction : -direction;
      final end = Offset(
        mouths[to].dx + targetSide * (shape.width * .27 + 8),
        cells[to].top + 8,
      );
      final gutter = mouths[from].dx + direction * cells[from].width / 2;
      final path = Path()..moveTo(start.dx, start.dy);
      if ((from - column).abs() <= 1) {
        path.cubicTo(
          gutter,
          start.dy + 18,
          gutter,
          end.dy - 18,
          end.dx,
          end.dy,
        );
      } else {
        final corridor = cells[to].top - 6;
        path.cubicTo(
          gutter,
          start.dy + 18,
          gutter,
          corridor - 10,
          gutter,
          corridor,
        );
        path.cubicTo(
          gutter + direction * 36,
          corridor,
          end.dx - direction * 18,
          corridor,
          end.dx,
          end.dy,
        );
      }
      return path;
    }
    final route = hintRoute(from, to);
    final path = Path()..moveTo(route.first.dx, route.first.dy);
    for (var i = 1; i < route.length - 1; i++) {
      final corner = route[i], before = route[i - 1], after = route[i + 1];
      final radius = math.min(
        20.0,
        math.min((corner - before).distance, (after - corner).distance) / 2,
      );
      final entry =
          corner + (before - corner) / (before - corner).distance * radius;
      final exit =
          corner + (after - corner) / (after - corner).distance * radius;
      path.lineTo(entry.dx, entry.dy);
      path.quadraticBezierTo(corner.dx, corner.dy, exit.dx, exit.dy);
    }
    path.lineTo(route.last.dx, route.last.dy);
    return path;
  }

  Rect get flightBounds => Rect.fromLTWH(0, 0, width, height);
  Rect labelRect(int index) {
    final labelWidth = math.min(cells[index].width, _labelWidth);
    return Rect.fromLTWH(
      cells[index].center.dx - labelWidth / 2,
      cells[index].bottom + 5,
      labelWidth,
      labelHeight,
    );
  }
}
