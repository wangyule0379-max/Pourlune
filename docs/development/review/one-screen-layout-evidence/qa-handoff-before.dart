// Independent QA only. No scenario, SDK reward, screen/audio capture, or shipping
// entry point changes. Clears only the explicitly named ly_runtime.sqlite.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:sqflite/sqflite.dart';

import '../test/support/flame_board_ready.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'LY05 normal Bootstrap first screen play settlement next and SQLite reopen',
    (t) async {
      const name = String.fromEnvironment('POURLUNE_DATABASE');
      const scenario = String.fromEnvironment('POURLUNE_SCENARIO');
      const adMode = String.fromEnvironment('POURLUNE_AD_MODE');
      if (name != 'ly_runtime.sqlite' ||
          scenario.isNotEmpty ||
          adMode != 'disabled' ||
          const bool.fromEnvironment('POURLUNE_FIREBASE_NATIVE_READY') ||
          const String.fromEnvironment('POURLUNE_FIREBASE_OPTIONS')
              .isNotEmpty) {
        throw StateError(
          'Require isolated ly_runtime.sqlite, disabled ads, Firebase none and no scenario',
        );
      }
      final base = await getDatabasesPath();
      await deleteDatabase('$base/$name');
      final rows = <Map<String, Object?>>[];
      GameController? current;
      Future<void> ready() async {
        debugPrint('LY_NATIVE_WAIT=ready');
        for (var i = 0; i < 600; i++) {
          await t
              .pump(const Duration(milliseconds: 20))
              .timeout(const Duration(seconds: 10));
          if (!current!.busy) break;
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(current!.busy, isFalse);
        expect(current!.phase, SavePhase.clean);
        await t.pumpAndSettle().timeout(const Duration(seconds: 25));
        if (current!.page == GamePage.board) {
          await settleFlameBoard(t, current!);
        }
        expect(t.takeException(), isNull);
      }

      Future<void> open() async {
        debugPrint('LY_NATIVE_OPEN=start');
        app.main();
        for (
          var i = 0;
          i < 600 && find.byType(app.GameScreen).evaluate().isEmpty;
          i++
        ) {
          await t
              .pump(const Duration(milliseconds: 30))
              .timeout(const Duration(seconds: 10));
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        current = t
            .widget<app.GameScreen>(find.byType(app.GameScreen))
            .controller;
        debugPrint('LY_NATIVE_OPEN=controller');
        await ready();
        expect(current!.library.engineering, isFalse);
        expect(current!.library.main.length, 60);
      }

      void firstScreen(String stage, List<String> keys) {
        final context = t.element(find.byType(app.GameScreen));
        final media = MediaQuery.of(context),
            padding = MediaQuery.paddingOf(context);
        final safe = Rect.fromLTRB(
          padding.left,
          padding.top,
          media.size.width - padding.right,
          media.size.height - padding.bottom,
        );
        final controls = <String, Object?>{};
        for (final key in keys) {
          final f = find.byKey(Key(key));
          expect(f, findsOneWidget, reason: '$stage/$key');
          final rect = t.getRect(f);
          expect(rect.left, greaterThanOrEqualTo(safe.left));
          expect(rect.top, greaterThanOrEqualTo(safe.top));
          expect(rect.right, lessThanOrEqualTo(safe.right + .01));
          expect(rect.bottom, lessThanOrEqualTo(safe.bottom + .01));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(f.hitTestable(), findsOneWidget, reason: '$stage/$key');
          controls[key] = [rect.left, rect.top, rect.right, rect.bottom];
        }
        rows.add({
          'stage': stage,
          'page': current!.page.name,
          'instance': current!.current?.id,
          'revision': current!.current?.revision,
          'viewport': [media.size.width, media.size.height],
          'padding': [padding.left, padding.top, padding.right, padding.bottom],
          'text_scale': media.textScaler.scale(1),
          'controls': controls,
          'scroll_before_action': false,
        });
        debugPrint('LY_NATIVE_STAGE=$stage');
      }

      Future<void> tap(String key) async {
        debugPrint('LY_NATIVE_TAP=$key');
        final f = find.byKey(Key(key));
        if (current!.page == GamePage.home)
          await t.ensureVisible(f).timeout(const Duration(seconds: 20));
        expect(f.hitTestable(), findsOneWidget, reason: key);
        await t.tap(f);
        await ready();
      }

      Future<void> close() async {
        final old = current!;
        await t.pumpWidget(const SizedBox());
        for (var i = 0; i < 200 && old.store.db.isOpen; i++) {
          await t.pump(const Duration(milliseconds: 10));
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(old.store.db.isOpen, isFalse);
        current = null;
      }

      await open();
      await tap('sample-main-001');
      if (current!.current!.tutorial?.active == true) {
        await tap('skip-tutorial');
      }
      for (var level = 1; level <= 4; level++) {
        final c = current!;
        expect(c.current!.puzzle.mainLevel, level);
        firstScreen('level-$level', [
          'home',
          'pause',
          'undo',
          'hint',
          'restart',
          if (c.offersExtraBottle) 'extra-bottle',
          for (var i = 0; i < c.current!.board.length; i++) 'bottle-$i',
        ]);
        for (final move in c.current!.puzzle.referenceMoves) {
          await tap('bottle-${move.from}');
          await tap('bottle-${move.to}');
        }
        expect(c.current!.completed, isTrue);
        expect(c.receipt, isNotNull);
        firstScreen('complete-$level', [
          level == 4 ? 'view-patch' : 'next',
          'home',
        ]);
        if (level == 4) {
          await tap('view-patch');
          firstScreen('reward-4', ['next', 'view-collection']);
        }
        await tap('next');
      }
      final c = current!,
          id = c.current!.id,
          move = c.current!.puzzle.referenceMoves.first;
      await tap('bottle-${move.from}');
      await tap('bottle-${move.to}');
      final saved = c.current!.toJson();
      expect((await c.store.load('ordinary')).instance!.toJson(), saved);
      await close();
      await open();
      await tap('resume');
      expect(current!.current!.id, id);
      expect(current!.current!.toJson(), saved);
      firstScreen('sqlite-reopen', [
        'home',
        'pause',
        'undo',
        'hint',
        'restart',
        'extra-bottle',
      ]);
      // Explicit seven-bottle entitlement QA snapshot, not an ad/reward claim.
      final seven = GameInstance.create(
        id: 'ly-controlled-seven',
        puzzle: current!.library.main[10]!,
      ).grantExtraBottle();
      await current!.store.save(seven, replace: true);
      await close();
      await open();
      await tap('resume');
      expect(current!.current!.board.length, 7);
      firstScreen('controlled-seven', [
        'home',
        'pause',
        'undo',
        'hint',
        'restart',
        'extra-bottle',
        for (var i = 0; i < 7; i++) 'bottle-$i',
      ]);
      final report = {
        'platform': Platform.operatingSystem,
        'ad_mode': adMode,
        'database': name,
        'scenario': scenario,
        'stages': rows,
        'store_reopen_same_process': true,
        'sigkill_or_real_device': false,
        'controlled_seven_not_ad_reward': true,
        'captures': false,
        'result': 'passed',
      };
      binding.reportData = report;
      debugPrint('LY_NATIVE_REPORT=${jsonEncode(report)}');
      await close();
    },
  );
}
