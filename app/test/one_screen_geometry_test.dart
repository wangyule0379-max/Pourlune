import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

void main() {
  test(
    'LY-R03 readonly 4–7 previews retain equal bottles and labels in one row',
    () {
      for (final width in [296.0, 351.0, 406.0]) {
        for (final scale in [1.0, 1.3]) {
          for (var count = 4; count <= 7; count++) {
            final board = BoardLayout(
              width: width,
              count: count,
              textScale: scale,
              maxHeight: 140,
              preview: true,
            );
            expect(board.shape.width, greaterThanOrEqualTo(32));
            expect(board.height, lessThanOrEqualTo(140));
            for (var i = 0; i < count; i++) {
              expect(board.cells[i].top, board.cells.first.top);
              expect(
                board.cells[i].width,
                closeTo(board.cells.first.width, 1e-9),
              );
              expect(
                board.cells[i].height,
                closeTo(board.cells.first.height, 1e-9),
              );
              expect(board.cells[i].left, greaterThanOrEqualTo(0));
              expect(board.cells[i].right, lessThanOrEqualTo(width + .001));
              expect(
                board.labelRect(i).bottom,
                lessThanOrEqualTo(board.cells[i].top),
              );
              if (i > 0) {
                expect(board.cells[i].overlaps(board.cells[i - 1]), isFalse);
              }
            }
          }
        }
      }
    },
  );
  test('LY02 bounded 4–7 board has disjoint hits and every flight avoids labels', () {
    for (final width in [296.0, 351.0, 406.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final available in [305.0, 380.0, 480.0]) {
          for (var count = 4; count <= 7; count++) {
            final layout = BoardLayout(
              width: width,
              maxHeight: available,
              count: count,
              textScale: scale,
            );
            for (final cell in layout.cells) {
              expect(cell.width, closeTo(layout.cells.first.width, .00001));
              expect(cell.height, closeTo(layout.cells.first.height, .00001));
            }
            for (var i = 0; i < count; i++) {
              expect(layout.cells[i].width, greaterThanOrEqualTo(48));
              expect(layout.cells[i].height, greaterThanOrEqualTo(48));
              for (var j = i + 1; j < count; j++) {
                expect(layout.cells[i].overlaps(layout.cells[j]), isFalse);
              }
            }
            for (var from = 0; from < count; from++) {
              for (var to = 0; to < count; to++) {
                if (from == to) continue;
                for (final units in [1, 2, 4]) {
                  final g = PourGeometry(
                    shape: layout.shape,
                    sourceMouth: layout.mouths[from],
                    targetMouth: layout.mouths[to],
                    units: units,
                    sourceUnits: 4,
                    initialLift: 9,
                    bounds: layout.flightBounds,
                  );
                  for (var ms = 0.0; ms <= g.totalMs; ms += 15) {
                    final f = g.frame(ms);
                    final corners = [
                      layout.shape.imageRect.topLeft,
                      layout.shape.imageRect.topRight,
                      layout.shape.imageRect.bottomLeft,
                      layout.shape.imageRect.bottomRight,
                    ].map(f.source.transform).toList();
                    final art = Rect.fromLTRB(
                      corners.map((p) => p.dx).reduce(math.min),
                      corners.map((p) => p.dy).reduce(math.min),
                      corners.map((p) => p.dx).reduce(math.max),
                      corners.map((p) => p.dy).reduce(math.max),
                    );
                    expect(art.left, greaterThanOrEqualTo(-.01));
                    expect(art.right, lessThanOrEqualTo(width + .01));
                    expect(art.top, greaterThanOrEqualTo(-.01));
                    expect(art.bottom, lessThanOrEqualTo(layout.height + .01));
                    for (var i = 0; i < count; i++) {
                      expect(
                        art.overlaps(layout.labelRect(i)),
                        isFalse,
                        reason:
                            '$width/$scale/$available/$count $from->$to units$units ms$ms label$i',
                      );
                      if (f.inStream > .00001) {
                        expect(
                          Rect.fromPoints(
                            f.streamStart,
                            f.streamEnd,
                          ).inflate(2).overlaps(layout.labelRect(i)),
                          isFalse,
                        );
                      }
                    }
                    expect(
                      4 - f.out + f.delivered + f.inStream,
                      closeTo(4, .00001),
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
  });
}
