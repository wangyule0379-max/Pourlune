import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/completion_bottles.dart';
import 'package:pourlune_dev/presentation/bottle_foot_label.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  });
  for (final level in [1, 4, 12]) {
    testWidgets(
      'P10 level$level shows actual saved targets, prominent card action and separate Home',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(375, 667);
        t.view.padding = const FakeViewPadding(top: 20);
        addTearDown(t.view.reset);
        final dir = Directory.systemTemp.createTempSync('p10-reference-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final puzzle = Puzzle.parse(
          File(
            'assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json',
          ).readAsStringSync(),
        );
        var state = GameInstance.create(id: 'p10-$level', puzzle: puzzle);
        for (final move in puzzle.referenceMoves) {
          state = state.pour(move.from, move.to).state;
        }
        final c = GameController(
          store,
          library: ContentLibrary(main: {level: puzzle}),
        );
        try {
          await t.runAsync(() async {
            await store.settle(state, replace: true);
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          await t.pumpWidget(
            RepaintBoundary(
              key: const Key('p10-pixels'),
              child: PourluneApp(controller: c),
            ),
          );
          await t.pumpAndSettle();
          await t.runAsync(
            () => precacheImage(
              const AssetImage(completionReference),
              t.element(find.byType(CompletionBottles)),
            ),
          );
          await t.pumpAndSettle();
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('p10-pixels')),
          );
          final image = (await t.runAsync(
            () => boundary.toImage(pixelRatio: 1),
          ))!;
          final pixels = (await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          final corner = (140 * 375 + 365) * 4;
          expect(
            pixels.getUint8(corner + 1),
            greaterThan(140),
            reason: 'Cutout filters cannot darken the cyan page outside their own bounds.',
          );
          expect(pixels.getUint8(corner + 2), greaterThan(180));
          image.dispose();
          final display = t.widget<CompletionBottles>(
            find.byType(CompletionBottles),
          );
          expect(display.state.toJson(), state.toJson());
          final heroBounds = t.getRect(find.byType(CompletionBottles));
          for (final i in display.targetIndices) {
            expect(
              t.getRect(find.byKey(Key('completion-target-$i'))).bottom,
              lessThanOrEqualTo(heroBounds.bottom - 8),
              reason:
                  'Target cushions need a clear gap before the progress card.',
            );
          }
          expect(
            find.byType(TargetCushion),
            findsNWidgets(display.targetIndices.length),
          );
          expect(
            display.targetIndices.length,
            puzzle.targets.whereType<String>().length,
          );
          final card = find.byKey(const Key('completion-progress'));
          final primary = find.byKey(
            Key(level % 4 == 0 ? 'view-patch' : 'next'),
          );
          expect(find.descendant(of: card, matching: primary), findsOneWidget);
          expect(
            find.descendant(of: card, matching: find.byKey(const Key('home'))),
            findsNothing,
          );
          expect(t.getRect(primary).height, greaterThanOrEqualTo(54));
          expect(
            t.getRect(find.byKey(const Key('home'))).bottom,
            lessThanOrEqualTo(667),
          );
          expect(t.takeException(), isNull);
          final before = (await t.runAsync(store.progress))!.receipts;
          await t.pump(const Duration(seconds: 1));
          expect((await t.runAsync(store.progress))!.receipts, before);
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
