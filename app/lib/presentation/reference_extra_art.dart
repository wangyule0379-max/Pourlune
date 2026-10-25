import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'reference_play_art.dart';
import '../data/player_settings.dart';
import 'flame_board/geometry.dart';
import 'flame_board/paint.dart';

const _extraAsset = 'assets/art/p05-reference/reference-extra.png';
const _pauseAsset = 'assets/art/p05-reference/reference-pause.png';

/// Component pixels from the unchanged user-supplied P16/P17/P18 sheet.
class ReferenceExtraArt extends StatelessWidget {
  const ReferenceExtraArt({super.key, required this.source, this.radius = 0});
  final Rect source;
  final double radius;
  @override
  Widget build(BuildContext context) => ReferencePlayArt(
    source: source,
    radius: radius,
    asset: _extraAsset,
    imageSize: const Size(1477, 1065),
  );
}

enum ExtraSurfaceKind {
  modal,
  primary,
  secondary,
  pause,
  collection,
  settings,
  chapterCell,
  chapterPanel,
}

String _surfaceAsset(ExtraSurfaceKind kind) => switch (kind) {
  ExtraSurfaceKind.pause => _pauseAsset,
  ExtraSurfaceKind.collection =>
    'assets/art/p05-reference/reference-completion.png',
  ExtraSurfaceKind.settings =>
    'assets/art/p05-reference/reference-settings.png',
  ExtraSurfaceKind.chapterCell || ExtraSurfaceKind.chapterPanel =>
    'assets/art/p05-reference/reference-entry.png',
  _ => _extraAsset,
};

/// Draw only clean borders and a blank knit patch. Original titles/buttons
/// inside the reference are never used as live content or baked into the panel.
class ReferenceExtraSurface extends StatefulWidget {
  const ReferenceExtraSurface({
    super.key,
    this.kind = ExtraSurfaceKind.modal,
    this.tileEdges = false,
    this.cornerRadius,
  });
  final ExtraSurfaceKind kind;
  final bool tileEdges;
  final double? cornerRadius;
  @override
  State<ReferenceExtraSurface> createState() => _ReferenceExtraSurfaceState();
}

class _ReferenceExtraSurfaceState extends State<ReferenceExtraSurface> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final _listener = ImageStreamListener((image, sync) {
    void replace() {
      _image?.dispose();
      _image = image;
    }

    if (!mounted) {
      image.dispose();
      return;
    }
    if (sync) {
      replace();
    } else {
      setState(replace);
    }
  });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant ReferenceExtraSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_surfaceAsset(oldWidget.kind) != _surfaceAsset(widget.kind)) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final next = AssetImage(_surfaceAsset(widget.kind))
        .resolve(createLocalImageConfiguration(context));
    if (_stream?.key == next.key) return;
    _stream?.removeListener(_listener);
    // A new board sheet must never be sampled with the previous sheet's image.
    _image?.dispose();
    _image = null;
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.kind == ExtraSurfaceKind.primary && widget.cornerRadius == null
      ? const ReferencePlayArt(
          asset: 'assets/art/p05-reference/green-primary-candidate-v1.png',
          imageSize: Size(2172, 724),
          source: Rect.fromLTWH(72, 116, 2028, 492),
          radius: 0,
        )
      : ExcludeSemantics(
          child: CustomPaint(
            painter: _ExtraSurfacePainter(
              _image?.image,
              widget.kind,
              widget.tileEdges,
              widget.cornerRadius,
            ),
          ),
        );
}

