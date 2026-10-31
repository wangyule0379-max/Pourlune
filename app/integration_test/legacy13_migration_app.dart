// Explicit synthetic compatibility QA; normal production main never imports it.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pourlune_dev/main.dart' as normal;
import 'package:sqflite/sqflite.dart';

import 'fixtures/legacy13_fixture.dart';

Future<void> main() async {
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  const adMode = String.fromEnvironment('POURLUNE_AD_MODE');
  const firebase = bool.fromEnvironment('POURLUNE_FIREBASE_NATIVE_READY');
  const gm = String.fromEnvironment('POURLUNE_GAMEMUNCHIES_ENVIRONMENT');
  const scenario = String.fromEnvironment('POURLUNE_SCENARIO');
  if (!kDebugMode ||
      !Platform.isAndroid ||
      database != 'legacy13_compat_20261029.sqlite' ||
      adMode != 'disabled' ||
      firebase ||
      gm.isNotEmpty ||
      scenario.isNotEmpty) {
    throw StateError('Requires isolated Android debug compatibility selection');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final file = File('${await getDatabasesPath()}/$database');
  if (!file.existsSync()) {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(legacy13FixtureBytes(), flush: true);
  }
  // Existing QA progress is retained on every subsequent launcher restart.
  normal.main();
}
