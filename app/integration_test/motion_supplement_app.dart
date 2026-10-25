// New isolated QA identity + exact DB. Calls normal product main/Bootstrap;
// observes widget/frame readiness and delivers one actual Flutter pointer tap.
// No screenshots, screen recording, audio recording or product delay.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/main.dart' as product;
import 'package:pourlune_dev/presentation/startup_view.dart';
import 'package:sqflite/sqflite.dart';

void require(bool ok, String message) {
  if (!ok) throw StateError(message);
}

Future<void> main() async {
  final watch = Stopwatch()..start();
  final dartBeganUtc = DateTime.now().toUtc().toIso8601String();
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  if (!kDebugMode ||
      database != 'motion_supplement.sqlite' ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled' ||
      const String.fromEnvironment(
            'POURLUNE_FIREBASE_ENV',
            defaultValue: 'none',
          ) !=
          'none' ||
      const String.fromEnvironment('POURLUNE_SCENARIO').isNotEmpty) {
    throw StateError('Isolated MS startup diagnostic only');
  }
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final tester = LiveWidgetController(binding);
  int? firstFrame, shellFrame, homeFrame;
  GameController? controller;
  Directory? output;
  var gestureDispatched = false;
  int? firstControllerResponse, acceptedAt;
  final acceptedIds = <String>{};
  final changes = <Map<String, Object?>>[];
  final polls = <int>[];
  final start = find.byKey(const Key('sample-main-001'));
  bool rootExists() => binding.rootElement != null;
  void frameProbe(Duration _) {
    firstFrame ??= watch.elapsedMicroseconds;
    if (rootExists()) {
      if (find.byType(StartupView).evaluate().isNotEmpty) {
        shellFrame ??= watch.elapsedMicroseconds;
      }
      if (find.byType(product.PourluneApp).evaluate().isNotEmpty &&
          start.evaluate().isNotEmpty) {
        homeFrame ??= watch.elapsedMicroseconds;
      }
    }
    if (homeFrame == null) {
      binding.addPostFrameCallback(frameProbe);
    }
  }

  binding.addPostFrameCallback(frameProbe);
  final productMainAt = watch.elapsedMicroseconds;
  product.main();

  Future<void> until(bool Function() ready, String reason) async {
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Timeout: $reason');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void changed() {
    if (!gestureDispatched) return;
    firstControllerResponse ??= watch.elapsedMicroseconds;
    final c = controller!;
    if (changes.length < 50) {
      changes.add({
        'us': watch.elapsedMicroseconds,
        'page': c.page.name,
        'phase': c.phase.name,
        'busy': c.busy,
        'instance': c.current?.id,
        'revision': c.current?.revision,
      });
    }
    if (c.page == GamePage.board &&
        c.current != null &&
        c.phase == SavePhase.clean) {
      acceptedAt ??= watch.elapsedMicroseconds;
      acceptedIds.add(c.current!.id);
    }
  }

  bool buttonReady() {
    if (!rootExists()) return false;
    final found = start.evaluate();
    return found.length == 1 &&
        found.single.widget is ButtonStyleButton &&
        (found.single.widget as ButtonStyleButton).onPressed != null &&
        start.hitTestable().evaluate().length == 1;
  }

  try {
    await until(
      () =>
          rootExists() &&
          find.byType(product.PourluneApp).evaluate().length == 1,
      'normal Bootstrap',
    );
    final c = controller = tester
        .widget<product.PourluneApp>(find.byType(product.PourluneApp))
        .controller;
    require(
      !c.library.engineering && c.library.main.length == 60,
      'formal60 library',
    );
    require(c.store.db.path.endsWith('/$database'), 'exact private DB');
    require(
      c.current == null &&
          c.ordinary == null &&
          c.daily == null &&
          c.progress.firstClears == 0 &&
          !c.tutorialComplete,
      'identical fresh welcome preparation',
    );
    final appFoundAt = watch.elapsedMicroseconds;
    final probeStarted = watch.elapsedMicroseconds;
    final readyDeadline = DateTime.now().add(const Duration(seconds: 30));
    while (!buttonReady()) {
      polls.add(watch.elapsedMicroseconds);
      if (DateTime.now().isAfter(readyDeadline)) {
        throw StateError('Home enabled/hitTestable timed out');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    final enabledHitAt = watch.elapsedMicroseconds;
    polls.add(enabledHitAt);
    final context = tester.element(start);
    final query = MediaQuery.of(context);
    final before = {
      'page': c.page.name,
      'phase': c.phase.name,
      'busy': c.busy,
      'ordinary': c.ordinary?.id,
      'daily': c.daily?.id,
      'first_clears': c.progress.firstClears,
      'tutorial_complete': c.tutorialComplete,
      'settings': c.settings.toJson(),
      'firebase_status': c.services?.firebaseStatus,
      'logical_size': [query.size.width, query.size.height],
      'dpr': query.devicePixelRatio,
      'font14_scaled': query.textScaler.scale(14),
      'ancestor_fade_values': find
          .ancestor(of: start, matching: find.byType(FadeTransition))
          .evaluate()
          .map((e) => (e.widget as FadeTransition).opacity.value)
          .toList(),
      'ancestor_opacity': find
          .ancestor(of: start, matching: find.byType(Opacity))
          .evaluate()
          .map((e) => (e.widget as Opacity).opacity)
          .toList(),
    };
    var snapshots = 0;
    c.store.fault = (stage) {
      if (stage == 'snapshot') snapshots++;
    };
    c.addListener(changed);
    gestureDispatched = true;
    final downRequest = watch.elapsedMicroseconds;
    final gesture = await tester.startGesture(tester.getCenter(start));
    final downSent = watch.elapsedMicroseconds;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final upRequest = watch.elapsedMicroseconds;
    await gesture.up();
    final upSent = watch.elapsedMicroseconds;
    await until(
      () => acceptedAt != null,
      'real gesture accepted and committed',
    );
    final saved = (await c.store.load('ordinary')).instance!;
    output = Directory('${await getDatabasesPath()}/motion-supplement')
      ..createSync(recursive: true);
    require(
      acceptedIds.length == 1 && snapshots == 1,
      'one gesture, one instance/snapshot',
    );
    require(
      c.current!.puzzle.id == 'main-001' &&
          c.current!.moveCount == 0 &&
          c.current!.revision == 0,
      'normal Start accepted',
    );
    require(
      saved.id == c.current!.id &&
          jsonEncode(saved.toJson()) == jsonEncode(c.current!.toJson()),
      'actual native SQLite persisted navigation',
    );
    final accepted = {
      'page': c.page.name,
      'phase': c.phase.name,
      'busy': c.busy,
      'instance': c.current!.id,
      'saved_instance': saved.id,
      'revision': c.current!.revision,
      'moves': c.current!.moveCount,
      'snapshot_writes': snapshots,
      'new_instance_count': acceptedIds.length,
    };
    c.removeListener(changed);
    c.store.fault = null;
    // This exact new QA DB alone is reset AFTER measurement, ready for the next
    // process cold start. Schema/cache remain; no reinstall or global clearing.
    await c.resetProgress();
    await until(
      () =>
          c.page == GamePage.home &&
          c.phase == SavePhase.clean &&
          buttonReady(),
      'private next-launch preparation',
    );
    require(
      c.ordinary == null &&
          c.daily == null &&
          c.progress.firstClears == 0 &&
          !c.tutorialComplete,
      'cleanup only private progress',
    );
    final report = {
      'ok': true,
      'pid': pid,
      'platform': Platform.operatingSystem,
      'mode': 'debug standalone normal product.main, Flutter pointer + native sqflite',
      'database': c.store.db.path,
      'dart_began_utc': dartBeganUtc,
      'clock': 'one Dart Stopwatch at QA Dart entry; includes guard/binding/probe setup; excludes native pre-Dart',
      'product_main_call_us': productMainAt,
      'dart_start_us': 0,
      'app_controller_found_us': appFoundAt,
      'home_probe_started_us': probeStarted,
      'first_flutter_post_frame_us': firstFrame,
      'initialization_shell_first_post_frame_us': shellFrame,
      'home_first_post_frame_us': homeFrame,
      'home_enabled_hit_testable_us': enabledHitAt,
      'pointer_down_request_us': downRequest,
      'pointer_down_sent_us': downSent,
      'pointer_up_request_us': upRequest,
      'pointer_up_sent_us': upSent,
      'first_controller_response_us': firstControllerResponse,
      'first_accepted_committed_navigation_us': acceptedAt,
      'gesture_count': 1,
      'requested_hold_ms': 16,
      'requested_poll_interval_ms': 5,
      'home_probe_timestamps_us': polls,
      'controller_changes': changes,
      'before_gesture': before,
      'accepted': accepted,
      'prepared_for_next_launch': true,
      'excludes_native_pre_dart': true,
      'theoretical_earliest_interactive_claim': false,
      'captures_screen_or_audio': false,
    };
    final temporary = File('${output.path}/startup-$pid.tmp');
    await temporary.writeAsString(jsonEncode(report), flush: true);
    await temporary.rename('${output.path}/startup-$pid.json');
  } catch (error, stack) {
    controller?.removeListener(changed);
    controller?.store.fault = null;
    final out =
        output ?? Directory('${await getDatabasesPath()}/motion-supplement')
          ..createSync(recursive: true);
    await File('${out.path}/error-$pid.json').writeAsString(
      jsonEncode({
        'ok': false,
        'pid': pid,
        'error': error.toString(),
        'stack': stack.toString(),
        'first_frame_us': firstFrame,
        'shell_frame_us': shellFrame,
        'home_frame_us': homeFrame,
        'controller_changes': changes,
      }),
      flush: true,
    );
  }
}