class _ExtraSurfacePainter extends CustomPainter {
  const _ExtraSurfacePainter(
    this.image,
    this.kind,
    this.tileEdges,
    this.cornerRadius,
  );
  final ui.Image? image;
  final ExtraSurfaceKind kind;
  final bool tileEdges;
  final double? cornerRadius;
  @override
  void paint(Canvas canvas, Size size) {
    final im = image;
    if (im == null) return;
    final pause = kind == ExtraSurfaceKind.pause;
    final collection = kind == ExtraSurfaceKind.collection;
    final settings = kind == ExtraSurfaceKind.settings;
    final chapterCell = kind == ExtraSurfaceKind.chapterCell;
    final chapterPanel = kind == ExtraSurfaceKind.chapterPanel;
    final continuous = pause || collection || settings || chapterPanel;
    final modal = kind == ExtraSurfaceKind.modal || pause;
    final primary = kind == ExtraSurfaceKind.primary;
    final frame = chapterPanel
        ? const Rect.fromLTWH(1007, 144, 442, 449)
        : settings
        ? const Rect.fromLTWH(30, 153, 440, 528)
        : chapterCell
        ? const Rect.fromLTWH(1020, 294, 76, 64)
        : collection
        ? const Rect.fromLTRB(1005, 138, 1460, 356)
        : pause
        ? const Rect.fromLTRB(1049, 284, 1408, 758)
        : modal
        ? const Rect.fromLTRB(535, 315, 943, 850)
        : primary
        ? const Rect.fromLTRB(573, 659, 905, 741)
        : const Rect.fromLTRB(103, 784, 414, 862);
    final patch = chapterPanel
        ? const Rect.fromLTWH(1245, 258, 120, 20)
        : settings
        ? const Rect.fromLTWH(244, 175, 80, 70)
        : chapterCell
        ? const Rect.fromLTWH(1030, 308, 14, 18)
        : collection
        ? const Rect.fromLTWH(1270, 318, 48, 18)
        : pause
        ? const Rect.fromLTWH(1080, 330, 80, 70)
        : modal
        ? const Rect.fromLTWH(570, 390, 40, 80)
        : primary
        ? const Rect.fromLTWH(606, 683, 32, 32)
        : const Rect.fromLTWH(122, 805, 24, 24);
    final corner = chapterCell ? 24.0 : (modal ? 40.0 : 36.0);
    final scale = size.width / frame.width;
    final targetCorner = math.min(
      cornerRadius ??
          (pause
              ? corner * scale
              : modal
              ? 30.0
              : 28.0),
      size.height / 2,
    );
    final bounds = Offset.zero & size;
    if (continuous) {
      canvas.drawShadow(
        Path()..addRRect(
          RRect.fromRectAndRadius(bounds, Radius.circular(targetCorner)),
        ),
        const Color(0x503c3a28),
        6,
        false,
      );
    }
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(targetCorner)),
    );
    final paint = Paint()..filterQuality = FilterQuality.high;
    // Cream highlights remain opaque; only the blue outside the curved
    // reference edge is removed. The earlier steep key also erased highlights.
    if (!collection && !settings && !chapterCell && !chapterPanel) {
      paint.colorFilter = const ColorFilter.matrix([
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
        4,
        0,
        -4,
        0,
        225,
      ]);
    }
    final textureScale =
        scale *
        (pause
            ? .78
            : settings
            ? .85
            : 1.0);
    final tw = math.max(8.0, patch.width * textureScale);
    final th = math.max(8.0, patch.height * textureScale);
    for (var y = 0.0; y < size.height; y += th) {
      for (var x = 0.0; x < size.width; x += tw) {
        // Mirrored repeats meet the same source edge, avoiding hard tile seams.
        final flipX = (x / tw).round().isOdd;
        final flipY = (y / th).round().isOdd;
        canvas.save();
        canvas.translate(x + (flipX ? tw : 0), y + (flipY ? th : 0));
        canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
        canvas.drawImageRect(im, patch, Rect.fromLTWH(0, 0, tw, th), paint);
        canvas.restore();
      }
    }
    if (continuous) {
      // One continuous knit sheet avoids importing the dimmed board pixels
      // around the reference panel's corners or joining different tile scales.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bounds.deflate(4),
          Radius.circular(math.max(0, targetCorner - 4)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
          ..shader = ui.Gradient.linear(
            bounds.topCenter,
            bounds.bottomCenter,
            const [Color(0x60fff8e7), Color(0x0ffff8e7), Color(0x3590775a)],
            const [0, .45, 1],
          ),
      );
      canvas.restore();
      return;
    }
    void piece(
      Rect source,
      Rect target, {
      bool mirror = false,
      Offset? fadeFrom,
      Offset? fadeTo,
    }) {
      if (target.width <= 0 || target.height <= 0) return;
      if (fadeFrom != null) canvas.saveLayer(target, Paint());
      if (mirror) {
        canvas.save();
        canvas.translate(target.left + target.right, 0);
        canvas.scale(-1, 1);
      }
      if (tileEdges && fadeFrom != null) {
        // Repeat long edge stitches at their cross-axis scale, so a wide
        // completion card does not stretch one stitch across its top border.
        final horizontal = target.width > target.height;
        final scale = horizontal
            ? target.height / source.height
            : target.width / source.width;
        final length = (horizontal ? source.width : source.height) * scale;
        canvas.save();
        canvas.clipRect(target);
        var tileIndex = 0;
        for (
          var offset = 0.0;
          offset < (horizontal ? target.width : target.height);
          offset += length
        ) {
          final tile = horizontal
              ? Rect.fromLTWH(
                  target.left + offset,
                  target.top,
                  length,
                  target.height,
                )
              : Rect.fromLTWH(
                  target.left,
                  target.top + offset,
                  target.width,
                  length,
                );
          canvas.save();
          if (tileIndex.isOdd) {
            if (horizontal) {
              canvas.translate(tile.left + tile.right, 0);
              canvas.scale(-1, 1);
            } else {
              canvas.translate(0, tile.top + tile.bottom);
              canvas.scale(1, -1);
            }
          }
          canvas.drawImageRect(im, source, tile, paint);
          canvas.restore();
          tileIndex++;
        }
        canvas.restore();
      } else {
        canvas.drawImageRect(im, source, target, paint);
      }
      if (mirror) canvas.restore();
      if (fadeFrom != null) {
        canvas.drawRect(
          target,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.linear(
              fadeFrom,
              fadeTo!,
              [Colors.white, Colors.transparent],
              [.55, 1],
            ),
        );
        canvas.restore();
      }
    }

    final tl = Rect.fromLTWH(frame.left, frame.top, corner, corner);
    final bl = Rect.fromLTWH(frame.left, frame.bottom - corner, corner, corner);
    final c = targetCorner;
    piece(tl, Rect.fromLTWH(0, 0, c, c));
    piece(tl, Rect.fromLTWH(size.width - c, 0, c, c), mirror: true);
    piece(bl, Rect.fromLTWH(0, size.height - c, c, c));
    piece(
      bl,
      Rect.fromLTWH(size.width - c, size.height - c, c, c),
      mirror: true,
    );
    final edge = pause
        ? 28.0
        : modal
        ? 26.0
        : 18.0;
    final te = pause
        ? edge * scale
        : modal
        ? 19.0
        : 14.0;
    final side = Rect.fromLTRB(
      frame.left,
      frame.top + corner,
      frame.left + edge,
      frame.bottom - corner,
    );
    piece(
      side,
      Rect.fromLTRB(0, c, te, size.height - c),
      fadeFrom: Offset(0, c),
      fadeTo: Offset(te, c),
    );
    piece(
      side,
      Rect.fromLTRB(size.width - te, c, size.width, size.height - c),
      mirror: true,
      fadeFrom: Offset(size.width, c),
      fadeTo: Offset(size.width - te, c),
    );
    // Clean top strip ends before the reference's raised close button.
    piece(
      Rect.fromLTWH(
        frame.left + corner,
        frame.top,
        pause
            ? 249
            : modal
            ? 258
            : frame.width - 2 * corner,
        edge,
      ),
      Rect.fromLTRB(c, 0, size.width - c, te),
      fadeFrom: Offset(c, 0),
      fadeTo: Offset(c, te),
    );
    piece(
      chapterCell
          ? const Rect.fromLTWH(1035, 344, 25, 8)
          : Rect.fromLTRB(
              frame.left + corner,
              frame.bottom - (modal ? 16 : edge),
              frame.right - corner,
              frame.bottom,
            ),
      Rect.fromLTRB(c, size.height - te, size.width - c, size.height),
      fadeFrom: Offset(c, size.height),
      fadeTo: Offset(c, size.height - te),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ExtraSurfacePainter old) =>
      old.image != image ||
      old.kind != kind ||
      old.tileEdges != tileEdges ||
      old.cornerRadius != cornerRadius;
}

