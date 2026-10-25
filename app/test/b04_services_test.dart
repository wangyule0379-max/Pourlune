import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_consent.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/firebase_gateway.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:pourlune_dev/services/service_policy.dart';
import 'package:pourlune_dev/services/telemetry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Transport;

class Fire implements FirebaseGateway {
  int initializes = 0;
  bool privacyFails = false;
  final events = <String>[];
  final choices = <PrivacyChoices>[];
  Completer<void>? initializeWait;
  Map<String, String> raw = const RemotePolicy().toRaw();
  @override
  Future<void> initialize(FirebaseOptions options) async {
    initializes++;
    await initializeWait?.future;
  }

  @override
  Future<void> privacy({required bool analytics, required bool crash}) async {
    if (privacyFails) throw StateError('native unavailable');
    choices.add(PrivacyChoices(analytics: analytics, crash: crash));
  }

  @override
  Future<Map<String, String>> remote() async => raw;
  @override
  Future<void> event(String name, Map<String, Object> parameters) async {
    events.add(name);
  }

  @override
  Future<void> error(
    String category,
    StackTrace stack, {
    required bool fatal,
  }) async {
    events.add('error');
  }
}

class Consent implements ConsentGateway {
  AdConsent answer = const AdConsent(allowed: false, optionsRequired: false);
  int initializes = 0, requests = 0;
  @override
  Future<AdConsent> request() async {
    requests++;
    return answer;
  }

  @override
  Future<AdConsent> options() async => answer;
  @override
  Future<void> initializeAds() async {
    initializes++;
  }
}

