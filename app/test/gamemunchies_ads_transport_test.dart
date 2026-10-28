import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as plugin;
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/google_ads_transport.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';

import 'gamemunchies_reporting_test.dart' show ReportingHarness;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late ReportingHarness h;
  late GameMunchiesReporting stats;
  late GoogleAdsTransport transport;
  final calls = <MethodCall>[];
  Future<void> event(
    int id,
    String name, [
    Map<String, Object?> extra = const {},
  ]) async {
    final channel = plugin.instanceManager.channel;
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': name, ...extra}),
      ),
      (_) {},
    );
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    plugin.instanceManager = plugin.AdInstanceManager(
      'plugins.flutter.io/google_mobile_ads',
    );
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      plugin.instanceManager.channel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    h = ReportingHarness();
    stats = h.reporting();
    await stats.setEnabled(true);
    transport = GoogleAdsTransport(
      const ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-3940256099942544/1033173712',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      ),
      reporting: stats,
    );
  });
  tearDown(() async {
    await stats.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      plugin.instanceManager.channel,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  test('opt-in during loading reports the later callback without inventing an earlier request', () async {
    await stats.setEnabled(false);
    final pending = transport.load(AdKind.rewarded);
    final failure = expectLater(pending, throwsA(isA<AdLoadFailure>()));
    await Future<void>.delayed(Duration.zero);
    final id = (calls.single.arguments as Map)['adId'] as int;
    await h.flush();
    expect(h.posts, isEmpty);
    await stats.setEnabled(true);
    await event(id, 'onAdFailedToLoad', {
      'loadAdError': LoadAdError(3, 'com.google.android.gms.ads', 'test', null),
    });
    await failure;
    await h.flush();
    expect(h.received.map((e) => e['type']), ['ad_load_failed']);
    expect(h.received.single['ad']['reason'], 'no_fill');
  });

  for (final kind in AdKind.values) {
    test(
      '${kind.name}: load/show/open/close are not impressions; real impression type counts once',
      () async {
        final pending = transport.load(kind);
        await Future<void>.delayed(Duration.zero);
        final id = (calls.single.arguments as Map)['adId'] as int;
        await event(id, 'onAdLoaded');
        final handle = await pending;
        var rewards = 0;
        await handle.show(
          AdCallbacks(
            shown: () {},
            impression: () {},
            closed: () {},
            failed: () {},
            reward: () => rewards++,
          ),
        );
        await event(id, 'onAdShowedFullScreenContent');
        await h.flush();
        expect(h.received.map((e) => e['type']), [
          'ad_load_requested',
          'ad_loaded',
          'ad_opportunity',
          'ad_show_attempted',
        ]);
        expect(
          h.received.every(
            (e) =>
                e['ad']['provider'] == 'admob' && e['ad']['kind'] == kind.name,
          ),
          isTrue,
        );
        await event(id, 'onAdImpression');
        h.now = h.now.add(const Duration(seconds: 3));
        await event(id, 'onAdImpression');
        await h.flush();
        final impressions = h.received.where(
          (e) => e['type'] == 'ad_impression',
        );
        expect(impressions.length, 1);
        expect(impressions.single['occurredAt'], '2026-10-28T01:00:00.000Z');
        await event(id, 'onAdDismissedFullScreenContent');
        expect(rewards, 0);
        await handle.dispose();
      },
    );
  }

  test(
    'load failure and show failure have separate stages and reasons',
    () async {
      final pending = transport.load(AdKind.rewarded);
      final failed = expectLater(pending, throwsA(isA<AdLoadFailure>()));
      await Future<void>.delayed(Duration.zero);
      final id = (calls.single.arguments as Map)['adId'] as int;
      await event(id, 'onAdFailedToLoad', {
        'loadAdError': LoadAdError(
          2,
          'com.google.android.gms.ads',
          'test',
          null,
        ),
      });
      await failed;
      await h.flush();
      expect(h.received.map((e) => e['type']), [
        'ad_load_requested',
        'ad_load_failed',
      ]);
      expect(h.received.last['ad']['reason'], 'network');
      expect(
        h.received.first['ad']['loadAttemptId'],
        h.received.last['ad']['loadAttemptId'],
      );
      final another = transport.load(AdKind.interstitial);
      await Future<void>.delayed(Duration.zero);
      final next =
          (calls.lastWhere((c) => c.method == 'loadInterstitialAd').arguments
                  as Map)['adId']
              as int;
      await event(next, 'onAdLoaded');
      final handle = await another;
      await handle.show(
        AdCallbacks(
          shown: () {},
          impression: () {},
          reward: () {},
          closed: () {},
          failed: () {},
        ),
      );
      await event(next, 'onFailedToShowFullScreenContent', {
        'error': AdError(0, 'test', 'test'),
      });
      await h.flush();
      expect(h.received.where((e) => e['type'] == 'ad_impression'), isEmpty);
      expect(h.received.last['type'], 'ad_show_failed');
      expect(h.received.last['ad']['reason'], 'sdk_error');
      await handle.dispose();
    },
  );

  test('offline reporting cannot prevent real reward callback; close alone grants nothing', () async {
    h.offline = true;
    final pending = transport.load(AdKind.rewarded);
    await Future<void>.delayed(Duration.zero);
    final id = (calls.single.arguments as Map)['adId'] as int;
    await event(id, 'onAdLoaded');
    final handle = await pending;
    var rewarded = 0;
    await handle.show(
      AdCallbacks(
        shown: () {},
        impression: () {},
        closed: () {},
        failed: () {},
        reward: () => rewarded++,
      ),
    );
    await event(id, 'onAdImpression');
    await h.flush();
    await event(id, 'onAdDismissedFullScreenContent');
    expect(rewarded, 0);
    await event(id, 'onRewardedAdUserEarnedReward', {
      'rewardItem': RewardItem(1, 'extra_bottle'),
    });
    expect(rewarded, 1);
    await event(id, 'onRewardedAdUserEarnedReward', {
      'rewardItem': RewardItem(1, 'extra_bottle'),
    });
    expect(h.received, isEmpty);
    h.offline = false;
    h.now = h.now.add(const Duration(seconds: 3));
    await h.flush();
    final rewards = h.received.where((e) => e['type'] == 'ad_reward_earned');
    expect(rewards.length, 1);
    final impression = h.received.singleWhere(
      (e) => e['type'] == 'ad_impression',
    );
    expect(
      rewards.single['ad']['opportunityId'],
      impression['ad']['opportunityId'],
    );
    expect(
      rewards.single['ad']['loadAttemptId'],
      h.received.first['ad']['loadAttemptId'],
    );
    await handle.dispose();
  });
}
