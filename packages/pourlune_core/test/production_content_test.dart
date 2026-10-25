import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

GameInstance contentInstance(Puzzle p) => GameInstance.create(
  id: 'content-${p.id}',
  puzzle: p,
  slot: p.mode == 'daily' ? 'daily' : 'ordinary',
  puzzleDate: p.mode == 'daily' ? '2026-01-01' : null,
  timeZone: p.mode == 'daily' ? 'UTC' : null,
  offsetMinutes: p.mode == 'daily' ? 0 : null,
  catalogVersion: p.mode == 'daily' ? 1 : null,
);

void main() {
  final directory = Directory('../../app/assets/puzzles');
  final files = directory.existsSync()
      ? (directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];
  test(
    'B03 AC-35 packaged complete 60 main and 30 daily legal reference replays',
    () {
      expect(files, hasLength(90));
      final puzzles = files
          .map((f) => Puzzle.parse(f.readAsStringSync()))
          .toList();
      expect(
        puzzles.where((p) => p.mode == 'main').map((p) => p.mainLevel).toSet(),
        {for (var i = 1; i <= 60; i++) i},
      );
      expect(puzzles.where((p) => p.mode == 'daily'), hasLength(30));
      expect(puzzles.map((p) => p.id).toSet(), hasLength(90));
      for (final p in puzzles) {
        expect(p.contentStatus, 'production_candidate');
        var instance = contentInstance(p);
        for (final move in p.referenceMoves) {
          expect(instance.completed, isFalse, reason: '${p.id} premature win');
          final result = instance.pour(move.from, move.to);
          expect(
            result.changed,
            isTrue,
            reason: '${p.id} illegal reference action',
          );
          expect(result.units, greaterThan(0));
          instance = result.state;
          p.validateBoard(instance.board, extra: false);
        }
        expect(instance.extraBottleGranted, isFalse);
        expect(instance.completed, isTrue, reason: p.id);
        expect(instance.board.length, p.initial.length);
        expect(instance.moveCount, p.referenceMoves.length);
      }
    },
  );

  test('B03 preserved tutorial and original12 history replay identities', () {
    for (final id in ['001', '012']) {
      final fixture = Puzzle.parse(
        File('../../docs/content/fixtures/main-$id.reference.json')
            .readAsStringSync(),
      );
      final candidate = Puzzle.parse(
        File('../../app/assets/puzzles/main/main-$id.json').readAsStringSync(),
      );
      expect(candidate.initial, fixture.initial);
      expect(candidate.targets, fixture.targets);
      expect(
        candidate.referenceMoves.map((m) => m.toJson()).toList(),
        fixture.referenceMoves.map((m) => m.toJson()).toList(),
      );
      expect(candidate.contentVersion, fixture.contentVersion);
    }
  });

  test('B03 production daily cycle and old instance retain independent definitions', () {
    final definitions = {
      for (final file in files)
        Puzzle.parse(file.readAsStringSync()).id: Puzzle.parse(
          file.readAsStringSync(),
        ),
    };
    final source = File('../../app/assets/catalog/daily.json')
        .readAsStringSync();
    final catalog = DailyCatalog.parse(source, definitions);
    for (final entry in {
      '2026-01-01': 'daily-001',
      '2026-01-30': 'daily-030',
      '2026-01-31': 'daily-001',
      '2025-12-31': 'daily-030',
    }.entries) {
      expect(catalog.forDate(entry.key).id, entry.value);
    }
    final original = catalog.forDate('2026-01-01');
    final active = contentInstance(original)
        .pour(
          original.referenceMoves.first.from,
          original.referenceMoves.first.to,
        )
        .state;
    final saved = jsonEncode(active.toJson());
    final replacement = definitions['daily-004']!.toJson()
      ..['puzzle_id'] = 'daily-001'
      ..['content_version'] = 2;
    definitions['daily-001'] = Puzzle.fromJson(replacement);
    final newCatalog = jsonDecode(source) as Map<String, dynamic>
      ..['catalog_version'] = 2;
    final updated = DailyCatalog.parse(jsonEncode(newCatalog), definitions);
    expect(updated.version, 2);
    expect(updated.forDate('2026-01-01').contentVersion, 2);
    expect(updated.forDate('2026-01-01').initial, isNot(original.initial));
    final restored = GameInstance.parse(saved);
    expect(restored.catalogVersion, 1);
    expect(restored.puzzle.contentVersion, 1);
    expect(restored.puzzle.toJson(), original.toJson());
    expect(restored.restart().board, original.initial);
  });

  test('B03 all90 current-state solver initial and midpoint budget measurements', () {
    expect(files, hasLength(90));
    final rows = <Map<String, Object?>>[];
    for (final file in files) {
      final p = Puzzle.parse(file.readAsStringSync());
      var state = contentInstance(p);
      for (final position in ['initial', 'midpoint']) {
        if (position == 'midpoint') {
          for (final move in p.referenceMoves.take(
            p.referenceMoves.length ~/ 2,
          )) {
            state = state.pour(move.from, move.to).state;
          }
        }
        final hint = solveHint(p, state.board);
        rows.add({
          'puzzle_id': p.id,
          'position': position,
          'status': hint.status.name,
          'visited': hint.visited,
          'elapsed_microseconds': hint.elapsed.inMicroseconds,
          'budget_ms': 2000,
          'max_states': 50000,
        });
        expect(hint.status, HintStatus.found, reason: '${p.id} $position');
        final next = state.pour(hint.move!.from, hint.move!.to);
        expect(next.changed, isTrue);
        p.validateBoard(next.state.board, extra: false);
      }
    }
    final path = Platform.environment['POURLUNE_CONTENT_REPORT'];
    if (path != null) {
      File(path).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'scope': 'Pure Dart default solveHint on all90 initial and reference-midpoint states. '
            'No extra bottle. Automated measurement, neither shortest path nor human play.', 'dart_version': Platform.version, 'measurements': rows})}\n',
      );
    }
  });
}
