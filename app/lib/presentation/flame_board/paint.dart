import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/player_settings.dart';
import '../bottle.dart' show LiquidBand, ink, liquidColors;
import 'frame.dart';
import 'geometry.dart';

/// Two shared decoded layers, owned by one mounted board, not a global cache.
class BottleArt {
  BottleArt(this.back, this.front);
  final ui.Image back, front;
  bool disposed = false;
  static Future<ui.Image> _decode(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: 512,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static Future<BottleArt> load() async {
    final back = await _decode('assets/art/bottles/back.png');
    try {
      return BottleArt(back, await _decode('assets/art/bottles/front.png'));
    } catch (_) {
      back.dispose();
      rethrow;
    }
  }

  void dispose() {
    if (disposed) return;
    disposed = true;
    back.dispose();
    front.dispose();
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
    required List<double> press,
    double lift = 0,
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
          center: mouth + Offset(0, shape.height * .77),
          width: shape.width * .62,
          height: math.max(4.0, shape.width * .06),
        ),
        Paint()
          ..color = ink.withValues(alpha: active?.from == i ? .08 : .15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    for (final i in frame.paintOrder) {
      var pose = frame.poses[i];
      if (i != active?.from) {
        pose = BottlePose(
          pose.mouth +
              Offset(
                i == shaking ? shake : 0,
                !reduced && i == selected ? -lift : 0,
              ),
          pose.angle,
          scale: reduced ? 1 : 1 - .035 * press[i],
        );
      }
      final settle =
          frame.pour?.stage == 'settle' &&
          (active?.from == i || active?.to == i);
      paintBottle(
        canvas,
        i,
        pose,
        frame.bands[i],
        shape,
        settings,
        highlighted:
            selected == i ||
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
    final flow = frame.pour;
    if (flow != null && flow.inStream > .000001) {
      final top = Offset.lerp(
        flow.streamStart,
        flow.streamEnd,
        flow.streamTail,
      )!;
      final bottom = Offset.lerp(
        flow.streamStart,
        flow.streamEnd,
        flow.streamHead,
      )!;
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
          ..color = liquidColors[active!.before[active.from].last]!
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth =
              math.max(1.5, shape.width * .018) + active.units * .17,
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
    double wave = 0,
  }) {
    void layer(ui.Image image) {
      canvas.save();
      canvas.translate(pose.mouth.dx, pose.mouth.dy);
      canvas.rotate(pose.angle);
      canvas.scale(pose.scale);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        shape.imageRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }

    layer(art.back);
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
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bottom), [
            Color.lerp(color, Colors.white, .13)!,
            color,
          ]),
      );
      if (settings.colorSymbols && band.units > .5) {
        _symbol(
          canvas,
          Offset((left + right) / 2, (top + bottom) / 2),
          band.color,
          math.max(2.0, shape.width * .025),
          settings.strongContrast,
        );
      }
      bottom = top;
    }
    if (merged.isNotEmpty) {
      canvas.drawPath(
        Path()
          ..moveTo(left, bottom)
          ..cubicTo(
            left + (right - left) * .3,
            bottom - wave,
            left + (right - left) * .7,
            bottom + wave,
            right,
            bottom,
          ),
        Paint()
          ..color = Colors.white.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9,
      );
    }
    canvas.restore();
    layer(art.front);
    if (settings.strongContrast || highlighted) {
      canvas.drawPath(
        path,
        Paint()
          ..color = ink.withValues(alpha: settings.strongContrast ? .9 : .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = settings.strongContrast ? 1.8 : 1.1,
      );
    }
    for (var u = 1; u <= 4; u++) {
      final y = waterline(shape.interior, u * shape.unitArea);
      canvas.drawLine(
        pose.transform(Offset(shape.width * .165, y)),
        pose.transform(Offset(shape.width * .205, y)),
        Paint()
          ..color = ink.withValues(alpha: settings.strongContrast ? .9 : .5)
          ..strokeWidth = .8,
      );
    }
    if (highlighted) {
      canvas.drawCircle(
        pose.transform(Offset(0, shape.height * .76)),
        2.2,
        Paint()..color = ink,
      );
    }
  }

  void _symbol(Canvas canvas, Offset p, String color, double r, bool contrast) {
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = contrast ? 1.8 : 1.1;
    switch (color) {
      case 'O':
        canvas.drawCircle(p, r, paint);
      case 'G':
        canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - r)
            ..lineTo(p.dx + r, p.dy + r)
            ..lineTo(p.dx - r, p.dy + r)
            ..close(),
          paint,
        );
      case 'P':
        canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - r)
            ..lineTo(p.dx + r, p.dy)
            ..lineTo(p.dx, p.dy + r)
            ..lineTo(p.dx - r, p.dy)
            ..close(),
          paint,
        );
      case 'B':
        canvas.drawRect(
          Rect.fromCenter(center: p, width: r * 2, height: r * 2),
          paint,
        );
    }
  }
}
