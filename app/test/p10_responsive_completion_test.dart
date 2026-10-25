import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/completion_bottles.dart';
import 'package:pourlune_dev/presentation/completion_compact_layout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show finish, sample, daily;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  testWidgets(
    'P10 final keeps bottles and Info reachable through enlarged text and SE safe area',
    (t) async {
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('p10-info-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      final state = finish(
        GameInstance.create(
          id: 'info-final60',
          puzzle: Puzzle.parse(
            File('assets/puzzles/main/main-060.json').readAsStringSync(),
          ),
        ),
      );
      try {
        await t.runAsync(() async {
          await store.settle(state, replace: true);
          await c.initialize();
          await c.resumeSlot('ordinary');
        });
        for (final entry in [
          (const Size(375, 667), 2.35),
          (const Size(320, 568), 2.35),
          (const Size(440, 956), 2.35),
          (const Size(375, 667), 3.2),
        ]) {
          final size = entry.$1;
          t.view.physicalSize = size;
          t.view.padding = const FakeViewPadding(top: 20);
          await t.pumpWidget(
            PourluneApp(controller: c, textScaler: TextScaler.linear(entry.$2)),
          );
          await t.pumpAndSettle();
          for (var i = 0; i < 4; i++) {
            expect(
              t.getSize(find.byKey(Key('completion-bottle-$i'))).width,
              greaterThanOrEqualTo(32),
              reason: 'actual final60 / $entry / bottle $i',
            );
          }
          for (final key in [
            'daily-final',
            'view-collection',
            'replay-levels',
            'home',
          ]) {
            final action = find.byKey(Key(key));
            expect(action.hitTestable(), findsOneWidget);
            expect(t.getRect(action).bottom, lessThanOrEqualTo(size.height));
          }
          expect(t.takeException(), isNull);
          for (final closeKey in [
            'completion-info-close',
            'completion-info-dismiss',
          ]) {
            await t.tap(find.byKey(const Key('completion-info')));
            await t.pumpAndSettle();
            final close = find.byKey(Key(closeKey));
            expect(close.hitTestable(), findsOneWidget);
            final rect = t.getRect(close);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            await t.tap(close);
            await t.pumpAndSettle();
            expect(c.page, GamePage.completion);
            expect(c.current!.toJson(), state.toJson());
            expect(t.takeException(), isNull);
          }
        }
        expect((await t.runAsync(store.progress))!.receipts, 1);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
  testWidgets(
    'AC-12 daily replay reports no new stamp in compact and normal completion',
    (t) async {
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('p10-daily-replay-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      final original = daily();
      final replay = finish(
        GameInstance.create(
          id: 'daily-layout-replay',
          puzzle: original.puzzle,
          slot: 'daily',
          isReplay: true,
          puzzleDate: original.puzzleDate,
          timeZone: original.timeZone,
          offsetMinutes: original.offsetMinutes,
          catalogVersion: original.catalogVersion,
        ),
      );
      try {
        await t.runAsync(() async {
          await store.settle(finish(original), replace: true);
          await store.settle(replay, replace: true);
          await c.initialize();
          await c.resumeSlot('daily');
        });
        for (final size in [const Size(440, 956), const Size(375, 667)]) {
          t.view.physicalSize = size;
          await t.pumpWidget(PourluneApp(controller: c));
          await t.pumpAndSettle();
          final l = AppLocalizations.of(
            t.element(find.byKey(const Key('daily-calendar'))),
          );
          expect(find.text(l.dailyReplayComplete), findsOneWidget);
          expect(find.text(l.stampSaved(replay.puzzleDate!)), findsNothing);
          expect(c.current!.isReplay, isTrue);
        }
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
  testWidgets(
    'P10 resize and enlarged text keep receipt and return to the original two rows',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(440, 956);
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('p10-responsive-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      final completed = finish(sample('p10-responsive'));
      try {
        await t.runAsync(() async {
          await store.settle(completed, replace: true);
          await c.initialize();
          await c.resumeSlot('ordinary');
        });
        final saved = c.current!.toJson(),
            receipts = (await t.runAsync(store.progress))!.receipts;
        for (final entry in [
          (const Size(440, 956), 1.0, false),
          (const Size(440, 956), 1.29, true),
          (const Size(375, 667), 1.0, true),
          (const Size(440, 956), 1.28, false),
          (const Size(440, 956), 1.0, false),
        ]) {
          t.view.physicalSize = entry.$1;
          await t.pumpWidget(
            PourluneApp(controller: c, textScaler: TextScaler.linear(entry.$2)),
          );
          await t.pumpAndSettle();
          expect(
            find.byType(CompactCompletionLayout),
            entry.$3 ? findsOneWidget : findsNothing,
          );
          expect(
            t
                .widget<CompletionBottles>(find.byType(CompletionBottles))
                .singleRow,
            entry.$3,
          );
          expect(c.current!.toJson(), saved);
          expect(c.page, GamePage.completion);
          expect(t.takeException(), isNull);
        }
        expect((await t.runAsync(store.progress))!.receipts, receipts);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
}
