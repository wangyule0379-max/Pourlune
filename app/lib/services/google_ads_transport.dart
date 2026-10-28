import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_coordinator.dart';
import 'service_config.dart';
import 'gamemunchies_reporting.dart';

class GoogleAdsTransport implements AdTransport {
  GoogleAdsTransport(this.config, {this.reporting});
  final ServiceConfig config;
  final GameMunchiesReporting? reporting;
  @override
  Future<AdHandle> load(AdKind kind) {
    final done = Completer<AdHandle>();
    if (!config.adsConfigured) {
      done.completeError(StateError('Ads not configured'));
      return done.future;
    }
    // No IDFA/tracking opt-in is inferred from ad request eligibility.
    const request = AdRequest(nonPersonalizedAds: true);
    final load = reporting?.loadAttempt(kind);
    void loadFailed(LoadAdError error) {
      final reason = adLoadReason(
        defaultTargetPlatform,
        error.domain,
        error.code,
      );
      if (kDebugMode) {
        // Fixed category and numeric code only; never the SDK's free message.
        debugPrint(
          'POURLUNE_AD_LOAD_FAILED ${kind.name} $reason ${error.code}',
        );
      }
      load?.emit('ad_load_failed', reason: monetizationFailureReason(reason));
      if (!done.isCompleted) {
        done.completeError(AdLoadFailure(reason));
      }
    }

    void loaded(AdWithoutView ad) {
      load?.emit('ad_loaded');
      if (done.isCompleted) return;
      done.complete(_GoogleHandle(ad, kind, reporting, load?.id));
    }

    void dispatch(Future<void> request) {
      unawaited(
        request.catchError((Object _) {
          load?.emit('ad_load_failed', reason: 'sdk_error');
          if (!done.isCompleted) {
            done.completeError(const AdLoadFailure('load_failed'));
          }
        }),
      );
    }

    if (kind == AdKind.interstitial) {
      dispatch(
        InterstitialAd.load(
          adUnitId: config.interstitialId,
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: loaded,
            onAdFailedToLoad: loadFailed,
          ),
        ),
      );
    } else {
      dispatch(
        RewardedAd.load(
          adUnitId: config.rewardedId,
          request: request,
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: loaded,
            onAdFailedToLoad: loadFailed,
          ),
        ),
      );
    }
    return done.future;
  }
}

class _GoogleHandle implements AdHandle {
  _GoogleHandle(this.ad, this.kind, this.reporting, this.loadId);
  final AdWithoutView ad;
  final AdKind kind;
  final GameMunchiesReporting? reporting;
  final String? loadId;
  bool _showCalled = false;

  @override
  Future<void> show(AdCallbacks callbacks) async {
    if (_showCalled) return;
    _showCalled = true;
    final observation = callbacks.observation ?? reporting?.opportunity(kind);
    if (loadId != null) observation?.attachLoad(loadId!);
    observation?.emit('ad_show_attempted');
    FullScreenContentCallback<T> full<T extends AdWithoutView>() =>
        FullScreenContentCallback<T>(
          onAdShowedFullScreenContent: (_) => callbacks.shown(),
          onAdImpression: (_) {
            observation?.emit('ad_impression');
            callbacks.impression();
          },
          onAdDismissedFullScreenContent: (_) => callbacks.closed(),
          onAdFailedToShowFullScreenContent: (_, e) {
            observation?.emit('ad_show_failed', reason: 'sdk_error');
            callbacks.failed();
          },
        );
    try {
      if (ad is InterstitialAd) {
        final value = ad as InterstitialAd;
        value.fullScreenContentCallback = full<InterstitialAd>();
        await value.show();
      } else {
        final value = ad as RewardedAd;
        value.fullScreenContentCallback = full<RewardedAd>();
        await value.show(
          onUserEarnedReward: (_, reward) {
            observation?.emit('ad_reward_earned');
            callbacks.reward();
          },
        );
      }
    } catch (_) {
      observation?.emit('ad_show_failed', reason: 'sdk_error');
      rethrow;
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

/// Keep the existing player-facing categories; map only the telemetry protocol.
String monetizationFailureReason(String reason) => switch (reason) {
  'network' || 'no_fill' || 'timeout' => reason,
  'invalid_request' => 'invalid_config',
  _ => 'sdk_error',
};
