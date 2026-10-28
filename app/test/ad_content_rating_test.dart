import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as plugin;
import 'package:pourlune_dev/services/ad_consent.dart';
import 'package:pourlune_dev/services/service_config.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'production SDK initialization applies PG ceiling before any ads load',
    () async {
      plugin.instanceManager = plugin.AdInstanceManager(
        'plugins.flutter.io/google_mobile_ads',
      );
      final calls = <MethodCall>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        plugin.instanceManager.channel,
        (call) async {
          calls.add(call);
          return call.method == 'MobileAds#initialize'
              ? InitializationStatus({})
              : null;
        },
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          plugin.instanceManager.channel,
          null,
        ),
      );
      await UmpConsentGateway(const ServiceConfig(adMode: 'production'))
          .initializeAds();
      final config = calls.singleWhere(
        (call) => call.method == 'MobileAds#updateRequestConfiguration',
      );
      expect((config.arguments as Map)['maxAdContentRating'], 'PG');
      expect(
        calls.indexOf(config),
        lessThan(
          calls.indexWhere((call) => call.method == 'MobileAds#initialize'),
        ),
      );
      expect((config.arguments as Map)['testDeviceIds'], isNull);
    },
  );
}
