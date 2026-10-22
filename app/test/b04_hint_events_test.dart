import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/application/hint_worker.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_services_test.dart' show Fire, options;
import 'store_test.dart' show fixture;

void main() {
  sqfliteFfiInit();
  test('AC36 cancel emits once; same saved instance after controller restart retains distinct hint request identities', () async {
    final dir = Directory.systemTemp.createTempSync('b04-hint-event-');
    final store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
    final fire = Fire();
    final hub = ServiceHub(
      store: store,
      config: ServiceConfig(firebaseJson: options(), firebaseNativeReady: true),
      knownPuzzleIds: {},
      firebase: fire,
    );
    await hub.initializeLocal();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
    HintTask task(GameInstance state) {
      final result = Completer<HintResult>();
      return (
        result: result.future,
        released: Future<void>.value(),
        cancel: () {
          if (!result.isCompleted) {
            result.complete(const HintResult(HintStatus.cancelled));
          }
        },
      );
    }

    var c = GameController(store, services: hub, hintLauncher: task);
    try {
      await c.initialize();
      await c.start(fixture(4));
      final first = c.requestHint();
      c.cancelHint();
      c.cancelHint();
      await first;
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(fire.events.where((e) => e == 'pl_hint_result'), hasLength(1));
      c.dispose();
      c = GameController(store, services: hub, hintLauncher: task);
      await c.initialize();
      await c.resumeSlot('ordinary');
      final next = c.requestHint();
      c.cancelHint();
      await next;
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(fire.events.where((e) => e == 'pl_hint_result'), hasLength(2));
      final identities = await store.db.query(
        'service_events',
        where: 'event_id LIKE ?',
        whereArgs: ['hint_result:%'],
      );
      expect(identities, hasLength(2));
    } finally {
      c.dispose();
      hub.dispose();
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
