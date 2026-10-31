// Dedicated QA only. Normal main/Bootstrap, real sqflite and native pointers.
// Prior1–59 settlements are explicit setup, not human campaign completion.
import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:sqflite/sqflite.dart';

import '../test/support/flame_board_ready.dart';
import 'support/b05_support.dart' show b05Library, b05Seed;
import 'support/main60_v3_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'five-color normal Bootstrap native7/8 actions and old SQLite snapshot',
    (t) async {
      const filename = String.fromEnvironment('POURLUNE_DATABASE');
      const run = String.fromEnvironment('POURLUNE_MAIN60_RUN');
      if (run.isEmpty ||
          filename != 'main60_five_color.sqlite' ||
          const String.fromEnvironment('POURLUNE_SCENARIO').isNotEmpty ||
          const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled' ||
          const bool.fromEnvironment('POURLUNE_FIREBASE_NATIVE_READY') ||
          const String.fromEnvironment('POURLUNE_FIREBASE_OPTIONS')
              .isNotEmpty) {
        throw StateError(
          'Require exact isolated main60_five_color.sqlite, ads disabled, no scenario/Firebase',
        );
      }
      final base = await getDatabasesPath();
      final out = Directory('$base/main60-five-color-native');
      await out.create(recursive: true);
      await File('${out.path}/runtime.json').writeAsString(
        jsonEncode({'run': run, 'status': 'running'}),
        flush: true,
      );
      final ack = File('${out.path}/copied');
      if (await ack.exists()) await ack.delete();
      await deleteDatabase('$base/$filename');
      final library = await b05Library();
      final prep = await GameStore.open('$base/$filename');
      await b05Seed(prep, library, 59);
      final old = Puzzle.parse(oldMain21V3);
      var legacy = GameInstance.create(
        id: 'main60-v3-native-legacy',
        puzzle: old,
        isReplay: true,
      );
      for (final m in old.referenceMoves.take(2)) {
        legacy = legacy.pour(m.from, m.to).state;
      }
      legacy = legacy.grantExtraBottle();
      await prep.save(legacy, replace: true);
      await prep.close();
      app.main();
      for (
        var i = 0;
        i < 600 && find.byType(app.GameScreen).evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 30));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
      final c = t
          .widget<app.GameScreen>(find.byType(app.GameScreen))
          .controller;
      final shots = <Map<String, Object?>>[];
      final actions = <String>[];
      bool routeSettled() {
        for (final e
            in find
                .byWidgetPredicate(
                  (w) =>
                      w is FadeThroughTransition || w is SharedAxisTransition,
                )
                .evaluate()) {
          final w = e.widget;
          final animations = w is FadeThroughTransition
              ? [w.animation, w.secondaryAnimation]
              : [(w as SharedAxisTransition).animation, w.secondaryAnimation];
          if (animations.any((a) => a.isAnimating)) return false;
        }
        return true;
      }

      Future<void> ready() async {
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        do {
          await t.pump(const Duration(milliseconds: 20));
          expect(t.takeException(), isNull);
          if (!c.busy && !c.hintSearching && routeSettled()) break;
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        } while (DateTime.now().isBefore(deadline));
        expect(c.busy, isFalse);
        expect(c.hintSearching, isFalse);
        expect(c.phase, SavePhase.clean);
        expect(routeSettled(), isTrue);
        if (c.page == GamePage.board) await settleFlameBoard(t, c);
      }

      Future<void> tap(String key) async {
        final target = find.byKey(Key(key));
        expect(target.hitTestable(), findsOneWidget, reason: key);
        await t.tap(target);
        actions.add(key);
        await ready();
      }

      void bounds() {
        final media = MediaQuery.of(t.element(find.byType(app.GameScreen)));
        for (var i = 0; i < c.current!.board.length; i++) {
          final target = find.byKey(Key('bottle-$i'));
          final r = t.getRect(target);
          expect(target.hitTestable(), findsOneWidget);
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(media.size.width + .01));
          expect(r.top, greaterThanOrEqualTo(media.padding.top));
          expect(
            r.bottom,
            lessThanOrEqualTo(media.size.height - media.padding.bottom + .01),
          );
        }
      }

      Future<void> shot(
        String name, {
        String source = 'normal main/Bootstrap; native UI',
      }) async {
        await t.pump();
        final bytes = await binding.takeScreenshot(name);
        await File('${out.path}/$name.png').writeAsBytes(bytes, flush: true);
        final media = MediaQuery.of(t.element(find.byType(app.GameScreen)));
        shots.add({
          'file': '$name.png',
          'source': source,
          'viewport': [media.size.width, media.size.height],
          'text_scale': media.textScaler.scale(14) / 14,
          'puzzle': c.current?.puzzle.id,
          'version': c.current?.puzzle.contentVersion,
          'board': c.current?.board,
          'revision': c.current?.revision,
          'page': c.page.name,
          'motion_token': c.motion?.token,
        });
        debugPrint('MAIN60_NATIVE_SHOT=$name');
      }

      Future<void> pour(int from, int to, {String? keyframe}) async {
        if (c.selectedSource != null) await tap('bottle-${c.selectedSource}');
        await tap('bottle-$from');
        final target = find.byKey(Key('bottle-$to'));
        expect(target.hitTestable(), findsOneWidget);
        await t.tap(target);
        actions.add('bottle-$to');
        if (keyframe != null) {
          for (var i = 0; i < 200 && c.motion == null; i++) {
            await t.pump(const Duration(milliseconds: 10));
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 2)),
            );
          }
          expect(c.motion, isNotNull);
          await t.pump(const Duration(milliseconds: 500));
          await shot(keyframe);
        }
        await ready();
        expect(
          (await c.store.load('ordinary')).instance!.toJson(),
          c.current!.toJson(),
        );
      }

      await ready();
      expect(c.library.main[21]!.initial, hasLength(7));
      await tap('resume');
      expect(c.current!.toJson(), legacy.toJson());
      bounds();
      await shot('legacy-v3-retained');
      expect(await c.startLevel(21, replace: true), isTrue);
      await ready();
      expect(c.current!.board, hasLength(7));
      bounds();
      await shot('five-color-seven');
      await tap('bottle-4');
      await shot('rose-target-selected');
      await tap('hint');
      expect(c.hint?.status, HintStatus.found);
      await shot('five-color-hint');
      if (c.selectedSource != null) await tap('bottle-${c.selectedSource}');
      await tap('extra-bottle');
      expect(c.current!.board, hasLength(8));
      bounds();
      await shot('five-color-eight');
      final entitlement = await c.store.db.query('reward_entitlements');
      expect(entitlement, hasLength(1));
      await c.watchExtraBottle();
      await ready();
      expect(await c.store.db.query('reward_entitlements'), hasLength(1));
      await pour(4, 7, keyframe: 'same-row-pour-keyframe');
      await tap('undo');
      expect(c.current!.board, [...c.current!.puzzle.initial, <String>[]]);
      await pour(2, 7, keyframe: 'cross-row-pour-keyframe');
      await tap('pause');
      await tap('pause-restart');
      await tap('confirm-restart');
      expect(c.current!.board, [...c.current!.puzzle.initial, <String>[]]);
      expect(c.current!.extraBottleGranted, isTrue);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      await t.pump(const Duration(milliseconds: 300));
      bounds();
      await shot(
        'eight-text2-basic',
        source: 'normal main/Bootstrap, controlled platform text scale2 basic usability',
      );
      t.platformDispatcher.clearTextScaleFactorTestValue();
      await t.pump(const Duration(milliseconds: 300));
      for (final m in c.current!.puzzle.referenceMoves) {
        await pour(m.from, m.to);
      }
      expect(c.current!.completed, isTrue);
      expect(c.receipt, isNotNull);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(Key('completion-bottle-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('completion-bottle-5')), findsNothing);
      await shot('five-target-completion');
      expect(
        c.receipt!.firstClear,
        isFalse,
        reason: 'prior59 are explicit seeded QA progress',
      );
      for (final level in [31, 40, 50, 60]) {
        expect(await c.startLevel(level, replace: true), isTrue);
        await ready();
        bounds();
        await shot('stage-$level-opening');
        await tap('hint');
        expect(c.hint?.status, HintStatus.found);
        if (level == 60) {
          for (final m in c.current!.puzzle.referenceMoves) {
            await pour(m.from, m.to);
          }
          expect(c.receipt!.firstClear, isTrue);
          expect(c.progress.firstClears, 60);
          expect(c.progress.pieces.toSet(), hasLength(15));
          await shot('stage-60-five-target-completion');
        }
      }
      expect(await c.startLevel(31, replace: true), isTrue);
      await ready();
      await tap('extra-bottle');
      await pour(0, 7);
      bounds();
      await shot('persisted-eight-before-process-restore');
      for (final table in [
        'reward_attempts',
        'fullscreen_attempts',
        'fullscreen_shows',
      ]) {
        expect(await c.store.db.query(table), isEmpty);
      }
      final report = {
        'status': 'evidence_ready',
        'run': run,
        'scope': 'actual normal Bootstrap/native sqflite and automated pointers; seeded1–59, looked-up reference solutions and Hint used; not blind human play or process-kill proof',
        'database': filename,
        'snapshot_for_normal_main_restore': c.current!.toJson(),
        'screenshots': shots,
        'native_actions': actions,
        'first_clears': c.progress.firstClears,
        'pieces': c.progress.pieces,
        'integrity': await c.store.db.rawQuery('PRAGMA integrity_check'),
      };
      await File('${out.path}/runtime.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
        flush: true,
      );
      debugPrint('MAIN60_NATIVE_EVIDENCE_READY=${out.path}');
      final deadline = DateTime.now().add(const Duration(seconds: 55));
      while (!await ack.exists() && DateTime.now().isBefore(deadline)) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump(const Duration(milliseconds: 20));
      }
      expect(
        await ack.exists(),
        isTrue,
        reason: 'host must copy sandbox evidence before runner teardown',
      );
      debugPrint('MAIN60_NATIVE_PASS');
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
