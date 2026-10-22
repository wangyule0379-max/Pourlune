import 'package:flutter/foundation.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../../application/game_controller.dart';
import '../bottle.dart' show LiquidBand;
import 'geometry.dart';

/// Immutable, derived presentation only. It is never fed to the game core or
/// persistence layer. Native capacity text and canvas consume this same frame.
class BoardVisualFrame {
  BoardVisualFrame({
    required this.state,
    required this.layout,
    PourMotion? motion,
    this.elapsedMs = 0,
    bool reduced = false,
    double initialLift = 0,
  }) {
    final m = motion != null && matchesMotion(state, motion) ? motion : null;
    active = m;
    final source = m?.from, target = m?.to;
    double out = 0, arrived = 0;
    PourFrame? flowing;
    if (m != null) {
      if (reduced) {
        out = arrived = m.units * (elapsedMs / 120).clamp(0.0, 1.0);
      } else {
        flowing = geometryFor(
          layout,
          m,
          initialLift: initialLift,
        ).frame(elapsedMs);
        out = flowing.out;
        arrived = flowing.delivered;
      }
    }
    pour = flowing;
    contents = m == null
        ? state.board
        : presentedContents(m.before, m.from, m.to, out, arrived);
    counts = contents.map((b) => b.length).toList(growable: false);
    poses = [for (final mouth in layout.mouths) BottlePose(mouth, 0)];
    if (pour != null) {
      poses[source!] = pour!.source;
      poses[target!] = pour!.target;
    }
    bands = [
      for (var i = 0; i < state.board.length; i++)
        _bands(
          m?.before[i] ?? state.board[i],
          remove: i == source ? out : 0,
          add: i == target ? arrived : 0,
          color: m == null ? null : m.before[m.from].last,
        ),
    ];
    paintOrder = [
      for (var i = 0; i < state.board.length; i++)
        if (i != source) i,
      ?source,
    ];
  }
  final GameInstance state;
  final BoardLayout layout;
  final double elapsedMs;
  late final PourMotion? active;
  late final PourFrame? pour;
  late final Board contents;
  late final List<int> counts, paintOrder;
  late final List<BottlePose> poses;
  late final List<List<LiquidBand>> bands;
}

bool matchesMotion(GameInstance state, PourMotion motion) =>
    motion.instanceId == state.id &&
    motion.revision == state.revision &&
    motion.before.length == state.board.length &&
    motion.after.length == state.board.length &&
    motion.from >= 0 &&
    motion.from < state.board.length &&
    motion.to >= 0 &&
    motion.to < state.board.length &&
    motion.from != motion.to &&
    motion.units > 0 &&
    motion.units <= 4 &&
    motion.before[motion.from].isNotEmpty &&
    List.generate(
      state.board.length,
      (i) => listEquals(state.board[i], motion.after[i]),
    ).every((same) => same);

PourGeometry geometryFor(
  BoardLayout layout,
  PourMotion motion, {
  double initialLift = 0,
}) => PourGeometry(
  shape: layout.shape,
  sourceMouth: layout.mouths[motion.from],
  targetMouth: layout.mouths[motion.to],
  units: motion.units,
  sourceUnits: motion.before[motion.from].length,
  bounds: layout.flightBounds,
  initialLift: initialLift,
);

/// Counts change only on a shared integer boundary; source and destination
/// semantics therefore conserve the same color units, without per-frame speech.
Board presentedContents(
  Board before,
  int from,
  int to,
  double out,
  double arrived,
) {
  final values = transferCounts(
    sourceBefore: before[from].length,
    targetBefore: before[to].length,
    out: out,
    arrived: arrived,
  );
  final transferred = before[from].length - values.source;
  return [
    for (var i = 0; i < before.length; i++)
      if (i == from)
        before[i].sublist(0, values.source)
      else if (i == to)
        [...before[i], ...List.filled(transferred, before[from].last)]
      else
        before[i],
  ];
}

List<LiquidBand> _bands(
  List<String> contents, {
  required double remove,
  required double add,
  String? color,
}) {
  final result = <LiquidBand>[
    for (final color in contents) (color: color, units: 1.0),
  ];
  var remaining = remove;
  while (remaining > .000001 && result.isNotEmpty) {
    final last = result.removeLast();
    if (last.units > remaining) {
      result.add((color: last.color, units: last.units - remaining));
      break;
    }
    remaining -= last.units;
  }
  if (add > .000001 && color != null) result.add((color: color, units: add));
  return result;
}
