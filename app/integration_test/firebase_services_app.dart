// Standalone development diagnostic. Runs the real main/Bootstrap and formal
// content, without a test runner, seed, or shipping UI controls.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as product;
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:pourlune_dev/services/telemetry.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  if (!kDebugMode ||
      const String.fromEnvironment('POURLUNE_FIREBASE_ENV') != 'dev' ||
      const String.fromEnvironment('POURLUNE_DATABASE') !=
          'firebase_dev_native.sqlite' ||
      const String.fromEnvironment('POURLUNE_SCENARIO').isNotEmpty) {
    throw StateError('Development diagnostic selection required');
  }
  product.main();
  GameController? controller;
  void locate(Element element) {
    if (element.widget case final product.PourluneApp app) {
      controller = app.controller;
    }
    element.visitChildElements(locate);
  }

  for (var n = 0; n < 300 && controller == null; n++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    WidgetsBinding.instance.rootElement?.visitChildElements(locate);
  }
  final c = controller;
  if (c == null) throw StateError('Real Bootstrap did not mount');
  final hub = c.services!;
  final out = Directory('${await getDatabasesPath()}/firebase-evidence');
  await out.create(recursive: true);
  Future<void> write(String name, Object value) =>
      File('${out.path}/$name.json')
          .writeAsString(jsonEncode(value), flush: true);
  Future<Map<String, Object?>> state() async {
    final app = Firebase.apps.isEmpty ? null : Firebase.app();
    final saved = (await c.store.load(c.current?.slot ?? 'ordinary')).instance;
    return {
      'utc': DateTime.now().toUtc().toIso8601String(),
      'pid': pid,
      'platform': Platform.operatingSystem,
      'firebase_status': hub.firebaseStatus,
      'firebase_ready': hub.firebaseReady,
      'project_id': app?.options.projectId,
      'app_id': app?.options.appId,
      'choices': hub.choices.toJson(),
      'privacy_sync_failed': hub.privacySyncFailed,
      'automatic_crash_collection': app == null
          ? null
          : FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled,
      'remote_policy': hub.policy.toRaw(),
      'events': await c.store.db.query('service_events'),
      'page': c.page.name,
      'instance_id': c.current?.id,
      'revision': c.current?.revision,
      'saved_instance_id': saved?.id,
      'saved_revision': saved?.revision,
      'save_phase': c.phase.name,
    };
  }

  await write('ready', await state());
  var busy = false;
  Timer.periodic(const Duration(milliseconds: 100), (_) async {
    final file = File('${out.path}/command.json');
    if (busy || !file.existsSync()) return;
    busy = true;
    String id = 'invalid';
    try {
      final command = jsonDecode(await file.readAsString()) as Map;
      await file.delete();
      id = command['id'] as String;
      if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(id)) {
        throw StateError('Invalid diagnostic ID');
      }
      final action = command['action'];
      if (action == 'privacy') {
        await hub.updatePrivacy(
          PrivacyChoices(
            analytics: command['analytics'] == true,
            crash: command['crash'] == true,
          ),
        );
      } else if (action == 'start') {
        await c.startLevel(1, replace: true);
      } else if (action == 'move') {
        final move = c.current!.puzzle.referenceMoves.first;
        await c.pour(move.from, move.to);
      } else if (action == 'undo') {
        await c.undo();
      } else if (action == 'event') {
        // Same actual identity twice must claim one SQLite event.
        for (var n = 0; n < 2; n++) {
          await hub.telemetry.log(ProductEvent.hintResult, id, {
            'instance_id': id,
            'result': 'found',
          });
        }
      } else if (action == 'nonfatal') {
        await hub.recordError('service', StackTrace.current);
      } else if (action == 'crash') {
        await write(id, {'before_native_crash': true, ...await state()});
        FirebaseCrashlytics.instance.crash();
        return;
      } else if (action == 'pending') {
        await write(id, {
          'unsent_reports': await FirebaseCrashlytics.instance
              .checkForUnsentReports(),
          ...await state(),
        });
        return;
      } else if (action == 'remote') {
        // QA-only forced fetch. Product gateway still has its normal 12h
        // setting; activated values flow through its unchanged strict parser.
        final rc = FirebaseRemoteConfig.instance;
        await rc.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 5),
            minimumFetchInterval: Duration.zero,
          ),
        );
        await rc.fetchAndActivate();
        final raw = {
          for (final key in hub.policy.toRaw().keys)
            key: {
              'value': rc.getValue(key).asString(),
              'source': rc.getValue(key).source.name,
            },
        };
        await hub.fetchRemote();
        await write(id, {
          'activated': raw,
          'fetch_status': rc.lastFetchStatus.name,
          ...await state(),
        });
        return;
      } else if (action == 'resume') {
        c.resume();
      } else if (action != 'state') {
        throw StateError('Unknown diagnostic action');
      }
      await write(id, {'ok': true, ...await state()});
    } catch (_) {
      // Never serialize native exceptions or configuration into diagnostics.
      await write(id, {
        'ok': false,
        'category': 'diagnostic_failed',
        ...await state(),
      });
    } finally {
      busy = false;
    }
  });
}
