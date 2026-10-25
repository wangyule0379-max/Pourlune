import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../labels.dart';
import '../scene_art.dart';
import 'collection_visuals.dart';

/// Presentation covers stay inside the corresponding art region. They use
/// smaller, separate footprints so neighboring locks never cover one another.
const sceneLockDisplayRects = <String, List<Rect>>{
  'color_studio': [
    Rect.fromLTWH(.11, .24, .25, .25),
    Rect.fromLTWH(.13, .51, .43, .18),
    Rect.fromLTWH(.35, .74, .17, .17),
    Rect.fromLTWH(.73, .54, .18, .16),
    Rect.fromLTWH(.70, .74, .14, .17),
  ],
  'garden_nook': [
    Rect.fromLTWH(.22, .13, .56, .30),
    Rect.fromLTWH(.38, .66, .25, .17),
    Rect.fromLTWH(.69, .48, .17, .34),
    Rect.fromLTWH(.11, .65, .22, .23),
    Rect.fromLTWH(.44, .50, .14, .13),
  ],
  'seaside_corner': [
    Rect.fromLTWH(.34, .77, .50, .15),
    Rect.fromLTWH(.28, .18, .35, .33),
    Rect.fromLTWH(.12, .68, .18, .12),
    Rect.fromLTWH(.085, .44, .18, .18),
    Rect.fromLTWH(.65, .42, .14, .18),
  ],
};

/// The room underneath always uses the saved piece IDs. The translucent covers
/// only identify missing regions; no full-room bitmap substitutes for progress.
class CollectionSceneDetail extends StatelessWidget {
  const CollectionSceneDetail({
    super.key,
    required this.scene,
    required this.pieces,
    this.reveal,
  });
  final String scene;
  final List<String> pieces;
  final int? reveal;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = ownedRegions(pieces, scene);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(
              child: SceneArt(scene: scene, pieces: pieces, reveal: reveal),
            ),
            for (var number = 1; number <= 5; number++)
              if (!owned.contains(number))
                Positioned.fromRect(
                  rect: Rect.fromLTWH(
                    sceneLockDisplayRects[scene]![number - 1].left *
                        box.maxWidth,
                    sceneLockDisplayRects[scene]![number - 1].top *
                        box.maxWidth,
                    sceneLockDisplayRects[scene]![number - 1].width *
                        box.maxWidth,
                    sceneLockDisplayRects[scene]![number - 1].height *
                        box.maxWidth,
                  ),
                  child: Semantics(
                    label:
                        '${regionLabel(l, scene, number)} · ${l.sceneLocked}',
                    child: CustomPaint(
                      key: Key('scene-region-lock-$number'),
                      painter: const _RegionCover(),
                      child: const Center(
                        child: FractionallySizedBox(
                          widthFactor: .65,
                          heightFactor: .65,
                          child: FittedBox(child: CollectionLock(size: 42)),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _RegionCover extends CustomPainter {
  const _RegionCover();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .06, size.height * .08)
      ..quadraticBezierTo(
        size.width * .06,
        0,
        size.width * .2,
        size.height * .03,
      )
      ..lineTo(size.width * .94, size.height * .16)
      ..lineTo(size.width * .94, size.height * .91)
      ..quadraticBezierTo(
        size.width * .94,
        size.height,
        size.width * .8,
        size.height * .96,
      )
      ..lineTo(size.width * .06, size.height * .83)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xbbece5d6));
    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xffb0a38d)
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 9) {
        canvas.drawPath(metric.extractPath(at, at + 5), stitch);
      }
    }
  }

  @override
  bool shouldRepaint(_RegionCover oldDelegate) => false;
}

class CollectionObjectStrip extends StatelessWidget {
  const CollectionObjectStrip({
    super.key,
    required this.scene,
    required this.pieces,
  });
  final String scene;
  final List<String> pieces;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = ownedRegions(pieces, scene);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: Semantics(
              label:
                  '${l.patchNumber(i)} · ${regionLabel(l, scene, i)} · ${owned.contains(i) ? l.sceneOwned : l.sceneLocked}',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: .92,
                      child: CollectionSurface(
                        key: Key('scene-object-$i'),
                        padding: const EdgeInsets.all(5),
                        cornerRadius: 12,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: owned.contains(i) ? 1 : .32,
                              child: Image(
                                image: sceneImage(
                                  context,
                                  scene,
                                  'piece-$i',
                                  70,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (!owned.contains(i))
                              const Center(
                                child: FractionallySizedBox(
                                  widthFactor: .65,
                                  heightFactor: .65,
                                  child: FittedBox(
                                    child: CollectionLock(size: 32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xfffff4df),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22635249),
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$i',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