String options({String platform = 'android'}) => jsonEncode({
  'apiKey': 'AIza${'a' * 35}',
  'appId': '1:123:$platform:abc123',
  'messagingSenderId': '123',
  'projectId': 'unit-boundary',
});
void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late Fire fire;
  ServiceHub? hub;
  Future<ServiceHub> create({
    String? firebase,
    bool ads = false,
    Consent? consent,
  }) async {
    final h = hub = ServiceHub(
      store: store,
      config: ServiceConfig(
        firebaseJson: firebase ?? options(),
        firebaseNativeReady: true,
        adMode: ads ? 'test' : 'disabled',
        interstitialId: 'ca-app-pub-3940256099942544/1033173712',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      ),
      knownPuzzleIds: {'main-001'},
      firebase: fire,
      transport: Transport(),
      consent: consent,
      timeout: const Duration(milliseconds: 15),
    );
    await h.initializeLocal();
    return h;
  }

  Future<void> settle() async =>
      Future<void>.delayed(const Duration(milliseconds: 30));
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-services-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    fire = Fire();
  });
  tearDown(() async {
    hub?.dispose();
    hub = null;
    await store.close();
    dir.deleteSync(recursive: true);
  });
  test('AC34 missing/illegal Firebase config is disabled without attempting initialization', () async {
    final h = await create(firebase: '');
    await settle();
    expect(h.firebaseStatus, 'disabled');
    expect(fire.initializes, 0);
    expect(ServiceConfig(firebaseJson: options()).firebaseOptions, isNull);
    expect(ServiceConfig(firebaseJson: '{}').firebaseOptions, isNull);
    expect(
      ServiceConfig(
        firebaseJson: options(platform: 'ios'),
        firebaseNativeReady: true,
      ).firebaseOptions,
      isNull,
    );
    expect(ServiceConfig.httpsUrl('https://example.com/privacy'), isNull);
    expect(
      const ServiceConfig(feedbackEmail: 'hello@example.com').feedback,
      isNull,
    );
    expect(
      const ServiceConfig(
        adMode: 'test',
        interstitialId: 'ca-app-pub-1111111111111111/1111111111',
        rewardedId: 'ca-app-pub-1111111111111111/1111111111',
      ).adsConfigured,
      isFalse,
    );
  });
  test('AC34 init timeout and late completion never enables analytics or blocks local store', () async {
    fire.initializeWait = Completer();
    final h = await create();
    await settle();
    expect(h.firebaseStatus, 'unavailable');
    expect(await store.progress(), isNotNull);
    fire.initializeWait!.complete();
    await settle();
    expect(h.firebaseReady, isFalse);
    expect(fire.choices, isEmpty);
  });
  test('AC36 separate privacy, no denied queue, withdrawal, persistent event dedup and field rejection', () async {
    final h = await create();
    await settle();
    await h.telemetry.log(ProductEvent.puzzleStart, 'denied', {
      'instance_id': 'denied',
    });
    expect(fire.events, isEmpty);
    await h.updatePrivacy(const PrivacyChoices(analytics: true));
    expect(fire.choices.last.crash, isFalse);
    await h.telemetry.log(ProductEvent.puzzleStart, 'a', {'instance_id': 'a'});
    await h.telemetry.log(ProductEvent.puzzleStart, 'a', {'instance_id': 'a'});
    await h.telemetry.log(ProductEvent.puzzleComplete, 'bad', {
      'board': 'private',
    });
    expect(fire.events, ['pl_puzzle_start']);
    await h.updatePrivacy(const PrivacyChoices(crash: true));
    await h.telemetry.log(ProductEvent.puzzleStart, 'b', {'instance_id': 'b'});
    await h.recordError('storage', StackTrace.current);
    expect(fire.events, ['pl_puzzle_start', 'error']);
    expect(
      await store.db.query(
        'service_events',
        where: 'event_id = ?',
        whereArgs: ['puzzle_start:denied'],
      ),
      isEmpty,
    );
    final another = ProductTelemetry(store, fire, () => true);
    await another.log(ProductEvent.puzzleStart, 'a', {'instance_id': 'a'});
    expect(fire.events, hasLength(2));
  });
  test('AC34 malformed remote values preserve last valid snapshot across local reopen', () async {
    final h = await create();
    await settle();
    fire.raw = {
      ...const RemotePolicy().toRaw(),
      'ads_enabled': 'false',
      'disabled_puzzle_ids': '["main-001"]',
    };
    await h.fetchRemote();
    expect(h.policy.adsEnabled, isFalse);
    fire.raw = {...fire.raw, 'ads_enabled': 'oops'};
    await h.fetchRemote();
    expect(h.policy.adsEnabled, isFalse);
    expect(
      (await store.readServiceValue('remote_policy') as Map)['ads_enabled'],
      'false',
    );
  });
  test('AC18/34 UMP false never initializes ads; qualified options and repeated callbacks do not double init', () async {
    final consent = Consent();
    final h = await create(ads: true, consent: consent);
    await settle();
    await h.prepareAdsPrivacy();
    expect(consent.initializes, 0);
    expect(h.ads.allowed, isFalse);
    consent.answer = const AdConsent(allowed: true, optionsRequired: true);
    await h.prepareAdsPrivacy(force: true);
    expect(consent.initializes, 1);
    expect(h.adPrivacyRequired, isTrue);
    await h.prepareAdsPrivacy(force: true);
    expect(consent.initializes, 1);
    consent.answer = const AdConsent(allowed: false, optionsRequired: true);
    await h.showAdPrivacy();
    expect(h.ads.allowed, isFalse);
    expect(h.ads.state(AdKind.rewarded), AdLoadState.idle);
  });
  test(
    'AC36 native privacy synchronization failure recovers through Retry',
    () async {
      fire.privacyFails = true;
      final h = await create();
      await settle();
      expect(h.privacySyncFailed, isTrue);
      expect(h.firebaseReady, isFalse);
      fire.privacyFails = false;
      await h.retryPrivacy();
      expect(h.privacySyncFailed, isFalse);
      expect(h.firebaseReady, isTrue);
      await h.updatePrivacy(const PrivacyChoices(analytics: true));
      await h.telemetry.log(ProductEvent.puzzleStart, 'after-retry', {
        'instance_id': 'after-retry',
      });
      expect(fire.events, ['pl_puzzle_start']);
    },
  );
}
