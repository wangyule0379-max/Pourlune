import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../completion_bottles.dart' show CompletionReferenceArt;
import '../knit_components.dart' show knitPressFeedback;
import '../labels.dart';
import '../reference_extra_art.dart';
import '../reference_play_art.dart';

/// Page-specific composition of the existing blank reference material. No
/// reference title, progress number or button label is baked into the surface.
class CollectionSurface extends StatelessWidget {
  const CollectionSurface({
    super.key,
    required this.child,
    this.locked = false,
    this.padding = const EdgeInsets.all(14),
    this.cornerRadius = 24,
  });
  final Widget child;
  final bool locked;
  final EdgeInsetsGeometry padding;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final material = ReferenceExtraSurface(
      kind: ExtraSurfaceKind.collection,
      cornerRadius: cornerRadius,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: locked
              ? ClipRect(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0xa6c6a2ef),
                      BlendMode.srcATop,
                    ),
                    child: material,
                  ),
                )
              : material,
        ),
        Padding(padding: padding, child: child),
      ],
    );
  }
}

class CollectionBookIcon extends StatelessWidget {
  const CollectionBookIcon({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 30,
    height: 26,
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
            -3,
            0,
            3,
            0,
            -100,
          ]),
          child: ReferencePlayArt(
            asset: 'assets/art/p05-reference/reference-scene.png',
            imageSize: Size(1477, 1065),
            source: Rect.fromLTWH(126, 1000, 58, 47),
            radius: 0,
          ),
        ),
      ),
    ),
  );
}

class CollectionLock extends StatelessWidget {
  const CollectionLock({super.key, this.size = 44, this.purple = false});
  final double size;
  final bool purple;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: ClipPath(
        clipper: const _LockSilhouette(),
        child: ColorFiltered(
          colorFilter: purple
              ? const ColorFilter.mode(Colors.white, BlendMode.modulate)
              : const ColorFilter.matrix([
                  .2126,
                  .7152,
                  .0722,
                  0,
                  8,
                  .2126,
                  .7152,
                  .0722,
                  0,
                  4,
                  .2126,
                  .7152,
                  .0722,
                  0,
                  -6,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
          child: const CompletionReferenceArt(
            source: Rect.fromLTWH(1100, 475, 71, 73),
          ),
        ),
      ),
    ),
  );
}

class CollectionChevron extends StatelessWidget {
  const CollectionChevron({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 28,
    child: ExcludeSemantics(
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
          -3,
          0,
          3,
          0,
          -100,
        ]),
        child: CompletionReferenceArt(source: Rect.fromLTWH(1418, 207, 29, 44)),
      ),
    ),
  );
}

