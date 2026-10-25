// Independent R04 transition test; real SQLite, no capture or native devices.
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show finish;
import 'support/flame_board_ready.dart';
import 'ly_ui_probes_test.dart' as probe;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });
  for (final level in [20, 60]) {
    testWidgets(
      'LY-R04 independent saved-result $level keeps old Home isolated',
      (t) async {
        addTearDown(t.view.reset);
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(390, 844);
        t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        final dir = Directory.systemTemp.createTempSync('ly-ui-r04-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/ui.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final puzzle = Puzzle.parse(
          File(
            'assets/puzzles/main/main-${level.toString().padLeft(3, '0')}.json',
          ).readAsStringSync(),
        );
        final completed = finish(
          GameInstance.create(
            id: 'r04-$level',
            puzzle: puzzle,
          ).grantExtraBottle(),
        );
        expect(completed.board.length, 7);
        expect(completed.completed, isTrue);
        final c = GameController(
          store,
          library: ContentLibrary(main: {level: puzzle}),
        );
        try {
          await t.runAsync(() async {
            await store.settle(completed);
            await c.initialize();
          });
          await t.pumpWidget(PourluneApp(controller: c));
          await t.pumpAndSettle();
          expect(c.page, GamePage.home);
          final saved = find.byKey(const Key('saved-result'));
          // Home may scroll to its real result entry; result is never scrolled.
          await t.ensureVisible(saved);
          expect(saved.hitTestable(), findsOneWidget);
          await t.tap(saved);
          var observedOutgoing = false;
          for (var frame = 0; frame < 20; frame++) {
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await t.pump(const Duration(milliseconds: 20));
            expect(
              t.takeException(),
              isNull,
              reason: '$level transition frame$frame',
            );
            final outgoing = find.byKey(const Key('page-outgoing'));
            if (outgoing.evaluate().isNotEmpty) {
              observedOutgoing = true;
              expect(t.widget<IgnorePointer>(outgoing).ignoring, isTrue);
              final oldScroll = find.descendant(
                of: outgoing,
                matching: find.byKey(const PageStorageKey('scroll-home')),
              );
              expect(
                oldScroll,
                findsOneWidget,
                reason: 'retained Home must keep its own scroll policy',
              );
              final excluded = find.descendant(
                of: outgoing,
                matching: find.byType(ExcludeSemantics),
              );
              expect(excluded, findsWidgets);
              expect(
                excluded.evaluate().any(
                  (e) => (e.widget as ExcludeSemantics).excluding,
                ),
                isTrue,
              );
              final focus = find.descendant(
                of: outgoing,
                matching: find.byType(ExcludeFocus),
              );
              expect(focus, findsOneWidget);
              expect(t.widget<ExcludeFocus>(focus).excluding, isTrue);
              final ticker = find.descendant(
                of: outgoing,
                matching: find.byType(TickerMode),
              );
              expect(t.widget<TickerMode>(ticker.first).enabled, isFalse);
            }
            debugPrint(
              'LY_R04_FRAME=${jsonEncode({'level': level, 'frame': frame, 'page': c.page.name, 'outgoing': outgoing.evaluate().isNotEmpty, 'error': false})}',
            );
          }
          expect(
            observedOutgoing,
            isTrue,
            reason: 'must observe actual retained transition',
          );
          await t.pumpAndSettle();
          await waitForFlameArt(t);
          expect(c.page, GamePage.completion);
          expect(c.current!.id, completed.id);
          expect(c.receipt, isNotNull);
          expect(find.byKey(const Key('page-outgoing')), findsNothing);
          for (final key
              in level == 20
                  ? ['next', 'view-collection', 'home']
                  : [
                      'daily-final',
                      'view-collection',
                      'replay-levels',
                      'home',
                    ]) {
            probe.reportBounds(
              t,
              'R04/$level/$key',
              find.byKey(Key(key)),
              mustFit: true,
              control: true,
            );
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
