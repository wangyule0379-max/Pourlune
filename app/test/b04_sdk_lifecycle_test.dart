// Actual locked plugin Dart routing + production GoogleAdsTransport; mocked native
// channel only. This is NOT native advertising, UMP or real earned-ad evidence.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as sdk;
import 'package:google_mobile_ads/google_mobile_ads.dart' show RewardItem;
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/google_ads_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final earns in [true, false]) {
      test(
        'B04-R01 SDK9.2 shown routing survives timeout; platform=$platform earned=$earns; dispose only on normal closure',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          final config = ServiceConfig.environment();
          final dir = Directory.systemTemp.createTempSync('b04-sdk-route-');
          final store = await GameStore.open(
            '${dir.path}/g.db',
            factory: databaseFactoryFfi,
          );
          sdk.instanceManager = sdk.AdInstanceManager(
            'plugins.flutter.io/google_mobile_ads',
          );
          final channel = sdk.instanceManager.channel;
          int? adId;
          var disposals = 0, platformShows = 0;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (call) async {
                if (call.method == 'loadRewardedAd') {
                  adId = (call.arguments as Map)['adId'] as int;
                }
                if (call.method == 'disposeAd') disposals++;
                if (call.method == 'showAdWithoutView') platformShows++;
                return null;
              });
          Future<void> event(
            String name, {
            Map<String, Object> fields = const {},
          }) async {
            final done = Completer<void>();
            ServicesBinding.instance.channelBuffers.push(
              channel.name,
              channel.codec.encodeMethodCall(
                MethodCall('onAdEvent', {
                  'adId': adId,
                  'eventName': name,
                  ...fields,
                }),
              ),
              (_) => done.complete(),
            );
            await done.future;
          }

          Future<void> until(bool Function() condition) async {
            for (var n = 0; n < 1000 && !condition(); n++) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(condition(), isTrue);
          }

          final ads = AdCoordinator(
            store: store,
            transport: GoogleAdsTransport(config),
            configured: true,
            preShowTimeout: const Duration(milliseconds: 40),
          );
          Future<Object?>? grant;
          try {
            final origin = sample('sdk-origin', level: 4);
            await store.save(origin);
            await store.beginReward('sdk-request', origin);
            await ads.initialize();
            ads.update(consent: true);
            final load = ads.preload(AdKind.rewarded);
            await until(() => adId != null);
            await event('onAdLoaded');
            await load;
            final shownId = adId!;
            var ended = false;
            final showing =
                ads.show(
                  AdKind.rewarded,
                  'sdk-request',
                  onReward: () {
                    grant = store.confirmReward('sdk-request');
                  },
                )..then((_) {
                  ended = true;
                });
            await until(() => platformShows == 1);
            await event(
              platform == TargetPlatform.android
                  ? 'onAdShowedFullScreenContent'
                  : 'adWillPresentFullScreenContent',
            );
            ads.update(isForeground: false);
            await Future<void>.delayed(const Duration(milliseconds: 90));
            expect(ads.showing, isTrue);
            expect(ended, isFalse);
            expect(disposals, 0);
            expect(sdk.instanceManager.adFor(shownId), isNotNull);
            ads.update(isForeground: true);
            if (earns) {
              await event(
                'onRewardedAdUserEarnedReward',
                fields: {'rewardItem': RewardItem(1, 'bottle')},
              );
              await event(
                'onRewardedAdUserEarnedReward',
                fields: {'rewardItem': RewardItem(1, 'bottle')},
              );
              await grant;
            }
            expect(
              (await store.load('ordinary')).instance!.extraBottleGranted,
              earns,
            );
            await event(
              platform == TargetPlatform.android
                  ? 'onAdDismissedFullScreenContent'
                  : 'adDidDismissFullScreenContent',
            );
            await showing;
            await until(() => disposals == 1);
            expect(sdk.instanceManager.adFor(shownId), isNull);
            expect(
              await store.db.query('reward_entitlements'),
              hasLength(earns ? 1 : 0),
            );
          } finally {
            ads.dispose();
            debugDefaultTargetPlatformOverride = null;
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null);
            await store.close();
            dir.deleteSync(recursive: true);
          }
        },
      );
    }
  }
}
