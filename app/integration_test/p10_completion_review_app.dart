// Disposable native UI evidence. Never imported by normal main/Bootstrap.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite/sqflite.dart';

import 'support/b05_support.dart' show b05Library, b05Seed, b05Finish;

Future<void> main() => runP10Review();

Future<void> runP10Review({
  String expectedDatabase = 'p10_completion_review.sqlite',
  String initialCase = 'main12',
  Widget Function(GameController)? reviewApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  if (!{
        'p10_completion_review.sqlite',
        'p10_compact_review.sqlite',
      }.contains(expectedDatabase) ||
      !kDebugMode ||
      database != expectedDatabase ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled') {
    throw StateError('Dedicated P10 review only');
  }
  final directory = await getDatabasesPath();
  final command = File('$directory/p10-review-command.txt');
  final library = await b05Library();
  GameController? active;
  GameStore? opened;
  var currentCase = '', loading = false;
  const cases = {
    'main4',
    'main12',
    'chapter20',
    'final60',
    'replay12',
    'daily',
  };
  Future<void> load(String name) async {
    if (loading || !cases.contains(name) || currentCase == name) return;
    loading = true;
    runApp(const SizedBox.shrink());
    await WidgetsBinding.instance.endOfFrame;
    active?.dispose();
    await opened?.close();
    final path = '$directory/$database';
    await deleteDatabase(path); // Only this explicitly named disposable DB.
    final store = await GameStore.open(path);
    opened = store;
    final level = name == 'daily'
        ? 12
        : int.parse(name.replaceAll(RegExp('[^0-9]'), ''));
    await b05Seed(store, library, name == 'replay12' ? level : level - 1);
    GameInstance completed;
    if (name == 'daily') {
      final preparer = GameController(store, library: library);
      await preparer.initialize();
      await preparer.startToday();
      if (preparer.current?.slot != 'daily') {
        throw StateError('No actual daily definition');
      }
      completed = b05Finish(preparer.current!);
      preparer.dispose();
    } else {
      completed = b05Finish(
        GameInstance.create(
          id: 'p10-review-$name',
          puzzle: library.main[level]!,
          isReplay: name == 'replay12',
        ),
      );
    }
    await store.settle(completed, replace: true);
    final c = GameController(store, library: library);
    active = c;
    await c.initialize();
    await c.resumeSlot(completed.slot);
    currentCase = name;
    await File('$directory/p10-review-state.json').writeAsString(
      jsonEncode({
        'case': name,
        'instance': c.current!.toJson(),
        'page': c.page.name,
        'completed_levels': c.progress.completedLevels.toList(),
        'piece': c.receipt?.piece,
        'first_clear': c.receipt?.firstClear,
        'source':
            'actual bundled definitions + actual SQLite settle in isolated QA',
      }),
      flush: true,
    );
    runApp(
      reviewApp?.call(c) ?? PourluneApp(key: ValueKey(name), controller: c),
    );
    loading = false;
  }

  await load(initialCase);
  Timer.periodic(const Duration(milliseconds: 250), (_) async {
    if (!loading && await command.exists()) {
      final value = (await command.readAsString()).trim();
      if (cases.contains(value)) await load(value);
    }
  });
}
