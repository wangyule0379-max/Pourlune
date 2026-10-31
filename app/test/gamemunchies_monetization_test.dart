import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_policy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'b04_ads_test.dart' show Transport;
import 'gamemunchies_reporting_test.dart' show ReportingHarness;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    '0.2 restores legacy 0.1 queue without replacing installation or cooldown',
    () async {
      final h = ReportingHarness();
      final scope = jsonEncode([
        'https://api.gamemunchies.com',
        'unit-reporting',
        'ios',
        'test',
      ]);
      final legacy = {
        'id': 'legacy-round-event',
        'type': 'round_start',
        'installationId': 'existing-installation',
        'environment': 'test',
        'occurredAt': h.now
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      };
      await h.store.write(scope, {
        'schemaVersion': 1,
        'events': [legacy],
        'splits': [],
        'retryAt': 0,
        'retryAttempt': 0,
        'installationId': 'existing-installation',
        'lastShownAt': h.now
            .subtract(const Duration(seconds: 30))
            .millisecondsSinceEpoch,
      });
      final r = h.reporting();
      await r.setEnabled(true);
      await h.flush();
      expect(h.received, [legacy]);
      final saved = await h.store.read(scope);
      expect(saved!['installationId'], 'existing-installation');
      expect(saved['events'], isEmpty);
      expect(r.allowsShow(AdKind.interstitial), false);
      await r.dispose();
    },
  );

  test('real blocked attempts report one opportunity with matching reason; readiness polling emits nothing', () async {
    final h = ReportingHarness(), r = h.reporting();
    final directory = Directory.systemTemp.createTempSync('gm-funnel-');
    final store = await GameStore.open(
      '${directory.path}/game.sqlite',
      factory: databaseFactoryFfi,
    );
    final ads = AdCoordinator(
      store: store,
      transport: Transport(),
      configured: true,
      reporting: r,
    );
    try {
      await r.setEnabled(true);
      await ads.initialize();
      for (var i = 0; i < 10; i++) {
        ads.ready(AdKind.rewarded);
        ads.blockedReason(AdKind.rewarded);
      }
      await h.flush();
      expect(h.received, isEmpty);
      await ads.show(AdKind.rewarded, 'privacy-guard');
      ads.update(consent: true);
      await ads.show(AdKind.rewarded, 'empty-inventory');
      ads.update(isForeground: false);
      await ads.show(AdKind.rewarded, 'background');
      ads.policy = const RemotePolicy(adsEnabled: false);
      await ads.show(AdKind.rewarded, 'disabled');
      ads.blockedOpportunity(AdKind.interstitial, 'entitlement');
      await h.flush();
      final blocked = h.received
          .where((e) => e['type'] == 'ad_blocked')
          .toList();
      final opportunities = h.received
          .where((e) => e['type'] == 'ad_opportunity')
          .toList();
      expect(blocked.map((e) => e['ad']['reason']), [
        'privacy',
        'not_ready',
        'in_background',
        'config_disabled',
        'entitlement',
      ]);
      expect(opportunities.length, 5);
      for (final b in blocked) {
        expect(
          opportunities
              .where(
                (o) => o['ad']['opportunityId'] == b['ad']['opportunityId'],
              )
              .length,
          1,
        );
      }
      expect(
        h.received.where((e) => e['type'] == 'ad_show_attempted'),
        isEmpty,
      );
    } finally {
      ads.dispose();
      await r.dispose();
      await store.close();
      directory.deleteSync(recursive: true);
    }
  });

  test('offline funnel keeps original associations and first times after SDK restart and lost acknowledgement', () async {
    final h = ReportingHarness()..offline = true;
    var r = h.reporting();
    await r.setEnabled(true);
    final load = r.loadAttempt(AdKind.rewarded);
    await load.emit('ad_loaded');
    final opportunity = r.opportunity(AdKind.rewarded)..attachLoad(load.id);
    await opportunity.emit('ad_show_attempted');
    await opportunity.emit('ad_impression');
    await opportunity.emit('ad_reward_earned');
    await h.flush();
    final original = h.posts.last;
    expect(original.length, 6);
    await r.dispose();
    h.offline = false;
    h.loseAck = true;
    h.now = h.now.add(const Duration(seconds: 7));
    r = h.reporting();
    await r.setEnabled(true);
    await h.flush();
    await h.flush();
    expect(h.received, original);
    expect(h.posts.last, original);
    expect(h.received.every((e) => e['environment'] == 'test'), true);
    await r.dispose();
  });

  test('withdrawal erases queued funnel, ignores late stages, but impression cooldown survives restart', () async {
    final h = ReportingHarness()..offline = true;
    var r = h.reporting();
    await r.setEnabled(true);
    final opportunity = r.opportunity(AdKind.interstitial);
    await opportunity.emit('ad_show_attempted');
    await r.setEnabled(false);
    await opportunity.emit('ad_impression');
    await opportunity.emit('ad_show_failed', reason: 'sdk_error');
    await r.loadAttempt(AdKind.rewarded).emit('ad_loaded');
    await h.flush();
    expect(h.posts, isEmpty);
    expect(r.allowsShow(AdKind.interstitial), false);
    await r.dispose();
    h.offline = false;
    r = h.reporting();
    await r.setEnabled(false);
    await h.flush();
    expect(h.posts, isEmpty);
    expect(r.allowsShow(AdKind.interstitial), false);
    await r.setEnabled(true);
    await h.flush();
    expect(h.received, isEmpty);
    await r.dispose();
  });
}