/// Only the existing decorative yarn pieces are sampled. The room and every
/// ownership/reveal decision remain the live SceneArt child.
class CollectionCelebrationHero extends StatelessWidget {
  const CollectionCelebrationHero({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Positioned.fill(child: child),
          for (final (x, y, source, purple) in [
            (.01, .18, const Rect.fromLTWH(77, 205, 37, 32), false),
            (.01, .42, const Rect.fromLTWH(117, 234, 31, 29), true),
            (.01, .66, const Rect.fromLTWH(336, 261, 37, 38), false),
            (.76, .05, const Rect.fromLTWH(336, 261, 37, 38), false),
            (.92, .20, const Rect.fromLTWH(117, 234, 31, 29), true),
            (.93, .42, const Rect.fromLTWH(77, 205, 37, 32), false),
            (.91, .65, const Rect.fromLTWH(32, 482, 35, 35), false),
          ])
            Positioned(
              left: box.maxWidth * x,
              top: box.maxHeight * y,
              width: box.maxWidth * .065,
              height: box.maxWidth * .065,
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
                      purple ? -200 / 255 : 100 / 255,
                      0,
                    ]),
                    child: CompletionReferenceArt(source: source),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _LockSilhouette extends CustomClipper<Path> {
  const _LockSilhouette();
  @override
  Path getClip(Size size) =>
      (Path()
            ..moveTo(2, 27)
            ..quadraticBezierTo(2, 14, 19, 10)
            ..quadraticBezierTo(24, 0, 37, 0)
            ..quadraticBezierTo(51, 0, 56, 11)
            ..quadraticBezierTo(70, 15, 70, 30)
            ..lineTo(69, 54)
            ..quadraticBezierTo(68, 70, 53, 72)
            ..lineTo(18, 72)
            ..quadraticBezierTo(1, 69, 1, 53)
            ..close())
          .transform(
            Matrix4.diagonal3Values(
              size.width / 71,
              size.height / 73,
              1,
            ).storage,
          );
  @override
  bool shouldReclip(_LockSilhouette oldClipper) => false;
}

class CollectionPatchSlots extends StatelessWidget {
  const CollectionPatchSlots({
    super.key,
    required this.scene,
    required this.pieces,
    this.showLocks = false,
    this.raised = true,
  });
  final String scene;
  final List<String> pieces;
  final bool showLocks, raised;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = ownedRegions(pieces, scene);
    return Row(
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              label:
                  '${regionLabel(l, scene, i)} · ${owned.contains(i) ? l.sceneOwned : l.sceneLocked}',
              child: ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _SlotStitches(
                      locked: showLocks && !owned.contains(i),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: owned.contains(i)
                          ? raised
                                ? ClipPath(
                                    clipper: const _RaisedPatchClipper(),
                                    child: const CompletionReferenceArt(
                                      source: Rect.fromLTWH(536, 609, 75, 70),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.asset(
                                      'assets/art/ui/patch-tile.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                          : showLocks
                          ? const Center(
                              child: FractionallySizedBox(
                                widthFactor: .5,
                                heightFactor: .6,
                                child: FittedBox(
                                  child: CollectionLock(size: 32),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RaisedPatchClipper extends CustomClipper<Path> {
  const _RaisedPatchClipper();
  @override
  Path getClip(Size size) =>
      (Path()
            ..moveTo(4, 36)
            ..lineTo(34, 3)
            ..quadraticBezierTo(39, 0, 46, 3)
            ..lineTo(69, 16)
            ..quadraticBezierTo(75, 21, 71, 31)
            ..lineTo(43, 66)
            ..quadraticBezierTo(39, 70, 31, 67)
            ..lineTo(4, 52)
            ..quadraticBezierTo(0, 45, 4, 36)
            ..close())
          .transform(
            Matrix4.diagonal3Values(
              size.width / 75,
              size.height / 70,
              1,
            ).storage,
          );
  @override
  bool shouldReclip(_RaisedPatchClipper oldClipper) => false;
}

class _SlotStitches extends CustomPainter {
  const _SlotStitches({required this.locked});
  final bool locked;
  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.5),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..color = locked ? const Color(0x66958c7b) : const Color(0x18bd9872),
    );
    final path = Path()..addRRect(shape);
    final stroke = Paint()
      ..color = const Color(0xffbaa185)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 6) {
        canvas.drawPath(metric.extractPath(at, at + 3), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_SlotStitches oldDelegate) => locked != oldDelegate.locked;
}

/// This only counts existing completion records; patch count is never used to
/// infer a completed level between the four-level milestones.
int sceneRemainingLevels(String scene, List<int> completedLevels) =>
    20 - completedLevels.where((n) => sceneForLevel(n) == scene).toSet().length;

class CollectionProgressText extends StatelessWidget {
  const CollectionProgressText({
    super.key,
    required this.scene,
    required this.pieces,
    this.remainingLevels,
    this.showTitle = false,
  });
  final String scene;
  final List<String> pieces;
  final int? remainingLevels;
  final bool showTitle;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Text(
            sceneTitle(scene),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        Text(
          l.sceneCount(ownedRegions(pieces, scene).length),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (remainingLevels != null) ...[
          const SizedBox(height: 4),
          Text(
            remainingLevels == 0
                ? l.chapterComplete
                : l.sceneLevelsRemaining(remainingLevels!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

/// Retains native button behavior and system font scaling; only the material,
/// hierarchy and normal-state widths are specific to P11/P13.
class CollectionActions extends StatelessWidget {
  const CollectionActions({
    super.key,
    required this.children,
    this.compactSecondary = false,
  });
  final List<Widget> children;
  final bool compactSecondary;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final enlarged = MediaQuery.textScalerOf(context).scale(18) > 25;
    ButtonStyle style(ButtonStyle? original, {required bool primary}) =>
        (original ?? const ButtonStyle()).copyWith(
          minimumSize: WidgetStatePropertyAll(Size(48, primary ? 72 : 64)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: enlarged ? 0 : 10),
          ),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Nunito',
              fontSize: primary ? 23 : 18,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          foregroundColor: WidgetStatePropertyAll(
            primary ? const Color(0xff123a00) : const Color(0xff07166c),
          ),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundBuilder: (context, states, child) => knitPressFeedback(
            context,
            states,
            Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: states.contains(WidgetState.disabled) ? .5 : 1,
                    child: ReferenceExtraSurface(
                      kind: primary
                          ? ExtraSurfaceKind.primary
                          : ExtraSurfaceKind.collection,
                      cornerRadius: primary ? null : 28,
                    ),
                  ),
                ),
                ?child,
              ],
            ),
          ),
        );
    return Theme(
      data: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: style(base.filledButtonTheme.style, primary: true),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: style(base.outlinedButtonTheme.style, primary: false),
        ),
      ),
      child: compactSecondary && children.length > 2 && !enlarged
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                children.first,
                const SizedBox(height: 6),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 1; i < children.length; i++) ...[
                        if (i > 1) const SizedBox(width: 8),
                        Expanded(child: children[i]),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: enlarged ? 4 : 6),
                  FractionallySizedBox(
                    widthFactor: enlarged
                        ? 1
                        : i == 0
                        ? .86
                        : .76,
                    child: children[i],
                  ),
                ],
              ],
            ),
    );
  }
}

class CollectionActionLabel extends StatelessWidget {
  const CollectionActionLabel(
    this.text, {
    super.key,
    this.icon = Icons.arrow_forward_rounded,
    this.leading = false,
  });
  final String text;
  final IconData icon;
  final bool leading;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (leading) ...[const CollectionBookIcon(), const SizedBox(width: 6)],
      Flexible(child: Text(text, textAlign: TextAlign.center)),
      if (!leading) ...[
        const SizedBox(width: 6),
        if (icon == Icons.arrow_forward_rounded)
          const SizedBox(
            width: 27,
            height: 27,
            child: ExcludeSemantics(
              child: ClipRect(
                key: Key('collection-arrow-clip'),
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
                    -3,
                    0,
                    -3,
                    1,
                    0,
                  ]),
                  child: CompletionReferenceArt(
                    source: Rect.fromLTWH(809, 836, 40, 40),
                  ),
                ),
              ),
            ),
          )
        else
          Icon(icon, size: 25),
      ],
    ],
  );
}
