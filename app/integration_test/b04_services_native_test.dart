// Real sqflite/Google plugin probe. Setup clears ONLY b04_native.sqlite.
// No fake consent or rewards. Setup settlements unlock level4, never simulate SDK reward.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as app;
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/ad_consent.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'B04 real plugin qualification / optional ad / free play evidence',
    (t) async {
      final path = '${await getDatabasesPath()}/b04_native.sqlite';
      await deleteDatabase(path);
      final captureKey = GlobalKey();
      runApp(RepaintBoundary(key: captureKey, child: const app.Bootstrap()));
      for (
        var i = 0;
        i < 100 && find.byType(app.GameScreen).evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final c = t
          .widget<app.GameScreen>(find.byType(app.GameScreen))
          .controller;
      final hub = c.services!;
      final out = Directory('${await getDatabasesPath()}/b04-evidence');
      await out.create(recursive: true);
      final evidence = <String, Object?>{
        'scope': 'real plugin / iOS Simulator, no Firebase project',
        'setup': 'three reference settlements unlock4, no reward seed',
        'firebase': hub.firebaseStatus,
      };
      Future<void> write() => File('${out.path}/services.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
      Future<void> capture(String name) async {
        await t.pump();
        final render =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${out.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      for (var i = 0; i < 130 && hub.privacyBusy; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      evidence['ump_allowed'] = hub.ads.allowed;
      evidence['ump_failed'] = hub.adPrivacyFailed;
      evidence['privacy_options_required'] = hub.adPrivacyRequired;
      if (hub.adPrivacyFailed) {
        // Read-only SDK status/error probe, never override eligibility.
        final result = await UmpConsentGateway(hub.config).request().timeout(
          const Duration(seconds: 20),
          onTimeout: () => const AdConsent(
            allowed: false,
            optionsRequired: false,
            failed: true,
          ),
        );
        evidence['second_official_request'] = {
          'allowed': result.allowed,
          'failed': result.failed,
          'options_required': result.optionsRequired,
        };
      }
      await write();
      for (var level = 1; level <= 3; level++) {
        var s = GameInstance.create(
          id: 'b04-setup-$level',
          puzzle: c.library.main[level]!,
        );
        for (final move in s.puzzle.referenceMoves) {
          s = s.pour(move.from, move.to).state;
        }
        await c.store.settle(s, replace: true);
      }
      await c.initialize();
      await c.startLevel(4);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('extra-bottle')));
      await t.tap(find.byKey(const Key('extra-bottle')));
      await t.pumpAndSettle();
      evidence['explanation_visible'] = find
          .text('Watch ad')
          .evaluate()
          .isNotEmpty;
      await capture('extra-explanation');
      evidence['attempts_before_watch'] = (await c.store.db.query(
        'reward_attempts',
      )).length;
      await write();
      // Allows external screenshots of actual UI; no input injected by this wait.
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
      await t.tap(find.text('Not now'));
      await t.pumpAndSettle();
      const privacyOnly = bool.fromEnvironment('POURLUNE_TEST_PRIVACY_OPTIONS');
      if (hub.ads.allowed && !privacyOnly) {
        final loading = hub.ads.preload(AdKind.rewarded);
        for (
          var n = 0;
          n < 320 && hub.ads.state(AdKind.rewarded) == AdLoadState.loading;
          n++
        ) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await loading;
        evidence['rewarded_load_state'] = hub.ads.state(AdKind.rewarded).name;
        evidence['rewarded_load_reason'] = hub.ads.loadReasons[AdKind.rewarded];
        if (c.canWatchExtraBottle) {
          await t.ensureVisible(find.byKey(const Key('extra-bottle')));
          await t.tap(find.byKey(const Key('extra-bottle')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('watch-ad')));
          await t.pump();
          evidence['show_requested_from_watch_button'] = true;
          await write();
          debugPrint('B04_WAIT_FOR_ACTUAL_REWARDED_AD_CLOSE');
          // Human/agent uses the real SDK Close affordance, never synthetic callback.
          for (var n = 0; n < 125 && c.busy; n++) {
            await t.pump(const Duration(seconds: 1));
          }
          evidence['extra_after_actual_callback'] =
              c.current!.extraBottleGranted;
        }
      }
      await c.pour(0, 2);
      c.completeMotion(c.motion?.token ?? -1);
      await t.pumpAndSettle();
      evidence['free_move_saved'] =
          (await c.store.load('ordinary')).instance!.revision ==
          c.current!.revision;
      evidence['attempts'] = await c.store.db.query(
        'reward_attempts',
        columns: ['attempt_id', 'status', 'confirmed'],
      );
      evidence['entitlements'] = await c.store.db.query('reward_entitlements');
      evidence['fullscreen'] = await c.store.db.query('fullscreen_shows');
      await c.navigate(GamePage.settings);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('privacy')));
      await t.tap(find.byKey(const Key('privacy')));
      await t.pumpAndSettle();
      evidence['privacy_choices_visible'] =
          find.byKey(const Key('analytics-choice')).evaluate().isNotEmpty &&
          find.byKey(const Key('crash-choice')).evaluate().isNotEmpty;
      await write();
      await capture('privacy-choices');
      if (privacyOnly && hub.adPrivacyRequired) {
        debugPrint('B04_WAIT_FOR_OFFICIAL_PRIVACY_OPTIONS');
        await t.tap(find.text('Close'));
        await t.pumpAndSettle();
        final options = hub.showAdPrivacy();
        for (var i = 0; i < 125 && hub.privacyBusy; i++) {
          await t.pump(const Duration(seconds: 1));
        }
        await options;
        evidence['privacy_options_completed'] = !hub.privacyBusy;
        evidence['privacy_options_after'] = {
          'allowed': hub.ads.allowed,
          'failed': hub.adPrivacyFailed,
          'required': hub.adPrivacyRequired,
        };
        await write();
      }
      debugPrint('B04_NATIVE_EVIDENCE ${jsonEncode(evidence)}');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 12)));
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
