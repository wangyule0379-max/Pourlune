import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client configuration only; no account, service key or signing secret.
class ServiceConfig {
  const ServiceConfig({
    this.adMode = 'disabled',
    this.interstitialId = '',
    this.rewardedId = '',
    this.firebaseJson = '',
    this.firebaseNativeReady = false,
    this.supportUrl = '',
    this.privacyUrl = '',
    this.feedbackEmail = '',
    this.umpTestDevice = '',
    this.umpTestRegion = '',
  });
  final bool firebaseNativeReady;
  final String adMode,
      interstitialId,
      rewardedId,
      firebaseJson,
      supportUrl,
      privacyUrl,
      feedbackEmail,
      umpTestDevice,
      umpTestRegion;
  static ServiceConfig environment() {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    const mode = String.fromEnvironment(
      'POURLUNE_AD_MODE',
      defaultValue: kReleaseMode ? 'disabled' : 'test',
    );
    return ServiceConfig(
      adMode: mode,
      interstitialId: mode == 'test'
          ? (ios
                ? 'ca-app-pub-3940256099942544/4411468910'
                : 'ca-app-pub-3940256099942544/1033173712')
          : const String.fromEnvironment('POURLUNE_INTERSTITIAL_ID'),
      rewardedId: mode == 'test'
          ? (ios
                ? 'ca-app-pub-3940256099942544/1712485313'
                : 'ca-app-pub-3940256099942544/5224354917')
          : const String.fromEnvironment('POURLUNE_REWARDED_ID'),
      firebaseJson: const String.fromEnvironment('POURLUNE_FIREBASE_OPTIONS'),
      firebaseNativeReady: const bool.fromEnvironment(
        'POURLUNE_FIREBASE_NATIVE_READY',
      ),
      supportUrl: const String.fromEnvironment('POURLUNE_SUPPORT_URL'),
      privacyUrl: const String.fromEnvironment('POURLUNE_PRIVACY_URL'),
      feedbackEmail: const String.fromEnvironment('POURLUNE_FEEDBACK_EMAIL'),
      umpTestDevice: kDebugMode
          ? const String.fromEnvironment('POURLUNE_UMP_TEST_DEVICE')
          : '',
      umpTestRegion: kDebugMode
          ? const String.fromEnvironment('POURLUNE_UMP_TEST_REGION')
          : '',
    );
  }

  bool get testing => adMode == 'test';
  bool get adsConfigured {
    final valid = RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]{10}$');
    if (!{'test', 'production'}.contains(adMode) ||
        !valid.hasMatch(interstitialId) ||
        !valid.hasMatch(rewardedId)) {
      return false;
    }
    const testPublisher = 'ca-app-pub-3940256099942544/';
    return testing
        ? interstitialId.startsWith(testPublisher) &&
              rewardedId.startsWith(testPublisher)
        : !interstitialId.startsWith(testPublisher) &&
              !rewardedId.startsWith(testPublisher);
  }

  FirebaseOptions? get firebaseOptions {
    if (!firebaseNativeReady) return null;
    try {
      final m = jsonDecode(firebaseJson);
      if (m is! Map<String, dynamic> ||
          m.keys.any(
            (k) => !{
              'apiKey',
              'appId',
              'messagingSenderId',
              'projectId',
              'storageBucket',
              'iosBundleId',
            }.contains(k),
          )) {
        return null;
      }
      String field(String k) => m[k] is String ? m[k] as String : '';
      if (!RegExp(r'^AIza[A-Za-z0-9_-]{35}$').hasMatch(field('apiKey')) ||
          !RegExp(r'^1:[0-9]+:(ios|android):[A-Fa-f0-9]+$')
              .hasMatch(field('appId')) ||
          !RegExp(r'^[0-9]+$').hasMatch(field('messagingSenderId')) ||
          !RegExp(r'^[a-z][a-z0-9-]{4,28}[a-z0-9]$')
              .hasMatch(field('projectId'))) {
        return null;
      }
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      if (!field('appId').contains(':$platform:') ||
          !field('appId').startsWith('1:${field('messagingSenderId')}:')) {
        return null;
      }
      return FirebaseOptions(
        apiKey: field('apiKey'),
        appId: field('appId'),
        messagingSenderId: field('messagingSenderId'),
        projectId: field('projectId'),
        storageBucket: m['storageBucket'] as String?,
        iosBundleId: m['iosBundleId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Uri? httpsUrl(String value) {
    final u = Uri.tryParse(value);
    if (u == null ||
        u.scheme != 'https' ||
        u.host.isEmpty ||
        u.userInfo.isNotEmpty ||
        !u.host.contains('.') ||
        [
          'localhost',
          'example.com',
          'example.org',
          'example.net',
        ].contains(u.host) ||
        u.host.endsWith('.invalid') ||
        u.host.endsWith('.test') ||
        u.host.endsWith('.example')) {
      return null;
    }
    return u;
  }

  Uri? get support => httpsUrl(supportUrl);
  Uri? get privacy => httpsUrl(privacyUrl);
  Uri? get feedback {
    if (!RegExp(
          r'^[a-zA-Z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(feedbackEmail) ||
        httpsUrl('https://${feedbackEmail.split('@').last}') == null) {
      return null;
    }
    return Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: {'subject': 'Pourlune feedback'},
    );
  }
}
