import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';
import 'package:pourlune_dev/presentation/reference_extra_art.dart';

void main() {
  testWidgets(
    'neutral cuffs preserve the original shoulder knit and clear glass material',
    (t) async {
      final art = (await t.runAsync(BottleArt.load))!;
      try {
        Future<ByteData> render(String? target) async {
          final recorder = ui.PictureRecorder();
          FlameBoardPainter(art).paintBottle(
            Canvas(recorder),
            0,
            const BottlePose(Offset(60, 35), 0),
            [],
            const BottleShape(100),
            const PlayerSettings(),
            fixedTarget: target,
            highlighted: false,
          );
          final picture = recorder.endRecording();
          final image = (await t.runAsync(() => picture.toImage(120, 230)))!;
          final bytes = (await t.runAsync<ByteData?>(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          image.dispose();
          picture.dispose();
          return bytes;
        }

        final original = await render('O'), neutral = await render(null);
        var materialPixels = 0;
        for (var y = 75; y < 145; y++) {
          for (final x in [
            for (var x = 12; x < 24; x++) x,
            for (var x = 96; x < 108; x++) x,
          ]) {
            final i = (y * 120 + x) * 4;
            if (original.getUint8(i + 3) > 200) {
              materialPixels++;
            }
            for (var c = 0; c < 4; c++) {
              expect(
                neutral.getUint8(i + c),
                original.getUint8(i + c),
                reason: 'A rim correction must not bleach the shoulders.',
              );
            }
          }
        }
        expect(materialPixels, greaterThan(100));
      } finally {
        art.dispose();
      }
    },
  );
  testWidgets(
    'extra bottle illustration has neutral knit and retains its blue +1 badge',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: Key('extra-pixels'),
              child: SizedBox(
                width: 201,
                height: 234,
                child: ExtraBottleHero(),
              ),
            ),
          ),
        ),
      );
      await t.runAsync(
        () => precacheImage(
          const AssetImage('assets/art/p05-reference/reference-extra.png'),
          t.element(find.byType(ExtraBottleHero)),
        ),
      );
      await t.pumpAndSettle();
      late ui.Image image;
      late ByteData bytes;
      for (var attempt = 0; attempt < 100; attempt++) {
        image = (await t.runAsync(
          () => t
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('extra-pixels')),
              )
              .toImage(),
        ))!;
        bytes = (await t.runAsync<ByteData?>(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        if (bytes.getUint8((22 * image.width + 75) * 4 + 3) > 200) break;
        if (attempt < 99) {
          image.dispose();
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await t.pumpAndSettle();
        }
      }
      Color color(int x, int y) {
        final i = (y * image.width + x) * 4;
        return Color.fromARGB(
          255,
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      }

      expect(HSVColor.fromColor(color(75, 22)).saturation, lessThan(.23));
      final evidenceDir = Platform.environment['POURLUNE_EVIDENCE_DIR'];
      if (evidenceDir != null) {
        final png = (await t.runAsync<ByteData?>(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        ))!;
        Directory(evidenceDir).createSync(recursive: true);
        File('$evidenceDir/neutral-extra-hero.png')
            .writeAsBytesSync(png.buffer.asUint8List());
      }
      expect(
        bytes.getUint8((22 * image.width + 75) * 4 + 3),
        greaterThan(200),
        reason: 'The actual bottle art must finish loading.',
      );
      var orangePixels = 0;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i + 3) > 150 &&
            bytes.getUint8(i) > bytes.getUint8(i + 1) + 45 &&
            bytes.getUint8(i + 1) > bytes.getUint8(i + 2) + 25) {
          orangePixels++;
        }
      }
      expect(
        orangePixels,
        lessThan(4),
        reason: 'No orange rim fragments may remain on a buffer illustration.',
      );
      var bluePixels = 0;
      for (var y = 155; y < 220; y++) {
        for (var x = 145; x < 200; x++) {
          final hsv = HSVColor.fromColor(color(x, y));
          if (hsv.hue >= 195 && hsv.hue <= 250 && hsv.saturation > .5) {
            bluePixels++;
          }
        }
      }
      expect(
        bluePixels,
        greaterThan(300),
        reason: 'Keep the actual blue badge; a white +1 glyph is not a blue sample.',
      );
      image.dispose();
    },
  );
  testWidgets(
    'fixed targets determine knit identity even for filled buffers and empty targets',
    (t) async {
      final art = (await t.runAsync(BottleArt.load))!;
      try {
        final data = Puzzle.parse(
          File('assets/puzzles/main/main-012.json').readAsStringSync(),
        ).toJson();
        data['target_labels'] = [null, 'G', 'P', 'B', 'O', null];
        final originalBoard = data['initial_bottom_to_top'] as List;
        data['initial_bottom_to_top'] = [
          originalBoard[4],
          originalBoard[1],
          originalBoard[2],
          originalBoard[3],
          originalBoard[0],
          originalBoard[5],
        ];
        final puzzle = Puzzle.fromJson(data);
        final initial = GameInstance.create(
          id: 'fixed-material',
          puzzle: puzzle,
        );
        final state = GameInstance.fromJson(
          initial.toJson()
            ..['board'] = originalBoard
            ..['board_revision'] = 1,
        ).grantExtraBottle();
        final layout = BoardLayout(width: 416, count: 7, maxHeight: 600);
        final recorder = ui.PictureRecorder();
        FlameBoardPainter(art).paint(
          Canvas(recorder),
          BoardVisualFrame(state: state, layout: layout),
          const PlayerSettings(),
          press: List.filled(7, 0),
        );
        final picture = recorder.endRecording();
        final image = (await t.runAsync(
          () => picture.toImage(416, layout.height.ceil()),
        ))!;
        final pixels = (await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        for (final index in [0, 4, 5, 6]) {
          final center =
              layout.mouths[index] + Offset(0, -layout.shape.height * .055);
          var red = 0.0, green = 0.0, blue = 0.0, count = 0;
          for (var y = center.dy.floor() - 2; y <= center.dy.floor() + 2; y++) {
            for (
              var x = center.dx.floor() - 9;
              x <= center.dx.floor() + 9;
              x++
            ) {
              final offset = (y * 416 + x) * 4;
              if (pixels.getUint8(offset + 3) < 150) continue;
              red += pixels.getUint8(offset);
              green += pixels.getUint8(offset + 1);
              blue += pixels.getUint8(offset + 2);
              count++;
            }
          }
          expect(count, greaterThan(30));
          final color = Color.fromARGB(
            255,
            (red / count).round(),
            (green / count).round(),
            (blue / count).round(),
          );
          final hsv = HSVColor.fromColor(color);
          if (index == 4) {
            expect(
              hsv.hue,
              inInclusiveRange(10, 50),
              reason: 'An empty O target retains its orange cuff, even at buffer-like index 4.',
            );
            expect(hsv.saturation, greaterThan(.5));
          } else {
            expect(
              hsv.saturation,
              lessThan(.23),
              reason:
                  'Null target $index is warm neutral regardless of contents or index.',
            );
            expect(hsv.value, greaterThan(.65));
            expect(color.r, greaterThanOrEqualTo(color.b));
            var orangeFragments = 0;
            final interior = Path()..addPolygon(layout.shape.interior, true);
            final mouth = layout.mouths[index];
            final bounds = layout.shape.imageRect.shift(mouth);
            for (var y = bounds.top.ceil(); y < bounds.bottom.floor(); y++) {
              for (var x = bounds.left.ceil(); x < bounds.right.floor(); x++) {
                if (interior.contains(Offset(x + .5, y + .5) - mouth)) continue;
                final i = (y * 416 + x) * 4;
                if (pixels.getUint8(i + 3) > 150 &&
                    pixels.getUint8(i) > pixels.getUint8(i + 1) + 45 &&
                    pixels.getUint8(i + 1) > pixels.getUint8(i + 2) + 25) {
                  orangeFragments++;
                }
              }
            }
            expect(
              orangeFragments,
              0,
              reason: 'All knitted exterior pixels must be neutral, including base joins.',
            );
          }
        }
        image.dispose();
        picture.dispose();
      } finally {
        art.dispose();
      }
    },
  );
}
