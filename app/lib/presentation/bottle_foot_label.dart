import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'bottle.dart' show ink;

class BottleFootLabel extends StatelessWidget {
  const BottleFootLabel({
    super.key,
    required this.index,
    required this.target,
    required this.count,
    required this.prefix,
    required this.symbolsEnabled,
    required this.strongContrast,
  });
  final int index, count;
  final String? target;
  final String prefix;
  final bool symbolsEnabled, strongContrast;

  @override
  Widget build(BuildContext context) {
    final badgeSize = math.max(
      34.0,
      MediaQuery.textScalerOf(context).scale(12) + 12,
    );
    const numberStyle = TextStyle(
      fontFamily: 'Nunito',
      color: ink,
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );
    const countStyle = TextStyle(
      fontFamily: 'Nunito',
      color: ink,
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );
    final number = Text('${index + 1}', style: numberStyle);
    final capacity = Text(
      '$count/4',
      key: Key('$prefix-count-$index'),
      style: countStyle,
    );
    final badge = target == null
        ? null
        : TargetCushion(
            key: Key('$prefix-target-$index'),
            size: badgeSize,
            target: target!,
            symbolsEnabled: symbolsEnabled,
            strongContrast: strongContrast,
          );
    return LayoutBuilder(
      builder: (context, box) {
        double textWidth(String value, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(
              text: value,
              style: DefaultTextStyle.of(context).style.merge(style),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final numberWidth = textWidth('${index + 1}', numberStyle);
        final separateCount =
            numberWidth + 7 + textWidth('$count/4', countStyle) >
                box.maxWidth &&
            numberWidth + 4 + (badge == null ? 0 : badgeSize) <= box.maxWidth;
        if (separateCount) {
          // Reuse the two reserved label lines. Full-size number beside the
          // target, full capacity underneath; a buffer gains no false target.
          return Column(
            children: [
              SizedBox(
                height: badgeSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    number,
                    if (badge != null) ...[const SizedBox(width: 4), badge],
                  ],
                ),
              ),
              const SizedBox(height: 3),
              capacity,
            ],
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ?badge,
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [number, const SizedBox(width: 7), capacity],
            ),
          ],
        );
      },
    );
  }
}

/// The target shape is a pictogram, bounded inside the cushion at any font size.
/// Real labels/numbers continue to follow the system text scaler.
class TargetCushion extends StatelessWidget {
  const TargetCushion({
    super.key,
    required this.size,
    required this.target,
    required this.symbolsEnabled,
    required this.strongContrast,
  });
  final double size;
  final String target;
  final bool symbolsEnabled, strongContrast;
  @override
  Widget build(BuildContext context) {
    const colors = {
      'O': Color(0xffff7918),
      'G': Color(0xff328521),
      'P': Color(0xff862bb5),
      'B': Color(0xff086cbf),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffffffff), Color(0xfffff6e7), Color(0xffe3cfb7)],
        ),
        border: Border.all(color: const Color(0xfffffbf2), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4451465e),
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: symbolsEnabled
            ? SizedBox(
                width: size * .52,
                height: size * .52,
                child: CustomPaint(
                  painter: _TargetGlyph(
                    target,
                    strongContrast ? ink : colors[target]!,
                  ),
                ),
              )
            : Text(
                target,
                style: TextStyle(
                  color: strongContrast ? ink : colors[target],
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _TargetGlyph extends CustomPainter {
  const _TargetGlyph(this.target, this.color);
  final String target;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path();
    switch (target) {
      case 'O':
        path.addOval(rect);
      case 'B':
        path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)));
      case 'G':
        path.addPolygon([
          rect.topCenter,
          rect.bottomRight,
          rect.bottomLeft,
        ], true);
      default:
        path.addPolygon([
          rect.topCenter,
          rect.centerRight,
          rect.bottomCenter,
          rect.centerLeft,
        ], true);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TargetGlyph old) =>
      old.target != target || old.color != color;
}
