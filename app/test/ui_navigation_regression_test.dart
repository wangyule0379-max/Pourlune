import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/knit_components.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      'UI-R05 $platform menu header stays fixed at both scroll limits',
      (t) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        addTearDown(t.view.reset);
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(390, 844);
        t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        final dir = Directory.systemTemp.createTempSync('ui-navigation-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/ui.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final c = GameController(store, library: testLibrary());
        try {
          await t.runAsync(c.initialize);
          await t.pumpWidget(PourluneApp(controller: c));
          await t.pumpAndSettle();
          for (final page in [GamePage.chapters, GamePage.settings]) {
            await c.navigate(page);
            await t.pumpAndSettle();
            final scroll = find.byKey(PageStorageKey('scroll-${page.name}'));
            final header = find.byType(KnitHeader);
            final initial = t.getRect(header);
            final title = find.descendant(
              of: header,
              matching: find.text(
                page == GamePage.chapters ? 'Chapters' : 'Settings',
              ),
            );
            final back = find.descendant(
              of: header,
              matching: find.byKey(const Key('home')),
            );
            expect(
              (t.getCenter(title).dy - t.getCenter(back).dy).abs(),
              lessThanOrEqualTo(2),
              reason: 'The original menu heading is aligned with Back, not pushed below an unrelated emblem.',
            );
            final position = t
                .state<ScrollableState>(
                  find.descendant(
                    of: scroll,
                    matching: find.byType(Scrollable),
                  ),
                )
                .position;
            expect(position.maxScrollExtent, greaterThan(0));
            await t.drag(scroll, const Offset(0, -200));
            await t.pumpAndSettle();
            expect(position.pixels, greaterThan(0));
            expect(
              t.getRect(header),
              initial,
              reason:
                  'Scrolling ${page.name} must not drag away Back and the page title.',
            );
            for (final (edge, delta) in [
              (0.0, 120.0),
              (position.maxScrollExtent, -120.0),
            ]) {
              position.jumpTo(edge);
              await t.pump();
              final gesture = await t.startGesture(t.getCenter(scroll));
              await gesture.moveBy(Offset(0, delta));
              await t.pump(const Duration(milliseconds: 80));
              expect(
                position.outOfRange,
                isFalse,
                reason: 'A menu card must not stretch/pull into the fixed header/background.',
              );
              expect(t.getRect(header), initial);
              await gesture.up();
              await t.pumpAndSettle();
            }
            expect(t.takeException(), isNull);
          }
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
