import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'labels.dart';
import 'motion.dart';
import 'reference_play_art.dart';

// Display bounds remove transparent canvas margins, without altering raw PNGs.
const _art = <String, (Size, Rect)>{
  'logo': (Size(1969, 799), Rect.fromLTRB(15, 23, 1958, 799)),
  'green-frame': (Size(2079, 756), Rect.fromLTRB(46, 97, 2034, 671)),
  'cream-frame': (Size(1896, 830), Rect.fromLTRB(39, 99, 1860, 730)),
  'moon': (Size(1374, 1145), Rect.fromLTRB(319, 208, 1135, 1043)),
  'chapters': (Size(1474, 1067), Rect.fromLTRB(165, 118, 1372, 1004)),
  'calendar': (Size(1254, 1254), Rect.fromLTRB(104, 62, 1154, 1190)),
  'success': (Size(1254, 1254), Rect.fromLTRB(52, 57, 1209, 1206)),
  'patch-tile': (Size(64, 57), Rect.fromLTWH(0, 0, 64, 57)),
};

class KnitArt extends StatelessWidget {
  const KnitArt({
    super.key,
    required this.name,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final String name;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final (size, bounds) = _art[name]!;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: fit,
          child: SizedBox(
            width: bounds.width,
            height: bounds.height,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -bounds.left,
                    top: -bounds.top,
                    width: size.width,
                    height: size.height,
                    child: Image(
                      image: knitArtImage(context, name, width: width ?? 360),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Buttons keep native text, focus, semantics, hit testing and disabled state.
Widget knitButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child, {
  required bool primary,
}) => knitPressFeedback(
  context,
  states,
  Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: Opacity(
          opacity: states.contains(WidgetState.disabled) ? .55 : 1,
          child: KnitArt(
            name: primary ? 'green-frame' : 'cream-frame',
            fit: BoxFit.fill,
          ),
        ),
      ),
      ?child,
    ],
  ),
);

class KnitPanel extends StatelessWidget {
  const KnitPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    decoration: BoxDecoration(
      color: cream,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xffffe8ba), width: 5),
      image: const DecorationImage(
        image: AssetImage('assets/art/ui/cream-tile.png'),
        repeat: ImageRepeat.repeat,
        scale: 2,
        opacity: .65,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x28635249),
          offset: Offset(0, 5),
          blurRadius: 4,
        ),
      ],
    ),
    padding: padding,
    child: child,
  );
}

class KnitIconButton extends StatelessWidget {
  const KnitIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 52,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  @override
  Widget build(BuildContext context) {
    final source = icon == Icons.arrow_back_rounded
        ? const Rect.fromLTWH(714, 61, 85, 82)
        : icon == Icons.settings_rounded
        ? const Rect.fromLTWH(575, 54, 82, 80)
        : null;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        onTap: onPressed,
        excludeSemantics: true,
        child: SizedBox(
          width: size,
          height: size,
          child: OutlinedButton(
            style:
                OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  side: BorderSide.none,
                  backgroundColor: Colors.transparent,
                ).copyWith(
                  backgroundBuilder: (context, states, child) =>
                      knitPressFeedback(context, states, child!),
                ),
            onPressed: onPressed,
            child: source == null
                ? Icon(icon, size: 28)
                : Opacity(
                    opacity: onPressed == null ? .45 : 1,
                    child: SizedBox.expand(
                      child: ReferencePlayArt(source: source, radius: 12),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class KnitHeader extends StatelessWidget {
  const KnitHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backKey,
    this.backLabel,
    this.trailing,
    this.compact = false,
    this.showMoon = false,
  });
  final String title;
  final bool compact, showMoon;
  final String? backLabel;
  final VoidCallback? onBack;
  final Key? backKey;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          KnitIconButton(
            key: backKey,
            icon: Icons.arrow_back_rounded,
            label: backLabel ?? AppLocalizations.of(context).home,
            onPressed: onBack,
            size: compact ? 48 : 52,
          )
        else
          const SizedBox(width: 52),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: compact
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showMoon &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.4) ...[
                        const KnitArt(name: 'moon', width: 20, height: 20),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        trailing ?? const SizedBox(width: 52),
      ],
    ),
  );
}

class PatchProgress extends StatelessWidget {
  const PatchProgress({
    super.key,
    required this.scene,
    required this.pieces,
    this.compact = false,
  });
  final String scene;
  final List<String> pieces;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), owned = ownedRegions(pieces, scene);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final side = ((box.maxWidth - 24) / 5).clamp(
              12.0,
              compact ? 32.0 : 48.0,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Semantics(
                    label:
                        '${regionLabel(l, scene, i)} · ${owned.contains(i) ? l.sceneOwned : l.sceneLocked}',
                    child: ExcludeSemantics(
                      child: Container(
                        width: side,
                        height: side,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xffffedc9),
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/art/ui/${owned.contains(i) ? 'patch-tile' : 'cream-tile'}.png',
                            ),
                            repeat: owned.contains(i)
                                ? ImageRepeat.noRepeat
                                : ImageRepeat.repeat,
                            fit: owned.contains(i) ? BoxFit.cover : null,
                            scale: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x16635249),
                              offset: Offset(0, 3),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: const CustomPaint(
                          painter: _PatchProgressStitches(),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          l.sceneCount(owned.length),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 14 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PatchProgressStitches extends CustomPainter {
  const _PatchProgressStitches();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(5),
          const Radius.circular(7),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xffbaa185)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 6) {
        canvas.drawPath(metric.extractPath(at, at + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatchProgressStitches old) => false;
}

class CalendarArt extends StatelessWidget {
  const CalendarArt({super.key, required this.day, this.size = 100});
  final int day;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        Positioned.fill(
          child: KnitArt(name: 'calendar', width: size, height: size),
        ),
        Positioned(
          left: size * .1,
          top: size * .40,
          width: size * .8,
          height: size * .45,
          child: Center(
            child: Text(
              '$day',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: size * .34,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

ImageProvider<Object> knitArtImage(
  BuildContext context,
  String name, {
  double width = 360,
}) {
  final (size, bounds) = _art[name]!;
  final cacheWidth =
      (width *
              MediaQuery.devicePixelRatioOf(context) *
              size.width /
              bounds.width)
          .ceil()
          .clamp(64, size.width.toInt());
  return ResizeImage(AssetImage('assets/art/ui/$name.png'), width: cacheWidth);
}

Widget knitPressFeedback(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => AnimatedScale(
  scale:
      !MediaQuery.disableAnimationsOf(context) &&
          states.contains(WidgetState.pressed) &&
          !states.contains(WidgetState.disabled)
      ? .96
      : 1,
  duration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : states.contains(WidgetState.pressed)
      ? KnitMotion.press
      : KnitMotion.release,
  curve: states.contains(WidgetState.pressed)
      ? Curves.easeOut
      : Curves.easeOutBack,
  child: child,
);
