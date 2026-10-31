// Isolated mobile verification entry. Never imported by normal main/release.
// Uses production reporting, AdMob transport, controller and SQLite rewards.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamemunchies_client/gamemunchies_client.dart';
import 'package:gamemunchies_client/src/preferences_store.dart';
import 'package:http/http.dart' as http;
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart' show PourluneApp;
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite/sqflite.dart';

import 'gamemunchies_api_native_app.dart' show QaAckLossClient;

class ObservedTestHttp extends http.BaseClient {
  ObservedTestHttp(
    this.directory,
    Directory runDirectory,
    this.offline,
    List<Map<String, dynamic>> originals,
  ) : inner = QaAckLossClient(
        File('${runDirectory.path}/lost-ack-once'),
        savedOriginals: originals,
        proofDirectory: directory,
      );
  final Directory directory;
  final bool offline;
  final QaAckLossClient inner;
  final records = <Map<String, dynamic>>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host != 'api.gamemunchies.com') {
      throw StateError('API only');
    }
    final events = request.method == 'POST' && request is http.Request
        ? (jsonDecode(request.body)['events'] as List)
              .cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    if (events.isNotEmpty) {
      if (events.any((e) => e['environment'] != 'test')) {
        throw StateError('Test only');
      }
      // Private native evidence, never client admin credentials or repository data.
      await File('${directory.path}/last-batch.private.json')
          .writeAsString(jsonEncode(events));
    }
    if (offline && request.method == 'POST') {
      throw const SocketException('controlled_test_event_disconnect');
    }
    final response = await inner.send(request);
    final bytes = await response.stream.toBytes();
    records.add({
      'method': request.method,
      'status': response.statusCode,
      'types': events.map((e) => e['type']).toList(),
      if (response.statusCode != 200) 'response': utf8.decode(bytes),
    });
    await File('${directory.path}/http.json')
        .writeAsString(jsonEncode(records));
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  @override
  void close() => inner.close();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  const gameId = String.fromEnvironment('POURLUNE_GAMEMUNCHIES_GAME_ID');
  const environment = String.fromEnvironment(
    'POURLUNE_GAMEMUNCHIES_ENVIRONMENT',
  );
  final config = ServiceConfig.environment();
  if (!kDebugMode ||
      !{
        'gm_020_20261028.sqlite',
        'gm_020_recovery_20261028.sqlite',
      }.contains(database) ||
      gameId != GameMunchiesReporting.testGameId ||
      environment != 'test' ||
      !config.testing ||
      !config.adsConfigured ||
      !(Platform.isIOS || Platform.isAndroid)) {
    throw StateError(
      'Explicit isolated official-test-ad mobile build required',
    );
  }
  final base = await getDatabasesPath();
  final evidence = Directory(
    '$base/gm-020-evidence${database.contains('recovery') ? '-recovery' : ''}',
  );
  await evidence.create(recursive: true);
  // Preserve each process's receipts through every subsequent cold restart.
  final processEvidence = Directory(
    '${evidence.path}/process-${DateTime.now().microsecondsSinceEpoch}-$pid',
  );
  await processEvidence.create();
  final marker = File('${evidence.path}/first-process.private.json');
  final first = !await marker.exists();
  final prior = first ? null : jsonDecode(await marker.readAsString()) as Map;
  final prefs = PreferencesStore();
  final platform = Platform.isIOS ? 'ios' : 'android';
  final scope = jsonEncode([
    GameMunchiesReporting.baseUrl,
    gameId,
    platform,
    'test',
  ]);
  final before = await prefs.read(scope);
  if (first && before != null && (before['events'] as List).isNotEmpty) {
    throw StateError(
      'Existing pending queue must be drained normally before QA',
    );
  }
  final originals = first
      ? <Map<String, dynamic>>[]
      : ((jsonDecode(
                  await File('${evidence.path}/offline-state.private.json')
                      .readAsString(),
                ) as Map)['events']
                as List)
            .cast<Map<String, dynamic>>();
  final transport = ObservedTestHttp(
    processEvidence,
    evidence,
    first,
    originals,
  );
  late GameMunchiesClient client;
  late GameMunchiesReporting reporting;
  reporting = GameMunchiesReporting(
    appVersion: '0.5.0+19',
    createClient: () => client = GameMunchiesClient(
      ClientOptions(
        baseUrl: GameMunchiesReporting.baseUrl,
        gameId: gameId,
        platform: platform,
        environment: 'test',
        statisticsEnabled: false,
        defaultConfig: GameMunchiesReporting.defaultConfig,
        onConfigChanged: (_) => reporting.onRulesChanged?.call(),
      ),
      httpClient: transport,
    ),
  );
  final puzzle = Puzzle.parse(
    await rootBundle.loadString('assets/puzzles/main/main-004.json'),
  );
  final store = await GameStore.open('$base/$database');
  final hub = ServiceHub(
    store: store,
    config: config,
    knownPuzzleIds: {puzzle.id},
    reporting: reporting,
  );
  final controller = GameController(
    store,
    library: ContentLibrary(main: {4: puzzle}),
    services: hub,
  );
  await controller.initialize();
  await hub.initializeLocal();
  if (first) {
    // User explicitly requested test statistics. Only this new QA database opts in.
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
    await reporting.setEnabled(true);
    await controller.start(puzzle);
    await marker.writeAsString(
      jsonEncode({'pid': pid, 'instance': controller.current!.id}),
    );
  } else {
    await reporting.setEnabled(hub.choices.analytics);
    controller.resume();
  }
  final recovery = {
    'new_process': prior != null && prior['pid'] != pid,
    'same_game_instance':
        prior != null && prior['instance'] == controller.current?.id,
    'restored_original_events':
        !first &&
        originals.every(
          (e) => (before?['events'] as List? ?? []).any(
            (v) => jsonEncode(v) == jsonEncode(e),
          ),
        ),
  };
  Future<Map<String, dynamic>> status() async {
    final state = await prefs.read(client.scope);
    if (first) {
      await File('${evidence.path}/offline-state.private.json')
          .writeAsString(jsonEncode(state));
    }
    final report = <String, dynamic>{
      'sdk': '0.2.0',
      'platform': platform,
      'environment': 'test',
      'phase': first
          ? 'offline_queue_then_restart_same_installation'
          : 'online_recovery',
      ...recovery,
      'queued': (state?['events'] as List? ?? []).length,
      'statistics': hub.choices.analytics,
      'configVersion': reporting.snapshot['version'],
      'interstitial': hub.ads.state(AdKind.interstitial).name,
      'rewarded': hub.ads.state(AdKind.rewarded).name,
      'adConsent': hub.ads.allowed,
      'cooldownSeconds': hub.ads.cooldown.inSeconds,
      'sdkCooldownSaved': state?['lastShownAt'] != null,
      'extraBottle': controller.current?.extraBottleGranted,
      'pendingRewards': controller.pendingRewards.length,
    };
    await File('${processEvidence.path}/status.json')
        .writeAsString(jsonEncode(report));
    return report;
  }

  await status();
  runApp(
    MaterialApp(
      home: NativeVerification(
        controller: controller,
        hub: hub,
        client: client,
        status: status,
      ),
    ),
  );
}

