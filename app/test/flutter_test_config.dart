import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout checks use the same bundled typeface as the app, rather than Ahem's
/// square test glyphs. Tests may still choose their own font explicitly.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await (FontLoader(
    'Nunito',
  )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  await testMain();
}
