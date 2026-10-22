import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'service_config.dart';

class AdConsent {
  const AdConsent({
    required this.allowed,
    required this.optionsRequired,
    this.failed = false,
  });
  final bool allowed, optionsRequired, failed;
}

abstract interface class ConsentGateway {
  Future<AdConsent> request();
  Future<AdConsent> options();
  Future<void> initializeAds();
}

class UmpConsentGateway implements ConsentGateway {
  UmpConsentGateway(this.config);
  final ServiceConfig config;
  Future<AdConsent> _read({bool failed = false}) async => AdConsent(
    allowed: await ConsentInformation.instance.canRequestAds(),
    optionsRequired:
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required,
    failed: failed,
  );
  @override
  Future<AdConsent> request() {
    final done = Completer<AdConsent>();
    Future<void> complete(bool failed) async {
      try {
        final result = await _read(failed: failed);
        if (!done.isCompleted) done.complete(result);
      } catch (_) {
        if (!done.isCompleted) {
          done.complete(
            const AdConsent(
              allowed: false,
              optionsRequired: false,
              failed: true,
            ),
          );
        }
      }
    }

    ConsentDebugSettings? debug;
    if (config.testing && config.umpTestRegion == 'eea') {
      debug = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: config.umpTestDevice.isEmpty
            ? null
            : [config.umpTestDevice],
      );
    }
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(consentDebugSettings: debug),
      () => ConsentForm.loadAndShowConsentFormIfRequired(
        (error) => unawaited(complete(error != null)),
      ),
      (_) => unawaited(complete(true)),
    );
    return done.future;
  }

  @override
  Future<AdConsent> options() async {
    final done = Completer<AdConsent>();
    await ConsentForm.showPrivacyOptionsForm((error) async {
      try {
        done.complete(await _read(failed: error != null));
      } catch (_) {
        done.complete(
          const AdConsent(allowed: false, optionsRequired: false, failed: true),
        );
      }
    });
    return done.future;
  }

  @override
  Future<void> initializeAds() async {
    await MobileAds.instance.initialize();
  }
}
