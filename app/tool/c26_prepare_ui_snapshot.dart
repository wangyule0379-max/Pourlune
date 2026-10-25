// Explicit evidence setup only. Never imported by production or auto-discovered tests.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/support/b05_support.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'prepare an explicit ordinary P11 QA snapshot through real store APIs',
    (t) async {
      final path = Platform.environment['POURLUNE_C26_UI_SNAPSHOT'];
      if (path == null ||
          !path.startsWith('/Volumes/data/App Development/Pourlune/build/') ||
          File(path).existsSync()) {
        throw StateError(
          'An absent explicit build/ QA output is required. No device database is opened.',
        );
      }
      final library = (await t.runAsync(b05Library))!;
      final store = (await t.runAsync(
        () => GameStore.open(path, factory: databaseFactoryFfi),
      ))!;
      try {
        await t.runAsync(() async {
          await b05Seed(store, library, 11);
          final completed = b05Finish(
            GameInstance.create(id: 'c26-ui-main12', puzzle: library.main[12]!),
          );
          await store.settle(completed, replace: true);
        });
        final progress = (await t.runAsync(store.progress))!;
        expect(progress.completedLevels.length, 12);
        expect(progress.pieces.length, 3);
        expect(progress.revealedPieces.length, 2);
      } finally {
        await t.runAsync(store.close);
      }
    },
  );
}
