import 'dart:io';

import 'package:animations/animations.dart';
import 'package:pourlune_dev/presentation/motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  Future<void> appCase(
    WidgetTester t,
    Future<void> Function(GameController) check,
  ) async {
    final dir = Directory.systemTemp.createTempSync('motion-polish-');
    final store = (await t.runAsync(
      () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
    ))!;
    final c = GameController(store, library: testLibrary());
    try {
      await t.runAsync(c.initialize);
      await t.pumpWidget(PourluneApp(controller: c));
      await t.pumpAndSettle();
      await check(c);
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(store.close);
      dir.deleteSync(recursive: true);
    }
  }

  testWidgets(
    'official page patterns retain transparent woven background',
    (t) => appCase(t, (c) async {
      await c.navigate(GamePage.chapters);
      await t.pump();
      expect(find.byType(FadeThroughTransition), findsWidgets);
      expect(
        t
            .widgetList<FadeThroughTransition>(
              find.byType(FadeThroughTransition),
            )
            .every((w) => w.fillColor == Colors.transparent),
        isTrue,
      );
      await t.pumpAndSettle();
      await c.navigate(GamePage.settings);
      await t.pumpAndSettle();
      await c.navigate(GamePage.rules);
      await t.pump();
      expect(find.byType(SharedAxisTransition), findsWidgets);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('home')));
      await t.pump();
      final shared = t.widgetList<SharedAxisTransition>(
        find.byType(SharedAxisTransition),
      );
      expect(shared, isNotEmpty);
      expect(shared.every((w) => w.fillColor == Colors.transparent), isTrue);
      await t.pumpAndSettle();
      expect(c.page, GamePage.settings);
    }),
  );
  testWidgets(
    'instance replacement transitions while actions retain page identity',
    (t) => appCase(t, (c) async {
      await t.runAsync(() => c.startLevel(1));
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      Object key() => t.widget<PageMotion>(find.byType(PageMotion)).page;
      final first = key();
      await t.runAsync(() => c.pour(0, 2));
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      expect(key(), first);
      await t.runAsync(() => c.start(c.library.main[1]!, replace: true));
      await t.pump();
      expect(key(), isNot(first));
      expect(find.byKey(const Key('page-outgoing')), findsNothing);
      expect(find.byType(SharedAxisTransition), findsWidgets);
      await t.pumpAndSettle();
      await settleFlameBoard(t, c);
      expect(find.byKey(const Key('bottle-0')).hitTestable(), findsOneWidget);
    }),
  );
  testWidgets(
    'pause uses official modal and returns focus and board input',
    (t) => appCase(t, (c) async {
      await t.runAsync(() => c.startLevel(1));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('pause')));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(FadeScaleTransition), findsOneWidget);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('resume-pause')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('bottle-0')).hitTestable(), findsOneWidget);
    }),
  );
  testWidgets(
    'one active modal rejects a repeated request without duplicating actions',
    (t) async {
      late BuildContext context;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      var confirmations = 0;
      Future<void> request() async {
        final yes = await showKnitDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Confirm once'),
              ),
            ],
          ),
        );
        if (yes == true) confirmations++;
      }

      final first = request(), duplicate = request();
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(find.text('Confirm once'));
      await t.pumpAndSettle();
      await Future.wait([first, duplicate]);
      expect(confirmations, 1);
    },
  );

  testWidgets(
    'license route and date dialogs use shared official transitions',
    (t) => appCase(t, (c) async {
      await c.navigate(GamePage.settings);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('licenses')));
      await t.tap(find.byKey(const Key('licenses')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.byType(SharedAxisTransition), findsWidgets);
      await t.pumpAndSettle();
      await t.pageBack();
      await t.pumpAndSettle();
      expect(c.page, GamePage.settings);
      await c.navigate(GamePage.daily);
      await t.pumpAndSettle();
      final dates = find.byWidgetPredicate(
        (w) =>
            w is TextButton &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('date-'),
      );
      final other = dates
          .evaluate()
          .map((e) => (e.widget.key! as ValueKey<String>).value)
          .firstWhere((key) => key != 'date-${c.today.date}');
      await t.ensureVisible(find.byKey(Key(other)));
      await t.tap(find.byKey(Key(other)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(FadeScaleTransition), findsOneWidget);
      await t.pumpAndSettle();
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      expect(c.current, isNull);
    }),
  );
  testWidgets(
    'application reduced motion removes route animation and rapid returns keep one old view',
    (t) => appCase(t, (c) async {
      await t.runAsync(() => c.updateSetting('reduced_motion', true));
      await t.pumpAndSettle();
      await c.navigate(GamePage.settings);
      await t.pump();
      expect(find.byKey(const Key('page-outgoing')), findsNothing);
      await t.ensureVisible(find.byKey(const Key('licenses')));
      await t.tap(find.byKey(const Key('licenses')));
      await t.pump();
      expect(find.byType(SharedAxisTransition), findsNothing);
      await t.pumpAndSettle();
      await t.pageBack();
      await t.pumpAndSettle();
      expect(c.page, GamePage.settings);
    }),
  );
  testWidgets(
    'narrow large text keeps destinations and modal controls usable',
    (t) => appCase(t, (c) async {
      await t.binding.setSurfaceSize(const Size(360, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        PourluneApp(controller: c, textScaler: TextScaler.linear(2)),
      );
      for (final page in [
        GamePage.home,
        GamePage.chapters,
        GamePage.daily,
        GamePage.collection,
        GamePage.scene,
        GamePage.settings,
        GamePage.rules,
      ]) {
        await c.navigate(page);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: page.name);
      }
      await c.navigate(GamePage.settings);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('reset-progress')));
      await t.tap(find.byKey(const Key('reset-progress')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Keep progress'));
      await t.tap(find.text('Keep progress'));
      await t.pumpAndSettle();
      expect(c.page, GamePage.settings);
      expect(t.takeException(), isNull);
    }),
  );
  testWidgets(
    'new board instance and different scene start at top; returning keeps scroll',
    (t) => appCase(t, (c) async {
      await t.binding.setSurfaceSize(const Size(360, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.runAsync(() => c.startLevel(1));
      await t.pumpAndSettle();
      Finder scroll() => find.descendant(
        of: find.byType(PageMotion),
        matching: find.byType(SingleChildScrollView),
      );
      double offset() => t
          .state<ScrollableState>(
            find.descendant(of: scroll(), matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      await t.drag(scroll(), const Offset(0, -600));
      await t.pumpAndSettle();
      final previous = offset();
      expect(previous, greaterThan(0));
      await c.goHome();
      await t.pumpAndSettle();
      await c.resumeSlot('ordinary');
      await t.pumpAndSettle();
      expect(offset(), closeTo(previous, 1));
      await t.runAsync(() => c.start(c.library.main[1]!, replace: true));
      await t.pumpAndSettle();
      debugPrint('SCROLL_CHECK previous=$previous, newInstance=${offset()}');
      expect(
        offset(),
        0,
        reason: 'New instance must not inherit another board scroll',
      );
      await c.navigate(GamePage.scene, scene: 'color_studio');
      await t.pumpAndSettle();
      await t.drag(scroll(), const Offset(0, -600));
      await t.pumpAndSettle();
      final sceneOffset = offset();
      expect(sceneOffset, greaterThan(0));
      await c.navigate(GamePage.scene, scene: 'garden_nook');
      await t.pumpAndSettle();
      expect(offset(), 0);
      await c.navigate(GamePage.scene, scene: 'color_studio');
      await t.pumpAndSettle();
      expect(offset(), closeTo(sceneOffset, 1));
    }),
  );
}
