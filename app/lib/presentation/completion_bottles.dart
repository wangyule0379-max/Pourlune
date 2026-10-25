import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../data/player_settings.dart';
import '../l10n/app_localizations.dart';
import 'bottle_foot_label.dart';
import 'labels.dart';
import 'flame_board/geometry.dart';
import 'flame_board/paint.dart';
import 'reference_play_art.dart';

const completionReference = 'assets/art/p05-reference/reference-completion.png';

/// Follows the original medallion silhouette, excluding the adjacent orange
/// bottle which shares the rectangular source crop at its lower left edge.
class CompletionMedallionClipper extends CustomClipper<Path> {
  const CompletionMedallionClipper();
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(78, 1)
      ..cubicTo(121, -2, 153, 23, 156, 62)
      ..cubicTo(162, 101, 130, 139, 85, 143)
      ..cubicTo(49, 146, 25, 123, 12, 97)
      ..cubicTo(-6, 65, 5, 30, 34, 13)
      ..cubicTo(48, 4, 61, 1, 78, 1)
      ..close();
    return path.transform(
      Matrix4.diagonal3Values(size.width / 157, size.height / 147, 1).storage,
    );
  }

  @override
  bool shouldReclip(CompletionMedallionClipper oldClipper) => false;
}

class CompletionReferenceArt extends StatelessWidget {
  const CompletionReferenceArt({super.key, required this.source});
  final Rect source;
  @override
  Widget build(BuildContext context) => ReferencePlayArt(
    asset: completionReference,
    imageSize: const Size(1476, 1066),
    source: source,
    radius: 0,
  );
}

/// A read-only presentation of the saved targets. No replacement game instance,
/// fake fourth color, buffer target, gesture or settlement is created here.
class CompletionBottles extends StatefulWidget {
  const CompletionBottles({
    super.key,
    required this.state,
    required this.settings,
    this.badge,
    this.singleRow = false,
  });
  final GameInstance state;
  final PlayerSettings settings;
  final Widget? badge;
  final bool singleRow;
  List<int> get targetIndices => [
    for (var i = 0; i < state.puzzle.targets.length; i++)
      if (state.puzzle.targets[i] != null) i,
  ];
  @override
  State<CompletionBottles> createState() => _CompletionBottlesState();
}

class _CompletionBottlesState extends State<CompletionBottles> {
  BottleArt? art;
  @override
  void initState() {
    super.initState();
    BottleArt.load().then((value) {
      if (!mounted) {
        value.dispose();
        return;
      }
      setState(() => art = value);
    });
  }

