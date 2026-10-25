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
    Future<void> until(bool Function() ready, String boundary) async {
      final watch = Stopwatch()..start();
      while (!ready()) {
        if (watch.elapsed > const Duration(seconds: 3)) {
          fail('Timed out waiting for $boundary');
        }
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }

    await hub.initializeLocal();
    await until(() => hub.firebaseReady, 'configured analytics gateway');
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
      await until(
        () => fire.events.where((e) => e == 'pl_hint_result').isNotEmpty,
        'first hint result dispatch after its durable claim',
      );
      expect(fire.events.where((e) => e == 'pl_hint_result'), hasLength(1));
      final instanceId = c.current!.id;
      c.dispose();
      c = GameController(store, services: hub, hintLauncher: task);
      await c.initialize();
      await c.resumeSlot('ordinary');
      expect(c.current!.id, instanceId);
      // Hold the actual SQLite writer to separate hint completion from the
      // independent telemetry claim/dispatch. No latency or SDK success mock.
      final entered = Completer<void>(), release = Completer<void>();
      final held = store.db.transaction((tx) async {
        final previous = await tx.query(
          'service_events',
          where: 'event_id LIKE ?',
          whereArgs: ['hint_result:%'],
        );
        expect(previous, hasLength(1));
        entered.complete();
        await release.future;
      });
      try {
        await entered.future.timeout(const Duration(seconds: 3));
        final next = c.requestHint();
        c.cancelHint();
        c.cancelHint();
        await next;
        expect(hub.telemetry.allowed(), isTrue);
        expect(
          fire.events.where((e) => e == 'pl_hint_result'),
          hasLength(1),
          reason: 'hint completion cannot bypass the pending durable claim',
        );
      } finally {
        release.complete();
        await held;
      }
      await until(
        () => fire.events.where((e) => e == 'pl_hint_result').length >= 2,
        'second hint result dispatch after releasing SQLite',
      );
      expect(fire.events.where((e) => e == 'pl_hint_result'), hasLength(2));
      final identities = await store.db.query(
        'service_events',
        where: 'event_id LIKE ?',
        whereArgs: ['hint_result:%'],
      );
      expect(identities, hasLength(2));
      expect(identities.map((row) => row['event_id']).toSet(), hasLength(2));
    } finally {
      c.dispose();
      hub.dispose();
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
