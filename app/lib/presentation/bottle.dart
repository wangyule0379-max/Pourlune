import 'dart:math' as math;

import 'package:flutter/material.dart';

const ink = Color(0xff061b78);
const cream = Color(0xfffff9e6);
const liquidColors = {
  'O': Color(0xffff8218),
  'G': Color(0xff8fd342),
  'P': Color(0xffad72e5),
  'B': Color(0xff38b5e8),
  'R': Color(0xffe56c9a),
};
const colorNames = {
  'O': 'Orange circle',
  'G': 'Green triangle',
  'P': 'Purple diamond',
  'B': 'Blue square',
  'R': 'Rose star',
};
const symbols = {'O': '●', 'G': '▲', 'P': '◆', 'B': '■', 'R': '★'};

/// Shared pictogram for liquid layers and the fixed target cushion.
Path fivePointStar(Offset center, double radius) {
  final points = [
    for (var i = 0; i < 10; i++)
      center +
          Offset(
                math.cos(-math.pi / 2 + i * math.pi / 5),
                math.sin(-math.pi / 2 + i * math.pi / 5),
              ) *
              (i.isEven ? radius : radius * .381966),
  ];
  return Path()..addPolygon(points, true);
}

typedef LiquidBand = ({String color, double units});

class BottleButton extends StatelessWidget {
  const BottleButton({
    super.key,
    required this.index,
    required this.liquid,
    required this.target,
    required this.selected,
    required this.width,
    required this.onTap,
    this.semanticLabel,
    this.showSymbols = true,
    this.strongContrast = false,
    this.suggested = false,
    this.visualLiquid,
    this.angle = 0,
    this.lift = 0,
  });
  final int index;
  final List<String> liquid;
  final String? target;
  final bool selected;
  final double width;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool showSymbols, strongContrast, suggested;
  final List<LiquidBand>? visualLiquid;
  final double angle, lift;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        semanticLabel ??
        'Bottle ${index + 1}. ${target == null ? 'Buffer' : 'Target ${colorNames[target]}'}. ${liquid.isEmpty ? 'Empty' : 'Bottom to top: ${liquid.map((c) => colorNames[c]).join(', ')}'}. ${liquid.length} of 4.',
    button: true,
    enabled: onTap != null,
    onTap: onTap,
    selected: selected,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          height: 184,
          child: Column(
            children: [
              SizedBox(
                height: 148,
                width: width,
                child: Transform.translate(
                  offset: Offset(0, -lift),
                  child: Transform.rotate(
                    angle: angle,
                    alignment: const Alignment(0, .135135),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -width * .15,
                          top: 0,
                          width: width * 1.3,
                          height: 148,
                          child: Opacity(
                            opacity: .4,
                            child: Image.asset(
                              'assets/art/bottles/shadow.png',
                              key: Key('bottle-$index-shadow'),
                              fit: BoxFit.fill,
                              cacheWidth:
                                  (width *
                                          1.3 *
                                          MediaQuery.devicePixelRatioOf(
                                            context,
                                          ))
                                      .ceil(),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -width * .15,
                          top: 0,
                          width: width * 1.3,
                          height: 148,
                          child: Image.asset(
                            'assets/art/bottles/back.png',
                            key: Key('bottle-$index-back'),
                            fit: BoxFit.fill,
                            cacheWidth:
                                (width *
                                        1.3 *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BottlePainter(
                              liquid,
                              target,
                              selected || suggested,
                              showSymbols: showSymbols,
                              strongContrast: strongContrast,
                              visualLiquid: visualLiquid,
                              angle: angle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -width * .15,
                          top: 148 * .0130208,
                          width: width * 1.3,
                          height: 148,
                          child: Image.asset(
                            'assets/art/bottles/front.png',
                            key: Key('bottle-$index-front'),
                            fit: BoxFit.fill,
                            cacheWidth:
                                (width *
                                        1.3 *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index + 1} · ',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: target == null ? cream : liquidColors[target],
                          border: Border.all(color: ink, width: .7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          target == null
                              ? '—'
                              : showSymbols
                              ? symbols[target]!
                              : target!,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BottlePainter extends CustomPainter {
  BottlePainter(
    this.liquid,
    this.target,
    this.selected, {
    this.showSymbols = true,
    this.strongContrast = false,
    this.visualLiquid,
    this.angle = 0,
  });
  final bool showSymbols, strongContrast;
  final List<String> liquid;
  final String? target;
  final bool selected;
  final List<LiquidBand>? visualLiquid;
  final double angle;
  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * .24,
        right = size.width * .76,
        top = size.height * .32,
        bottom = size.height * .86;
    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(size.width * .08),
    );
    final outline = Paint()
      ..color = ink.withValues(alpha: selected ? .85 : .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strongContrast
          ? 2
          : selected
          ? 2
          : .7;
    canvas.save();
    canvas.clipRRect(bottle);
    canvas.translate(size.width / 2, 84);
    canvas.rotate(-angle);
    canvas.translate(-size.width / 2, -84);

    final bands = <LiquidBand>[];
    for (final band
        in visualLiquid ??
            [for (final color in liquid) (color: color, units: 1.0)]) {
      if (bands.isNotEmpty && bands.last.color == band.color) {
        final previous = bands.removeLast();
        bands.add((color: band.color, units: previous.units + band.units));
      } else {
        bands.add(band);
      }
    }
    var filled = 0.0;
    final cumulative = <double>[0];
    for (final band in bands) {
      cumulative.add(cumulative.last + band.units);
    }
    final surfaces = _liquidSurfaces(
      bottle,
      Offset(size.width / 2, 84),
      angle,
      cumulative,
    );
    var bandIndex = 0;
    for (final band in bands) {
      final y = surfaces[bandIndex], nextY = surfaces[bandIndex + 1];
      canvas.drawRect(
        Rect.fromLTRB(-size.width, nextY, size.width * 2, y),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(liquidColors[band.color]!, Colors.white, .18)!,
              liquidColors[band.color]!,
              Color.lerp(liquidColors[band.color]!, ink, .06)!,
            ],
          ).createShader(Rect.fromLTRB(left, top, right, bottom)),
      );
      if (showSymbols && band.units > .5) {
        _shape(canvas, Offset(size.width / 2, (y + nextY) / 2), band.color, 4);
      }
      filled += band.units;
      bandIndex++;
    }
    if (filled > 0) {
      final surface = surfaces.last;
      canvas.drawOval(
        Rect.fromLTRB(
          -size.width,
          surface - 1.4,
          size.width * 2,
          surface + 1.4,
        ),
        Paint()..color = Colors.white.withValues(alpha: .4),
      );
    }
    canvas.restore();
    canvas.drawRRect(bottle, outline);
    for (var i = 1; i <= 4; i++) {
      final y = bottom - i * (bottom - top) / 4;
      canvas.drawLine(
        Offset(right - 6, y),
        Offset(right, y),
        Paint()
          ..color = ink.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
    }

    if (selected) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height - 2),
        3,
        Paint()..color = ink,
      );
    }
  }

  void _shape(Canvas canvas, Offset c, String color, double r) {
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strongContrast ? 2.2 : 1.5;
    switch (color) {
      case 'O':
        canvas.drawCircle(c, r, p);
      case 'G':
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy + r)
            ..lineTo(c.dx - r, c.dy + r)
            ..close(),
          p,
        );
      case 'P':
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy)
            ..lineTo(c.dx, c.dy + r)
            ..lineTo(c.dx - r, c.dy)
            ..close(),
          p,
        );
      case 'R':
        canvas.drawPath(fivePointStar(c, r), p);
      case 'B':
        canvas.drawRect(
          Rect.fromCenter(center: c, width: r * 2, height: r * 2),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(covariant BottlePainter old) =>
      old.liquid != liquid ||
      old.target != target ||
      old.selected != selected ||
      old.visualLiquid != visualLiquid ||
      old.angle != angle ||
      old.showSymbols != showSymbols ||
      old.strongContrast != strongContrast;
}

/// Horizontal area quantiles of the rotated rounded window. Geometry only;
/// model units remain authoritative. No fluid simulation or persistence here.
List<double> _liquidSurfaces(
  RRect window,
  Offset pivot,
  double angle,
  List<double> volumes,
) {
  final r = window.tlRadiusX;
  final centers = [
    Offset(window.left + r, window.top + r),
    Offset(window.right - r, window.top + r),
    Offset(window.right - r, window.bottom - r),
    Offset(window.left + r, window.bottom - r),
  ];
  // Twelve chords per quarter circle keep area error well below one pixel at
  // runtime size. Upright and tilted poses share the same area model.
  final polygon = <Offset>[];
  final cos = math.cos(angle), sin = math.sin(angle);
  for (var corner = 0; corner < 4; corner++) {
    for (var step = 0; step <= 12; step++) {
      final a = math.pi + corner * math.pi / 2 + step * math.pi / 24;
      final point =
          centers[corner] + Offset(r * math.cos(a), r * math.sin(a)) - pivot;
      polygon.add(
        pivot +
            Offset(
              point.dx * cos - point.dy * sin,
              point.dx * sin + point.dy * cos,
            ),
      );
    }
  }
  double area(List<Offset> points) {
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  double below(double y) {
    final clipped = <Offset>[];
    var previous = polygon.last;
    for (final point in polygon) {
      final inside = point.dy >= y, previousInside = previous.dy >= y;
      if (inside != previousInside) {
        final t = (y - previous.dy) / (point.dy - previous.dy);
        clipped.add(Offset(previous.dx + (point.dx - previous.dx) * t, y));
      }
      if (inside) clipped.add(point);
      previous = point;
    }
    return area(clipped);
  }

  final minY = polygon.map((p) => p.dy).reduce(math.min),
      maxY = polygon.map((p) => p.dy).reduce(math.max);
  final total = area(polygon);
  return [
    for (final units in volumes)
      (() {
        if (units <= 0) return maxY + 1;
        if (units >= 4) return minY - 1;
        var low = minY, high = maxY;
        for (var i = 0; i < 24; i++) {
          final middle = (low + high) / 2;
          if (below(middle) > total * units / 4) {
            low = middle;
          } else {
            high = middle;
          }
        }
        return (low + high) / 2;
      })(),
  ];
}
