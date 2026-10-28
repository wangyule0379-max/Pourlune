import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

import 'support/flame_board_support.dart';

GameInstance mainPuzzle(int level) => GameInstance.create(
  id: 'transport-main-$level',
  puzzle: Puzzle.fromJson(
    jsonDecode(
      File('assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>,
  ),
  isReplay: true,
);

Rect artBounds(BoardLayout layout, BottlePose pose) {
  final r = layout.shape.visibleRect;
  final corners = [
    r.topLeft,
    r.topRight,
    r.bottomLeft,
    r.bottomRight,
  ].map(pose.transform);
  return Rect.fromLTRB(
    corners.map((p) => p.dx).reduce(math.min),
    corners.map((p) => p.dy).reduce(math.min),
    corners.map((p) => p.dx).reduce(math.max),
    corners.map((p) => p.dy).reduce(math.max),
  );
}

void main() {
  test('real Level4 lower bottle 3 stays full sized when pouring into upper 2', () {
    var before = mainPuzzle(4);
    // Legal core moves reproduce the player's exact board, without editing it.
    for (final move in [
      (0, 2),
      (1, 2),
      (1, 0),
      (1, 2),
      (0, 1),
      (1, 3),
      (2, 1),
      (0, 2),
    ]) {
      before = boardMove(before, move.$1, move.$2).after;
    }
    expect(before.board, [
      <String>[],
      ['G', 'G', 'G'],
      ['G'],
      ['O', 'O', 'O', 'O'],
    ]);
    final move = boardMove(before, 2, 1);
    final layout = BoardLayout(width: 370, count: 4, maxHeight: 580);
    final geometry = geometryFor(layout, move.motion, initialLift: 8);
    var smallest = 1.0;
    for (var ms = 0.0; ms <= geometry.totalMs; ms += 10) {
      final pose = geometry.frame(ms).source;
      final width =
          (pose.transform(layout.shape.imageRect.topRight) -
                  pose.transform(layout.shape.imageRect.topLeft))
              .distance;
      smallest = math.min(smallest, width / layout.shape.width);
    }
    expect(
      smallest,
      greaterThanOrEqualTo(.9),
      reason:
          'A pouring bottle must remain recognizably the same bottle, '
          'rather than becoming a miniature to satisfy the canvas bounds.',
    );
  });

  test(
    'real Level6 upper 2 to lower 4 restores bottles and fixed readouts',
    () {
      final move = boardMove(mainPuzzle(6), 1, 3);
      expect(move.motion.units, 2);
      final layout = BoardLayout(width: 370, count: 5, maxHeight: 580);
      final geometry = geometryFor(layout, move.motion);
      final finalFrame = BoardVisualFrame(
        state: move.after,
        layout: layout,
        motion: move.motion,
        elapsedMs: geometry.totalMs,
      );
      for (var i = 0; i < 5; i++) {
        expect(finalFrame.poses[i].mouth, layout.mouths[i]);
        expect(
          artBounds(layout, finalFrame.poses[i]).overlaps(layout.labelRect(i)),
          isFalse,
        );
      }
    },
  );

  test(
    'normal 4/6/7/8 bottle routes keep size, bounds and stationary captions',
    () {
      for (final count in [4, 6, 7, 8]) {
        for (final size in [(370.0, 580.0), (296.0, 380.0)]) {
          final layout = BoardLayout(
            width: size.$1,
            count: count,
            maxHeight: size.$2,
          );
          final captions = List.generate(count, layout.labelRect);
          final lower = layout.topRowCount;
          for (final route in [
            (0, 1),
            (lower, 1),
            (1, lower),
            (count - 1, 0),
          ]) {
            final geometry = PourGeometry(
              shape: layout.shape,
              sourceMouth: layout.mouths[route.$1],
              targetMouth: layout.mouths[route.$2],
              units: 4,
              sourceUnits: 4,
              initialLift: 8,
              bounds: layout.flightBounds,
            );
            for (var ms = 0.0; ms <= geometry.totalMs; ms += 15) {
              final f = geometry.frame(ms),
                  art = artBounds(layout, geometry.frame(ms).source);
              expect(
                f.source.scale,
                greaterThanOrEqualTo(.9),
                reason: '$count/${size.$1} $route at $ms becomes a miniature',
              );
              expect(art.left, greaterThanOrEqualTo(-.01));
              expect(
                art.top,
                greaterThanOrEqualTo(layout.flightBounds.top - .01),
              );
              expect(art.right, lessThanOrEqualTo(layout.width + .01));
              expect(art.bottom, lessThanOrEqualTo(layout.height + .01));
              // The approved short locked animation may pass in front of
              // captions. Resting geometry and readout positions never move.
            }
            expect(List.generate(count, layout.labelRect), captions);
          }
        }
      }
    },
  );

  test('only the source moves during the whole real 4–8 bottle pour', () {
    for (final count in [4, 5, 6, 7, 8]) {
      var before = mainPuzzle(
        count == 4
            ? 4
            : count == 5
            ? 6
            : count == 6
            ? 11
            : 21,
      );
      if (count == 8) before = before.grantExtraBottle();
      late (int, int) route;
      if (count == 4) {
        for (final move in [
          (0, 2),
          (1, 2),
          (1, 0),
          (1, 2),
          (0, 1),
          (1, 3),
          (2, 1),
          (0, 2),
        ]) {
          before = boardMove(before, move.$1, move.$2).after;
        }
        route = (2, 1);
      } else if (count == 5) {
        route = (1, 3);
      } else {
        final upper = count == 6 ? 3 : 4;
        for (final move in before.puzzle.referenceMoves) {
          if (move.from >= upper && move.to < upper) {
            route = (move.from, move.to);
            break;
          }
          before = boardMove(before, move.from, move.to).after;
        }
      }
      final moved = boardMove(before, route.$1, route.$2);
      final layout = BoardLayout(width: 370, count: count, maxHeight: 580);
      final geometry = geometryFor(layout, moved.motion);
      for (var ms = 0.0; ms <= geometry.totalMs; ms += 10) {
        final frame = BoardVisualFrame(
          state: moved.after,
          layout: layout,
          motion: moved.motion,
          elapsedMs: ms,
        );
        for (var i = 0; i < count; i++) {
          if (i == route.$1) continue;
          expect(
            frame.poses[i].mouth,
            layout.mouths[i],
            reason: '$count bottles, stationary $i at $ms ms must not sink',
          );
          expect(frame.poses[i].angle, 0);
          expect(frame.poses[i].scale, 1);
        }
      }
    }
  });
}
