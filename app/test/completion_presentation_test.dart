import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, daily, finish;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'AC-12 main daily replay success appears only after saved receipt and cannot reaward',
    (t) async {
      final dir = Directory.systemTemp.createTempSync(
        'completion-presentation',
      );
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store);
      try {
        await t.runAsync(c.initialize);
        for (final state in [
          finish(sample('normal')),
          finish(daily()),
          finish(sample('replay', replay: true)),
        ]) {
          c.current = state;
          c.receipt = null;
          c.phase = SavePhase.failed;
          Future<void> show({bool reduced = false}) => t.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduced),
                child: child!,
              ),
              home: Scaffold(
                body: CompletionPage(controller: c, onPlay: (_) {}),
              ),
            ),
          );
          await show();
          expect(
            find.byKey(Key('completion-feedback-${state.id}')),
            findsNothing,
          );
          c.receipt = await t.runAsync(
            () => store.settle(state, replace: true),
          );
          c.phase = SavePhase.clean;
          await show();
          final animation = find.byKey(Key('completion-feedback-${state.id}'));
          expect(animation, findsOneWidget);
          final fade = find.descendant(
            of: animation,
            matching: find.byType(Opacity),
          );
          expect(t.widget<Opacity>(fade).opacity, 0);
          await t.pump(const Duration(milliseconds: 200));
          final mid = t.widget<Opacity>(fade).opacity;
          expect(mid, greaterThan(0));
          expect(mid, lessThan(1));
          final before = await t.runAsync(store.progress);
          await show();
          expect(t.widget<Opacity>(fade).opacity, greaterThanOrEqualTo(mid));
          await t.pumpAndSettle();
          expect(t.widget<Opacity>(fade).opacity, 1);
          expect(
            (await t.runAsync(store.progress))!.receipts,
            before!.receipts,
          );
          expect(c.current!.toJson(), state.toJson());
          await t.pumpWidget(const SizedBox());
          await show(reduced: true);
          await t.pump(const Duration(milliseconds: 90));
          expect(t.widget<Opacity>(fade).opacity, lessThan(1));
          await t.pump(const Duration(milliseconds: 90));
          expect(t.widget<Opacity>(fade).opacity, 1);
          final transforms = find.descendant(
            of: animation,
            matching: find.byType(Transform),
          );
          for (final e in transforms.evaluate()) {
            final matrix = (e.widget as Transform).transform;
            expect(matrix.storage[0], 1);
            expect(matrix.storage[5], 1);
          }
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
