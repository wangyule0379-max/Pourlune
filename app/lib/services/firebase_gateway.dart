import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'service_policy.dart';

abstract interface class FirebaseGateway {
  Future<void> initialize(FirebaseOptions options);
  Future<void> privacy({required bool analytics, required bool crash});
  Future<Map<String, String>> remote();
  Future<void> event(String name, Map<String, Object> parameters);
  Future<void> error(String category, StackTrace stack, {required bool fatal});
}

class FlutterFireGateway implements FirebaseGateway {
  FirebaseApp? _app;
  int _privacyGeneration = 0;
  bool _analyticsAllowed = false, _crashAllowed = false;
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instanceFor(app: _app!);
  @override
  Future<void> initialize(FirebaseOptions options) async {
    _app = await Firebase.initializeApp(options: options);
  }

  @override
  Future<void> privacy({required bool analytics, required bool crash}) async {
    final generation = ++_privacyGeneration;
    _analyticsAllowed = analytics;
    _crashAllowed = crash;
    await _analytics.setAnalyticsCollectionEnabled(false);
    if (generation != _privacyGeneration) return;
    await _analytics.setConsent(
      analyticsStorageConsentGranted: analytics,
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    if (generation != _privacyGeneration) return;
    if (analytics) await _analytics.setAnalyticsCollectionEnabled(true);
    if (generation != _privacyGeneration) return;
    // Automatic upload is never turned on; false cannot undo a previous true
    // within this run. Explicit sharing includes cached reports disclosed in UI.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    if (generation != _privacyGeneration) return;
    if (crash) {
      await FirebaseCrashlytics.instance.sendUnsentReports();
    } else {
      await FirebaseCrashlytics.instance.deleteUnsentReports();
    }
  }

  @override
  Future<Map<String, String>> remote() async {
    final rc = FirebaseRemoteConfig.instanceFor(app: _app!);
    await rc.setDefaults(RemotePolicy.defaults);
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 12),
      ),
    );
    await rc.fetchAndActivate();
    return {
      for (final key in RemotePolicy.defaults.keys)
        key: rc.getValue(key).asString(),
    };
  }

  @override
  Future<void> event(String name, Map<String, Object> parameters) async {
    if (_analyticsAllowed) {
      await _analytics.logEvent(name: name, parameters: parameters);
    }
  }

  @override
  Future<void> error(
    String category,
    StackTrace stack, {
    required bool fatal,
  }) async {
    if (!_crashAllowed) return;
    await FirebaseCrashlytics.instance.recordError(
      StateError(category),
      stack,
      fatal: fatal,
    );
    if (_crashAllowed) await FirebaseCrashlytics.instance.sendUnsentReports();
  }
}
