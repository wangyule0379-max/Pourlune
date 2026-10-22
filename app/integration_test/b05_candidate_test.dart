// Actual Flutter/sqflite/formal90 evidence; ad/clock inputs controlled, NOT SDK earn.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/main.dart' show PourluneApp;
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('B05 formal90 five E2E and service accessibility surfaces', (
    t,
  ) async {
    final base = await getDatabasesPath();
    final out = Directory('$base/b05-candidate-evidence');
    await out.create(recursive: true);
    final library = await b05Library();
    final events = <Map<String, Object?>>[];
    final captures = <String>[];
    Future<void> record(
      String flow,
      GameController c, [
      Map<String, Object?> extra = const {},
    ]) async {
      events.add({
        'flow': flow,
        'instance': c.current?.toJson(),
        'phase': c.phase.name,
        'first': c.progress.firstClears,
        'pieces': c.progress.pieces,
        'revealed': c.progress.revealedPieces,
        'counter': c.progress.qualifyingClears,
        'stamps': c.progress.dailyStamps,
        ...extra,
      });
      await b05Json('${out.path}/candidate.json', {
        'scope': 'native Flutter/sqflite, formal bundled90; QA initial progress; controlled ad callbacks/clock, no SDK display/earned',
        'events': events,
        'screenshots': captures,
      });
    }

    final root = GlobalKey();
    GameController? controller;
    Future<void> until(bool Function() condition) async {
      for (var n = 0; n < 600 && !condition(); n++) {
        await t.pump(const Duration(milliseconds: 50));
        expect(t.takeException(), isNull);
      }
      expect(condition(), isTrue);
    }

    Future<void> idle() async {
      await until(() => !controller!.busy && !controller.hintSearching);
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
    }

    Future<void> tap(String key, {bool wait = true}) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump(const Duration(milliseconds: 100));
      if (wait) await idle();
    }

    Future<void> capture(String name) async {
      await t.pumpAndSettle();
      for (final e in find.byType(Image).evaluate().toList()) {
        await precacheImage((e.widget as Image).image, e);
      }
      await t.pump(const Duration(milliseconds: 100));
      await b05Capture(root, '${out.path}/$name.png');
      captures.add('$name.png');
    }

    Future<void> solve({int skip = 0, bool useExtra = false}) async {
      final c = controller!;
      final moves = c.current!.puzzle.referenceMoves;
      if (useExtra) {
        final first = moves.first, extra = c.current!.board.length - 1;
        await tap('bottle-${first.from}');
        await tap('bottle-$extra');
        expect(c.current!.board[extra], isNotEmpty);
        await tap('bottle-$extra');
        await tap('bottle-${first.to}');
        skip = 1;
      }
      for (final m in moves.skip(skip)) {
        await tap('bottle-${m.from}');
        await tap('bottle-${m.to}');
      }
      expect(c.current!.completed, isTrue);
      expect(c.phase, SavePhase.clean);
    }

    for (final flow in ['11', '16', '13', 'daily', '12']) {
      final path = '$base/b05_e2e_$flow.sqlite';
      await deleteDatabase(
        path,
      ); // Only these explicitly named B05 QA databases.
      final store = await GameStore.open(path);
      final transport = B05Transport();
      final hub = ServiceHub(
        store: store,
        config: const ServiceConfig(
          adMode: 'test',
          interstitialId: 'ca-app-pub-3940256099942544/4411468910',
          rewardedId: 'ca-app-pub-3940256099942544/1712485313',
        ),
        transport: transport,
        knownPuzzleIds: {},
      );
      var day = LocalDay('2026-10-21', 'Asia/Taipei', 480);
      await b05Seed(store, library, switch (flow) {
        '16' => 15,
        '13' => 12,
        '12' => 11,
        _ => 10,
      });
      final c = controller = GameController(
        store,
        library: library,
        services: hub,
        clock: () => day,
      );
      await c.initialize();
      await hub.initializeLocal();
      hub.ads.update(consent: true);
      await c.navigate(
        GamePage.settings,
      ); // Controlled test does not request real UMP.
      await t.pumpWidget(
        RepaintBoundary(
          key: root,
          child: PourluneApp(controller: c),
        ),
      );
      await t.pumpAndSettle();
      try {
        if (flow == '11') {
          await c.startLevel(11);
          await idle();
          await solve();
          expect(c.progress.qualifyingClears, 1);
          await capture('e2e-11-settled');
          await tap('next');
          expect(c.current!.puzzle.mainLevel, 12);
          expect(await store.db.query('fullscreen_shows'), isEmpty);
        } else if (flow == '16') {
          final ad = await transport.ready(hub.ads, AdKind.interstitial);
          await c.startLevel(16);
          await idle();
          await solve();
          expect(c.progress.pieces, contains('color_studio:4'));
          expect(c.progress.revealedPieces, isNot(contains('color_studio:4')));
          expect(ad.shows, 0);
          await tap('view-patch');
          await capture('e2e-16-patch');
          await tap('next', wait: false);
          await until(() => ad.route != null);
          expect(c.progress.revealedPieces, contains('color_studio:4'));
          expect(c.current!.puzzle.mainLevel, 16);
          await c.nextLevel();
          await c.goHome();
          ad.route!.shown();
          ad.route!.closed();
          await idle();
          expect(c.current!.puzzle.mainLevel, 17);
          expect(ad.shows, 1);
          expect(c.progress.qualifyingClears, 0);
        } else if (flow == '13') {
          final reward = await transport.ready(hub.ads, AdKind.rewarded);
          final interstitial = await transport.ready(
            hub.ads,
            AdKind.interstitial,
          );
          await c.startLevel(13);
          await idle();
          await tap('extra-bottle');
          await capture('e2e-13-extra-explanation');
          expect(reward.shows, 0);
          await tap('watch-ad', wait: false);
          await until(() => reward.route != null);
          reward.route!.shown();
          reward.route!.reward();
          reward.route!.closed();
          await until(() => c.current!.extraBottleGranted && !c.busy);
          await capture('e2e-13-granted-CONTROLLED');
          await solve(useExtra: true);
          await tap('next');
          expect(c.current!.puzzle.mainLevel, 14);
          expect(interstitial.shows, 0);
          expect(c.progress.qualifyingClears, 3);
          expect(hub.ads.cooldown, greaterThan(Duration.zero));
        } else if (flow == 'daily') {
          await c.startLevel(11);
          await idle();
          final ordinary = c.current!.toJson();
          await c.startToday();
          await idle();
          final yesterday = c.current!.id;
          final first = c.current!.puzzle.referenceMoves.first;
          await tap('bottle-${first.from}');
          await tap('bottle-${first.to}');
          await c.goHome();
          day = LocalDay('2026-10-22', 'Asia/Taipei', 480);
          c.refreshToday();
          await c.navigate(GamePage.daily);
          await idle();
          await tap('today');
          await t.tap(find.text('Keep playing'));
          await t.pumpAndSettle();
          expect(c.daily!.id, yesterday);
          await tap('daily-resume');
          await solve(skip: 1);
          expect(c.progress.dailyStamps, ['2026-10-21']);
          await tap('daily-calendar');
          await tap('today');
          await solve();
          expect(c.progress.dailyStamps, ['2026-10-21', '2026-10-22']);
          expect((await store.load('ordinary')).instance!.toJson(), ordinary);
          await capture('e2e-daily-two-dates');
        } else {
          await c.startLevel(12);
          await idle();
          final moves = c.current!.puzzle.referenceMoves;
          for (final m in moves.take(moves.length - 1)) {
            await tap('bottle-${m.from}');
            await tap('bottle-${m.to}');
          }
          final before = (await store.load('ordinary')).instance!.toJson();
          store.fault = (stage) {
            if (stage == 'receipt') {
              throw StateError('B05 QA transaction write failure');
            }
          };
          final last = moves.last;
          await tap('bottle-${last.from}');
          await tap('bottle-${last.to}');
          expect(c.phase, SavePhase.failed);
          expect((await store.load('ordinary')).instance!.toJson(), before);
          expect(
            (await store.progress()).pieces,
            isNot(contains('color_studio:3')),
          );
          await capture('e2e-12-save-failed');
          store.fault = null;
          await tap('retry');
          expect(c.progress.pieces, contains('color_studio:3'));
          await tap('view-patch');
          await capture('e2e-12-reveal');
          await c.acknowledgeReveal(next: false);
          expect(
            (await store.db.query(
              'pieces',
              where: 'piece=?',
              whereArgs: ['color_studio:3'],
            )).length,
            1,
          );
          await record('12-transaction-rollback-retry-not-process-restart', c);
          // Actual process termination is a separate same-install B05 lifecycle harness.
        }
        await record(flow, c, {
          'qa_seed': true,
          'formal_main_count': library.main.length,
        });
        if (flow == '13') {
          // Actual native rendering under controlled viewport/text scaler, not physical device/VoiceOver.
          await t.binding.setSurfaceSize(const Size(320, 568));
          await c.updateSetting('reduced_motion', true);
          await c.updateSetting('music', false);
          await c.updateSetting('sound', false);
          await t.pumpWidget(
            RepaintBoundary(
              key: root,
              child: PourluneApp(
                controller: c,
                textScaler: TextScaler.linear(2),
              ),
            ),
          );
          final semantics = t.ensureSemantics();
          await idle();
          final label = t
              .getSemantics(find.byKey(const Key('bottle-0')))
              .getSemanticsData()
              .label;
          expect(label, contains('Bottle 1'));
          expect(label, contains('Target'));
          expect(label, contains('of 4'));
          await tap('extra-bottle');
          await capture('narrow-2x-extra-cooldown');
          expect(
            t
                .getSemantics(find.byKey(const Key('watch-ad')))
                .getSemanticsData()
                .label,
            contains('Watch'),
          );
          await t.tap(find.text('Not now'));
          await t.pumpAndSettle();
          await c.navigate(GamePage.settings);
          await idle();
          await tap('privacy');
          await capture('narrow-2x-privacy');
          expect(find.byKey(const Key('analytics-choice')), findsOneWidget);
          expect(find.byKey(const Key('crash-choice')), findsOneWidget);
          for (final key in ['analytics-choice', 'crash-choice']) {
            final toggle = find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(Switch),
            );
            await t.ensureVisible(toggle);
            await t.tap(toggle);
            await t.pumpAndSettle();
          }
          expect(hub.choices.analytics, isTrue);
          expect(hub.choices.crash, isTrue);
          await capture('narrow-2x-privacy-scrolled-choices');
          await t.tap(find.text('Close'));
          await t.pumpAndSettle();
          await c.navigate(GamePage.progress);
          await idle();
          await capture('narrow-2x-reward-history');
          await File('${out.path}/semantics.txt').writeAsString(
            t.getSemantics(find.byType(Scaffold).first).toStringDeep(),
          );
          final rewardOrigin = c.current!.id;
          await store.beginReward('b05-narrow-controlled', c.current!);
          await c.startLevel(3, replace: true);
          await idle();
          await store.confirmReward('b05-narrow-controlled');
          await c.initialize();
          await c.goHome();
          await idle();
          final restore = find.text('Resume rewarded puzzle');
          await t.ensureVisible(restore);
          await capture('narrow-2x-pending-reward');
          await t.tap(restore);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await capture('narrow-2x-restore-confirmation');
          final details = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(SingleChildScrollView),
          );
          await t.drag(details, const Offset(0, -500));
          await t.pumpAndSettle();
          await capture('narrow-2x-restore-details-scrolled');
          await tap('confirm-reward-restore');
          expect(c.current!.id, rewardOrigin);
          expect(c.current!.extraBottleGranted, isTrue);
          semantics.dispose();
          await t.binding.setSurfaceSize(null);
          await record('narrow320x568-text2-reduced-muted-service-surfaces', c);
        }
      } finally {
        store.fault = null;
        await t.pumpWidget(const SizedBox());
        c.dispose();
        hub.dispose();
        await store.close();
      }
    }
    await b05Json('${out.path}/complete.json', {
      'status': 'passed',
      'events': events.length,
      'screenshots': captures,
    });
    debugPrint('B05_CANDIDATE_COMPLETE ${out.path}');
    await Future<void>.delayed(
      const Duration(seconds: 15),
    ); // Host copies sandbox evidence before runner teardown.
  });
}
