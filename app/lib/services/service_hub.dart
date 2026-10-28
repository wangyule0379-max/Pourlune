import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/game_store.dart';
import 'ad_consent.dart';
import 'ad_continuation.dart';
import 'ad_coordinator.dart';
import 'firebase_gateway.dart';
import 'google_ads_transport.dart';
import 'gamemunchies_reporting.dart';
import 'service_config.dart';
import 'service_policy.dart';
import 'telemetry.dart';

class PrivacyChoices {
  const PrivacyChoices({this.analytics = false, this.crash = false});
  final bool analytics, crash;
  factory PrivacyChoices.parse(Object? raw) {
    if (raw is! Map || raw['analytics'] is! bool || raw['crash'] is! bool) {
      return const PrivacyChoices();
    }
    return PrivacyChoices(
      analytics: raw['analytics'] as bool,
      crash: raw['crash'] as bool,
    );
  }
  Map<String, bool> toJson() => {'analytics': analytics, 'crash': crash};
}

/// Optional network capabilities. Local GameController/SQLite remain authoritative.
class ServiceHub extends ChangeNotifier {
  ServiceHub({
    required this.store,
    required this.config,
    required this.knownPuzzleIds,
    AdTransport? transport,
    ConsentGateway? consent,
    FirebaseGateway? firebase,
    GameMunchiesReporting? reporting,
    this.timeout = const Duration(seconds: 5),
    this.consentTimeout = const Duration(minutes: 2),
    Duration adPreShowTimeout = const Duration(minutes: 2),
    FullscreenCooldown? adClock,
  }) : consent = consent ?? UmpConsentGateway(config),
       firebase = firebase ?? FlutterFireGateway(),
       reporting = reporting ?? GameMunchiesReporting.environment() {
    ads = AdCoordinator(
      store: store,
      transport:
          transport ?? GoogleAdsTransport(config, reporting: this.reporting),
      configured: config.adsConfigured,
      reporting: this.reporting,
      rulesAllowLoad: this.reporting.allowsLoad,
      rulesAllowShow: this.reporting.allowsShow,
      preShowTimeout: adPreShowTimeout,
      clock: adClock,
    );
    this.reporting.onRulesChanged = () => ads.update(remote: policy);
    ads.addListener(_notify);
    telemetry = ProductTelemetry(
      store,
      this.firebase,
      () =>
          firebaseReady &&
          choices.analytics &&
          !privacySaveFailed &&
          !privacySyncBusy &&
          !privacySyncFailed &&
          !_disposed,
    );
    ads.onEvent = (event, id, kind, result) {
      final type = switch (event) {
        'impression' => ProductEvent.adImpression,
        'dismiss' => ProductEvent.adDismiss,
        'error' => ProductEvent.adError,
        _ => null,
      };
      if (event == 'dismiss' && telemetry.allowed()) {
        continuation.closed(id, kind.name);
      }
      if (type != null) {
        unawaited(
          telemetry.log(type, id, {
            'request_id': id,
            'format': kind.name,
            'result': result,
          }),
        );
      }
    };
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _notify());
  }
  final GameStore store;
  final ServiceConfig config;
  final Set<String> knownPuzzleIds;
  final ConsentGateway consent;
  final FirebaseGateway firebase;
  final GameMunchiesReporting reporting;
  final Duration timeout, consentTimeout;
  late final AdCoordinator ads;
  late final ProductTelemetry telemetry;
  final continuation = AdContinuationWindow();
  late final Timer _ticker;
  PrivacyChoices choices = const PrivacyChoices();
  RemotePolicy policy = const RemotePolicy();
  bool firebaseReady = false,
      privacySaveFailed = false,
      privacySyncFailed = false,
      privacySyncBusy = false;
  bool privacyBusy = false, adPrivacyRequired = false, adPrivacyFailed = false;
  bool _adsInitialized = false,
      _umpChecked = false,
      _disposed = false,
      _firebaseInitialized = false;
  int _consentGeneration = 0;
  String firebaseStatus = 'disabled';
  int _privacyGeneration = 0;
  int _privacyChoiceGeneration = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initializeLocal() async {
    choices = PrivacyChoices.parse(
      await store.readServiceValue('privacy_choices'),
    );
    unawaited(reporting.setEnabled(choices.analytics));
    try {
      final raw = await store.readServiceValue('remote_policy');
      if (raw is Map) {
        policy = RemotePolicy.fromRaw(
          raw.cast<String, String>(),
          knownPuzzleIds: knownPuzzleIds,
        );
      }
    } catch (_) {
      policy = const RemotePolicy();
    }
    ads.update(remote: policy);
    await ads.initialize();
    _notify();
    unawaited(initializeFirebase());
  }

  Future<void> initializeFirebase() async {
    final options = config.firebaseOptions;
    if (options == null || _disposed) {
      firebaseStatus = 'disabled';
      _notify();
      return;
    }
    if (_firebaseInitialized || firebaseStatus == 'initializing') return;
    firebaseStatus = 'initializing';
    _notify();
    try {
      await firebase.initialize(options).timeout(timeout);
      if (_disposed) return;
      _firebaseInitialized = true;
      await _syncPrivacy();
      firebaseReady = !privacySyncFailed;
      firebaseStatus = firebaseReady ? 'ready' : 'unavailable';
      if (firebaseReady) await fetchRemote();
    } catch (_) {
      firebaseReady = false;
      firebaseStatus = 'unavailable';
    }
    _notify();
  }

  Future<void> _syncPrivacy() async {
    if (!_firebaseInitialized || _disposed) return;
    final generation = ++_privacyGeneration;
    privacySyncBusy = true;
    _notify();
    final current = privacySaveFailed ? const PrivacyChoices() : choices;
    try {
      await firebase
          .privacy(analytics: current.analytics, crash: current.crash)
          .timeout(timeout);
      if (generation == _privacyGeneration) privacySyncFailed = false;
    } catch (_) {
      if (generation == _privacyGeneration) privacySyncFailed = true;
    } finally {
      if (generation == _privacyGeneration) {
        privacySyncBusy = false;
        firebaseReady = !privacySyncFailed;
        firebaseStatus = firebaseReady ? 'ready' : 'unavailable';
      }
      _notify();
    }
  }

  void setForeground(bool value) {
    continuation.setForeground(value);
    ads.update(isForeground: value);
  }

  void recordLegalMove() {
    if (!telemetry.allowed()) {
      continuation.clear();
      return;
    }
    for (final display in continuation.legalMove()) {
      unawaited(
        telemetry.log(ProductEvent.adContinue, display.request, {
          'request_id': display.request,
          'format': display.format,
          'result': 'continued',
        }),
      );
    }
  }

  Future<void> updatePrivacy(PrivacyChoices value) async {
    final choiceGeneration = ++_privacyChoiceGeneration;
    if (!value.analytics) continuation.clear();
    choices = value;
    privacySaveFailed = false;
    // Withdraw immediately; enable only once the user's choice is saved.
    if (!value.analytics) unawaited(reporting.setEnabled(false));
    // In-memory gate closes synchronously; native withdrawal is queued immediately.
    final sync = _syncPrivacy();
    _notify();
    var saveFailed = false;
    try {
      await store.writeServiceValue('privacy_choices', value.toJson());
    } catch (_) {
      saveFailed = true;
    }
    // An older save acknowledgement cannot restore a withdrawn choice, close
    // a newer allowed client, or overwrite the latest save-failure state.
    if (choiceGeneration == _privacyChoiceGeneration && !_disposed) {
      privacySaveFailed = saveFailed;
      unawaited(reporting.setEnabled(choices.analytics && !saveFailed));
    }
    await sync;
    if (choiceGeneration != _privacyChoiceGeneration || _disposed) return;
    if (privacySaveFailed) await _syncPrivacy();
    _notify();
  }

  Future<void> retryPrivacy() async {
    await updatePrivacy(choices);
    if (privacySyncFailed) await _syncPrivacy();
  }

  Future<void> fetchRemote() async {
    if (!_firebaseInitialized || _disposed) return;
    try {
      final raw = await firebase.remote().timeout(timeout);
      final valid = RemotePolicy.fromRaw(raw, knownPuzzleIds: knownPuzzleIds);
      if (_disposed) return;
      await store.writeServiceValue('remote_policy', valid.toRaw());
      policy = valid;
      ads.update(remote: policy);
    } catch (_) {
      /* Retain the last validated snapshot, not malformed SDK coercions. */
    }
    _notify();
  }

  Future<void> prepareAdsPrivacy({bool force = false}) async {
    if (_disposed ||
        privacyBusy ||
        ads.showing ||
        !ads.foreground ||
        !config.adsConfigured ||
        (_umpChecked && !force)) {
      return;
    }
    _umpChecked = true;
    privacyBusy = true;
    adPrivacyFailed = false;
    final epoch = ++_consentGeneration;
    ads.update(consent: false);
    try {
      final result = await consent.request().timeout(consentTimeout);
      if (_disposed || epoch != _consentGeneration) return;
      await _applyAdConsent(result, epoch);
    } catch (_) {
      adPrivacyFailed = true;
      ads.update(consent: false);
    } finally {
      privacyBusy = false;
      _notify();
    }
  }

  Future<void> showAdPrivacy() async {
    if (_disposed ||
        privacyBusy ||
        !adPrivacyRequired ||
        ads.showing ||
        !ads.foreground) {
      return;
    }
    privacyBusy = true;
    final epoch = ++_consentGeneration;
    ads.update(consent: false);
    _notify();
    try {
      await _applyAdConsent(
        await consent.options().timeout(consentTimeout),
        epoch,
      );
    } catch (_) {
      adPrivacyFailed = true;
      ads.update(consent: false);
    } finally {
      privacyBusy = false;
      _notify();
    }
  }

  Future<void> _applyAdConsent(AdConsent result, int epoch) async {
    if (_disposed || epoch != _consentGeneration) return;
    adPrivacyRequired = result.optionsRequired;
    adPrivacyFailed = result.failed;
    if (!result.allowed) {
      ads.update(consent: false);
      return;
    }
    if (!_adsInitialized) {
      await consent.initializeAds().timeout(timeout);
      if (_disposed || epoch != _consentGeneration) return;
      _adsInitialized = true;
    }
    ads.update(consent: true);
    for (final kind in AdKind.values) {
      unawaited(ads.preload(kind));
    }
  }

  Future<void> recordError(
    String category,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!firebaseReady ||
        !choices.crash ||
        privacySaveFailed ||
        privacySyncBusy ||
        privacySyncFailed ||
        _disposed) {
      return;
    }
    if (!{'flutter', 'unhandled', 'storage', 'service'}.contains(category)) {
      return;
    }
    try {
      await firebase.error(category, stack, fatal: fatal);
    } catch (_) {}
  }

  Future<bool> openSupport({
    bool privacy = false,
    bool feedback = false,
  }) async {
    final uri = feedback
        ? config.feedback
        : privacy
        ? config.privacy
        : config.support;
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _consentGeneration++;
    _privacyChoiceGeneration++;
    _ticker.cancel();
    ads.removeListener(_notify);
    ads.dispose();
    reporting.onRulesChanged = null;
    unawaited(reporting.dispose());
    super.dispose();
  }
}