  @override
  void dispose() {
    art?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final indices = widget.targetIndices;
      final fiveTargets = indices.length == 5;
      final maxHeight = box.hasBoundedHeight ? box.maxHeight : 370.0;
      // Normal small screens keep3+2. Exceptionally short celebration space
      // uses one bounded row rather than shrinking five targets to points.
      final compactFive = fiveTargets && widget.singleRow;
      final singleRow = widget.singleRow && (!fiveTargets || maxHeight < 153);
      final rows = singleRow || indices.length <= 2 ? 1 : 2;
      final perRow = singleRow
          ? indices.length
          : fiveTargets
          ? 3
          : 2;
      const ratio =
          190 / 134; // Measured P10 completed bottle, separate from PLAY.
      double badgeWidth(double width) => (width * 1.12).clamp(68.0, 160.0);
      double topFor(double width) => widget.badge == null
          ? 4.0
          : math.max(4.0, badgeWidth(width) * 147 / 157 - 24);
      // Reserve the complete cushion and a clear gap before the card, rather
      // than counting only the bottle body as available celebration height.
      final rowGap = compactFive && !singleRow ? 4.0 : 8.0;
      double footFor(double width) => compactFive && !singleRow
          ? (width * .34).clamp(24.0, 34.0) + 3
          : singleRow
          ? (width * .34).clamp(24.0, 34.0) + 7
          : 45.0;
      double needed(double width) =>
          topFor(width) +
          rows * (width * ratio + footFor(width)) +
          (rows - 1) * rowGap;
      var low = 0.0;
      var high = math.min(
        rows == 1 ? 150.0 : 120.0,
        singleRow
            ? box.maxWidth / (indices.length + .5)
            : box.maxWidth * (fiveTargets ? .28 : .36),
      );
      for (var i = 0; i < 24; i++) {
        final middle = (low + high) / 2;
        if (needed(middle) <= maxHeight) {
          low = middle;
        } else {
          high = middle;
        }
      }
      final bottleWidth = math.max(1.0, low);
      final top = topFor(bottleWidth);
      final shape = BottleShape(bottleWidth, aspectRatio: ratio);
      final labelSize = (bottleWidth * .34).clamp(24.0, 34.0);
      final stride = shape.height + footFor(bottleWidth) + rowGap;
      final natural = needed(bottleWidth);
      final inset = math.max(0.0, (maxHeight - natural) / 2);
      final poses = <BottlePose>[];
      for (var row = 0; row < rows; row++) {
        final n = math.min(perRow, indices.length - row * perRow);
        for (var col = 0; col < n; col++) {
          final x =
              box.maxWidth / 2 +
              (col - (n - 1) / 2) *
                  box.maxWidth *
                  (singleRow
                      ? 1 / indices.length
                      : fiveTargets
                      ? .30
                      : .46);
          poses.add(
            BottlePose(
              Offset(x, inset + top + row * stride - shape.visibleRect.top),
              0,
            ),
          );
        }
      }
      final l = AppLocalizations.of(context);
      return SizedBox(
        height: maxHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: art == null
                    ? const SizedBox.shrink()
                    : CustomPaint(
                        painter: _SolvedBottlesPainter(
                          art!,
                          widget.state,
                          widget.settings,
                          indices,
                          poses,
                          shape,
                        ),
                      ),
              ),
            ),
            if (widget.badge != null)
              Positioned(
                top: inset,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: badgeWidth(bottleWidth),
                    height: badgeWidth(bottleWidth) * 147 / 157,
                    child: widget.badge,
                  ),
                ),
              ),
            for (var n = 0; n < indices.length; n++)
              Positioned.fromRect(
                rect: shape.visibleRect.shift(poses[n].mouth),
                child: Semantics(
                  key: Key('completion-bottle-${indices[n]}'),
                  label: l.bottleSemantics(
                    indices[n] + 1,
                    l.targetLabel(
                      colorLabel(l, widget.state.puzzle.targets[indices[n]]!),
                    ),
                    l.contentsLabel(
                      widget.state.board[indices[n]]
                          .map((c) => colorLabel(l, c))
                          .join(', '),
                    ),
                    widget.state.board[indices[n]].length,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            for (var n = 0; n < indices.length; n++)
              Positioned(
                left: poses[n].mouth.dx - labelSize / 2,
                top: poses[n].mouth.dy + shape.visibleRect.bottom + 3,
                width: labelSize,
                height: labelSize,
                child: ExcludeSemantics(
                  child: TargetCushion(
                    key: Key('completion-target-${indices[n]}'),
                    size: labelSize,
                    target: widget.state.puzzle.targets[indices[n]]!,
                    symbolsEnabled: widget.settings.colorSymbols,
                    strongContrast: widget.settings.strongContrast,
                  ),
                ),
              ),
            if (maxHeight > 220 &&
                MediaQuery.textScalerOf(context).scale(14) < 19) ...[
              for (final (x, y, source, purple) in [
                (0.02, .20, const Rect.fromLTWH(77, 205, 37, 32), false),
                (.91, .27, const Rect.fromLTWH(117, 234, 31, 29), true),
                (.01, .60, const Rect.fromLTWH(40, 269, 40, 39), true),
                (.92, .76, const Rect.fromLTWH(414, 266, 38, 34), false),
              ])
                Positioned(
                  left: box.maxWidth * x,
                  top: maxHeight * y,
                  width: 22,
                  height: 22,
                  child: ExcludeSemantics(
                    child: ClipRect(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix([
                          1,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                          0,
                          purple ? 0 : 4,
                          purple ? -8 : 0,
                          purple ? 8 : -4,
                          0,
                          purple ? -200 : 100,
                        ]),
                        child: CompletionReferenceArt(source: source),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}

class _SolvedBottlesPainter extends CustomPainter {
  const _SolvedBottlesPainter(
    this.art,
    this.state,
    this.settings,
    this.indices,
    this.poses,
    this.shape,
  );
  final BottleArt art;
  final GameInstance state;
  final PlayerSettings settings;
  final List<int> indices;
  final List<BottlePose> poses;
  final BottleShape shape;
  @override
  void paint(Canvas canvas, Size size) {
    final painter = FlameBoardPainter(art);
    for (var n = 0; n < indices.length; n++) {
      final i = indices[n], pose = poses[n];
      canvas.drawOval(
        Rect.fromCenter(
          center: pose.mouth + Offset(0, shape.visibleRect.bottom + 1),
          width: shape.width * .93,
          height: 7,
        ),
        Paint()
          ..color = const Color(0x33061b78)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      painter.paintBottle(
        canvas,
        i,
        pose,
        [for (final color in state.board[i]) (color: color, units: 1.0)],
        shape,
        settings,
        fixedTarget: state.puzzle.targets[i],
        highlighted: false,
        contentsSymbols: false,
      );
    }
  }

  @override
  bool shouldRepaint(_SolvedBottlesPainter old) =>
      old.art != art ||
      old.state != state ||
      old.settings != settings ||
      old.shape.width != shape.width ||
      old.poses.first.mouth != poses.first.mouth;
}
