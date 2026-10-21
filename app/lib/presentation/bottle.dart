import 'package:flutter/material.dart';

const ink = Color(0xff061b78);
const cream = Color(0xfffff9e6);
const liquidColors = {
  'O': Color(0xffebc69b),
  'G': Color(0xffb9d89f),
  'P': Color(0xffc6aadb),
  'B': Color(0xffa9d4e6),
};
const colorNames = {
  'O': 'Orange circle',
  'G': 'Green triangle',
  'P': 'Purple diamond',
  'B': 'Blue square',
};
const symbols = {'O': '●', 'G': '▲', 'P': '◆', 'B': '■'};

class BottleButton extends StatelessWidget {
  const BottleButton({
    super.key,
    required this.index,
    required this.liquid,
    required this.target,
    required this.selected,
    required this.width,
    required this.onTap,
  });
  final int index;
  final List<String> liquid;
  final String? target;
  final bool selected;
  final double width;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
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
                child: CustomPaint(
                  painter: BottlePainter(liquid, target, selected),
                ),
              ),
              SizedBox(
                height: 36,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${index + 1} · ${target == null ? '—' : symbols[target]}',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
  BottlePainter(this.liquid, this.target, this.selected);
  final List<String> liquid;
  final String? target;
  final bool selected;
  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * .18,
        right = size.width * .82,
        top = 20.0,
        bottom = size.height - 9;
    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(14),
    );
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 4 : 2;
    canvas.drawRRect(
      bottle,
      Paint()..color = Colors.white.withValues(alpha: .4),
    );
    canvas.save();
    canvas.clipRRect(bottle);
    final unit = (bottom - top - 18) / 4;
    for (var i = 0; i < liquid.length; i++) {
      final y = bottom - i * unit;
      canvas.drawRect(
        Rect.fromLTRB(left, y - unit, right, y),
        Paint()..color = liquidColors[liquid[i]]!,
      );
      _shape(canvas, Offset(size.width / 2, y - unit / 2), liquid[i], 4);
    }
    canvas.restore();
    canvas.drawRRect(bottle, outline);
    for (var i = 1; i <= 4; i++) {
      final y = bottom - i * (bottom - top - 18) / 4;
      canvas.drawLine(
        Offset(right - 6, y),
        Offset(right, y),
        Paint()
          ..color = ink.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
    }
    canvas.drawLine(Offset(left - 2, top), Offset(right + 2, top), outline);
    if (target != null) _shape(canvas, Offset(size.width / 2, 10), target!, 6);
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
      ..strokeWidth = 1.5;
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
      case 'B':
        canvas.drawRect(
          Rect.fromCenter(center: c, width: r * 2, height: r * 2),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(covariant BottlePainter old) =>
      old.liquid != liquid || old.target != target || old.selected != selected;
}
