// Opt-in host fixture generation; never runs in ordinary tests or normal main.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/support/b05_support.dart' show b05Finish, b05Seed;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'prepare isolated manual-function databases from actual bundled puzzles',
    () async {
      sqfliteFfiInit();
      const interstitialOnly = bool.fromEnvironment(
        'POURLUNE_GENERATE_INTERSTITIAL_FIXTURE',
      );
      final output = Directory(
        interstitialOnly
            ? '../build/manual-functional-20261028/interstitial-r1'
            : '../build/manual-functional-20261028/fixtures-r2',
      ).absolute;
      if (output.existsSync()) {
        throw StateError('Preserve frozen fixtures; choose a new output');
      }
      output.createSync(recursive: true);
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
        daily: DailyCatalog.parse(
          File('assets/catalog/daily.json').readAsStringSync(),
          definitions,
        ),
      );
      expect(library.main.length, 60);
      final receipts = <Map<String, Object?>>[];
      for (final name
          in interstitialOnly
              ? ['main021-last']
              : [
                  'fresh',
                  'main004-last',
                  'main020-last',
                  'main060-last',
                  'replay004-last',
                  'daily-today-last',
                  'daily-yesterday',
                ]) {
        final store = await GameStore.open(
          '${output.path}/$name.sqlite',
          factory: databaseFactoryFfi,
        );
        try {
          final level = name.contains('021')
              ? 21
              : name.contains('020')
              ? 20
              : name.contains('060')
              ? 60
              : 4;
          GameInstance? ordinary, daily;
          if (name != 'fresh') {
            await store.save(
              GameInstance.create(
                id: 'function-lesson',
                puzzle: library.main[1]!,
                tutorial: true,
              ).skipTutorial(),
            );
            await b05Seed(
              store,
              library,
              name.startsWith('replay') ? 4 : level - 1,
            );
            ordinary = GameInstance.create(
              id: 'function-$name',
              puzzle: library.main[level]!,
              isReplay: name.startsWith('replay'),
            );
            ordinary = b05Finish(
              ordinary,
              take: name.contains('daily')
                  ? 1
                  : ordinary.puzzle.referenceMoves.length - 1,
            );
            expect(ordinary.completed, isFalse);
            await store.save(ordinary, replace: true);
            if (name.startsWith('daily')) {
              final date = name == 'daily-yesterday'
                  ? '2026-10-27'
                  : '2026-10-28';
              final puzzle = library.daily!.forDate(date);
              daily = GameInstance.create(
                id: 'function-$name-daily',
                puzzle: puzzle,
                slot: 'daily',
                puzzleDate: date,
                timeZone: 'Asia/Taipei',
                offsetMinutes: 480,
                catalogVersion: library.daily!.version,
              );
              daily = b05Finish(
                daily,
                take: name == 'daily-yesterday'
                    ? 1
                    : puzzle.referenceMoves.length - 1,
              );
              expect(daily.completed, isFalse);
              await store.save(daily);
            }
          }
          expect((await store.load('ordinary')).instance?.id, ordinary?.id);
          expect((await store.load('daily')).instance?.id, daily?.id);
          final target = daily ?? ordinary;
          final last = target == null || name == 'daily-yesterday'
              ? null
              : target.puzzle.referenceMoves.last;
          if (last != null) {
            expect(target!.pour(last.from, last.to).state.completed, isTrue);
          }
          receipts.add({
            'name': name,
            'filename': '$name.sqlite',
            'prepared_progress': true,
            'ordinary_puzzle': ordinary?.puzzle.id,
            'daily_puzzle': daily?.puzzle.id,
            'daily_date': daily?.puzzleDate,
            'first_clears': (await store.progress()).firstClears,
            'last_move_from_1_based': last == null ? null : last.from + 1,
            'last_move_to_1_based': last == null ? null : last.to + 1,
            'gm_enabled': false,
            'fault_injection': false,
          });
        } finally {
          await store.close();
        }
      }
      await File('${output.path}/manifest.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'client_date': '2026-10-28',
          'target_identity': 'dev.pourlune.functionValidation',
          'target_database': 'function_validation_20261028.sqlite',
          'fixtures': receipts,
          'warning': 'Prepared real-puzzle/store states; not natural campaign play or manual acceptance.',
        }),
      );
    },
    skip: !const bool.fromEnvironment('POURLUNE_GENERATE_FUNCTION_FIXTURES'),
  );
}
