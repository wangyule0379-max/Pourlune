import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Save {
  final committed = Completer<void>();
  final response = Completer<void>();
}

// Real writes remain ordered; only completion acknowledgements are delayed.
class _Store extends Fake implements GameStore {
  _Store(this.backing);
  final GameStore backing;
  final writes = <_Save>[];
  @override
  Future<Object?> readServiceValue(String key) => backing.readServiceValue(key);
  @override
  Future<int?> lastFullscreenMillis() => backing.lastFullscreenMillis();
  @override
  Future<void> writeServiceValue(String key, Object? value) async {
    final save = _Save();
    writes.add(save);
    await backing.writeServiceValue(key, value);
    save.committed.complete();
    await save.response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late GameStore backing;
  late _Store store;
  late ServiceHub hub;
  final requests = <Future<void>>[];
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('privacy-choice-');
    backing = await GameStore.open(
      '${dir.path}/qa.sqlite',
      factory: databaseFactoryFfi,
    );
    store = _Store(backing);
    hub = ServiceHub(
      store: store,
      config: const ServiceConfig(),
      knownPuzzleIds: {},
    );
    requests.clear();
    await hub.initializeLocal();
  });
  tearDown(() async {
    for (final save in store.writes) {
      if (!save.response.isCompleted) save.response.complete();
    }
    await Future.wait(requests);
    hub.dispose();
    await backing.close();
    dir.deleteSync(recursive: true);
  });
  Future<void> choose(bool analytics) async {
    requests.add(hub.updatePrivacy(PrivacyChoices(analytics: analytics)));
    await store.writes.last.committed.future;
  }

  test('late old failure cannot overwrite a newer successfully saved privacy choice', () async {
    await choose(true);
    await choose(false);
    store.writes[1].response.complete();
    await requests[1];
    store.writes[0].response.completeError(
      StateError('old acknowledgement failed'),
    );
    await requests[0];
    expect(hub.choices.analytics, isFalse);
    expect(
      (await backing.readServiceValue('privacy_choices') as Map)['analytics'],
      isFalse,
    );
    expect(hub.privacySaveFailed, isFalse);
  });

  test(
    'disposed services ignore a pending privacy save failure acknowledgement',
    () async {
      await choose(true);
      hub.dispose();
      store.writes.single.response.completeError(
        StateError('late acknowledgement failed'),
      );
      await requests.single;
      expect(hub.privacySaveFailed, isFalse);
    },
  );
}
