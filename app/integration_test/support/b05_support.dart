// B05-only utilities. Formal bundled content; controlled ad transport is explicit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/services/ad_coordinator.dart';

Future<ContentLibrary> b05Library() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final definitions = parsePuzzleDefinitions([
    for (final path in manifest.listAssets().where(
      (p) => p.startsWith('assets/puzzles/') && p.endsWith('.json'),
    ))
      await rootBundle.loadString(path),
  ]);
  return ContentLibrary(
    main: {
      for (final p in definitions.values.where((p) => p.mode == 'main'))
        p.mainLevel!: p,
    },
    daily: DailyCatalog.parse(
      await rootBundle.loadString('assets/catalog/daily.json'),
      definitions,
    ),
  );
}

GameInstance b05Finish(GameInstance s, {int? take}) {
  for (final m in s.puzzle.referenceMoves.take(
    take ?? s.puzzle.referenceMoves.length,
  )) {
    final r = s.pour(m.from, m.to);
    if (!r.changed) throw StateError('Invalid QA reference ${s.puzzle.id}');
    s = r.state;
  }
  return s;
}

Future<void> b05Seed(
  GameStore store,
  ContentLibrary library,
  int through,
) async {
  for (var n = 1; n <= through; n++) {
    await store.settle(
      b05Finish(
        GameInstance.create(id: 'b05-qa-seed-$n', puzzle: library.main[n]!),
      ),
      replace: true,
    );
  }
  for (final piece in (await store.progress()).pieces) {
    await store.markRevealed(piece);
  }
}

Future<void> b05Json(String path, Object value) => File(path).writeAsString(
  '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  flush: true,
);

Future<void> b05Capture(GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  image.dispose();
}

class B05Handle implements AdHandle {
  AdCallbacks? route;
  int shows = 0;
  @override
  Future<void> show(AdCallbacks callbacks) async {
    shows++;
    route = callbacks;
  }

  @override
  Future<void> dispose() async {}
}

class B05Transport implements AdTransport {
  final loads = <({AdKind kind, Completer<AdHandle> result})>[];
  @override
  Future<AdHandle> load(AdKind kind) {
    final result = Completer<AdHandle>();
    loads.add((kind: kind, result: result));
    return result.future;
  }

  Future<B05Handle> ready(AdCoordinator ads, AdKind kind) async {
    final loading = ads.preload(kind);
    final handle = B05Handle();
    loads.lastWhere((e) => e.kind == kind).result.complete(handle);
    await loading;
    return handle;
  }
}
