import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';

import 'support/flame_board_support.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

void main() {
  test('integer capacity counters use one rounded visual transfer and conserve both ends', () {
    for (final c in [
      (out: 0.0, arrived: 0.0, source: 4, target: 0),
      (out: .8, arrived: .4, source: 3, target: 1),
      (out: 1.4, arrived: 1.1, source: 3, target: 1),
      (out: 2.3, arrived: 2.0, source: 2, target: 2),
      (out: 4.0, arrived: 4.0, source: 0, target: 4),
    ]) {
      final value = transferCounts(
        sourceBefore: 4,
        targetBefore: 0,
        out: c.out,
        arrived: c.arrived,
      );
      expect(value.source, c.source);
      expect(value.target, c.target);
      expect(value.source + value.target, 4);
    }
    expect(
      transferCounts(sourceBefore: 3, targetBefore: 2, out: 2, arrived: 2),
      (source: 1, target: 4),
    );
  });
  test('4–7 bottles preserve equal sizes, accessible cells and two-row content at narrow 2x text', () {
    for (var count = 4; count <= 7; count++) {
      for (final width in [288.0, 338.0, 768.0]) {
        final layout = BoardLayout(width: width, count: count, textScale: 2);
        expect(layout.mouths.length, count);
        for (final cell in layout.cells) {
          expect(cell.width, closeTo(layout.cells.first.width, .00001));
        }
        for (final rect in layout.cells) {
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width + .001));
          expect(rect.bottom, lessThanOrEqualTo(layout.height));
        }
        expect(layout.mouths.last.dy, greaterThan(layout.mouths.first.dy));
      }
    }
  });
  test('every edge/cross-row trajectory stays in the canvas and shares a vertical lip-aligned stream', () {
    for (final width in [288.0, 338.0, 370.0, 379.42857142857144, 768.0]) {
      final layout = BoardLayout(width: width, count: 7, textScale: 2);
      for (var from = 0; from < 7; from++) {
        for (var to = 0; to < 7; to++) {
          if (from == to) continue;
          for (final units in [1, 2, 4]) {
            final g = PourGeometry(
              shape: layout.shape,
              sourceMouth: layout.mouths[from],
              targetMouth: layout.mouths[to],
              units: units,
              sourceUnits: 4,
              bounds: Rect.fromLTWH(0, 0, width, layout.height),
            );
            for (var ms = 0.0; ms <= g.totalMs; ms += 15) {
              final f = g.frame(ms);
              final corners = [
                layout.shape.visibleRect.topLeft,
                layout.shape.visibleRect.topRight,
                layout.shape.visibleRect.bottomLeft,
                layout.shape.visibleRect.bottomRight,
              ].map(f.source.transform);
              for (final p in corners) {
                expect(
                  p.dx,
                  inInclusiveRange(-.01, width + .01),
                  reason: '$from→$to at $ms',
                );
                expect(p.dy, inInclusiveRange(-.01, layout.height + .01));
              }
              expect(4 - f.out + f.delivered + f.inStream, closeTo(4, .00001));
              if (f.inStream > .00001) {
                expect(
                  (f.streamStart.dx - f.streamEnd.dx).abs(),
                  lessThan(.001),
                );
                expect(f.streamStart.dy, lessThan(f.streamEnd.dy));
              }
            }
            expect(
              g.frame(g.totalMs).source.angle,
              closeTo(0, math.pi / 10000),
            );
          }
        }
      }
    }
  });

  test('compact large-text board fits both rows while keeping 48px bottle touch cells', () {
    for (var count = 4; count <= 7; count++) {
      final layout = BoardLayout(
        width: 296,
        count: count,
        textScale: 2,
        maxHeight: 284,
        footLabels: false,
      );
      expect(layout.height, lessThanOrEqualTo(284.01));
      for (final cell in layout.cells) {
        expect(cell.width, greaterThanOrEqualTo(48));
        expect(cell.height, greaterThanOrEqualTo(48));
      }
    }
  });

  test('all 4–7 bottle flights avoid the independent motion readout band', () {
    for (var count = 4; count <= 7; count++) {
      for (final width in [288.0, 370.0, 768.0]) {
        for (final scale in [1.0, 2.0]) {
          final layout = BoardLayout(
            width: width,
            count: count,
            textScale: scale,
          );
          for (var from = 0; from < count; from++) {
            for (var to = 0; to < count; to++) {
              if (from == to) continue;
              for (final units in [1, 2, 4]) {
                final before = [
                  for (var n = 0; n < count; n++)
                    n == to ? <String>[] : List.filled(4, 'O'),
                ];
                final after = [
                  for (var n = 0; n < count; n++)
                    n == from
                        ? List.filled(4 - units, 'O')
                        : n == to
                        ? List.filled(units, 'O')
                        : before[n],
                ];
                final motion = PourMotion(
                  token: 1,
                  from: from,
                  to: to,
                  units: units,
                  before: before,
                  after: after,
                  instanceId: 'geometry',
                  revision: 1,
                  reducedMotion: false,
                );
                final g = geometryFor(layout, motion, initialLift: 9);
                for (var ms = 0.0; ms <= g.totalMs; ms += 15) {
                  final f = g.frame(ms);
                  final art = layout.shape.worldOutline(f.source);
                  // Quiet captions leave this canvas during flight. The real
                  // widget test also verifies every readout is below it.
                  final readouts = Rect.fromLTWH(0, layout.height, width, 160);
                  {
                    expect(
                      Path.combine(
                        PathOperation.intersect,
                        art,
                        Path()..addRect(readouts),
                      ).computeMetrics().isNotEmpty,
                      isFalse,
                      reason:
                          '$count $width scale$scale $from→$to units$units at$ms independent motion readouts, actual silhouette',
                    );
                    if (f.inStream > .00001) {
                      expect(
                        Rect.fromPoints(
                          f.streamStart,
                          f.streamEnd,
                        ).inflate(2).overlaps(readouts),
                        isFalse,
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  });

  test('archived main9 partial top-run transfer respects one-unit capacity at every presentation frame', () {
    final puzzle = Puzzle.fromJson(
      // Keep this exact one-unit-capacity regression after the authored v2
      // library replaces main9; old saved instances still use this definition.
      jsonDecode(
        File(
          '../docs/development/evidence/main60-content-redesign/old-main/main-009.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final initial = GameInstance.create(
      id: 'formal-partial',
      puzzle: puzzle,
      isReplay: true,
    );
    final before = initial.pour(2, 4).state;
    final move = boardMove(before, 3, 2);
    expect(before.board[3], ['B', 'B', 'P', 'P']);
    expect(before.board[2], ['G', 'P', 'P']);
    expect(move.motion.units, 1);
    expect(move.after.board[3], ['B', 'B', 'P']);
    expect(move.after.board[2], ['G', 'P', 'P', 'P']);
    final layout = BoardLayout(width: 288, count: 6);
    final duration = geometryFor(layout, move.motion).totalMs;
    for (var ms = 0.0; ms <= duration; ms += 10) {
      final frame = BoardVisualFrame(
        state: move.after,
        layout: layout,
        motion: move.motion,
        elapsedMs: ms,
      );
      expect(frame.counts[2] + frame.counts[3], 7);
      expect(frame.counts[2], inInclusiveRange(3, 4));
      expect(frame.counts[3], inInclusiveRange(3, 4));
      if (ms < 290) {
        expect(
          frame.contents,
          before.board,
          reason: 'SQLite after state cannot jump ahead of flow',
        );
      }
      final liquid = frame.bands
          .expand((b) => b)
          .fold(0.0, (n, b) => n + b.units);
      expect(liquid + frame.pour!.inStream, closeTo(16, .00001));
    }
    final done = BoardVisualFrame(
      state: move.after,
      layout: layout,
      motion: move.motion,
      elapsedMs: duration,
    );
    expect(done.contents, move.after.board);
    expect(before.moveCount, 1);
    expect(move.after.moveCount, 2);
  });
}
