import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/completion_bottles.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show finish, sample;

void main() {
  sqfliteFfiInit();

  testWidgets('R01 completion shows the saved board without accepting moves', (
    t,
  ) async {
    final dir = Directory.systemTemp.createTempSync('r01-completion-');
    final store = (await t.runAsync(
      () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
    ))!;
    final c = GameController(store);
    try {
      await t.runAsync(c.initialize);
      final completed = finish(sample('r01-complete'));
      c.current = completed;
      c.receipt = await t.runAsync(
        () => store.settle(completed, replace: true),
      );
      c.phase = SavePhase.clean;
      await t.pumpWidget(
        _screen(CompletionPage(controller: c, onPlay: (_) {})),
      );
      await t.pumpAndSettle();
      expect(find.byType(CompletionBottles), findsOneWidget);
      final board = t.widget<CompletionBottles>(find.byType(CompletionBottles));
      expect(board.state.toJson(), completed.toJson());
      expect(
        board.targetIndices.length,
        completed.puzzle.targets.whereType<String>().length,
      );
      expect(
        find.descendant(
          of: find.byType(CompletionBottles),
          matching: find.byType(OutlinedButton),
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Your progress is saved on this device.'),
        findsOneWidget,
      );
      final before = await t.runAsync(store.progress);
      await t.pump(const Duration(seconds: 1));
      expect((await t.runAsync(store.progress))!.receipts, before!.receipts);
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    }
  });

  testWidgets('R01 collection remains reachable at 320px and 2x text', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(320, 800));
    final dir = Directory.systemTemp.createTempSync('r01-collection-');
    final store = (await t.runAsync(
      () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
    ))!;
    final c = GameController(store);
    try {
      await t.runAsync(c.initialize);
      await t.pumpWidget(
        _screen(CollectionPage(controller: c), largeText: true),
      );
      await t.pumpAndSettle();
      for (final scene in ['color_studio', 'garden_nook', 'seaside_corner']) {
        final entry = find.byKey(Key('scene-$scene'));
        await t.ensureVisible(entry);
        await t.tap(entry);
        await t.pumpAndSettle();
        expect(c.selectedScene, scene);
        expect(c.page, GamePage.scene);
      }
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
      await t.binding.setSurfaceSize(null);
    }
  });
}

Widget _screen(Widget child, {bool largeText = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
