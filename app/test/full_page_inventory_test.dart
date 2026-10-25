// Automated layout/action inventory. This produces no images and is not a
// substitute for independent visual comparison or a normal-entry native run.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  });
  testWidgets('UI-R04 page inventory keeps visible controls separate', (
    t,
  ) async {
    addTearDown(t.view.reset);
    final definitions = parsePuzzleDefinitions(
      Directory('assets/puzzles')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.readAsStringSync()),
    );
    final library = ContentLibrary(
      main: {
        for (final p in definitions.values)
          if (p.mainLevel != null) p.mainLevel!: p,
      },
      daily: DailyCatalog.parse(
        File('assets/catalog/daily.json').readAsStringSync(),
        definitions,
      ),
    );
    final records = <Map<String, Object?>>[];
    for (final spec in [
      (size: const Size(320, 568), top: 20.0, bottom: 0.0),
      (size: const Size(390, 844), top: 47.0, bottom: 34.0),
      (size: const Size(430, 932), top: 59.0, bottom: 34.0),
    ]) {
      for (final scale in [1.0, 2.0]) {
        final dir = Directory.systemTemp.createTempSync('ui-pages-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/inventory.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final c = GameController(
          store,
          library: library,
          clock: () => LocalDay('2026-10-23', 'QA', 480),
        );
        try {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = spec.size;
          t.view.padding = FakeViewPadding(top: spec.top, bottom: spec.bottom);
          await t.runAsync(c.initialize);
          await t.pumpWidget(
            PourluneApp(controller: c, textScaler: TextScaler.linear(scale)),
          );
          await t.pumpAndSettle();
          void record(String page) {
            final controls = find
                .byWidgetPredicate((w) => w is ButtonStyleButton)
                .hitTestable();
            final rects = <Rect>[];
            for (final e in controls.evaluate()) {
              final finder = find.byElementPredicate(
                (candidate) => identical(candidate, e),
              );
              var rect = t.getRect(finder);
              // Scroll content can be partly clipped at a fixed action bar.
              // Compare its actual visible hit region, retaining the full
              // overlap guard for controls inside the same viewport.
              for (final ancestor
                  in find
                      .ancestor(
                        of: finder,
                        matching: find.byType(SingleChildScrollView),
                      )
                      .evaluate()) {
                rect = rect.intersect(
                  t.getRect(
                    find.byElementPredicate(
                      (candidate) => identical(candidate, ancestor),
                    ),
                  ),
                );
              }
              for (final other in rects) {
                expect(
                  rect.overlaps(other),
                  isFalse,
                  reason: '$page ${spec.size}/$scale controls $rect / $other',
                );
              }
              rects.add(rect);
            }
            records.add({
              'page': page,
              'size': '${spec.size}',
              'text_scale': scale,
              'visible_button_rects': [
                for (final r in rects) [r.left, r.top, r.right, r.bottom],
              ],
              'texts': [
                for (final e in find.byType(Text).evaluate())
                  (e.widget as Text).data,
              ].whereType<String>().toList(),
              'visual_pass': false,
            });
            expect(
              t.takeException(),
              isNull,
              reason: '$page ${spec.size}/$scale',
            );
          }

          Future<void> tap(String key) async {
            final f = find.byKey(Key(key));
            await t.ensureVisible(f);
            await t.tap(f);
            await t.pumpAndSettle();
          }

          Future<void> close() async {
            if (find.byKey(const Key('restart-close')).evaluate().isNotEmpty) {
              final before = c.current;
              await t.tap(find.byKey(const Key('restart-close')));
              expect(c.current, same(before));
            } else {
              Navigator.of(t.element(find.byType(Dialog))).pop();
            }
            await t.pumpAndSettle();
          }

          record('P01 welcome');
          if (scale == 1) {
            final start = t.getRect(find.byKey(const Key('sample-main-001')));
            expect(
              start.bottom,
              lessThanOrEqualTo(spec.size.height - spec.bottom),
            );
          }
          await t.runAsync(() => c.start(library.main[10]!));
          await t.pumpAndSettle();
          await settleFlameBoard(t, c);
          record('P05 play');
          await tap('pause');
          record('P06 pause');
          await tap('resume-pause');
          await tap('pause');
          await tap('pause-restart');
          record('P09 restart');
          await close();
          await tap('extra-bottle');
          record('P16-P17 extra unavailable');
          await close();
          await t.runAsync(c.goHome);
          await t.pumpAndSettle();
          record('P02 home');
          for (final entry in [
            (GamePage.chapters, 'P03 chapters'),
            (GamePage.collection, 'P12 collection'),
            (GamePage.scene, 'P13 scene'),
            (GamePage.daily, 'P14 daily'),
            (GamePage.settings, 'P19 settings'),
          ]) {
            await t.runAsync(() => c.navigate(entry.$1));
            await t.pumpAndSettle();
            record(entry.$2);
          }
          await tap('privacy');
          record('P20 privacy');
          await close();
          await tap('reset-progress');
          record('P21 reset');
          await close();
        } finally {
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      }
    }
    const report = String.fromEnvironment('UI_LAYOUT_REPORT');
    if (report.isNotEmpty) {
      File(report).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'kind': 'automated widget layout inventory; no native/visual pass',
          'font': 'bundled Nunito loaded',
          'catalog': 'actual 60 main +30daily',
          'screenshots': false,
          'records': records,
        }),
      );
    }
  });
}
