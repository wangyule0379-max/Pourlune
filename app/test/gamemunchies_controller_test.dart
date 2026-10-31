import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'gamemunchies_reporting_test.dart' show ReportingHarness;
import 'store_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late ReportingHarness reporting;
  late GameMunchiesReporting stats;
  late ServiceHub hub;
  late GameController c;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pourlune-gm-');
    store = await GameStore.open(
      '${dir.path}/gm.sqlite',
      factory: databaseFactoryFfi,
    );
    reporting = ReportingHarness()..now = DateTime.now().toUtc();
    stats = reporting.reporting();
    await store.writeServiceValue('privacy_choices', {
      'analytics': true,
      'crash': false,
    });
    hub = ServiceHub(
      store: store,
      config: const ServiceConfig(),
      knownPuzzleIds: {'main-004'},
      reporting: stats,
    );
    c = GameController(store, services: hub);
    await c.initialize();
    await hub.initializeLocal();
  });
  tearDown(() async {
    c.dispose();
    hub.dispose();
    await stats.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });

  test('only new persisted instance counts; resume restart foreground and local extra bottle do not', () async {
    await reporting.flush();
    expect(reporting.received, isEmpty);
    await c.start(fixture(4));
    await reporting.flush();
    final first = c.current!.id;
    expect(reporting.received.single['id'], 'round:$first');
    await c.restart();
    await c.watchExtraBottle();
    expect(c.current!.extraBottleGranted, isTrue);
    expect(c.current!.id, first);
    c.setForeground(false);
    c.setForeground(true);
    c.resume();
    c.dispose();
    c = GameController(store, services: hub);
    await c.initialize();
    c.resume();
    await reporting.flush();
    expect(
      reporting.received.where((e) => e['type'] == 'round_start').length,
      1,
    );
    await c.start(fixture(4), replace: true, replay: true);
    await reporting.flush();
    expect(c.current!.id, isNot(first));
    expect(
      reporting.received.where((e) => e['type'] == 'round_start').length,
      2,
    );
  });

  test('failed candidate commit does not count; retry commits and counts same round once', () async {
    store.fault = (stage) {
      if (stage == 'snapshot') throw StateError('full disk');
    };
    await c.start(fixture(4));
    await reporting.flush();
    expect(c.phase, SavePhase.failed);
    expect(reporting.received, isEmpty);
    store.fault = null;
    await c.retry();
    await c.retry();
    await reporting.flush();
    expect(reporting.received.single['id'], 'round:${c.current!.id}');
    expect((await store.load('ordinary')).instance!.id, c.current!.id);
  });

  test('ServiceHub withdrawal closes collection even when saving the privacy choice fails', () async {
    await hub.updatePrivacy(const PrivacyChoices());
    store.fault = (stage) {
      if (stage == 'service_value') throw StateError('privacy save failed');
    };
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
    expect(hub.privacySaveFailed, isTrue);
    store.fault = null;
    await c.start(fixture(4));
    await reporting.flush();
    expect(reporting.received, isEmpty);
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
    await c.start(fixture(4), replace: true);
    await reporting.flush();
    expect(reporting.received.single['type'], 'round_start');
    await hub.updatePrivacy(const PrivacyChoices());
    await c.start(fixture(4), replace: true);
    expect(reporting.received.length, 1);
  });

  test('unavailable telemetry does not turn a legal saved new round or direct bottle into failure', () async {
    reporting.offline = true;
    await c.start(fixture(4));
    await reporting.flush();
    expect(c.phase, SavePhase.clean);
    await c.watchExtraBottle();
    expect(c.current!.extraBottleGranted, isTrue);
    expect((await store.load('ordinary')).instance!.extraBottleGranted, isTrue);
    expect(c.phase, SavePhase.clean);
    expect(reporting.received, isEmpty);
  });
}
