import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/paint.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  for (final level in [4, 6]) {
    testWidgets(
      'real level$level source uses screen paint space with build18 static layout',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(402, 874);
        t.view.padding = const FakeViewPadding(top: 62, bottom: 34);
        t.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
        addTearDown(t.view.reset);
        final puzzle = Puzzle.fromJson(
          jsonDecode(
            File(
              'assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json',
            ).readAsStringSync(),
          ) as Map<String, dynamic>,
        );
        var state = GameInstance.create(id: 'r03-main-$level', puzzle: puzzle);
        if (level == 4) {
          for (final m in [
            (0, 2),
            (1, 2),
            (1, 0),
            (1, 2),
            (0, 1),
            (1, 3),
            (2, 1),
            (0, 2),
          ]) {
            state = state.pour(m.$1, m.$2).state;
          }
        }
        final dir = Directory.systemTemp.createTempSync('r03-source-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final c = GameController(
          store,
          library: ContentLibrary(main: {level: puzzle}),
        );
        const root = Key('source-full-page');
        try {
          await t.runAsync(() async {
            await store.saveSettings(
              const PlayerSettings(music: false, sound: false, haptics: false),
            );
            await store.save(state);
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          await t.pumpWidget(
            RepaintBoundary(
              key: root,
              child: PourluneApp(controller: c),
            ),
          );
          await t.pumpAndSettle();
          await settleFlameBoard(t, c);
          final game = t
              .widget<GameWidget<FlameBoardGame>>(
                find.byType(GameWidget<FlameBoardGame>),
              )
              .game!;
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(root),
          );
          final board = t.getRect(find.byKey(const Key('dock-canvas')));
          final staticRects = {
            for (final key in [
              'home',
              'pause',
              'undo',
              'hint',
              'extra-bottle',
              for (var i = 0; i < state.board.length; i++) 'bottle-$i',
            ])
              key: t.getRect(find.byKey(Key(key))),
          };
          final titleRects = [
            t.getRect(find.byKey(const Key('home'))),
            t.getRect(find.byKey(const Key('pause'))),
            t.getRect(find.text('Level $level')),
          ];
          final feedback = t.getRect(find.byKey(const Key('feedback-title')));
          final initial = (await t.runAsync(
            () => boundary.toImage(pixelRatio: 1),
          ))!;
          final before = (await t.runAsync(
            () => initial.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          final from = level == 4 ? 2 : 1, to = level == 4 ? 1 : 3;
          await t.runAsync(() => c.tapBottle(from));
          await t.pumpAndSettle();
          await t.runAsync(() => c.tapBottle(to));
          await t.pump();
          game.pauseEngine();
          var previous = 0.0;
          for (final ms in [120.0, 400.0, 700.0, 840.0]) {
            game.update((ms - previous) / 1000);
            game.stepEngine(stepTime: 0);
            await t.pump();
            previous = ms;
            final frame = game.frame;
            expect(t.getRect(find.byKey(const Key('dock-canvas'))), board);
            for (final entry in staticRects.entries) {
              expect(
                t.getRect(find.byKey(Key(entry.key))),
                entry.value,
                reason:
                    'Published static controls must not move during pouring.',
              );
            }
            expect(frame.poses[from].scale, greaterThanOrEqualTo(.9));
            for (var i = 0; i < frame.poses.length; i++) {
              if (i != from) {
                expect(frame.poses[i].mouth, frame.layout.mouths[i]);
              }
            }
            final actual = (await t.runAsync(
              () => boundary.toImage(pixelRatio: 1),
            ))!;
            final bytes = (await t.runAsync(
              () => actual.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder)..translate(board.left, board.top);
            FlameBoardPainter(game.art!).paintBottle(
              canvas,
              from,
              frame.poses[from],
              frame.bands[from],
              frame.layout.shape,
              c.settings,
              highlighted: false,
              fixedTarget: from < puzzle.targets.length
                  ? puzzle.targets[from]
                  : null,
            );
            final picture = recorder.endRecording();
            final ref = (await t.runAsync(() => picture.toImage(402, 874)))!;
            final expected = (await t.runAsync(
              () => ref.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            var outside = 0,
                mismatched = 0,
                headerInkChanged = 0,
                feedbackInkChanged = 0;
            for (var y = 0; y < 874; y++) {
              for (var x = 0; x < 402; x++) {
                final p = (y * 402 + x) * 4;
                final point = Offset(x + .5, y + .5);
                final oldInk =
                    before.getUint8(p) < 90 &&
                    before.getUint8(p + 2) > before.getUint8(p) * 1.3;
                final changed = List.generate(
                  3,
                  (k) => (bytes.getUint8(p + k) - before.getUint8(p + k)).abs(),
                ).any((v) => v > 10);
                if (oldInk &&
                    changed &&
                    titleRects.any((r) => r.contains(point))) {
                  headerInkChanged++;
                }
                if (oldInk && changed && feedback.contains(point)) {
                  feedbackInkChanged++;
                }
                if (y < board.top && expected.getUint8(p + 3) >= 254) {
                  outside++;
                  if (List.generate(
                    3,
                    (k) => (bytes.getUint8(p + k) - expected.getUint8(p + k))
                        .abs(),
                  ).any((v) => v > 8)) {
                    mismatched++;
                  }
                }
              }
            }
            final evidence = Platform.environment['POURLUNE_EVIDENCE_DIR'];
            if (evidence != null) {
              final png = (await t.runAsync(
                () => actual.toByteData(format: ui.ImageByteFormat.png),
              ))!;
              File('$evidence/level$level-${ms.toInt()}.png')
                  .writeAsBytesSync(png.buffer.asUint8List());
            }
            // Diagnostic count makes any real overlap explicit, rather than
            // assuming a local canvas represents the available screen region.
            debugPrint(
              'level$level ${ms}ms source=${frame.poses[from].scale} outside=$outside mismatch=$mismatched header=$headerInkChanged feedback=$feedbackInkChanged',
            );
            if (level == 4 && ms >= 400) {
              expect(outside, greaterThan(100));
            }
            if (outside > 100) {
              expect(
                mismatched / outside,
                lessThan(.02),
                reason: 'Full source pixels above the old canvas must actually render.',
              );
            }
            expect(
              headerInkChanged,
              0,
              reason: 'Source flight must preserve the original level header and buttons.',
            );
            actual.dispose();
            ref.dispose();
            picture.dispose();
          }
          initial.dispose();
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      },
    );
  }
}