class ExtraBottleHero extends StatelessWidget {
  const ExtraBottleHero({super.key, this.unavailable = false});
  final bool unavailable;
  @override
  Widget build(BuildContext context) => unavailable
      ? ClipPath(
          clipper: const _CloudHeroClipper(),
          child: const ReferenceExtraArt(
            source: Rect.fromLTWH(624, 354, 229, 160),
          ),
        )
      : const _NeutralBottleIllustration();
}

class _NeutralBottleIllustration extends StatefulWidget {
  const _NeutralBottleIllustration();
  @override
  State<_NeutralBottleIllustration> createState() =>
      _NeutralBottleIllustrationState();
}

class _NeutralBottleIllustrationState
    extends State<_NeutralBottleIllustration> {
  BottleArt? art;
  @override
  void initState() {
    super.initState();
    BottleArt.load().then((loaded) {
      if (!mounted) {
        loaded.dispose();
        return;
      }
      setState(() => art = loaded);
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
      final badgeSize = math.min(box.maxWidth * .36, box.maxHeight * .36);
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _NeutralBottleIllustrationPainter(art)),
          ),
          Positioned(
            left: box.maxWidth * .59,
            bottom: box.maxHeight * .04,
            width: badgeSize,
            height: badgeSize,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff75acff),
                      Color(0xff2468e8),
                      Color(0xff0736a1),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55062269),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: FittedBox(
                      child: Text(
                        '+1',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 32,
                          decoration: TextDecoration.none,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color(0x800c3692),
                              offset: Offset(0, 2),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _NeutralBottleIllustrationPainter extends CustomPainter {
  const _NeutralBottleIllustrationPainter(this.art);
  final BottleArt? art;
  @override
  void paint(Canvas canvas, Size size) {
    final loaded = art;
    if (loaded == null) return;
    final width = math.min(size.width * .69, size.height / (309 / 166));
    final shape = BottleShape(width);
    FlameBoardPainter(loaded).paintBottle(
      canvas,
      0,
      BottlePose(Offset(size.width * .36, shape.height * .1), 0),
      [],
      shape,
      const PlayerSettings(),
      fixedTarget: null,
      highlighted: false,
    );
  }

  @override
  bool shouldRepaint(_NeutralBottleIllustrationPainter old) => old.art != art;
}

class _CloudHeroClipper extends CustomClipper<Path> {
  const _CloudHeroClipper();
  @override
  Path getClip(Size s) => Path()
    ..addOval(
      Rect.fromLTWH(
        s.width * .02,
        s.height * .39,
        s.width * .94,
        s.height * .60,
      ),
    )
    ..addOval(
      Rect.fromLTWH(
        s.width * .12,
        s.height * .16,
        s.width * .77,
        s.height * .74,
      ),
    )
    ..addOval(Rect.fromLTWH(s.width * .28, 0, s.width * .49, s.height * .78))
    ..addOval(
      Rect.fromLTWH(
        s.width * .64,
        s.height * .50,
        s.width * .36,
        s.height * .50,
      ),
    );
  @override
  bool shouldReclip(_CloudHeroClipper oldClipper) => false;
}
