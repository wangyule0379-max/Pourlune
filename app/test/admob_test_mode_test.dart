import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/services/service_config.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test('ADM01 test mode rejects wrong-platform and unknown sample units', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      const ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-3940256099942544/4411468910',
        rewardedId: 'ca-app-pub-3940256099942544/1712485313',
      ).adsConfigured,
      isFalse,
    );
    expect(
      const ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-3940256099942544/9999999999',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      ).adsConfigured,
      isFalse,
    );
    expect(ServiceConfig.environment().adsConfigured, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(ServiceConfig.environment().adsConfigured, isTrue);
    expect(
      const ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-3940256099942544/1033173712',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      ).adsConfigured,
      isFalse,
    );
  });
}
