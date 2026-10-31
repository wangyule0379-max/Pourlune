// Explicit host-only QA preparation, not discovered by ordinary flutter test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../integration_test/support/b05_support.dart' show b05Seed;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('prepare only new isolated real-puzzle pour fixtures', () async {
    if (!const bool.fromEnvironment('POURLUNE_PREPARE_POUR_FIXTURES')) {
      throw StateError('Explicit fixture preparation flag required');
    }
    final out = Directory('../build/pour-flight-fix-20261028/native-fixtures-1')
        .absolute;
    if (out.existsSync()) throw StateError('Never overwrite prepared QA data');
    out.createSync(recursive: true);
    sqfliteFfiInit();
    final definitions = parsePuzzleDefinitions([
      for (final file in Directory(
        'assets/puzzles',
      ).listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.json')) file.readAsStringSync(),
    ]);
    final library = ContentLibrary(
      main: {
        for (final p in definitions.values.where((p) => p.mode == 'main'))
          p.mainLevel!: p,
      },
    );
    final receipts = <Map<String, Object?>>[];
    for (final c in [(4, 4), (5, 6), (6, 11), (7, 21), (8, 21)]) {
      var s = GameInstance.create(
        id: 'pour-qa-${c.$1}',
        puzzle: library.main[c.$2]!,
      );
      if (c.$1 == 8) s = s.grantExtraBottle();
      late (int, int) route;
      if (c.$1 == 4) {
        for (final m in [
          (0, 2),
          (1, 2),
          (1, 0),
          (1, 2),
          (0, 1),
          (1, 3),
          (2, 1),
          (0, 2),
        ]) {
          final moved = s.pour(m.$1, m.$2);
          expect(moved.changed, isTrue);
          s = moved.state;
        }
        route = (2, 1);
      } else if (c.$1 == 5) {
        route = (1, 3);
      } else {
        final upper = c.$1 == 6 ? 3 : 4;
        for (final m in s.puzzle.referenceMoves) {
          if (m.from >= upper && m.to < upper) {
            route = (m.from, m.to);
            break;
          }
          s = s.pour(m.from, m.to).state;
        }
      }
      expect(s.board.length, c.$1);
      expect(s.pour(route.$1, route.$2).changed, isTrue);
      final file = '${c.$1}-bottles.sqlite';
      final store = await GameStore.open(
        '${out.path}/$file',
        factory: databaseFactoryFfi,
      );
      try {
        await store.save(
          GameInstance.create(
            id: 'pour-qa-lesson-${c.$1}',
            puzzle: library.main[1]!,
            tutorial: true,
          ).skipTutorial(),
        );
        await b05Seed(store, library, c.$2 - 1);
        await store.saveSettings(
          const PlayerSettings(music: false, sound: false, haptics: false),
        );
        await store.save(s, replace: true);
        expect((await store.load('ordinary')).instance!.board, s.board);
      } finally {
        await store.close();
      }
      receipts.add({
        'file': file,
        'bottles': c.$1,
        'level': c.$2,
        'from_1_based': route.$1 + 1,
        'to_1_based': route.$2 + 1,
        'prepared_progress': true,
        'extra_bottle_core_fixture': c.$1 == 8,
      });
    }
    final manifest = const JsonEncoder.withIndent('  ').convert({
      'identity': 'dev.pourlune.pourFlightValidation',
      'database': 'pour_flight_fix_20261028.sqlite',
      'fixtures': receipts,
      'normal_font_scale': 1,
      'firebase': 'none',
      'ads': 'disabled',
      'gm': 'disabled',
      'qa_audio_muted': true,
      'warning': 'Prepared actual definitions/core/store states, not natural campaign or SDK rewards.',
    });
    File('${out.path}/manifest.json').writeAsStringSync('$manifest\n');
  });
}
