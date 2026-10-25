import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

void main() {
  for (final lift in [0.0, 9.0]) {
    for (final ms in [75.0, 90.0]) {
      testWidgets(
        'actual source paint avoids motion readouts at ${ms}ms with lift $lift',
        (t) async {
          final art = (await t.runAsync(BottleArt.load))!;
          try {
            final layout = BoardLayout(width: 288, count: 4);
            final g = PourGeometry(
              shape: layout.shape,
              sourceMouth: layout.mouths[0],
              targetMouth: layout.mouths[2],
              units: 1,
              sourceUnits: 4,
              initialLift: lift,
              bounds: layout.flightBounds,
            );
            final frame = g.frame(ms);
            final recorder = ui.PictureRecorder();
            FlameBoardPainter(art).paintBottle(
              Canvas(recorder),
              0,
              frame.source,
              [(color: 'O', units: 4.0)],
              layout.shape,
              const PlayerSettings(),
              highlighted: false,
            );
            final picture = recorder.endRecording();
            final image = (await t.runAsync(
              () => picture.toImage(
                layout.width.ceil(),
                (layout.height + 160).ceil(),
              ),
            ))!;
            final bytes = (await t.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final png = (await t.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.png),
            ))!;
            final evidenceDir = Platform.environment['POURLUNE_EVIDENCE_DIR'];
            if (evidenceDir != null) {
              File(
                '$evidenceDir/flight-${ms.toInt()}ms-source-lift${lift.toInt()}.png',
              ).writeAsBytesSync(png.buffer.asUint8List());
            }
            // User-approved relocation: static captions are absent during flight.
            // Test raw material beyond the canvas, without clipping it away.
            final rect = Rect.fromLTWH(0, layout.height, layout.width, 160);
            final oldCaption = layout.labelRect(0);
            var quietCaptionInk = 0;
            for (
              var y = oldCaption.top.ceil();
              y < oldCaption.bottom.floor();
              y++
            ) {
              for (
                var x = oldCaption.left.ceil();
                x < oldCaption.right.floor();
                x++
              ) {
                if (bytes.getUint8((y * layout.width.ceil() + x) * 4 + 3) >
                    16) {
                  quietCaptionInk++;
                }
              }
            }
            var opaque = 0;
            for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
              for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
                if (bytes.getUint8((y * layout.width.ceil() + x) * 4 + 3) >
                    16) {
                  opaque++;
                }
              }
            }
            image.dispose();
            picture.dispose();
            debugPrint(
              'lift$lift motionReadouts=$rect paintedPixels=$opaque oldQuietCaptionInk=$quietCaptionInk pose=${frame.source.mouth}/${frame.source.angle}/${frame.source.scale}',
            );
            expect(
              opaque,
              0,
              reason: 'Raw source material must stay clear of the actual motion readout band; no clipping masks this check.',
            );
          } finally {
            art.dispose();
          }
        },
      );
    }
  }
}
