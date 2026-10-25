import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_coordinator.dart';
import 'service_config.dart';

class GoogleAdsTransport implements AdTransport {
  GoogleAdsTransport(this.config);
  final ServiceConfig config;
  @override
  Future<AdHandle> load(AdKind kind) {
    final done = Completer<AdHandle>();
    if (!config.adsConfigured) {
      done.completeError(StateError('Ads not configured'));
      return done.future;
    }
    // No IDFA/tracking opt-in is inferred from ad request eligibility.
    const request = AdRequest(nonPersonalizedAds: true);
    if (kind == AdKind.interstitial) {
      InterstitialAd.load(
        adUnitId: config.interstitialId,
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => done.complete(_GoogleHandle(ad)),
          onAdFailedToLoad: (e) => done.completeError(
            AdLoadFailure(
              adLoadReason(defaultTargetPlatform, e.domain, e.code),
            ),
          ),
        ),
      );
    } else {
      RewardedAd.load(
        adUnitId: config.rewardedId,
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => done.complete(_GoogleHandle(ad)),
          onAdFailedToLoad: (e) => done.completeError(
            AdLoadFailure(
              adLoadReason(defaultTargetPlatform, e.domain, e.code),
            ),
          ),
        ),
      );
    }
    return done.future;
  }
}

class _GoogleHandle implements AdHandle {
  _GoogleHandle(this.ad);
  final AdWithoutView ad;
  @override
  Future<void> show(AdCallbacks callbacks) async {
    FullScreenContentCallback<T> full<T extends AdWithoutView>() =>
        FullScreenContentCallback<T>(
          onAdShowedFullScreenContent: (_) => callbacks.shown(),
          onAdImpression: (_) => callbacks.impression(),
          onAdDismissedFullScreenContent: (_) => callbacks.closed(),
          onAdFailedToShowFullScreenContent: (_, e) => callbacks.failed(),
        );
    if (ad is InterstitialAd) {
      final value = ad as InterstitialAd;
      value.fullScreenContentCallback = full<InterstitialAd>();
      await value.show();
    } else {
      final value = ad as RewardedAd;
      value.fullScreenContentCallback = full<RewardedAd>();
      await value.show(onUserEarnedReward: (_, reward) => callbacks.reward());
    }
  }

  @override
  Future<void> dispose() => ad.dispose();
}

/// Numeric SDK codes are platform/domain specific; no free SDK message is logged.
String adLoadReason(TargetPlatform platform, String domain, int code) {
  if (platform == TargetPlatform.android &&
      domain == 'com.google.android.gms.ads') {
    return switch (code) {
      2 => 'network',
      3 || 9 => 'no_fill',
      1 => 'invalid_request',
      _ => 'load_failed',
    };
  }
  if (platform == TargetPlatform.iOS && domain == 'com.google.admob') {
    return switch (code) {
      2 => 'network',
      1 => 'no_fill',
      5 => 'timeout',
      0 || 12 => 'invalid_request',
      _ => 'load_failed',
    };
  }
  return 'load_failed';
}
