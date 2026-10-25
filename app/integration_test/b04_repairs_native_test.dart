// Real iOS sqflite + Flutter/controller regression. Ads below are controlled
// transport events, never real ad display/earned/UMP evidence. Clears ONLY the
// two named b04_repairs_* databases. Engineering aliases reuse the reference fixture.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart' show PourluneApp;
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:pourlune_dev/services/service_policy.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/b04_v4_fixture.dart';

class _Handle implements AdHandle {
  AdCallbacks? route;
  int shows = 0, disposals = 0;
  @override
  Future<void> show(AdCallbacks value) async {
    shows++;
    route = value;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    route = null;
  }
}

class _Transport implements AdTransport {
  final loads = <({AdKind kind, Completer<AdHandle> future})>[];
  @override
  Future<AdHandle> load(AdKind kind) {
    final f = Completer<AdHandle>();
    loads.add((kind: kind, future: f));
    return f.future;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'B04 repairs real sqflite migration/boundary; simulated ad lifecycle/controller and actual rendering',
    (t) async {
      final base = await getDatabasesPath();
      final out = Directory('$base/b04-repairs-evidence');
      await out.create(recursive: true);
      final raw = jsonDecode(
        await rootBundle.loadString('assets/fixtures/main-001.reference.json'),
      ) as Map<String, dynamic>;
      Puzzle puzzle(int level) => Puzzle.fromJson({
        ...raw,
        'puzzle_id': 'main-${level.toString().padLeft(3, '0')}',
        'main_level': level,
      });
      GameInstance state(String id, int level) =>
          GameInstance.create(id: id, puzzle: puzzle(level));
      GameInstance finish(GameInstance s) {
        for (final m in s.puzzle.referenceMoves) {
          s = s.pour(m.from, m.to).state;
        }
        return s;
      }

      final day = GameInstance.create(
        id: 'legacy-daily',
        puzzle: Puzzle.fromJson({
          ...raw,
          'puzzle_id': 'daily-test',
          'mode': 'daily',
          'main_level': null,
        }),
        slot: 'daily',
        puzzleDate: '2026-10-22',
        timeZone: 'UTC',
        offsetMinutes: 0,
        catalogVersion: 1,
      );
      final migrationPath = '$base/b04_repairs_migration.sqlite';
      await deleteDatabase(migrationPath);
      final active = state(
            'legacy-active',
            14,
          ).pour(0, 2).state.grantExtraBottle(),
          pending = state('legacy-origin', 4).grantExtraBottle();
      await writeLegacyV4(
        migrationPath,
        databaseFactory,
        active: active,
        pending: pending,
        dailyState: day,
      );
      final migration = await GameStore.open(migrationPath);
      final report = <String, Object?>{
        'scope': 'real sqflite/Flutter iOS Simulator; controlled transport NOT native advertising',
        'lifecycle': 'controller foreground simulation, not OS interruption',
        'content': 'reference-fixture aliases, not production difficulty/identity validation',
      };
      try {
        expect(await migration.db.getVersion(), 5);
        expect(
          (await migration.load('ordinary')).instance!.toJson(),
          active.toJson(),
        );
        expect(
          (await migration.load('daily')).instance!.toJson(),
          day.toJson(),
        );
        expect((await migration.progress()).qualifyingClears, 2);
        expect(
          (await migration.pendingRewards()).single.origin.toJson(),
          pending.toJson(),
        );
        await expectLater(
          migration.recordFullscreen(
            'legacy-uncertain',
            'interstitial',
            1100000,
          ),
          throwsStateError,
        );
        expect((await migration.progress()).qualifyingClears, 2);
        await migration.prepareFullscreen('known', 'interstitial');
        await migration.recordFullscreen('known', 'interstitial', 1200000);
        expect((await migration.progress()).qualifyingClears, 0);
        await migration.settle(finish(active));
        await migration.recordFullscreen('known', 'interstitial', 1300000);
        expect((await migration.progress()).qualifyingClears, 1);
        report['migration'] = {
          'from': 4,
          'to': await migration.db.getVersion(),
          'ordinary_and_daily_retained': true,
          'pending_reward_retained': true,
          'legacy_qualification_retained': 2,
          'after_new_show_and14': 1,
        };
      } finally {
        await migration.close();
      }
      final flowPath = '$base/b04_repairs_flow.sqlite';
      await deleteDatabase(flowPath);
      final store = await GameStore.open(flowPath);
      for (var n = 1; n <= 12; n++) {
        await store.settle(finish(state('setup-$n', n)), replace: true);
      }
      var elapsed = Duration.zero;
      final transport = _Transport();
      final hub = ServiceHub(
        store: store,
        config: const ServiceConfig(
          adMode: 'test',
          interstitialId: 'ca-app-pub-3940256099942544/4411468910',
          rewardedId: 'ca-app-pub-3940256099942544/1712485313',
        ),
        knownPuzzleIds: {},
        transport: transport,
        adPreShowTimeout: const Duration(seconds: 2),
        adClock: FullscreenCooldown(
          wall: () => DateTime.fromMillisecondsSinceEpoch(1000000),
          monotonic: () => elapsed,
        ),
      );
      final c = GameController(
        store,
        services: hub,
        library: ContentLibrary(
          main: {for (var n = 1; n <= 60; n++) n: puzzle(n)},
          engineering: true,
        ),
      );
      final root = GlobalKey();
      Future<void> until(bool Function() condition) async {
        for (var i = 0; i < 100 && !condition(); i++) {
          await t.pump(const Duration(milliseconds: 20));
        }
        expect(condition(), isTrue);
      }

      Future<_Handle> ready() async {
        final loading = hub.ads.preload(AdKind.interstitial);
        final h = _Handle();
        transport.loads
            .lastWhere(
              (l) => l.kind == AdKind.interstitial && !l.future.isCompleted,
            )
            .future
            .complete(h);
        await loading;
        await until(() => hub.ads.ready(AdKind.interstitial));
        return h;
      }

      Future<void> solve() async {
        for (final m in c.current!.puzzle.referenceMoves) {
          await c.pour(m.from, m.to);
          if (c.motion != null) c.completeMotion(c.motion!.token);
        }
        await t.pump();
        expect(c.current!.completed, isTrue);
      }

      Future<void> capture(String name) async {
        await t.pumpAndSettle();
        final render =
            root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${out.path}/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      }

      try {
        await c.initialize();
        await hub.initializeLocal();
        hub.ads.update(consent: true);
        await c.startLevel(13);
        await solve();
        await t.pumpWidget(
          RepaintBoundary(
            key: root,
            child: PourluneApp(controller: c),
          ),
        );
        await t.pumpAndSettle();
        final first = await ready();
        await t.ensureVisible(find.byKey(const Key('next')));
        await t.tap(find.byKey(const Key('next')));
        await until(() => first.shows == 1);
        store.fault = (stage) {
          if (stage == 'fullscreen') throw StateError('native SQLite rollback');
        };
        first.route!.shown();
        c.setForeground(false);
        await t.pump(const Duration(milliseconds: 2200));
        expect(first.disposals, 0);
        expect(c.current!.puzzle.mainLevel, 13);
        expect(c.busy, isTrue);
        report['shown_across_pre_show_deadline'] = {
          'lifecycle_simulated': true,
          'still_level': 13,
          'disposed_before_close': first.disposals,
        };
        c.setForeground(true);
        first.route!.closed();
        await until(() => c.current!.puzzle.mainLevel == 14 && !c.busy);
        await solve();
        expect((await store.progress()).qualifyingClears, 4);
        await capture('after14-before-retry');
        store.fault = null;
        await hub.ads.retryTiming();
        expect((await store.progress()).qualifyingClears, 1);
        await hub.ads.retryTiming();
        expect((await store.progress()).qualifyingClears, 1);
        elapsed = const Duration(seconds: 180);
        final second = await ready();
        await c.nextLevel();
        expect(second.shows, 0);
        await solve();
        expect(c.progress.qualifyingClears, 2);
        await c.nextLevel();
        expect(second.shows, 0);
        await solve();
        expect(c.progress.qualifyingClears, 3);
        await c.viewPatch();
        final next16 = c.nextLevel();
        await until(() => second.shows == 1);
        second.route!.shown();
        second.route!.closed();
        await next16;
        expect(c.current!.puzzle.mainLevel, 17);
        expect(c.progress.qualifyingClears, 0);
        await capture('after16-to17');
        report['qualification'] = {
          'after14_before_retry': 4,
          'after_retry': 1,
          'after_duplicate_retry': 1,
          'after15': 2,
          'after16': 3,
          'after_second_controlled_show': 0,
          'current_level': 17,
        };
        report['status'] = 'passed';
        await File('${out.path}/native.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
        debugPrint('B04_REPAIRS_NATIVE ${jsonEncode(report)}');
        await t.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 8)),
        );
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        c.dispose();
        hub.dispose();
        await store.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
