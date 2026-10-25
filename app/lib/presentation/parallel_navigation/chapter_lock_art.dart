import 'package:flutter/material.dart';

import '../reference_play_art.dart';

/// Original blue chapter lock. The parent provides its live locked semantics.
class ChapterLockArt extends StatelessWidget {
  const ChapterLockArt({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 28,
    height: 40,
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
          asset: 'assets/art/p05-reference/reference-entry.png',
          imageSize: Size(1475, 1067),
          source: Rect.fromLTWH(1389, 633, 32, 46),
          radius: 0,
        ),
      ),
    ),
  );
}
