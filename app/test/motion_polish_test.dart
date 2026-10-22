import 'dart:io';

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;

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
    'native press shrinks visually and dragging outside cancels start',
    (t) => appCase(t, (c) async {
      final button = find.byKey(const Key('sample-main-001'));
      await t.ensureVisible(button);
      final bounds = t.getRect(button);
      final gesture = await t.startGesture(bounds.center);
      await t.pump(const Duration(milliseconds: 120));
      final scale = find.descendant(
        of: button,
        matching: find.byType(AnimatedScale),
      );
      expect(scale, findsOneWidget);
      expect(t.widget<AnimatedScale>(scale).scale, lessThan(1));
      expect(
        t.getRect(button),
        bounds,
        reason: 'native target must not shrink',
      );
      await gesture.moveTo(Offset(bounds.right + 100, bounds.top - 100));
      await gesture.up();
      await t.pumpAndSettle();
      expect(c.current, isNull);
      expect(t.widget<AnimatedScale>(scale).scale, 1);
    }),
  );

  testWidgets(
    'page entry remains interactive and rapid back retires outgoing page',
    (t) => appCase(t, (c) async {
      c.navigate(GamePage.chapters);
      await t.pump();
      final entry = find.byKey(const Key('page-enter'));
      expect(entry, findsOneWidget);
      expect(
        t
            .widget<FadeThroughTransition>(
              find.descendant(
                of: entry,
                matching: find.byType(FadeThroughTransition),
              ),
            )
            .animation
            .value,
        lessThan(1),
      );
      expect(find.byKey(const Key('home')).hitTestable(), findsOneWidget);
      await t.tap(find.byKey(const Key('home')));
      await t.pump();
      c.navigate(GamePage.settings);
      await t.pump(const Duration(milliseconds: 40));
      expect(find.byKey(const Key('page-outgoing')), findsOneWidget);
      expect(
        find.byKey(const Key('level-1')),
        findsNothing,
        reason: 'rapid navigation retains at most one outgoing page',
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('page-outgoing')), findsNothing);
      expect(c.page, GamePage.settings);
    }),
  );

  testWidgets(
    'duplicate pause requests open one modal and resume restores input',
    (t) => appCase(t, (c) async {
      await t.runAsync(() => c.startLevel(1));
      await t.pumpAndSettle();
      final pause = t
          .widget<OutlinedButton>(
            find.descendant(
              of: find.byKey(const Key('pause')),
              matching: find.byType(OutlinedButton),
            ),
          )
          .onPressed!;
      pause();
      pause();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pause-card')), findsOneWidget);
      await t.tap(find.byKey(const Key('resume-pause')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pause-card')), findsNothing);
      expect(c.busy, isFalse);
      expect(find.byKey(const Key('bottle-0')).hitTestable(), findsOneWidget);
    }),
  );
  testWidgets(
    'failed save stays visible through attempted departure and Retry persists before Home',
    (t) => appCase(t, (c) async {
      await t.runAsync(() => c.startLevel(1));
      await t.pumpAndSettle();
      c.store.fault = (stage) {
        if (stage == 'snapshot') throw StateError('test disk full');
      };
      await t.runAsync(() => c.pour(0, 2));
      await t.pumpAndSettle();
      await t.runAsync(c.goHome);
      await t.pump();
      expect(c.page, GamePage.board);
      expect(find.byKey(const Key('save-failed')), findsOneWidget);
      expect(
        t
            .widget<SharedAxisTransition>(
              find.descendant(
                of: find.byKey(const Key('page-enter')),
                matching: find.byType(SharedAxisTransition),
              ),
            )
            .animation
            .value,
        1,
      );
      final committed = c.current!.toJson();
      c.store.fault = null;
      await t.ensureVisible(find.byKey(const Key('retry')));
      await t.tap(find.byKey(const Key('retry')));
      await t.runAsync(() async {
        for (var n = 0; n < 400 && c.phase != SavePhase.clean; n++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pumpAndSettle();
      expect(c.phase, SavePhase.clean);
      expect(c.page, GamePage.home);
      expect(
        (await t.runAsync(() => c.store.load('ordinary')))!.instance!.toJson(),
        committed,
      );
    }),
  );

  testWidgets(
    'chapters restores its own scroll position after settings navigation',
    (t) => appCase(t, (c) async {
      await t.binding.setSurfaceSize(const Size(360, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      c.navigate(GamePage.chapters);
      await t.pumpAndSettle();
      final scroll = find.byKey(const PageStorageKey('scroll-chapters'));
      await t.drag(scroll, const Offset(0, -600));
      await t.pumpAndSettle();
      double offset() => t
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      final before = offset();
      expect(before, greaterThan(0));
      c.navigate(GamePage.settings);
      await t.pumpAndSettle();
      c.navigate(GamePage.chapters);
      await t.pumpAndSettle();
      expect(offset(), closeTo(before, 1));
    }),
  );

  testWidgets(
    'pause closes faster than entry without leaving a modal barrier',
    (t) => appCase(t, (c) async {
      await t.runAsync(() => c.startLevel(1));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('pause')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('resume-pause')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 160));
      expect(find.byKey(const Key('pause-card')), findsNothing);
      expect(find.byKey(const Key('bottle-0')).hitTestable(), findsOneWidget);
    }),
  );
}
