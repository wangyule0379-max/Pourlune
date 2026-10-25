// Actual SQLite SELECT failure, confined to this test database: the view raises
// only after a show is recorded and before Next's snapshot transaction commits.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Handle, Transport;
import 'b04_controller_ads_test.dart' show config;
import 'store_test.dart' show fixture, sample, finish;

void main() {
  sqfliteFfiInit();
  for (final foreground in [true, false]) {
    for (final snapshotFault in [false, true]) {
      test(
        'B04-R03 post-ad SQL read fails; foreground=$foreground snapshotFault=$snapshotFault',
        () async {
          final dir = Directory.systemTemp.createTempSync('b04-r03-');
          final store = await GameStore.open(
            '${dir.path}/g.db',
            factory: databaseFactoryFfi,
          );
          final transport = Transport();
          final hub = ServiceHub(
            store: store,
            config: config,
            transport: transport,
            knownPuzzleIds: {},
          );
          final c = GameController(
            store,
            services: hub,
            library: ContentLibrary(
              main: {for (var n = 1; n <= 60; n++) n: fixture(n)},
            ),
          );
          var viewCreated = false, snapshotAttempts = 0;
          Future<void> until(bool Function() condition) async {
            for (var n = 0; n < 2000 && !condition(); n++) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(condition(), isTrue);
          }

          try {
            for (var n = 1; n <= 12; n++) {
              await store.settle(
                finish(sample('seed$n', level: n)),
                replace: true,
              );
            }
            await c.initialize();
            await hub.initializeLocal();
            hub.ads.update(consent: true);
            await c.startLevel(13);
            for (final m in c.current!.puzzle.referenceMoves) {
              await c.pour(m.from, m.to);
            }
            final origin = c.current!.id;
            final sqlOrigin = origin.replaceAll("'", "''");
            await store.db.execute(
              'ALTER TABLE revealed_pieces RENAME TO r03_saved_revealed_pieces',
            );
            await store.db.execute(
              '''CREATE VIEW revealed_pieces AS
            SELECT piece FROM r03_saved_revealed_pieces
            UNION ALL SELECT CAST(abs(-9223372036854775808) AS TEXT) AS piece
            WHERE EXISTS(SELECT 1 FROM fullscreen_shows)
            AND EXISTS(SELECT 1 FROM receipts WHERE instance_id='$sqlOrigin' AND next_instance_id IS NULL)''',
            );
            viewCreated = true;
            expect(
              (await store.progress()).qualifyingClears,
              3,
              reason: 'Pre-show progress read must still succeed',
            );
            final loading = hub.ads.preload(AdKind.interstitial);
            final h = Handle();
            transport.loads[transport.kinds.lastIndexOf(AdKind.interstitial)]
                .complete(h);
            await loading;
            Object? nextError;
            final next = c.nextLevel().then<void>(
              (_) {},
              onError: (Object error, StackTrace stack) {
                nextError = error;
              },
            );
            await until(
              () => h.shows == 1,
            ); // Confirms Controller's pre-check read succeeded.
            h.callbacks!.shown();
            // Wait for the real shown-record transaction, without calling progress.
            for (
              var n = 0;
              n < 2000 && await store.lastFullscreenMillis() == null;
              n++
            ) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(await store.lastFullscreenMillis(), isNotNull);
            await expectLater(
              store.progress(),
              throwsA(isA<DatabaseException>()),
            );
            store.fault = (stage) {
              if (stage == 'snapshot') {
                snapshotAttempts++;
                if (snapshotFault) throw StateError('next snapshot failed');
              }
            };
            if (!foreground) c.setForeground(false);
            h.callbacks!.closed();
            await next;
            expect(
              nextError,
              isNull,
              reason: 'Optional post-ad SELECT must not escape nextLevel',
            );
            if (!foreground) {
              expect(c.busy, isTrue);
              expect(c.current!.id, origin);
              c.setForeground(true);
            }
            await until(() => !c.busy);
            expect(
              snapshotAttempts,
              1,
              reason: 'Free Next must reach its real snapshot transaction',
            );
            if (snapshotFault) {
              expect(c.phase, SavePhase.failed);
              expect(c.current!.id, origin);
              expect(c.error, isNotNull);
              expect((await store.load('ordinary')).instance!.id, origin);
              expect(
                (await store.db.query(
                  'receipts',
                  where: 'instance_id=?',
                  whereArgs: [origin],
                )).single['next_instance_id'],
                isNull,
              );
            } else {
              expect(c.phase, SavePhase.clean);
              expect(c.current!.puzzle.mainLevel, 14);
              expect(
                (await store.load('ordinary')).instance!.id,
                c.current!.id,
              );
            }
            await store.db.execute('DROP VIEW revealed_pieces');
            await store.db.execute(
              'ALTER TABLE r03_saved_revealed_pieces RENAME TO revealed_pieces',
            );
            viewCreated = false;
            store.fault = null;
            if (snapshotFault) {
              await c.retry();
              expect(c.phase, SavePhase.clean);
              expect(c.current!.puzzle.mainLevel, 14);
              expect(c.busy, isFalse);
            }
            expect((await store.load('ordinary')).instance!.id, c.current!.id);
            expect(
              (await store.db.query(
                'receipts',
                where: 'instance_id=?',
                whereArgs: [origin],
              )).single['next_instance_id'],
              c.current!.id,
            );
            await c.goHome();
            expect(c.page, GamePage.home);
            expect(c.busy, isFalse);
          } finally {
            c.dispose();
            hub.dispose();
            store.fault = null;
            if (viewCreated) {
              await store.db.execute('DROP VIEW revealed_pieces');
              await store.db.execute(
                'ALTER TABLE r03_saved_revealed_pieces RENAME TO revealed_pieces',
              );
            }
            await store.close();
            dir.deleteSync(recursive: true);
          }
        },
      );
    }
  }
}
