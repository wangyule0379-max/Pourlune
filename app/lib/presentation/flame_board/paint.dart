import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/player_settings.dart';
import '../bottle.dart' show LiquidBand, ink, liquidColors, fivePointStar;
import '../bottle_material.dart';
import 'frame.dart';
import 'geometry.dart';

/// Two shared decoded layers, owned by one mounted board, not a global cache.
class BottleArt {
  BottleArt(this.reference);
  final ui.Image reference;
  bool disposed = false;
  static Future<BottleArt> load() async {
    final data = await rootBundle.load(
      'assets/art/p05-reference/reference-play.png',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      return BottleArt((await codec.getNextFrame()).image);
    } finally {
      codec.dispose();
    }
  }

  void dispose() {
    if (disposed) return;
    disposed = true;
    reference.dispose();
  }
}

class FlameBoardPainter {
  FlameBoardPainter(this.art);
  final BottleArt art;
  void paint(
    Canvas canvas,
    BoardVisualFrame frame,
    PlayerSettings settings, {
    int? selected,
    int? suggested,
    int? hintSource,
    int? addedBottle,
    required List<double> press,
    int? shaking,
    double shake = 0,
    bool reduced = false,
  }) {
    if (art.disposed) return;
    final shape = frame.layout.shape, active = frame.active;
    for (var i = 0; i < frame.poses.length; i++) {
      final mouth = frame.layout.mouths[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: mouth + Offset(0, shape.height * .90 + 1),
          width: shape.width * .92,
          height: math.max(5.0, shape.width * .14),
        ),
        Paint()
          ..color = ink.withValues(alpha: active?.from == i ? .08 : .15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shape.width * .045),
      );
    }
    for (final i in frame.paintOrder) {
      var pose = frame.poses[i];
      if (i != active?.from) {
        pose = BottlePose(
          pose.mouth + Offset(i == shaking ? shake : 0, 0),
          pose.angle,
          scale: 1,
        );
      }
      final settle =
          frame.pour?.stage == 'settle' &&
          (active?.from == i || active?.to == i);
      // The transported bottle is last: water stays visible in the receiver,
      // while the source glass and front knit lip correctly occlude its root.
      if (i == active?.from) _paintStream(canvas, frame);
      paintBottle(
        canvas,
        i,
        pose,
        frame.bands[i],
        shape,
        settings,
        fixedTarget: i < frame.state.puzzle.targets.length
            ? frame.state.puzzle.targets[i]
            : null,
        added: addedBottle == i,
        glowExclusions: addedBottle == i
            ? [
                for (var label = 0; label < frame.poses.length; label++)
                  frame.layout.labelRect(label).inflate(5),
              ]
            : const [],
        highlighted:
            selected == i ||
            hintSource == i ||
            suggested == i ||
            shaking == i ||
            reduced && (active?.from == i || active?.to == i),
        wave: settle
            ? math.sin(
                    (frame.elapsedMs -
                            (500 + geometryFor(frame.layout, active!).flowMs)) /
                        100 *
                        math.pi,
                  ) *
                  shape.width *
                  .008
            : 0,
      );
    }
    if (active == null && hintSource != null && suggested != null) {
      final path = frame.layout.hintPath(hintSource, suggested);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 6,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff249dea)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.5,
      );
      final metric = path.computeMetrics().first;
      final tangent = metric.getTangentForOffset(metric.length)!;
      final tip = tangent.position;
      final direction = tangent.vector.direction;
      final arrow = Path()..moveTo(tip.dx, tip.dy);
      for (final turn in [-.65, .65]) {
        final point = tip - Offset.fromDirection(direction + turn, 9);
        arrow
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        arrow,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 6,
      );
      canvas.drawPath(
        arrow,
        Paint()
          ..color = const Color(0xff249dea)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3,
      );
    }
  }

  void _paintStream(Canvas canvas, BoardVisualFrame frame) {
    final shape = frame.layout.shape, active = frame.active;
    final flow = frame.pour;
    if (flow != null && flow.inStream > .000001) {
      final receiver = frame.poses[active!.to];
      final hull = shape.worldHull(receiver);
      final filled = frame.bands[active.to].fold(0.0, (n, b) => n + b.units);
      final surface = Offset(
        flow.streamEnd.dx,
        waterline(hull, filled * shape.unitArea),
      );
      // One column continues through the neck to the rising liquid surface.
      // Below the opening it is restricted to the receiver's clear interior.
      canvas.save();
      canvas.clipPath(
        Path()
          ..addRect(Rect.fromLTRB(0, 0, frame.layout.width, receiver.mouth.dy))
          ..addPolygon(hull, true),
      );
      final top = Offset.lerp(flow.streamStart, surface, flow.streamTail)!;
      final bottom = Offset.lerp(flow.streamStart, surface, flow.streamHead)!;
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + .7,
          (top.dy + bottom.dy) / 2,
          bottom.dx,
          bottom.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = liquidColors[active.before[active.from].last]!
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth =
              math.max(2.8, shape.width * .035) + active.units * .25,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
      for (var n = 0; n < 3; n++) {
        final point = Offset.lerp(
          top,
          bottom,
          ((flow.out * 1.7 + n * .31) % 1),
        )!;
        canvas.drawCircle(
          point,
          .55,
          Paint()..color = Colors.white.withValues(alpha: .5),
        );
      }
      canvas.restore();
    }
  }

  void paintBottle(
    Canvas canvas,
    int index,
    BottlePose pose,
    List<LiquidBand> bands,
    BottleShape shape,
    PlayerSettings settings, {
    required bool highlighted,
    String? fixedTarget,
    bool added = false,
    List<Rect> glowExclusions = const [],
    bool contentsSymbols = true,
    double wave = 0,
  }) {
    // Each sampled part is an independent bottle material. Empty glass is
    // behind the computed liquid; the window is excluded from the front layer.
    const empty = Rect.fromLTWH(937, 574, 166, 300);
    const sources = {
      'O': Rect.fromLTWH(736, 211, 166, 309),
      'G': Rect.fromLTWH(937, 211, 166, 309),
      'P': Rect.fromLTWH(1139, 211, 166, 309),
      'B': Rect.fromLTWH(736, 574, 166, 300),
      'R': Rect.fromLTWH(736, 211, 166, 309),
    };
    Offset point(double x, double y) =>
        Offset((x - .5) * shape.width, (y - .10) * shape.height);
    final baseCuff = Path()
      ..moveTo(point(.015, .795).dx, point(.015, .795).dy)
      ..cubicTo(
        point(.08, .938).dx,
        point(.08, .938).dy,
        point(.92, .938).dx,
        point(.92, .938).dy,
        point(.985, .795).dx,
        point(.985, .795).dy,
      )
      ..lineTo(point(.985, .91).dx, point(.985, .91).dy)
      ..cubicTo(
        point(.98, 1.04).dx,
        point(.98, 1.04).dy,
        point(.02, 1.04).dx,
        point(.02, 1.04).dy,
        point(.015, .91).dx,
        point(.015, .91).dy,
      )
      ..close();
    if (fixedTarget == null) {
      // The empty source has knit joins above the filled source's U edge.
      // Include just those exterior corners; glass and shoulders stay intact.
      baseCuff.addPolygon([
        point(0, .76),
        point(.22, .90),
        point(0, .94),
      ], true);
      baseCuff.addPolygon([
        point(1, .76),
        point(1, .94),
        point(.78, .90),
      ], true);
    }
    void layer(
      Rect source, {
      bool front = false,
      Rect? cuff,
      Path? mask,
      bool neutral = false,
      bool rose = false,
    }) {
      canvas.save();
      canvas.translate(pose.mouth.dx, pose.mouth.dy);
      canvas.rotate(pose.angle);
      canvas.scale(pose.scale);
      canvas.clipPath(shape.outline);
      if (front) {
        canvas.clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(shape.imageRect.inflate(2)),
            Path()..addPolygon(shape.interior, true),
          ),
        );
      }
      if (cuff != null) canvas.clipRect(cuff);
      if (mask != null) canvas.clipPath(mask);
      canvas.drawImageRect(
        art.reference,
        source,
        shape.imageRect,
        Paint()
          ..filterQuality = FilterQuality.high
          ..colorFilter = neutral
              ? neutralKnitColorFilter
              : rose
              ? roseKnitColorFilter
              : null,
      );
      canvas.restore();
    }

    if (added) {
      final glowBounds = Rect.fromCenter(
        center: pose.mouth,
        width: shape.height * 8,
        height: shape.height * 8,
      );
      canvas.saveLayer(glowBounds, Paint());
      canvas.save();
      canvas.translate(pose.mouth.dx, pose.mouth.dy);
      canvas.rotate(pose.angle);
      canvas.scale(pose.scale);
      for (final (width, blur, color) in [
        (12.0, 7.0, const Color(0xd9ffdf26)),
        (3.0, 1.2, const Color(0xfffff370)),
      ]) {
        canvas.drawPath(
          shape.outline,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
      }
      final rays = Paint()
        ..color = const Color(0xfffff67d)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .6);
      for (final direction in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(direction * shape.width * .45, -shape.height * .17),
          Offset(direction * shape.width * .52, -shape.height * .23),
          rays,
        );
        canvas.drawLine(
          Offset(direction * shape.width * .59, -shape.height * .06),
          Offset(direction * shape.width * .68, -shape.height * .09),
          rays,
        );
      }
      canvas.restore();
      // Erase light on text within this separate decorative layer. A broad
      // feather reaches zero before the hard exclusion, avoiding a cut-out.
      for (final label in glowExclusions) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(label.inflate(5), const Radius.circular(5)),
          Paint()
            ..color = Colors.black
            ..blendMode = BlendMode.dstOut
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawRect(
          label,
          Paint()
            ..color = Colors.black
            ..blendMode = BlendMode.dstOut,
        );
      }
      canvas.restore();
    }
    if (highlighted) {
      canvas.save();
      canvas.translate(pose.mouth.dx, pose.mouth.dy);
      canvas.rotate(pose.angle);
      canvas.scale(pose.scale);
      canvas.drawPath(
        shape.outline,
        Paint()
          ..color = const Color(0xcc21c8ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawPath(
        shape.outline,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
      canvas.restore();
    }
    layer(empty);
    final hull = shape.worldHull(pose), path = Path()..addPolygon(hull, true);
    canvas.save();
    canvas.clipPath(path);
    var cumulative = 0.0;
    var bottom = hull.map((p) => p.dy).reduce(math.max);
    final left = hull.map((p) => p.dx).reduce(math.min),
        right = hull.map((p) => p.dx).reduce(math.max);
    final merged = <LiquidBand>[];
    for (final band in bands) {
      if (band.units <= .000001) continue;
      if (merged.isNotEmpty && merged.last.color == band.color) {
        final last = merged.removeLast();
        merged.add((color: band.color, units: last.units + band.units));
      } else {
        merged.add(band);
      }
    }
    for (final band in merged) {
      cumulative += band.units;
      final top = waterline(
        hull,
        cumulative * shape.unitArea * pose.scale * pose.scale,
      );
      final color = liquidColors[band.color]!;
      canvas.drawRect(
        Rect.fromLTRB(left - 1, top, right + 1, bottom + .2),
        Paint()
          ..shader = ui.Gradient.linear(
            pose.transform(Offset(-shape.width * .32, shape.height * .4)),
            pose.transform(Offset(shape.width * .32, shape.height * .4)),
            [
              Color.lerp(color, const Color(0xff58616a), .16)!,
              Color.lerp(color, Colors.white, .12)!,
              Color.lerp(color, Colors.white, .18)!,
              Color.lerp(color, Colors.white, .04)!,
              color,
              Color.lerp(color, const Color(0xff58616a), .12)!,
              Color.lerp(color, Colors.white, .18)!,
            ],
            [0, .07, .23, .45, .72, .93, 1],
          ),
      );
      if (contentsSymbols && settings.colorSymbols && band.units > .5) {
        _symbol(
          canvas,
          Offset((left + right) / 2, (top + bottom) / 2),
          band.color,
          math.max(3.0, shape.width * .075) * pose.scale,
          settings.strongContrast,
          pose.scale,
        );
      }
      bottom = top;
    }
    if (merged.isNotEmpty) {
      final surface = Rect.fromCenter(
        center: Offset((left + right) / 2, bottom),
        width: right - left,
        height: math.max(3, shape.width * .11) * pose.scale,
      );
      canvas.drawOval(
        surface,
        Paint()
          ..shader = ui.Gradient.linear(
            surface.topCenter,
            surface.bottomCenter,
            [
              Color.lerp(liquidColors[merged.last.color], Colors.white, .32)!,
              Color.lerp(liquidColors[merged.last.color], Colors.white, .08)!,
            ],
          ),
      );
      canvas.drawArc(
        surface,
        0,
        math.pi,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * pose.scale,
      );
      canvas.drawArc(
        surface.shift(Offset(0, wave)),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 * pose.scale,
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              left + (right - left) * (.68 + i * .075),
              bottom + surface.height * .12,
            ),
            width: (2.8 - i * .5) * pose.scale,
            height: (1.7 - i * .25) * pose.scale,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .55 * pose.scale,
        );
      }
    }
    // Curved continuous glass sheen, independent of all color boundaries.
    final reflection = Path()
      ..moveTo(
        pose.transform(Offset(-shape.width * .25, shape.height * .17)).dx,
        pose.transform(Offset(-shape.width * .25, shape.height * .17)).dy,
      )
      ..cubicTo(
        pose.transform(Offset(-shape.width * .30, shape.height * .24)).dx,
        pose.transform(Offset(-shape.width * .30, shape.height * .24)).dy,
        pose.transform(Offset(-shape.width * .29, shape.height * .65)).dx,
        pose.transform(Offset(-shape.width * .29, shape.height * .65)).dy,
        pose.transform(Offset(-shape.width * .24, shape.height * .74)).dx,
        pose.transform(Offset(-shape.width * .24, shape.height * .74)).dy,
      );
    canvas.drawPath(
      reflection,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = shape.width * .045 * pose.scale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, .7 * pose.scale),
    );
    final thin = Path()
      ..moveTo(
        pose.transform(Offset(shape.width * .275, shape.height * .19)).dx,
        pose.transform(Offset(shape.width * .275, shape.height * .19)).dy,
      )
      ..cubicTo(
        pose.transform(Offset(shape.width * .30, shape.height * .30)).dx,
        pose.transform(Offset(shape.width * .30, shape.height * .30)).dy,
        pose.transform(Offset(shape.width * .30, shape.height * .65)).dx,
        pose.transform(Offset(shape.width * .30, shape.height * .65)).dy,
        pose.transform(Offset(shape.width * .25, shape.height * .73)).dx,
        pose.transform(Offset(shape.width * .25, shape.height * .73)).dy,
      );
    canvas.drawPath(
      thin,
      Paint()
        ..color = Colors.white.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * pose.scale,
    );
    canvas.restore();
    layer(empty, front: true);
    final image = shape.imageRect;
    final material = fixedTarget == null ? empty : sources[fixedTarget]!;
    layer(
      material,
      neutral: fixedTarget == null,
      rose: fixedTarget == 'R',
      cuff: Rect.fromLTRB(
        image.left,
        image.top,
        image.right,
        // The neutral rim includes the source orange seam just below the knit.
        image.top + image.height * (fixedTarget == null ? .17 : .15),
      ),
    );
    // Only the U-shaped knitted band: never the source bottle's lower glass
    // or baked liquid. All clear glass comes from the actually empty bottle.
    layer(
      material,
      mask: baseCuff,
      neutral: fixedTarget == null,
      rose: fixedTarget == 'R',
    );
    if (settings.strongContrast) {
      canvas.drawPath(
        path,
        Paint()
          ..color = ink.withValues(alpha: settings.strongContrast ? .9 : .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = settings.strongContrast ? 1.8 : 1.1,
      );
    }
  }

  void _symbol(
    Canvas canvas,
    Offset p,
    String color,
    double r,
    bool contrast,
    double scale,
  ) {
    final path = Path();
    switch (color) {
      case 'R':
        path.addPath(fivePointStar(p, r), Offset.zero);
      case 'O':
        path.addOval(Rect.fromCircle(center: p, radius: r));
      case 'G':
        path
          ..moveTo(p.dx, p.dy - r)
          ..lineTo(p.dx + r, p.dy + r)
          ..lineTo(p.dx - r, p.dy + r)
          ..close();
      case 'P':
        path
          ..moveTo(p.dx, p.dy - r)
          ..lineTo(p.dx + r, p.dy)
          ..lineTo(p.dx, p.dy + r)
          ..lineTo(p.dx - r, p.dy)
          ..close();
      case 'B':
        path.addRect(Rect.fromCenter(center: p, width: r * 2, height: r * 2));
    }
    const colors = {
      'O': Color(0xff1655c2),
      'G': Color(0xff286b35),
      'P': Color(0xff33388b),
      'R': Color(0xffa52e54),
      'B': Color(0xff1655c2),
    };
    canvas.drawPath(path, Paint()..color = contrast ? ink : colors[color]!);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (contrast ? 2 : 1.4) * scale,
    );
  }
}
