// ADM01 real UMP/GMA probe; no capture, fabricated consent/reward, or Firebase.
// Host must use the independent dev.pourlune.admobValidation QA identity.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('ADM01 real SDK qualification and local-save fallback probe', (
    t,
  ) async {
    const database = String.fromEnvironment('POURLUNE_DATABASE');
    const native = String.fromEnvironment('POURLUNE_AD_NATIVE_ID');
    expect(database, 'adm01_native.sqlite');
    expect(native, 'dev.pourlune.admobValidation');
    final config = ServiceConfig.environment();
    expect(config.testing && config.adsConfigured, isTrue);
    expect(config.firebaseNativeReady, isFalse);
    expect(config.umpTestRegion, isEmpty);
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('AdMob SDK QA'))),
    );
    final result = <String, Object?>{
      'scope': 'actual SDK qualification/load; no production configuration or capture',
      'ad_mode': config.adMode,
      'interstitial_unit': config.interstitialId,
      'rewarded_unit': config.rewardedId,
      'native_identity': native,
      'owned_admob_registration': false,
      'show_close_reward_verified': false,
    };
    await t.runAsync(() async {
      final base = await getDatabasesPath();
      final path = '$base/$database';
      await deleteDatabase(path);
      final store = await GameStore.open(path);
      final hub = ServiceHub(
        store: store,
        config: config,
        knownPuzzleIds: {'main-001'},
        consentTimeout: const Duration(seconds: 35),
      );
      try {
        await hub.initializeLocal();
        await hub.prepareAdsPrivacy();
        result['ump_allowed'] = hub.ads.allowed;
        result['ump_failed'] = hub.adPrivacyFailed;
        result['privacy_options_required'] = hub.adPrivacyRequired;
        if (hub.ads.allowed) {
          for (var n = 0; n < 350; n++) {
            if (AdKind.values.every(
              (k) => hub.ads.state(k) != AdLoadState.loading,
            )) {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }
        result['inventory'] = {
          for (final kind in AdKind.values)
            kind.name: {
              'state': hub.ads.state(kind).name,
              'reason': hub.ads.loadReasons[kind],
            },
        };
        final puzzle = Puzzle.parse(
          await rootBundle.loadString('assets/puzzles/main/main-001.json'),
        );
        var instance = GameInstance.create(id: 'adm01-local', puzzle: puzzle);
        await store.save(instance);
        final move = puzzle.referenceMoves.first;
        instance = instance.pour(move.from, move.to).state;
        await store.save(instance);
        expect(
          (await store.load('ordinary')).instance!.revision,
          instance.revision,
        );
        expect(hub.firebaseStatus, 'disabled');
        expect(hub.choices.analytics || hub.choices.crash, isFalse);
        result['local_move_saved'] = true;
        result['firebase'] = hub.firebaseStatus;
        result['sharing_defaults_off'] = true;
        result['sdk_status'] = hub.ads.allowed
            ? 'qualified; inventory recorded; actual display/close/reward still unverified'
            : 'unavailable; no SDK load/show/reward claimed';
        final text = const JsonEncoder.withIndent('  ').convert(result);
        await File('$base/adm01-sdk-probe.json').writeAsString(text);
        debugPrint('ADM01_NATIVE_PROBE ${jsonEncode(result)}');
      } finally {
        hub.dispose();
        await store.close();
      }
    });
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
