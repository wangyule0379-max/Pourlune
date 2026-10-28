import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gamemunchies_client/gamemunchies_client.dart';

import 'ad_coordinator.dart';

/// One shared client owns cached ad rules and optional, consent-gated statistics.
/// GameController and SQLite remain authoritative for rewards and game state.
class GameMunchiesReporting {
  GameMunchiesReporting({
    this.createClient,
    DateTime Function()? now,
    this.onDiagnostic,
    this.appVersion = 'dev',
  }) : now = now ?? DateTime.now;

  static const baseUrl = 'https://api.gamemunchies.com';
  static const productionGameId = '8feaf0dc-ec12-4308-ac58-16b2180f2d63';
  static const testGameId = '566121d2-a3f5-4950-8bd9-6ff2f673a0ac';
  static const defaultConfig = <String, dynamic>{
    'enabled': true,
    'interstitial': {
      'enabled': true,
      'scenes': {'next_level': true},
      'minIntervalSeconds': 180,
    },
    'rewarded': {
      'scenes': {'extra_bottle': true},
    },
  };

  factory GameMunchiesReporting.environment() {
    const gameId = String.fromEnvironment('POURLUNE_GAMEMUNCHIES_GAME_ID');
    const environment = String.fromEnvironment(
      'POURLUNE_GAMEMUNCHIES_ENVIRONMENT',
    );
    // ID and environment must be an explicitly recognized pair.
    if (kIsWeb ||
        !registrationMatches(gameId, environment) ||
        !{
          TargetPlatform.iOS,
          TargetPlatform.android,
        }.contains(defaultTargetPlatform)) {
      return GameMunchiesReporting();
    }
    late GameMunchiesReporting owner;
    const version = String.fromEnvironment('POURLUNE_VERSION_NAME');
    const build = String.fromEnvironment('POURLUNE_VERSION_CODE');
    owner = GameMunchiesReporting(
      appVersion: version.isEmpty ? 'dev' : '$version+$build',
      createClient: () => GameMunchiesClient(
        ClientOptions(
          baseUrl: baseUrl,
          gameId: gameId,
          platform: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          environment: environment,
          defaultConfig: defaultConfig,
          statisticsEnabled: false,
          onConfigChanged: (_) => owner._rulesChanged(),
          onDiagnostic: (d) => debugPrint('GM_SDK ${d['code']}'),
        ),
      ),
    );
    return owner;
  }

  static bool registrationMatches(String gameId, String environment) =>
      (gameId == testGameId && environment == 'test') ||
      (gameId == productionGameId && environment == 'production');

  VoidCallback? onRulesChanged;
  Map<String, dynamic> get snapshot =>
      _client?.getConfig() ??
      {'config': defaultConfig, 'version': 0, 'source': 'default'};
  static String scene(AdKind kind) =>
      kind == AdKind.interstitial ? 'next_level' : 'extra_bottle';
  bool allowsLoad(AdKind kind) {
    final c = snapshot['config'];
    return c['enabled'] == true &&
        c[kind.name]?['scenes']?[scene(kind)] == true &&
        (kind != AdKind.interstitial || c['interstitial']['enabled'] == true);
  }

  bool allowsShow(AdKind kind) =>
      _client?.canShowAd(kind.name, scene(kind)) ?? allowsLoad(kind);
  void _rulesChanged() {
    if (_disposed) return;
    if (kDebugMode) {
      final value = snapshot, config = value['config'];
      debugPrint(
        'GM_RULES version=${value['version']} source=${value['source']} '
        'enabled=${config['enabled']} next_level=${config['interstitial']?['scenes']?['next_level']} '
        'extra_bottle=${config['rewarded']?['scenes']?['extra_bottle']} '
        'interval=${config['interstitial']?['minIntervalSeconds']}',
      );
    }
    onRulesChanged?.call();
  }

  final GameMunchiesClient Function()? createClient;
  bool get configured => createClient != null;
  final DateTime Function() now;
  final String appVersion;
  final void Function(String code)? onDiagnostic;
  GameMunchiesClient? _client;
  GameMunchiesLifecycle? _lifecycle;
  Future<void> _configuration = Future<void>.value();
  Future<void>? _disposing;
  bool _allowed = false, _disposed = false;
  int _choiceGeneration = 0;

