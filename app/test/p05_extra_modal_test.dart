import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/extra_bottle_modal.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('extra modal keeps real actions and close visible at $scale', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => t.binding.setSurfaceSize(null));
      var accepted = 0, cancelled = 0;
      await t.runAsync(
        () =>
            (FontLoader('Nunito')..addFont(
                  rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'),
                ))
                .load(),
      );
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(375, 667),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              backgroundColor: const Color(0xff72d9ef),
              body: RepaintBoundary(
                key: const Key('capture'),
                child: ExtraBottleModal(
                  title: 'A little more room',
                  body: 'Watch an ad to add one empty bottle to this puzzle.\nOne extra bottle per puzzle.',
                  primaryLabel: 'Watch ad',
                  secondaryLabel: 'Not now',
                  closeLabel: 'Close',
                  onPrimary: () => accepted++,
                  onSecondary: () => cancelled++,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.runAsync(
        () => precacheImage(
          const AssetImage('assets/art/p05-reference/reference-extra.png'),
          t.element(find.byType(ExtraBottleModal)),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      for (final key in ['watch-ad', 'extra-secondary', 'extra-close']) {
        final rect = t.getRect(find.byKey(Key(key)));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(667));
      }
      expect(t.takeException(), isNull);
      final evidenceDir = Platform.environment['POURLUNE_EVIDENCE_DIR'];
      if (scale == 1 && evidenceDir != null) {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('capture')),
        );
        final image = (await t.runAsync(
          () => boundary.toImage(pixelRatio: 2),
        ))!;
        final data = await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        File('$evidenceDir/modal-host.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      }
      await t.tap(find.byKey(const Key('watch-ad')));
      expect(accepted, 1);
      await t.tap(find.byKey(const Key('extra-close')));
      expect(cancelled, 1);
    });
  }
}
