import 'package:flutter/material.dart';

import '../reference_play_art.dart';

/// Original P02's overlapping purple and green patches, decoration only.
class HomeCollectionArt extends StatelessWidget {
  const HomeCollectionArt({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 52,
    height: 50,
    child: ClipRect(
      child: ColorFiltered(
        // Keep the purple/green yarn while removing surrounding cream cloth.
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
          -6,
          -6,
          -6,
          16.470588235294116,
          0,
        ]),
        child: ReferencePlayArt(
          asset: 'assets/art/p05-reference/reference-entry.png',
          imageSize: Size(1475, 1067),
          source: Rect.fromLTWH(838, 883, 87, 78),
          radius: 0,
        ),
      ),
    ),
  );
}