  void _diagnostic(String code) {
    try {
      if (onDiagnostic != null) {
        onDiagnostic!(code);
      } else {
        debugPrint('GM_REPORTING $code');
      }
    } catch (_) {
      // Diagnostics are optional too.
    }
  }

  /// Statistics withdraw synchronously; the same client keeps fetching rules.
  Future<void> setEnabled(bool value) {
    final allowed = value && createClient != null && !_disposed;
    if (allowed != _allowed) _choiceGeneration++;
    _allowed = allowed;
    if (!_allowed && _client != null) {
      unawaited(_client!.setStatisticsEnabled(false));
    }
    return _configuration = _configuration.then((_) async {
      if (_disposed || createClient == null) return;
      try {
        if (_client == null) {
          final client = _client = createClient!();
          await client.setStatisticsEnabled(_allowed);
          await client.start(); // Local restore only, never waits on HTTP.
          if (_disposed) {
            await _closeClient();
            return;
          }
          _lifecycle = GameMunchiesLifecycle(client.setForeground);
          _rulesChanged();
        } else {
          await _client!.setStatisticsEnabled(_allowed);
        }
      } catch (_) {
        await _closeClient();
        _diagnostic('initialization_failed');
      }
    });
  }

  Future<void> _closeClient() async {
    _lifecycle?.dispose();
    _lifecycle = null;
    final old = _client;
    _client = null;
    try {
      await old?.dispose();
    } catch (_) {
      _diagnostic('disposal_failed');
    }
  }

  Future<void> _submit(
    Future<String> Function(GameMunchiesClient client) event, {
    bool rulesOnly = false,
  }) async {
    if (_disposed || (!_allowed && !rulesOnly)) return;
    final generation = _choiceGeneration;
    try {
      // A live impression reaches the SDK synchronously so its consent epoch
      // also guards an in-flight enqueue. Rules still retain actual cooldown.
      if (_client == null) await _configuration;
      final client = _client;
      if (_disposed ||
          client == null ||
          generation != _choiceGeneration ||
          (!_allowed && !rulesOnly)) {
        return;
      }
      await event(client);
    } catch (_) {
      _diagnostic('observation_failed');
    }
  }

  Future<void> roundStarted(String instanceId, DateTime firstStartedAt) =>
      _submit(
        (client) => client.track(
          'round_start',
          id: 'round:$instanceId',
          occurredAt: firstStartedAt.toUtc().toIso8601String(),
        ),
      );

  /// Local identifiers only. No network or preferences work delays the ad path.
  GameMunchiesAdEvents loadAttempt(AdKind kind) =>
      GameMunchiesAdEvents._(this, kind, load: true)..emit('ad_load_requested');

  GameMunchiesAdEvents opportunity(AdKind kind) =>
      GameMunchiesAdEvents._(this, kind, load: false)..emit('ad_opportunity');

  Future<void> dispose() {
    _disposed = true;
    _allowed = false;
    return _disposing ??= _configuration.then((_) => _closeClient());
  }
}

/// A single load or display opportunity. Each stage owns its first timestamp and
/// stable ID; late/duplicate callbacks cannot enqueue another observation.
class GameMunchiesAdEvents {
  GameMunchiesAdEvents._(this.owner, AdKind kind, {required bool load})
    : id = List.generate(
        16,
        (_) => Random.secure().nextInt(256),
      ).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      _context = {
        'kind': kind.name,
        'scene': GameMunchiesReporting.scene(kind),
        'provider': 'admob',
        'appVersion': owner.appVersion,
      } {
    _context[load ? 'loadAttemptId' : 'opportunityId'] = id;
  }

  final GameMunchiesReporting owner;
  final String id;
  final Map<String, dynamic> _context;
  final _submissions = <String, Future<void>>{};

  void attachLoad(String loadId) => _context['loadAttemptId'] = loadId;

  Future<void> emit(String type, {String? reason}) => _submissions.putIfAbsent(
    type,
    () {
      final at = owner.now().toUtc().toIso8601String();
      final context = {..._context, 'reason': ?reason};
      return owner._submit(
        (client) =>
            client.trackAdEvent(type, context, id: '$id:$type', occurredAt: at),
        // A real interstitial impression maintains cooldown even after opt-out.
        rulesOnly: type == 'ad_impression',
      );
    },
  );
}
