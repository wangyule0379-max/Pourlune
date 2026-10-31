import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'gamemunchies_reporting_test.dart' show ReportingHarness;

class PrivacySave {
  final committed = Completer<void>();
  final response = Completer<void>();
}

/// Real SQLite writes in call order; only their completion acknowledgements can
/// be delayed/reordered. No test hooks are added to production storage.
class DelayedPrivacyStore extends Fake implements GameStore {
  DelayedPrivacyStore(this.backing);
  final GameStore backing;
  final writes = <PrivacySave>[];
  @override
  Future<Object?> readServiceValue(String key) => backing.readServiceValue(key);
  @override
  Future<int?> lastFullscreenMillis() => backing.lastFullscreenMillis();
  @override
  Future<void> writeServiceValue(String key, Object? value) async {
    final write = PrivacySave();
    writes.add(write);
    await backing.writeServiceValue(key, value);
    write.committed.complete();
    await write.response.future;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late GameStore backing;
  late DelayedPrivacyStore store;
  late ReportingHarness h;
  late GameMunchiesReporting stats;
  late ServiceHub hub;
  final requests = <Future<void>>[];
  setUp(() async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    dir = Directory.systemTemp.createTempSync('gm-privacy-race-');
    backing = await GameStore.open(
      '${dir.path}/qa.sqlite',
      factory: databaseFactoryFfi,
    );
    store = DelayedPrivacyStore(backing);
    h = ReportingHarness();
    stats = h.reporting();
    hub = ServiceHub(
      store: store,
      config: const ServiceConfig(),
      knownPuzzleIds: {},
      reporting: stats,
    );
    requests.clear();
    await hub.initializeLocal();
  });
  tearDown(() async {
    for (final write in store.writes) {
      if (!write.response.isCompleted) write.response.complete();
    }
    await Future.wait(requests);
    hub.dispose();
    await stats.dispose();
    await backing.close();
    dir.deleteSync(recursive: true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  });

  Future<void> choose(bool analytics) async {
    requests.add(hub.updatePrivacy(PrivacyChoices(analytics: analytics)));
    await store.writes.last.committed.future;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('on then off: earlier on save cannot start statistics while latest off is pending', () async {
    await choose(true);
    await choose(false);
    store.writes[0].response.complete();
    await requests[0];
    await settle();
    expect(hub.choices.analytics, isFalse);
    expect(h.clients.length, 1);
    expect(h.received, isEmpty);
    store.writes[1].response.complete();
    await requests[1];
    await settle();
    expect(h.clients.length, 1);
  });

  test('late earlier success after latest off failure cannot clear failure or reopen reporting', () async {
    await choose(true);
    await choose(false);
    store.writes[1].response.completeError(StateError('save failed'));
    await requests[1];
    expect(hub.privacySaveFailed, isTrue);
    store.writes[0].response.complete();
    await requests[0];
    await settle();
    expect(hub.privacySaveFailed, isTrue);
    expect(h.clients.length, 1);
    expect(h.received, isEmpty);
  });

  test('late earlier failure after latest off success cannot overwrite latest save state', () async {
    await choose(true);
    await choose(false);
    store.writes[1].response.complete();
    await requests[1];
    store.writes[0].response.completeError(StateError('old save failed'));
    await requests[0];
    await settle();
    expect(hub.choices.analytics, isFalse);
    expect(hub.privacySaveFailed, isFalse);
    expect(h.clients.length, 1);
  });

  test(
    'late earlier off acknowledgement cannot disable latest saved on selection',
    () async {
      await choose(false);
      await choose(true);
      store.writes[1].response.complete();
      await requests[1];
      await settle();
      expect(h.clients.length, 1);
      store.writes[0].response.complete();
      await requests[0];
      await settle();
      await stats.roundStarted('after-late-off', h.now);
      await h.flush();
      expect(h.received.where((e) => e['type'] == 'round_start').length, 1);
      expect(h.received.where((e) => e['type'] == 'active').length, 1);
      expect(hub.choices.analytics, isTrue);
    },
  );
}
