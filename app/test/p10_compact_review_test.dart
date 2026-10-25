import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/p10_compact_review_app.dart';
import '../integration_test/support/b05_support.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  for (final sample in [
    (const Size(375, 667), 1.0),
    (const Size(440, 956), 2.35),
  ]) {
    testWidgets(
      'unapproved compact final60 keeps core and bottles visible $sample',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = sample.$1;
        t.view.padding = FakeViewPadding(
          top: sample.$1.height > 700 ? 62 : 20,
          bottom: sample.$1.height > 700 ? 34 : 0,
        );
        addTearDown(t.view.reset);
        final dir = Directory.systemTemp.createTempSync('p10-compact-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final library = (await t.runAsync(b05Library))!;
        final c = GameController(store, library: library);
        try {
          await t.runAsync(() async {
            await b05Seed(store, library, 59);
            final completed = b05Finish(
              GameInstance.create(
                id: 'compact-real60',
                puzzle: library.main[60]!,
              ),
            );
            await store.settle(completed, replace: true);
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          await t.pumpWidget(
            CompactCompletionReview(
              controller: c,
              textScaler: TextScaler.linear(sample.$2),
            ),
          );
          await t.pumpAndSettle();
          final viewport = Rect.fromLTRB(
            0,
            t.view.padding.top,
            sample.$1.width,
            sample.$1.height - t.view.padding.bottom,
          );
          for (final f in [
            find.text('20 / 20 levels'),
            find.text('New patch unlocked'),
            for (final key in [
              'daily-final',
              'view-collection',
              'replay-levels',
              'home',
            ])
              find.byKey(Key(key)),
          ]) {
            expect(f, findsOneWidget);
            final rect = t.getRect(f);
            expect(rect.top, greaterThanOrEqualTo(viewport.top));
            expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
          }
          for (var i = 0; i < 4; i++) {
            final f = find.byKey(Key('completion-bottle-$i'));
            expect(f, findsOneWidget);
            expect(t.getRect(f).width, greaterThanOrEqualTo(32));
          }
          expect(t.takeException(), isNull);
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
