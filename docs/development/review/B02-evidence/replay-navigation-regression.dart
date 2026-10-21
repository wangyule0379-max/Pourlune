import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() {
  sqfliteFfiInit();
  testWidgets('Replay again intent survives failed settlement retry', (t) async {
    final dir = Directory.systemTemp.createTempSync('b02-independent-replay-');
    final store = (await t.runAsync(() => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi)))!;
    final p = Puzzle.fromJson(jsonDecode(File('assets/fixtures/main-001.reference.json').readAsStringSync()) as Map<String,Object?>);
    final c = GameController(store, library: ContentLibrary(main: {1:p}));
    await t.runAsync(() async {
      await c.initialize();
      await c.start(p);
      for (final m in p.referenceMoves) {await c.pour(m.from,m.to);}
      await c.startLevel(1);
      for (final m in p.referenceMoves.take(p.referenceMoves.length-1)) {await c.pour(m.from,m.to);}
      store.fault=(stage) {if (stage=='receipt') throw StateError('simulated disk write failure');};
      await c.pour(p.referenceMoves.last.from,p.referenceMoves.last.to);
    });
    final oldId=c.current!.id;
    expect(c.phase,SavePhase.failed);
    expect(c.settlementKind,SettlementKind.replay);
    await t.pumpWidget(PourluneApp(controller:c));
    final button=find.byKey(const Key('replay-again'));
    expect(t.widget<FilledButton>(button).onPressed,isNotNull);
    await t.ensureVisible(button);
    await t.tap(button);
    await t.pump();
    store.fault=null;
    await t.runAsync(c.retry);
    await t.pumpAndSettle();
    final actualPage=c.page, actualId=c.current!.id;
    await t.pumpWidget(const SizedBox());
    c.dispose();
    await t.runAsync(store.close);
    dir.deleteSync(recursive:true);
    expect(actualId,isNot(oldId),reason:'Replay again before Retry should run once after successful settlement');
    expect(actualPage,GamePage.board);
  });
}
