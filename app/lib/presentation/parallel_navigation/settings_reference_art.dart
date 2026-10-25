import 'package:flutter/material.dart';

import '../reference_play_art.dart';

/// Crops from the unchanged P19/P20/P21 source registered by the resource owner.
/// Used only for decoration; no labels or hit targets come from the bitmap.
class SettingsReferenceArt extends StatelessWidget {
  const SettingsReferenceArt({super.key, required this.source});
  final Rect source;

  @override
  Widget build(BuildContext context) => ReferencePlayArt(
    asset: 'assets/art/p05-reference/reference-settings.png',
    imageSize: const Size(1477, 1065),
    source: source,
    radius: 0,
  );
}

class SettingsReferenceIcon extends StatelessWidget {
  const SettingsReferenceIcon({
    super.key,
    required this.source,
    this.destructive = false,
  });
  final Rect source;
  final bool destructive;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 38,
    child: ColorFiltered(
      // Remove the cream cloth around the isolated blue/red glyph. The source
      // icon RGB values stay intact; the page's own knit surface shows through.
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
        destructive ? 3 : -3,
        0,
        destructive ? -3 : 3,
        0,
        destructive ? -160 : -100,
      ]),
      child: SettingsReferenceArt(source: source),
    ),
  );
}

class SettingsChevronArt extends StatelessWidget {
  const SettingsChevronArt({super.key, this.destructive = false});
  final bool destructive;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 36,
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
          destructive ? 3 : -3,
          0,
          destructive ? -3 : 3,
          0,
          destructive ? -160 : -100,
        ]),
        child: SettingsReferenceArt(
          source: destructive
              ? const Rect.fromLTWH(409, 904, 27, 36)
              : const Rect.fromLTWH(409, 721, 27, 36),
        ),
      ),
    ),
  );
}
