import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'store_test.dart' show daily, finish;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'first teaching step is visible text, not only a screen-reader hint',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(402, 874);
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('teaching-closeout-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store, library: testLibrary());
      try {
        await t.runAsync(() async {
          await c.initialize();
          await c.startLevel(1);
        });
        await t.pumpWidget(PourluneApp(controller: c));
        await t.pumpAndSettle();
        expect(find.textContaining('tap bottle'), findsOneWidget);
        expect(
          find.byKey(const Key('skip-tutorial')).hitTestable(),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
  for (final completed in [false, true]) {
    testWidgets(
      'normal daily ${completed ? 'completion' : 'entry'} shows a week and keeps actions reachable',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(402, 874);
        addTearDown(t.view.reset);
        final dir = Directory.systemTemp.createTempSync('daily-closeout-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final c = GameController(
          store,
          library: testLibrary(),
          clock: () => LocalDay('2026-10-22', 'Test', 480),
        );
        try {
          await t.runAsync(() async {
            if (completed) await store.settle(finish(daily()), replace: true);
            await c.initialize();
            if (completed) {
              await c.resumeSlot('daily');
            } else {
              await c.navigate(GamePage.daily);
            }
          });
          await t.pumpWidget(PourluneApp(controller: c));
          await t.pumpAndSettle();
          expect(find.byKey(const Key('daily-week-strip')), findsOneWidget);
          expect(
            find
                .byKey(Key(completed ? 'daily-calendar' : 'today'))
                .hitTestable(),
            findsOneWidget,
          );
          if (!completed) {
            expect(find.byKey(const Key('date-2026-10-01')), findsNothing);
            await t.tap(find.byKey(const Key('daily-history-toggle')));
            await t.pumpAndSettle();
            final old = find.byKey(const Key('date-2026-10-01'));
            await t.ensureVisible(old);
            await t.tap(old);
            await t.pumpAndSettle();
            expect(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.textContaining('History is read-only'),
              ),
              findsOneWidget,
            );
            expect(c.daily, isNull);
          } else {
            expect(find.byKey(const Key('home')).hitTestable(), findsOneWidget);
            expect(c.progress.dailyStamps, contains('2026-10-22'));
            expect(c.progress.receipts, 1);
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
