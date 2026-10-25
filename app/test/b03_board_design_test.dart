import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'R01 P04/P06 header and vertical real Pause actions preserve state at 320/2x',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 800));
      final dir = Directory.systemTemp.createTempSync('r01-board-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store, library: testLibrary());
      try {
        await t.runAsync(() async {
          await c.initialize();
          await c.startLevel(1);
        });
        final before = c.current!.toJson();
        await t.pumpWidget(
          PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
        );
        await t.pumpAndSettle();
        expect(find.byType(AppBar), findsNothing);
        expect(
          t.getTopLeft(find.byKey(const Key('pause'))).dy,
          lessThan(t.getTopLeft(find.byKey(const Key('bottle-0'))).dy),
        );
        expect(find.byKey(const Key('undo')), findsOneWidget);
        await t.ensureVisible(find.byKey(const Key('pause')));
        await t.tap(find.byKey(const Key('pause')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('pause-card')), findsOneWidget);
        final resume = find.byKey(const Key('resume-pause'));
        final restart = find.byKey(const Key('pause-restart'));
        final home = find.byKey(const Key('pause-home'));
        await t.ensureVisible(home);
        expect(t.getTopLeft(resume).dx, t.getTopLeft(restart).dx);
        expect(t.getTopLeft(restart).dx, t.getTopLeft(home).dx);
        expect(t.getTopLeft(home).dy, greaterThan(t.getBottomLeft(restart).dy));
        expect(t.getSize(resume).width, greaterThanOrEqualTo(200));
        expect(t.getSize(resume).height, greaterThanOrEqualTo(48));
        await t.ensureVisible(resume);
        await t.tap(resume);
        await t.pumpAndSettle();
        expect(c.current!.toJson(), before);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
        await t.binding.setSurfaceSize(null);
      }
    },
  );
}
