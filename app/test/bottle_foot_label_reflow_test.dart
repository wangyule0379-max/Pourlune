import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/bottle_foot_label.dart';

void main() {
  for (final scale in [1.0, 3.1176470588235294, 3.2]) {
    testWidgets('bottle labels retain full type inside each cell at $scale', (
      t,
    ) async {
      for (final target in <String?>['O', null]) {
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Center(
                child: SizedBox(
                  width: 83.75,
                  height:
                      (12 * scale + 12).clamp(34, double.infinity) +
                      3 +
                      14 * 1.2 * scale +
                      1,
                  child: BottleFootLabel(
                    index: 6,
                    target: target,
                    count: 4,
                    prefix: 'test',
                    symbolsEnabled: true,
                    strongContrast: false,
                  ),
                ),
              ),
            ),
          ),
        );
        final label = t.getRect(find.byType(BottleFootLabel));
        for (final value in ['7', '4/4']) {
          final f = find.text(value), rect = t.getRect(f);
          final text = t.widget<Text>(f);
          final paragraph = t.renderObject<RenderParagraph>(f);
          expect(
            paragraph.textScaler.scale(text.style!.fontSize!),
            closeTo(text.style!.fontSize! * scale, .001),
          );
          expect(rect.left, greaterThanOrEqualTo(label.left - .01));
          expect(rect.right, lessThanOrEqualTo(label.right + .01));
          expect(rect.bottom, lessThanOrEqualTo(label.bottom + .01));
        }
        if (scale > 3) {
          expect(
            t.getRect(find.text('7')).bottom,
            lessThanOrEqualTo(t.getRect(find.text('4/4')).top),
          );
          final targetFinder = find.byKey(const Key('test-target-6'));
          if (target == null) {
            expect(targetFinder, findsNothing);
          } else {
            final badge = t.getRect(targetFinder);
            expect(
              t.getRect(find.text('7')).right,
              lessThanOrEqualTo(badge.left),
            );
            expect(badge.right, lessThanOrEqualTo(label.right + .01));
            expect(
              badge.bottom,
              lessThanOrEqualTo(t.getRect(find.text('4/4')).top),
            );
          }
        }
        expect(t.takeException(), isNull);
      }
    });
  }
}
