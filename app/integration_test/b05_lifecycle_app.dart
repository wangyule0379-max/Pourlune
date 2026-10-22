// Test-only standalone entrypoint; no test runner, no shipping hooks.
// Host simctl terminate/launch retains this installation and b05_lifecycle.sqlite.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart' show PourluneApp;
import 'package:pourlune_dev/presentation/scene_art.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startup = Stopwatch()..start();
  final base = await getDatabasesPath();
  final out = Directory('$base/b05-lifecycle-evidence');
  await out.create(recursive: true);
  final library = await b05Library();
  const filename = 'b05_lifecycle.sqlite';
  GameStore? store;
  GameController? c;
  ServiceHub? hub;
  final root = GlobalKey();
  final frames = <Map<String, int>>[];
  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final frame in timings) {
      frames.add({
        'build_us': frame.buildDuration.inMicroseconds,
        'raster_us': frame.rasterDuration.inMicroseconds,
        'total_us': frame.totalSpan.inMicroseconds,
      });
    }
  });
  Future<void> mount({bool reset = false, int? level}) async {
    if (c != null) {
      c!.dispose();
      hub!.dispose();
      await store!.close();
    }
    if (reset) await deleteDatabase('$base/$filename');
    final s = store = await GameStore.open('$base/$filename');
    if (level != null) {
      await b05Seed(s, library, level - 1);
      final puzzle = library.daily!.forDate('2026-10-21');
      final first = puzzle.referenceMoves.first;
      final daily = GameInstance.create(
        id: 'b05-qa-daily',
        puzzle: puzzle,
        slot: 'daily',
        puzzleDate: '2026-10-21',
        timeZone: 'Asia/Taipei',
        offsetMinutes: 480,
        catalogVersion: library.daily!.version,
      ).pour(first.from, first.to).state;
      await s.save(daily);
    }
    final services = hub = ServiceHub(
      store: s,
      config: const ServiceConfig(),
      knownPuzzleIds: {},
    );
    await services.initializeLocal();
    final controller = c = GameController(
      s,
      library: library,
      services: services,
    );
    await controller.initialize();
    if (level != null) {
      await controller.startLevel(level);
    } else {
      controller.resume();
    }
    runApp(
      RepaintBoundary(
        key: root,
        child: PourluneApp(key: ObjectKey(controller), controller: controller),
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  List<SceneArt> renderedScenes() {
    final scenes = <SceneArt>[];
    void visit(Element e) {
      if (e.widget case final SceneArt art) scenes.add(art);
      e.visitChildElements(visit);
    }

    if (root.currentContext case final Element e) visit(e);
    return scenes;
  }

  double? revealOpacity() {
    Element? layer;
    void locate(Element e) {
      if (e.widget.key == const Key('scene-color_studio-piece-3')) layer = e;
      e.visitChildElements(locate);
    }

    if (root.currentContext case final Element e) locate(e);
    double? value;
    void opacity(Element e) {
      if (e.widget case final Opacity o) value ??= o.opacity;
      e.visitChildElements(opacity);
    }

    layer?.visitChildElements(opacity);
    return value;
  }

  Future<int> presentReveal() async {
    await c!.viewPatch();
    await WidgetsBinding.instance.endOfFrame;
    // Explicit QA warm-up: decode the actual ResizeImage providers before the
    // interruption run. This is not a cold-asset loading performance sample.
    final images = <Element>[];
    void collectImages(Element e) {
      if (e.widget is Image) {
        images.add(e);
      }
      e.visitChildElements(collectImages);
    }

    void collectScenes(Element e) {
      if (e.widget is SceneArt) {
        e.visitChildElements(collectImages);
      } else {
        e.visitChildElements(collectScenes);
      }
    }

    collectScenes(root.currentContext! as Element);
    for (final element in images) {
      Object? error;
      await precacheImage(
        (element.widget as Image).image,
        element,
        onError: (e, stack) => error = e,
      );
      if (error != null) {
        throw StateError('Scene decode failed: $error');
      }
    }
    await c!.navigate(GamePage.completion);
    await WidgetsBinding.instance.endOfFrame;
    await c!.viewPatch();
    await WidgetsBinding.instance.endOfFrame;
    for (var n = 0; n < 30 && (revealOpacity() ?? 0) <= 0; n++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final value = revealOpacity();
    if (value == null || value <= 0 || value >= .95) {
      throw StateError('QA did not observe an active SceneArt reveal: $value');
    }
    await b05Capture(root, '${out.path}/reveal-mid.png');
    return images.length;
  }

  Future<Map<String, Object?>> state() async {
    final p = await store!.progress();
    return {
      'pid': pid,
      'database': '$base/$filename',
      'mode': 'Simulator debug diagnostic',
      'current': c!.current?.toJson(),
      'phase': c!.phase.name,
      'page': c!.page.name,
      'motion': c!.motion != null,
      'busy': c!.busy,
      'first': p.firstClears,
      'pieces': p.pieces,
      'revealed': p.revealedPieces,
      'counter': p.qualifyingClears,
      'receipts': p.receipts,
      'daily': (await store!.load('daily')).instance?.toJson(),
      'rewards': await store!.db.query('reward_attempts'),
      'entitlements': await store!.db.query('reward_entitlements'),
      'rss_bytes': ProcessInfo.currentRss,
      'peak_rss_bytes': ProcessInfo.maxRss,
      'frame_count': frames.length,
      'rendered_scenes': [for (final art in renderedScenes()) art.scene],
      'rendered_reveals': [
        for (final art in renderedScenes())
          if (art.reveal != null) {'scene': art.scene, 'piece': art.reveal},
      ],
    };
  }

  Future<void> ready() async {
    for (var n = 0; n < 1000 && c!.busy; n++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (c!.busy) throw StateError('QA operation did not finish');
  }

  void barrier(String stage) {
    File(
      '${out.path}/barrier.json',
    ).writeAsStringSync(jsonEncode({'stage': stage, 'pid': pid}), flush: true);
    sleep(
      const Duration(seconds: 30),
    ); // Host terminates this actual process while SQL transaction is open.
    throw StateError('B05 barrier not terminated by host');
  }

  await mount();
  await b05Json('${out.path}/ready.json', {
    'startup_to_first_frame_ms': startup.elapsedMilliseconds,
    ...await state(),
  });
  var running = false;
  Timer.periodic(const Duration(milliseconds: 50), (_) async {
    final file = File('${out.path}/command.json');
    if (running || !file.existsSync()) return;
    running = true;
    String? id;
    try {
      final command =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await file.delete();
      id = command['id'] as String;
      final action = command['action'];
      if (action == 'prepare12' ||
          action == 'prepare11' ||
          action == 'prepare-reward') {
        final level = action == 'prepare12'
            ? 12
            : action == 'prepare11'
            ? 11
            : 13;
        await mount(reset: true, level: level);
        if (level == 12) {
          for (final m in c!.current!.puzzle.referenceMoves.take(
            c!.current!.puzzle.referenceMoves.length - 1,
          )) {
            await c!.pour(m.from, m.to);
            await ready();
          }
        }
        if (level == 13) {
          await store!.beginReward('b05-controlled-earned', c!.current!);
        }
      } else if (action == 'finish') {
        final stage = command['stage'] as String;
        var decoded = 0;
        if (stage == 'before') barrier(stage);
        if (!{'after', 'reveal'}.contains(stage)) {
          store!.fault = (s) {
            if (s == stage) barrier(stage);
          };
        }
        final last = c!.current!.puzzle.referenceMoves.last;
        await c!.pour(last.from, last.to);
        store!.fault = null;
        if (stage == 'reveal') {
          await ready();
          decoded = await presentReveal();
        }
        final snapshot = await state();
        if (stage == 'reveal') {
          final value = revealOpacity();
          if (value == null || value <= 0 || value >= .95) {
            throw StateError('Reveal finished before kill barrier: $value');
          }
          snapshot['reveal_opacity'] = value;
          snapshot['scene_images_decoded'] = decoded;
          snapshot['reveal_sampled_ms'] = DateTime.now().millisecondsSinceEpoch;
        }
        await b05Json('${out.path}/barrier.json', {
          'stage': stage,
          ...snapshot,
        });
      } else if (action == 'reveal-restored') {
        await presentReveal();
      } else if (action == 'acknowledge-reveal') {
        await c!.acknowledgeReveal();
      } else if (action == 'visit-collection') {
        await c!.navigate(GamePage.collection);
        await WidgetsBinding.instance.endOfFrame;
        await c!.navigate(GamePage.scene, scene: 'color_studio');
      } else if (action == 'pour-animation') {
        final move = c!.current!.puzzle.referenceMoves.first;
        await c!.pour(move.from, move.to);
        await b05Json('${out.path}/barrier.json', {
          'stage': 'animation',
          ...await state(),
        });
      } else if (action == 'finish-restored') {
        final last = c!.current!.puzzle.referenceMoves.last;
        await c!.pour(last.from, last.to);
        await ready();
      } else if (action == 'reward-pending') {
        await c!.startLevel(3, replace: true);
        await ready();
        await store!.confirmReward('b05-controlled-earned');
      } else if (action == 'reward-uncommitted') {
        store!.fault = (s) {
          if (s == 'reward_grant') barrier(s);
        };
        await store!.confirmReward('b05-controlled-earned');
      } else if (action == 'restore-reward') {
        final reward = (await store!.pendingRewards()).single;
        await c!.resumeRewardedPuzzle(
          reward.id,
          replacingInstance: c!.ordinary?.id,
        );
      } else if (action == 'undo') {
        await c!.undo();
        await ready();
      } else if (action == 'diagnose') {
        final rssBefore = ProcessInfo.currentRss;
        final hintCancel = <int>[];
        final begin = frames.length;
        for (var i = 0; i < 10; i++) {
          final move = c!.current!.puzzle.referenceMoves.first;
          await c!.pour(move.from, move.to);
          await ready();
          await c!.undo();
          await ready();
          final watch = Stopwatch()..start();
          final hint = c!.requestHint();
          c!.cancelHint();
          await hint;
          hintCancel.add(watch.elapsedMicroseconds);
        }
        await b05Json('${out.path}/diagnostics.json', {
          'scope': 'iOS Simulator debug, no mobile threshold pass; controlled formal11 repeated first move/undo',
          'hint_cancel_us': hintCancel,
          'frames': frames.skip(begin).toList(),
          'rss_before': rssBefore,
          'rss_after': ProcessInfo.currentRss,
          'peak_rss': ProcessInfo.maxRss,
          'old_hint_applied': c!.hint != null,
        });
      } else if (action != 'inspect') {
        throw ArgumentError.value(action);
      }
      await WidgetsBinding.instance.endOfFrame;
      await b05Capture(root, '${out.path}/latest.png');
      final snapshot = await state();
      if (action == 'reveal-restored') {
        snapshot['reveal_opacity'] = revealOpacity();
      }
      await b05Json('${out.path}/result.json', {
        'id': id,
        'action': action,
        ...snapshot,
      });
    } catch (error, stack) {
      await b05Json('${out.path}/result.json', {
        'id': id,
        'error': '$error',
        'stack': '$stack',
      });
    } finally {
      running = false;
    }
  });
}
