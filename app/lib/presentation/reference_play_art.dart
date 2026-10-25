import 'package:flutter/material.dart';

class ReferenceMoonArt extends StatelessWidget {
  const ReferenceMoonArt({super.key});
  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: const _MoonSilhouette(),
    child: const ReferencePlayArt(
      source: Rect.fromLTWH(920, 75, 48, 48),
      radius: 0,
    ),
  );
}

class _MoonSilhouette extends CustomClipper<Path> {
  const _MoonSilhouette();
  @override
  Path getClip(Size s) => Path.combine(
    PathOperation.difference,
    Path()..addOval(
      Rect.fromLTWH(
        s.width * .035,
        s.height * .025,
        s.width * .93,
        s.height * .95,
      ),
    ),
    Path()..addOval(
      Rect.fromLTWH(
        s.width * .39,
        -s.height * .05,
        s.width * .77,
        s.height * .79,
      ),
    ),
  );
  @override
  bool shouldReclip(_MoonSilhouette oldClipper) => false;
}

/// Component crops from the user's unchanged HOME/PLAY reference. These are
/// materials/icons only: Flutter still owns labels, semantics and every action.
class ReferencePlayArt extends StatelessWidget {
  const ReferencePlayArt({
    super.key,
    required this.source,
    this.radius = 20,
    this.asset = 'assets/art/p05-reference/reference-play.png',
    this.imageSize = const Size(1362, 1155),
  });
  final Rect source;
  final double radius;
  final String asset;
  final Size imageSize;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: source.width,
          height: source.height,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -source.left,
                  top: -source.top,
                  width: imageSize.width,
                  height: imageSize.height,
                  child: Image(
                    image: AssetImage(asset),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
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

class ReferencePlayActionArt extends StatelessWidget {
  const ReferencePlayActionArt({
    super.key,
    required this.index,
    this.enabled = true,
    this.emphasized = false,
    this.showIcon = true,
    this.usedExtraBottle = false,
  });
  final int index;
  final bool enabled, emphasized, showIcon, usedExtraBottle;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: emphasized
            ? const [
                BoxShadow(
                  color: Color(0xb3ffffff),
                  blurRadius: 3,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x8024caff),
                  blurRadius: 7,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          const FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: 1335,
              height: 700,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      left: -56,
                      top: -197,
                      width: 1446,
                      height: 1087,
                      child: Image(
                        image: AssetImage(
                          'assets/art/p05-reference/p05-button-blank-candidate-v3.png',
                        ),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (emphasized)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xff24b9f0),
                    width: 2.4,
                  ),
                ),
              ),
            ),
          if (showIcon)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              height: 36,
              child: Center(
                child: usedExtraBottle
                    ? const SizedBox(
                        width: 38,
                        height: 36,
                        child: ReferencePlayArt(
                          asset: 'assets/art/p05-reference/reference-extra.png',
                          imageSize: Size(1477, 1065),
                          source: Rect.fromLTWH(1345, 934, 55, 47),
                          radius: 12,
                        ),
                      )
                    : ReferencePlayIcon(index: index, enabled: enabled),
              ),
            ),
        ],
      ),
    );
  }
}

/// Retain the original blue sculpted shading and light-blue highlights while
/// removing only warm cream surroundings; no substitute line icon.
class ReferencePlayIcon extends StatelessWidget {
  const ReferencePlayIcon({
    super.key,
    required this.index,
    this.enabled = true,
  });
  final int index;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    const sources = [
      Rect.fromLTWH(814, 1011, 55, 59),
      Rect.fromLTWH(994, 1006, 50, 66),
      Rect.fromLTWH(1179, 1005, 47, 66),
    ];
    final source = sources[index];
    return ExcludeSemantics(
      child: Opacity(
        opacity: enabled ? 1 : .42,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
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
            -25,
            0,
            25,
            0,
            0,
          ]),
          child: AspectRatio(
            aspectRatio: source.width / source.height,
            child: ReferencePlayArt(source: source, radius: 0),
          ),
        ),
      ),
    );
  }
}

/// Preserve the cream cushion end caps instead of flattening the entire image.
class ReferenceHintMaterial extends StatelessWidget {
  const ReferenceHintMaterial({super.key});
  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: -3.9,
          top: -9.9,
          right: -3.6,
          bottom: -10,
          child: Image.asset(
            'assets/art/ui/cream-frame.png',
            scale: 10,
            fit: BoxFit.fill,
            centerSlice: const Rect.fromLTRB(35, 19, 154, 63),
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    ),
  );
}
