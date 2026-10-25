import 'package:flutter/material.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/bottle.dart' show LiquidBand;
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

// Observes real paint calls while preserving all asset/clip/liquid drawing.
class PaintOrderProbe extends FlameBoardPainter {
  PaintOrderProbe(super.art);
  final order = <int>[];
  @override
  void paintBottle(
    Canvas canvas,
    int index,
    BottlePose pose,
    List<LiquidBand> bands,
    BottleShape shape,
    PlayerSettings settings, {
    required bool highlighted,
    String? fixedTarget,
    bool added = false,
    List<Rect> glowExclusions = const [],
    bool contentsSymbols = true,
    double wave = 0,
  }) {
    order.add(index);
    super.paintBottle(
      canvas,
      index,
      pose,
      bands,
      shape,
      settings,
      highlighted: highlighted,
      fixedTarget: fixedTarget,
      added: added,
      glowExclusions: glowExclusions,
      contentsSymbols: contentsSymbols,
      wave: wave,
    );
  }
}
