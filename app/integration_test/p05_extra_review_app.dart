// Isolated UI evidence only. No real ad, UMP, Firebase or production database.
// The normal main/Bootstrap never imports this entry point.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/flame_board/board.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/services/ad_consent.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite/sqflite.dart';

class _QaTransport implements AdTransport {
  bool available = false;
  @override
  Future<AdHandle> load(AdKind kind) async {
    if (!available) throw const AdLoadFailure('no_fill');
    return _QaHandle();
  }
}

class _QaHandle implements AdHandle {
  @override
  Future<void> show(AdCallbacks callbacks) async {
    callbacks.shown();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    callbacks.reward();
    callbacks.closed();
  }

  @override
  Future<void> dispose() async {}
}

class _QaConsent implements ConsentGateway {
  _QaConsent(this.transport);
  final _QaTransport transport;
  @override
  Future<AdConsent> request() async {
    transport.available = true;
    return const AdConsent(allowed: true, optionsRequired: false);
  }

  @override
  Future<AdConsent> options() => request();
  @override
  Future<void> initializeAds() async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const name = String.fromEnvironment('POURLUNE_DATABASE');
  if (!kDebugMode ||
      name != 'p05_extra_review.sqlite' ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled') {
    throw StateError('Dedicated P05 extra-bottle QA only');
  }
  final path = '${await getDatabasesPath()}/$name';
  await deleteDatabase(path); // Only this named disposable QA database.
  final store = await GameStore.open(path);
  final puzzle = Puzzle.parse(
    await rootBundle.loadString('assets/puzzles/main/main-012.json'),
  );
  const stage = String.fromEnvironment('POURLUNE_QA_STAGE');
  if (stage != '' && stage != 'neutral') {
    throw StateError('Unknown isolated QA stage');
  }
  var initial = GameInstance.create(id: 'p05-extra-c3', puzzle: puzzle);
  if (stage == 'neutral') {
    for (final move in puzzle.referenceMoves) {
      initial = initial.pour(move.from, move.to).state;
      if (List.generate(
        puzzle.targets.length,
        (i) => puzzle.targets[i] != null && initial.board[i].isEmpty,
      ).any((v) => v)) {
        break;
      }
    }
    if (initial.completed ||
        !List.generate(
          puzzle.targets.length,
          (i) => puzzle.targets[i] != null && initial.board[i].isEmpty,
        ).any((v) => v)) {
      throw StateError(
        'Neutral QA requires a real reference prefix with an empty fixed target',
      );
    }
  }
  await store.save(initial, replace: true);
  await File('${File(path).parent.path}/p05-initial-state.json').writeAsString(
    jsonEncode({
      'stage': stage,
      'normal_main': false,
      'source': 'actual bundled reference moves',
      'instance': initial.toJson(),
    }),
  );
  final transport = _QaTransport();
  final hub = ServiceHub(
    store: store,
    config: ServiceConfig(
      adMode: 'test',
      interstitialId: ServiceConfig.testInterstitialId,
      rewardedId: ServiceConfig.testRewardedId,
    ),
    transport: transport,
    consent: _QaConsent(transport),
    knownPuzzleIds: {puzzle.id},
  );
  await hub.initializeLocal();
  hub.ads.update(consent: true);
  await hub.ads.preload(AdKind.rewarded);
  final controller = GameController(
    store,
    library: ContentLibrary(main: {12: puzzle}),
    services: hub,
  );
  await controller.initialize();
  await controller.resumeSlot('ordinary');
  runApp(PourluneApp(controller: controller));
  var previous = '', writing = false;
  // Record actual bounded native layout for the flight review, not a guessed
  // unbounded fixture. No controller, geometry or presentation state is changed.
  Timer.periodic(const Duration(seconds: 1), (_) async {
    if (writing) return;
    Element? boardElement;
    FlameBoardGame? game;
    void visit(Element element) {
      if (element.widget is FlameBoard) boardElement = element;
      final widget = element.widget;
      if (widget is GameWidget<FlameBoardGame>) game = widget.game;
      element.visitChildElements(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildElements(visit);
    final element = boardElement, activeGame = game;
    if (element == null ||
        activeGame?.artStatus.value != BoardArtStatus.ready) {
      return;
    }
    final render = element.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final layout = activeGame!.frame.layout;
    final scaled14 = MediaQuery.textScalerOf(element).scale(14);
    final signature = '${layout.count}-$scaled14-${render.size}';
    if (signature == previous) return;
    writing = true;
    final origin = render.localToGlobal(Offset.zero);
    List<double> rect(Rect r) => [r.left, r.top, r.width, r.height];
    final payload = {
      'qa_entry': true,
      'instance': controller.current?.id,
      'revision': controller.current?.revision,
      'count': layout.count,
      'native_viewport': [
        MediaQuery.sizeOf(element).width,
        MediaQuery.sizeOf(element).height,
      ],
      'native_pixel_ratio': MediaQuery.devicePixelRatioOf(element),
      'scaled_14': scaled14,
      'bounded_board': [render.size.width, render.size.height],
      'board_global_origin': [origin.dx, origin.dy],
      'layout_height': layout.height,
      'bottle_width': layout.shape.width,
      'bottle_height': layout.shape.height,
      'mouths': [
        for (final p in layout.mouths) [p.dx, p.dy],
      ],
      'cells': [for (final r in layout.cells) rect(r)],
      'labels': [
        for (var i = 0; i < layout.count; i++) rect(layout.labelRect(i)),
      ],
    };
    final output = File(
      '${File(path).parent.path}/p05-layout-${layout.count}-${scaled14.toStringAsFixed(2)}.json',
    );
    await File('${output.path}.tmp')
        .writeAsString(jsonEncode(payload), flush: true);
    await File('${output.path}.tmp').rename(output.path);
    previous = signature;
    writing = false;
  });
}
