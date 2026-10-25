import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/presentation/flame_board/frame.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';

void main() {
  testWidgets(
    'all seven capacity regions keep identical pixels when added glow is painted',
    (t) async {
      final art = (await t.runAsync(BottleArt.load))!;
      try {
        final puzzle = Puzzle.parse(
          (await t.runAsync(
            () => rootBundle.loadString('assets/puzzles/main/main-012.json'),
          ))!,
        );
        final state = GameInstance.create(
          id: 'glow-labels',
          puzzle: puzzle,
        ).grantExtraBottle();
        final layout = BoardLayout(width: 408, count: 7, maxHeight: 640);
        Future<ByteData> paint(bool added) async {
          final recorder = ui.PictureRecorder();
          FlameBoardPainter(art).paint(
            Canvas(recorder),
            BoardVisualFrame(state: state, layout: layout),
            const PlayerSettings(),
            press: List.filled(7, 0),
            addedBottle: added ? 6 : null,
          );
          final picture = recorder.endRecording();
          final image = (await t.runAsync(
            () => picture.toImage(408, layout.height.ceil()),
          ))!;
          final bytes = (await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          image.dispose();
          picture.dispose();
          return bytes;
        }

        final plain = await paint(false), glowing = await paint(true);
        var changedOutside = 0;
        for (var i = 0; i < plain.lengthInBytes; i++) {
          if (plain.getUint8(i) != glowing.getUint8(i)) changedOutside++;
        }
        expect(changedOutside, greaterThan(150));
        for (var label = 0; label < 7; label++) {
          final rect = layout.labelRect(label);
          var changed = 0;
          for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
            for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
              final i = (y * 408 + x) * 4;
              for (var channel = 0; channel < 4; channel++) {
                if (plain.getUint8(i + channel) !=
                    glowing.getUint8(i + channel)) {
                  changed++;
                }
              }
            }
          }
          expect(
            changed,
            0,
            reason: 'Decorative light cannot alter label $label pixels.',
          );
        }
      } finally {
        art.dispose();
      }
    },
  );
  testWidgets(
    'saved added-bottle glow is warm and distinct from cyan selection',
    (t) async {
      final art = (await t.runAsync(BottleArt.load))!;
      try {
        Future<int> warmPixels({
          bool added = false,
          bool selected = false,
        }) async {
          final recorder = ui.PictureRecorder();
          FlameBoardPainter(art).paintBottle(
            Canvas(recorder),
            2,
            const BottlePose(Offset(75, 42), 0),
            [],
            const BottleShape(100),
            const PlayerSettings(),
            highlighted: selected,
            added: added,
          );
          final picture = recorder.endRecording();
          final image = (await t.runAsync(() => picture.toImage(150, 245)))!;
          final bytes = (await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          var warm = 0;
          for (var y = 0; y < 245; y++) {
            for (var x = 0; x < 150; x++) {
              if (x > 30 && x < 120 && y > 30 && y < 222) continue;
              final i = (y * 150 + x) * 4;
              if (bytes.getUint8(i + 3) > 40 &&
                  bytes.getUint8(i) > 210 &&
                  bytes.getUint8(i + 1) > 180 &&
                  bytes.getUint8(i + 2) < 150) {
                warm++;
              }
            }
          }
          image.dispose();
          picture.dispose();
          return warm;
        }

        final normal = await warmPixels(),
            selected = await warmPixels(selected: true),
            added = await warmPixels(added: true);
        expect(added - normal, greaterThan(150));
        expect(selected - normal, lessThan(10));
      } finally {
        art.dispose();
      }
    },
  );
}
