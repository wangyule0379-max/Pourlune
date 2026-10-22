import 'package:flutter/material.dart';

import 'motion.dart';

/// Object rectangles are normalized to the square scene canvas; raw PNG alpha
/// is retained. The same composition serves Home, collection and detail.
const sceneObjectRects = <String, List<Rect>>{
  'color_studio': [
    Rect.fromLTWH(.10, .18, .33, .42),
    Rect.fromLTWH(.11, .46, .57, .43),
    Rect.fromLTWH(.34, .71, .19, .21),
    Rect.fromLTWH(.69, .53, .23, .30),
    Rect.fromLTWH(.54, .65, .31, .27),
  ],
  'garden_nook': [
    Rect.fromLTWH(.14, .09, .72, .68),
    Rect.fromLTWH(.31, .51, .36, .34),
    Rect.fromLTWH(.63, .41, .26, .43),
    Rect.fromLTWH(.10, .60, .30, .30),
    Rect.fromLTWH(.43, .49, .16, .16),
  ],
  'seaside_corner': [
    Rect.fromLTWH(.09, .41, .85, .53),
    Rect.fromLTWH(.12, .145, .58, .58),
    Rect.fromLTWH(.12, .62, .18, .20),
    Rect.fromLTWH(.08, .43, .19, .23),
    Rect.fromLTWH(.62, .40, .18, .24),
  ],
};

class SceneArt extends StatelessWidget {
  const SceneArt({
    super.key,
    required this.scene,
    required this.pieces,
    this.reveal,
  });
  final String scene;
  final List<String> pieces;
  final int? reveal;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          Widget image(String name, double logicalWidth) => Image(
            image: sceneImage(context, scene, name, logicalWidth),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
          return RepaintBoundary(
            key: Key('scene-$scene-composition'),
            child: Stack(
              children: [
                Positioned.fill(
                  key: Key('scene-$scene-base'),
                  child: image('base', width),
                ),
                for (var i = 1; i <= 5; i++)
                  if (pieces.contains('$scene:$i'))
                    Positioned.fromRect(
                      key: Key('scene-$scene-piece-$i'),
                      rect: Rect.fromLTWH(
                        sceneObjectRects[scene]![i - 1].left * width,
                        sceneObjectRects[scene]![i - 1].top * width,
                        sceneObjectRects[scene]![i - 1].width * width,
                        sceneObjectRects[scene]![i - 1].height * width,
                      ),
                      child: i == reveal
                          ? TweenAnimationBuilder<double>(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? const Duration(milliseconds: 150)
                                  : KnitMotion.reveal,
                              tween: Tween(begin: 0, end: 1),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: MediaQuery.disableAnimationsOf(context)
                                      ? 1
                                      : .88 + .12 * value,
                                  child: child,
                                ),
                              ),
                              child: image(
                                'piece-$i',
                                sceneObjectRects[scene]![i - 1].width * width,
                              ),
                            )
                          : image(
                              'piece-$i',
                              sceneObjectRects[scene]![i - 1].width * width,
                            ),
                    ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

ImageProvider<Object> sceneImage(
  BuildContext context,
  String scene,
  String name,
  double width,
) => ResizeImage(
  AssetImage('assets/art/scenes/$scene/$name.png'),
  width: (width * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
    64,
    1254,
  ),
);
Future<void> warmScene(
  BuildContext context,
  String scene,
  List<String> pieces,
  double width,
) async {
  final providers = <ImageProvider<Object>>[
    sceneImage(context, scene, 'base', width),
    for (var i = 1; i <= 5; i++)
      if (pieces.contains('$scene:$i'))
        sceneImage(
          context,
          scene,
          'piece-$i',
          width * sceneObjectRects[scene]![i - 1].width,
        ),
  ];
  await Future.wait([
    for (final image in providers)
      precacheImage(image, context, onError: (_, _) {}),
  ]);
}
