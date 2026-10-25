import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show finish;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  });
  testWidgets(
    'P10 core and action text must not shrink across the largest-text threshold',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(375, 667);
      t.view.padding = const FakeViewPadding(top: 20);
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('p10-text-growth-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      try {
        await t.runAsync(() async {
          final state = finish(
            GameInstance.create(
              id: 'text-growth-final60',
              puzzle: Puzzle.parse(
                File('assets/puzzles/main/main-060.json').readAsStringSync(),
              ),
            ),
          );
          await store.settle(state, replace: true);
          await c.initialize();
          await c.resumeSlot('ordinary');
        });
        final previous = <String, double>{};
        for (final scale in [2.78, 2.79, 3.1176470588235294, 3.2]) {
          await t.pumpWidget(
            PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
          );
          await t.pumpAndSettle();
          final labels = <String, Finder>{
            for (final key in [
              'daily-final',
              'view-collection',
              'replay-levels',
              'home',
            ])
              key: find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Text),
              ),
            for (final text in [
              'Level 60',
              'Story complete',
              'Seaside Corner',
              'Scene complete',
            ])
              text: find.text(text),
          };
          for (final entry in labels.entries) {
            final context = t.element(entry.value);
            final text = t.widget<Text>(entry.value);
            final base = DefaultTextStyle.of(context).style
                .merge(text.style)
                .fontSize!;
            final effective = MediaQuery.textScalerOf(context).scale(base);
            if (previous.containsKey(entry.key)) {
              expect(
                effective,
                greaterThanOrEqualTo(previous[entry.key]!),
                reason:
                    '${entry.key}: an OS text increase must not silently reverse core or action text size.',
              );
            }
            previous[entry.key] = effective;
          }
          expect(t.takeException(), isNull);
        }
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
}
