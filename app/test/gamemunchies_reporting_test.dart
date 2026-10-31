import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamemunchies_client/gamemunchies_client.dart';
import 'package:gamemunchies_client/src/preferences_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';

// Real SDK queue/serialization; replace only HTTP and platform preferences.
class ReportingHarness {
  final store = MemoryStore();
  final received = <Map<String, dynamic>>[];
  final posts = <List<dynamic>>[];
  final clients = <GameMunchiesClient>[];
  DateTime now = DateTime.utc(2026, 10, 28, 1);
  bool offline = false, loseAck = false;

  GameMunchiesReporting reporting() => GameMunchiesReporting(
    now: () => now,
    createClient: () {
      final c = GameMunchiesClient(
        ClientOptions(
          baseUrl: 'https://api.gamemunchies.com',
          gameId: 'unit-reporting',
          platform: 'ios',
          environment: 'test',
          defaultConfig: GameMunchiesReporting.defaultConfig,
        ),
        store: store,
        now: () => now.millisecondsSinceEpoch,
        random: () => 0,
        httpClient: MockClient((request) async {
          if (request.method == 'GET') return http.Response('', 409);
          final events = jsonDecode(request.body)['events'] as List;
          posts.add(events);
          if (offline) throw StateError('offline');
          var accepted = 0;
          for (final e in events.cast<Map<String, dynamic>>()) {
            if (!received.any((old) => old['id'] == e['id'])) {
              received.add(e);
              accepted++;
            }
          }
          if (loseAck) {
            loseAck = false;
            throw StateError('response lost after acceptance');
          }
          return http.Response(
            jsonEncode({'received': events.length, 'accepted': accepted}),
            200,
          );
        }),
      );
      clients.add(c);
      return c;
    },
  );

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await clients.last.flush();
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'startup and a new round never await an unresponsive config request',
    () async {
      final response = Completer<http.Response>();
      final client = GameMunchiesClient(
        ClientOptions(
          baseUrl: 'https://api.gamemunchies.com',
          gameId: 'unit-unresponsive',
          platform: 'android',
          environment: 'test',
          defaultConfig: GameMunchiesReporting.defaultConfig,
        ),
        store: MemoryStore(),
        httpClient: MockClient((_) => response.future),
      );
      final reporting = GameMunchiesReporting(createClient: () => client);
      addTearDown(() async {
        response.complete(http.Response('', 503));
        await reporting.dispose();
      });
      await reporting.setEnabled(true).timeout(const Duration(seconds: 1));
      await reporting
          .roundStarted('while-offline', DateTime.now())
          .timeout(const Duration(seconds: 1));
    },
  );

  test('analytics off retains one rules client without statistics; withdrawal stops observations', () async {
    final h = ReportingHarness();
    final r = h.reporting();
    await r.setEnabled(false);
    await r.roundStarted('off', h.now);
    expect(h.clients.length, 1);
    await r.setEnabled(true);
    await r.roundStarted('chosen', h.now);
    await h.flush();
    expect(h.received.where((e) => e['type'] == 'round_start').length, 1);
    await r.setEnabled(false);
    await r.roundStarted('withdrawn', h.now);
    await r.opportunity(AdKind.rewarded).emit('ad_impression');
    expect(h.received.where((e) => e['type'] == 'round_start').length, 1);
    await r.dispose();
  });

  test(
    'one SDK lifecycle handles duplicate resume without duplicate active',
    () async {
      final h = ReportingHarness();
      final r = h.reporting();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await r.setEnabled(true);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await h.flush();
      expect(h.received.where((e) => e['type'] == 'active').length, 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await h.flush();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await h.flush();
      expect(h.received.where((e) => e['type'] == 'active').length, 2);
      expect(h.clients.length, 1);
      await r.dispose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    },
  );

  test('real callback observations keep first time and ID across duplicate callbacks and lost ack', () async {
    final h = ReportingHarness();
    final r = h.reporting();
    await r.setEnabled(true);
    final displayed = r.opportunity(AdKind.interstitial);
    await h.flush();
    h.received.clear();
    final failed = r.loadAttempt(AdKind.rewarded);
    await h.flush();
    h.received.clear();
    h.now = h.now.add(const Duration(seconds: 5));
    await displayed.emit('ad_impression');
    await failed.emit('ad_load_failed', reason: 'network');
    h.loseAck = true;
    await h.flush();
    final first = h.posts.last;
    h.now = h.now.add(const Duration(seconds: 10));
    await displayed.emit('ad_impression');
    await failed.emit('ad_load_failed', reason: 'network');
    await h.flush();
    expect(h.posts.last, first);
    expect(h.received.where((e) => e['type'] == 'ad_impression').length, 1);
    expect(h.received.where((e) => e['type'] == 'ad_load_failed').length, 1);
    expect(
      first.every((e) => e['occurredAt'] == '2026-10-28T01:00:05.000Z'),
      isTrue,
    );
    await r.dispose();
  });

  test('offline SDK queue survives normal disposal and new client without changing original event', () async {
    final h = ReportingHarness()..offline = true;
    var r = h.reporting();
    await r.setEnabled(true);
    await r.roundStarted('new-round-1', h.now);
    await h.flush();
    final original = h.posts.last.single;
    await r.dispose();
    h.now = h.now.add(const Duration(seconds: 10));
    h.offline = false;
    r = h.reporting();
    await r.setEnabled(true);
    await h.flush();
    expect(h.received.single, original);
    expect(h.received.single['type'], 'round_start');
    expect(h.received.single['id'], 'round:new-round-1');
    await r.dispose();
  });

  test(
    'a broken stats dependency never throws into gameplay callers',
    () async {
      final codes = <String>[];
      final r = GameMunchiesReporting(
        createClient: () => throw StateError('unavailable'),
        onDiagnostic: codes.add,
      );
      await r.setEnabled(true);
      await r.roundStarted('new-round', DateTime.now());
      await r.opportunity(AdKind.rewarded).emit('ad_impression');
      await r
          .loadAttempt(AdKind.rewarded)
          .emit('ad_load_failed', reason: 'network');
      await r.dispose();
      expect(codes, contains('initialization_failed'));
    },
  );
}
