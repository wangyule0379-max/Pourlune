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
              targetDrop: layout.receivingDrop(route.$2),
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
              expect(art.top, greaterThanOrEqualTo(-.01));
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

  test(
    'upper receivers make local room without resizing the resting board',
    () {
      final before = mainPuzzle(4);
      // Reproduce the player's one-unit pour into the upper receiver.
      var state = before;
      for (final route in [
        (0, 2),
        (1, 2),
        (1, 0),
        (1, 2),
        (0, 1),
        (1, 3),
        (2, 1),
        (0, 2),
      ]) {
        state = boardMove(state, route.$1, route.$2).after;
      }
      final actual = boardMove(state, 2, 1);
      final layout = BoardLayout(width: 358, count: 4, maxHeight: 470);
      final g = geometryFor(layout, actual.motion);
      expect(layout.shape.width, greaterThanOrEqualTo(78));
      expect(actual.motion.units, 1);
      for (var ms = 0.0; ms <= g.totalMs; ms += 10) {
        final frame = BoardVisualFrame(
          state: actual.after,
          layout: layout,
          motion: actual.motion,
          elapsedMs: ms,
        );
        for (final pose in frame.poses) {
          final art = artBounds(layout, pose);
          expect(art.top, greaterThanOrEqualTo(-.01));
          expect(art.bottom, lessThanOrEqualTo(layout.height + .01));
        }
      }
      final end = BoardVisualFrame(
        state: actual.after,
        layout: layout,
        motion: actual.motion,
        elapsedMs: g.totalMs,
      );
      for (var i = 0; i < 4; i++) {
        expect(end.poses[i].mouth, layout.mouths[i]);
      }
    },
  );
}