class NativeVerification extends StatefulWidget {
  const NativeVerification({
    super.key,
    required this.controller,
    required this.hub,
    required this.client,
    required this.status,
  });
  final GameController controller;
  final ServiceHub hub;
  final GameMunchiesClient client;
  final Future<Map<String, dynamic>> Function() status;
  @override
  State<NativeVerification> createState() => _NativeVerificationState();
}

class _NativeVerificationState extends State<NativeVerification>
    with WidgetsBindingObserver {
  Map<String, dynamic> report = {};
  String result = '';
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final next = await widget.status();
      if (mounted) setState(() => report = next);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      widget.controller.setForeground(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> act(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => result = 'Action finished');
    } catch (e) {
      if (mounted) setState(() => result = 'Action failed: ${e.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pourlune SDK 0.2 TEST')),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Text(
            const JsonEncoder.withIndent(' ').convert(report),
            style: const TextStyle(fontSize: 13),
          ),
          Text(result),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () =>
                    act(() => widget.hub.prepareAdsPrivacy(force: true)),
                child: const Text('Prepare official test ads'),
              ),
              ElevatedButton(
                onPressed: () => act(() async {
                  await widget.hub.ads.show(
                    AdKind.interstitial,
                    'qa-${DateTime.now().microsecondsSinceEpoch}',
                  );
                }),
                child: const Text('Show test interstitial'),
              ),
              ElevatedButton(
                onPressed: () =>
                    act(() => widget.controller.watchExtraBottle()),
                child: const Text('Earn extra bottle'),
              ),
              ElevatedButton(
                onPressed: () => act(() => widget.client.flush()),
                child: const Text('Flush SDK queue'),
              ),
              ElevatedButton(
                onPressed: () =>
                    act(() => widget.hub.updatePrivacy(const PrivacyChoices())),
                child: const Text('Withdraw statistics'),
              ),
              ElevatedButton(
                onPressed: () => act(
                  () => widget.hub.updatePrivacy(
                    const PrivacyChoices(analytics: true),
                  ),
                ),
                child: const Text('Enable test statistics'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PourluneApp(controller: widget.controller),
                  ),
                ),
                child: const Text('Open actual game'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
