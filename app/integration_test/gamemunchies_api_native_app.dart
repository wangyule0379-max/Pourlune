// Independent new-API native QA entry; reuses the verified lost-ACK probe. Normal main never imports this file.
// Computer must use only the two explicitly named GM QA devices, preserve existing
// databases, and stop/relaunch the SAME installation between the two phases.
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
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite/sqflite.dart';

class QaDisconnectedClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(const SocketException('controlled_qa_disconnect'));
}

/// Fault injection only: forwards the SDK-built request untouched, records
/// aggregate ACKs, loses ONE valid ACK, then lets the SDK own every retry.
class QaAckLossClient extends http.BaseClient {
  QaAckLossClient(
    this.lossMarker, {
    http.Client? inner,
    this.savedOriginals = const [],
  }) : _inner = inner ?? http.Client();
  final File lossMarker;
  final http.Client _inner;
  final List<Map<String, dynamic>> savedOriginals;
  final acknowledgements = <Map<String, int>>[];
  List<Map<String, dynamic>>? _original;
  bool _firstAcceptedAll = false;
  bool retryPreservedOriginalFields = false;
  bool originalsDeduplicated = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isEvents =
        request.method == 'POST' && request.url.path.endsWith('/events');
    final observations = isEvents && request is http.Request
        ? (jsonDecode(request.body)['events'] as List)
              .cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    if (isEvents && response.statusCode == 200) {
      final ack = jsonDecode(utf8.decode(bytes));
      if (ack is Map &&
          ack['accepted'] is int &&
          ack['received'] is int &&
          ack['received'] == observations.length &&
          ack['accepted'] >= 0 &&
          ack['accepted'] <= ack['received']) {
        acknowledgements.add({
          'status': 200,
          'accepted': ack['accepted'] as int,
          'received': ack['received'] as int,
        });
        if (_original == null) {
          _original = observations;
          _firstAcceptedAll =
              ack['accepted'] == ack['received'] &&
              _sameObservations(savedOriginals, observations);
        } else {
          final preserved = _sameObservations(_original!, observations);
          retryPreservedOriginalFields |= preserved;
          originalsDeduplicated |=
              _firstAcceptedAll &&
              preserved &&
              ack['accepted'] <= observations.length - _original!.length;
        }
        // Save every real ACK before injecting loss or returning it to the SDK.
        // Public counts/booleans only; original fields stay in the private snapshot.
        await _writeProof(File('${lossMarker.parent.path}/acks.json'), {
          'acks': acknowledgements,
          'original_batch_count': _original!.length,
          'saved_original_count': savedOriginals.length,
          'first_batch_accepted_all_originals': _firstAcceptedAll,
          'retry_kept_original_ids_and_first_times':
              retryPreservedOriginalFields,
          'originals_deduplicated': originalsDeduplicated,
        });
        if (!await lossMarker.exists()) {
          await lossMarker.writeAsString(
            'one controlled lost ACK; never inject twice\n',
            flush: true,
          );
          throw const SocketException('controlled_qa_lost_ack');
        }
      }
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

Future<void> _writeProof(File file, Map<String, dynamic> proof) async {
  final temporary = File('${file.path}.tmp');
  await temporary.writeAsString(jsonEncode(proof), flush: true);
  await temporary.rename(file.path);
}

bool _sameObservations(List before, List after) => before.every(
  (old) => after.any(
    (next) =>
        old is Map &&
        next is Map &&
        old.keys.every((key) => next[key] == old[key]),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  const game = String.fromEnvironment('POURLUNE_GAMEMUNCHIES_GAME_ID');
  const environment = String.fromEnvironment(
    'POURLUNE_GAMEMUNCHIES_ENVIRONMENT',
  );
  const device = String.fromEnvironment('POURLUNE_GM_TEST_DEVICE');
  const appId = String.fromEnvironment('POURLUNE_GM_TEST_APP_ID');
  final platform = Platform.isIOS ? 'ios' : 'android';
  final expectedDevice = Platform.isIOS
      ? '2894A85E-04FC-4857-A856-3BEFF2CCB565'
      : 'Pourlune_GM_QA_20261028';
  final expectedAppId = Platform.isIOS
      ? 'dev.pourlune.gamemunchiesValidation'
      : 'dev.pourlune.pourlune_dev';
  if (!kDebugMode ||
      !(Platform.isAndroid || Platform.isIOS) ||
      database != 'gm_api_native_recovery_20261028.sqlite' ||
      game != GameMunchiesReporting.testGameId ||
      environment != 'test' ||
      device != expectedDevice ||
      appId != expectedAppId) {
    throw StateError('Independent mobile GM QA parameters required');
  }
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('GM native QA: preparing'))),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  final base = await getDatabasesPath();
  final evidence = Directory('$base/gamemunchies-api-native-evidence-20261028');
  await evidence.create(recursive: true);
  final marker = File('${evidence.path}/restart-marker.private.json');
  final snapshotFile = File('${evidence.path}/sdk-snapshot.private.json');
  final reportFile = File('${evidence.path}/report.json');
  if (await File('${evidence.path}/complete').exists()) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Text('GM native QA already complete; no new reports'),
        ),
      ),
    );
    return;
  }
  final restoring = await marker.exists();
  final previous = restoring
      ? jsonDecode(await marker.readAsString()) as Map
      : null;
  final original = restoring
      ? jsonDecode(await snapshotFile.readAsString()) as Map
      : null;
  final prefs = PreferencesStore();
  final scope = jsonEncode([
    GameMunchiesReporting.baseUrl,
    game,
    platform,
    'test',
  ]);
  final beforeStart = await prefs.read(scope);
  final priorScopeFile = File('${evidence.path}/prior-new-scope.private.json');
  if (!restoring) {
    if (beforeStart != null &&
        (beforeStart['events'] is! List ||
            (beforeStart['events'] as List).isNotEmpty)) {
      throw StateError(
        'Preserve the existing new-scope queue; drain normally before QA',
      );
    }
    if (await priorScopeFile.exists()) {
      throw StateError(
        'Preserve earlier QA evidence; do not overwrite a partial phase',
      );
    }
    await priorScopeFile.writeAsString(
      jsonEncode({'state': beforeStart}),
      flush: true,
    );
  }
  final restored = restoring ? beforeStart : null;
  final restoredExactly =
      restoring &&
      restored != null &&
      original != null &&
      restored['installationId'] == original['state']['installationId'] &&
      _sameObservations(
        original['state']['events'] as List,
        restored['events'] as List,
      );
  if (restoring && !restoredExactly) {
    throw StateError('Original native SDK queue did not restore');
  }
  late GameMunchiesClient client;
  final observation = Stopwatch()..start();
  final ackTransport = QaAckLossClient(
    File('${evidence.path}/lost-ack-once'),
    savedOriginals: restoring
        ? (original!['state']['events'] as List).cast<Map<String, dynamic>>()
        : const [],
  );
  final stats = GameMunchiesReporting(
    createClient: () => client = GameMunchiesClient(
      ClientOptions(
        baseUrl: GameMunchiesReporting.baseUrl,
        gameId: game,
        platform: platform,
        environment: 'test',
        defaultConfig: GameMunchiesReporting.defaultConfig,
      ),
      httpClient: restoring ? ackTransport : QaDisconnectedClient(),
    ),
  );
  final store = await GameStore.open('$base/$database');
  final puzzle = Puzzle.parse(
    await rootBundle.loadString('assets/puzzles/main/main-001.json'),
  );
  final hub = ServiceHub(
    store: store,
    config: const ServiceConfig(),
    knownPuzzleIds: {puzzle.id},
    reporting: stats,
  );
  final c = GameController(
    store,
    library: ContentLibrary(main: {1: puzzle}),
    services: hub,
  );
  await c.initialize();
  await hub.initializeLocal();
  if (!restoring) {
    if (c.ordinary != null) {
      throw StateError('Preserve prior QA data; missing phase marker');
    }
    // Explicit test opt-in, not a claim of manual privacy UI acceptance.
    await hub.updatePrivacy(const PrivacyChoices(analytics: true));
  }
  await stats.setEnabled(true);
  if (!restoring) {
    await c.startLevel(1); // Actual new instance/save; no direct track() calls.
    if (c.phase != SavePhase.clean || c.current == null) {
      throw StateError('Real new round was not saved');
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await client
        .flush(); // Controlled transport failure, original SDK persistence.
    final state = await prefs.read(client.scope);
    if (state == null ||
        !(state['events'] as List).any(
          (e) => e['id'] == 'round:${c.current!.id}',
        )) {
      throw StateError('Real SDK round observation was not persisted');
    }
    await snapshotFile.writeAsString(
      jsonEncode({
        'sourceDevice': device,
        'sourceAppId': appId,
        'preferencesKey': prefs.key(client.scope),
        'state': {
          'schemaVersion': state['schemaVersion'],
          'installationId': state['installationId'],
          'events': state['events'],
        },
      }),
      flush: true,
    );
    await marker.writeAsString(
      jsonEncode({'processId': pid, 'instanceId': c.current!.id}),
      flush: true,
    );
    await reportFile.writeAsString(
      jsonEncode({
        'phase': 'offline_ready',
        'real_new_round_saved': true,
        'sdk_native_queue_persisted': true,
        'queued_events': (state['events'] as List).length,
        'controlled_transport_disconnect': true,
        'radio_offline_verified': false,
        'ad_mode': 'disabled_for_data_probe',
        'normal_main_manual_ui': false,
      }),
      flush: true,
    );
    await stats
        .dispose(); // Preserve this queue without later offline timer attempts.
    debugPrint(
      'GM_NATIVE_OFFLINE_READY: private snapshot and public count report saved',
    );
  } else {
    if (pid == previous!['processId'] ||
        c.current?.id != previous['instanceId']) {
      throw StateError('A new process must restore the same saved instance');
    }
    c.resume(); // Resume never calls startLevel or track a second round.
    // One normal SDK flush; subsequent retries use its unchanged timer/backoff.
    unawaited(client.flush());
    var pending = -1;
    const limit = Duration(seconds: 90);
    while (observation.elapsed < limit) {
      pending = ((await prefs.read(client.scope))!['events'] as List).length;
      if (pending == 0 && ackTransport.originalsDeduplicated) {
        break;
      }
      final remaining = limit - observation.elapsed;
      if (remaining <= Duration.zero) break;
      await Future<void>.delayed(
        remaining < const Duration(seconds: 1)
            ? remaining
            : const Duration(seconds: 1),
      );
    }
    await stats
        .dispose(); // Bound this QA observation; no unobserved timer later.
    pending = ((await prefs.read(client.scope))!['events'] as List).length;
    final duplicateAck = ackTransport.acknowledgements.any(
      (a) => a['accepted'] == 0 && a['received']! > 0,
    );
    final priorScope = jsonDecode(await priorScopeFile.readAsString()) as Map;
    final afterScope = await prefs.read(client.scope);
    final proof = {
      'endpoint': GameMunchiesReporting.baseUrl,
      'new_scope_only': true,
      'prior_sdk_ad_cooldown_preserved':
          afterScope?['lastShownAt'] == priorScope['state']?['lastShownAt'],
      'phase': 'online_after_normal_process_restart',
      'same_installation_restored': restoredExactly,
      'same_game_instance_restored': true,
      'new_process': true,
      'new_round_on_restore': false,
      'controlled_transport_disconnect': true,
      'radio_offline_verified': false,
      'controlled_lost_ack_once': await ackTransport.lossMarker.exists(),
      'acks': ackTransport.acknowledgements,
      'retry_kept_original_ids_and_first_times':
          ackTransport.retryPreservedOriginalFields,
      'pure_duplicate_zero_ack_observed': duplicateAck,
      'originals_deduplicated': ackTransport.originalsDeduplicated,
      'sdk_pending': pending,
      'observation_limit_seconds': 90,
      'observation_elapsed_millis': observation.elapsedMilliseconds,
      'ad_mode': 'disabled_for_data_probe',
      'normal_main_manual_ui': false,
    };
    await _writeProof(reportFile, proof);
    if (pending == 0 && ackTransport.originalsDeduplicated) {
      await File('${evidence.path}/complete')
          .writeAsString('data probe complete\n', flush: true);
    }
    debugPrint('GM_NATIVE_ONLINE_RESULT ${jsonEncode(proof)}');
  }
  runApp(PourluneApp(controller: c));
}
