import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamemunchies_client/gamemunchies_client.dart';
import 'package:gamemunchies_client/src/preferences_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_consent.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Transport, Handle;
import 'b04_services_test.dart' show Consent;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test('production and test identities cannot be silently mixed', () {
    expect(
      GameMunchiesReporting.registrationMatches(
        GameMunchiesReporting.productionGameId,
        'production',
      ),
      true,
    );
    expect(
      GameMunchiesReporting.registrationMatches(
        GameMunchiesReporting.testGameId,
        'test',
      ),
      true,
    );
    expect(
      GameMunchiesReporting.registrationMatches(
        GameMunchiesReporting.productionGameId,
        'test',
      ),
      false,
    );
    expect(
      GameMunchiesReporting.registrationMatches('unknown', 'production'),
      false,
    );
    expect(GameMunchiesReporting.baseUrl, 'https://api.gamemunchies.com');
  });
  test('Analytics off receives remote total/scene rules through one client without any event POST', () async {
    final directory = Directory.systemTemp.createTempSync('gm-config-');
    final store = await GameStore.open(
      '${directory.path}/qa.sqlite',
      factory: databaseFactoryFfi,
    );
    var now = DateTime.utc(2026, 10, 28).millisecondsSinceEpoch,
        version = 1,
        posts = 0;
    var config = <String, dynamic>{
      ...GameMunchiesReporting.defaultConfig,
      'enabled': false,
    };
    late GameMunchiesClient client;
    late GameMunchiesReporting reporting;
    reporting = GameMunchiesReporting(
      createClient: () => client = GameMunchiesClient(
        ClientOptions(
          baseUrl: GameMunchiesReporting.baseUrl,
          gameId: GameMunchiesReporting.testGameId,
          platform: 'android',
          environment: 'test',
          defaultConfig: GameMunchiesReporting.defaultConfig,
          onConfigChanged: (_) => reporting.onRulesChanged?.call(),
        ),
        store: MemoryStore(),
        now: () => now,
        httpClient: MockClient((r) async {
          if (r.method == 'POST') {
            posts++;
            return http.Response('', 503);
          }
          return http.Response(
            jsonEncode({
              'gameId': GameMunchiesReporting.testGameId,
              'platform': 'android',
              'version': version,
              'publishedAt': '2026-10-28T00:00:00Z',
              'config': config,
            }),
            200,
          );
        }),
      ),
    );
    final transport = Transport(),
        consent = Consent()
          ..answer = const AdConsent(allowed: true, optionsRequired: false);
    final hub = ServiceHub(
      store: store,
      config: const ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-3940256099942544/1033173712',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      ),
      knownPuzzleIds: {},
      reporting: reporting,
      transport: transport,
      consent: consent,
    );
    try {
      await hub.initializeLocal();
      await reporting.setEnabled(false);
      await client.refreshConfig();
      await hub.prepareAdsPrivacy();
      expect(reporting.snapshot['version'], 1);
      expect(transport.loads, isEmpty);
      final before = hub.ads.revision;
      now += 300001;
      version = 2;
      config = {
        ...GameMunchiesReporting.defaultConfig,
        'interstitial': {
          'enabled': true,
          'scenes': {'next_level': false},
          'minIntervalSeconds': 180,
        },
      };
      await client.refreshConfig();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(hub.ads.revision, greaterThan(before));
      expect(transport.kinds, [AdKind.rewarded]);
      expect(reporting.allowsLoad(AdKind.interstitial), false);
      expect(reporting.allowsLoad(AdKind.rewarded), true);
      await reporting.roundStarted('off', DateTime.now());
      await reporting
          .loadAttempt(AdKind.rewarded)
          .emit('ad_load_failed', reason: 'network');
      await client.flush();
      expect(posts, 0);
    } finally {
      hub.dispose();
      for (final load in transport.loads) {
        if (!load.isCompleted) load.complete(Handle());
      }
      await reporting.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await store.close();
      directory.deleteSync(recursive: true);
    }
  });
  test('impression while Analytics off updates SDK interval but never queues statistics', () async {
    final state = MemoryStore();
    late GameMunchiesClient client;
    final now = DateTime.utc(2026, 10, 28);
    final reporting = GameMunchiesReporting(
      now: () => now,
      createClient: () => client = GameMunchiesClient(
        ClientOptions(
          baseUrl: GameMunchiesReporting.baseUrl,
          gameId: 'off-impression',
          platform: 'ios',
          environment: 'test',
          defaultConfig: GameMunchiesReporting.defaultConfig,
        ),
        store: state,
        now: () => now.millisecondsSinceEpoch,
        httpClient: MockClient((r) async => http.Response('', 409)),
      ),
    );
    await reporting.setEnabled(false);
    expect(reporting.allowsShow(AdKind.interstitial), true);
    await reporting.opportunity(AdKind.interstitial).emit('ad_impression');
    expect(reporting.allowsShow(AdKind.interstitial), false);
    expect((await state.read(client.scope))!['events'], isEmpty);
    await reporting.dispose();
  });
}
