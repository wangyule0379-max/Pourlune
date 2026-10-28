import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

void main() {
  test('static board geometry stays equal to published build18', () {
    final reference = jsonDecode(
      File('test/fixtures/build18_board_geometry.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(reference['source'], 'ea2bdee853559ddaa66e44e35fce7bac34a40d29');
    for (final entry in reference['cases'] as List<dynamic>) {
      final c = entry as Map<String, dynamic>;
      final layout = BoardLayout(
        width: (c['width'] as num).toDouble(),
        count: c['count'] as int,
        maxHeight: (c['maxHeight'] as num).toDouble(),
      );
      void same(double actual, dynamic expected) => expect(
        actual,
        closeTo((expected as num).toDouble(), 1e-9),
        reason: '${c['count']} bottles at ${c['width']}x${c['maxHeight']}',
      );
      same(layout.shape.width, c['shapeWidth']);
      same(layout.shape.height, c['shapeHeight']);
      same(layout.height, c['height']);
      same(layout.labelHeight, c['labelHeight']);
      for (var i = 0; i < layout.count; i++) {
        final cell = layout.cells[i],
            label = layout.labelRect(i),
            mouth = layout.mouths[i];
        for (final pair in [(cell, c['cells'][i]), (label, c['labels'][i])]) {
          final values = [
            pair.$1.left,
            pair.$1.top,
            pair.$1.right,
            pair.$1.bottom,
          ];
          for (var j = 0; j < 4; j++) {
            same(values[j], pair.$2[j]);
          }
        }
        same(mouth.dx, c['mouths'][i][0]);
        same(mouth.dy, c['mouths'][i][1]);
      }
    }
  });
}
