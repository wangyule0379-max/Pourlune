import 'dart:convert';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

import 'core_test.dart' show fixture;

void main() {
  test('B02-02 tutorial restricts moves, persists step, undo/restart and Skip preserve board', () {
    var s = GameInstance.create(
      id: 'lesson',
      puzzle: fixture(),
      tutorial: true,
    );
    expect(s.tutorial!.step, 0);
    expect(s.pour(1, 3).changed, isFalse);
    s = s.pour(0, 2).state;
    expect(s.tutorial!.step, 1);
    final restored = GameInstance.parse(jsonEncode(s.toJson()));
    expect(restored.tutorial!.step, 1);
    expect(restored.board, s.board);
    expect(restored.undo().tutorial!.step, 0);
    expect(restored.restart().tutorial!.step, 0);
    final skipped = restored.skipTutorial();
    expect(skipped.board, restored.board);
    expect(skipped.revision, restored.revision + 1);
    expect(skipped.tutorial!.status, TutorialStatus.skipped);
    expect(skipped.pour(2, 3).changed, isTrue);
    expect(skipped.restart().tutorial!.status, TutorialStatus.skipped);
  });
  test('B02-02 completion and v1 compatibility are stable', () {
    var s = GameInstance.create(
      id: 'lesson-done',
      puzzle: fixture(),
      tutorial: true,
    );
    for (final m in s.puzzle.referenceMoves.take(3)) {
      s = s.pour(m.from, m.to).state;
    }
    expect(s.tutorial!.status, TutorialStatus.completed);
    expect(s.restart().tutorial!.status, TutorialStatus.completed);
    final old = GameInstance.create(id: 'old', puzzle: fixture()).toJson()
      ..['instance_schema_version'] = 1
      ..remove('tutorial');
    expect(GameInstance.fromJson(old).tutorial, isNull);
    final invalid = s.toJson()
      ..['tutorial'] = {'version': 1, 'step': 99, 'status': 'active'};
    expect(() => GameInstance.fromJson(invalid), throwsFormatException);
  });
  test('B02-05 daily strict calendar mapping including pre-epoch/leap/offset independence', () {
    final p = fixture();
    final definitions = {
      for (final id in ['daily-a', 'daily-b', 'daily-c'])
        id: Puzzle.fromJson(
          p.toJson()
            ..['puzzle_id'] = id
            ..['mode'] = 'daily'
            ..['main_level'] = null,
        ),
    };
    final source = jsonEncode({
      'schema_version': 1,
      'catalog_version': 2,
      'epoch_date': '2024-02-28',
      'puzzle_ids': definitions.keys.toList(),
    });
    expect(
      () => DailyCatalog.parse(source, definitions),
      throwsFormatException,
    );
    final catalog = DailyCatalog.parse(source, definitions, engineering: true);
    expect(catalog.forDate('2024-02-28').id, 'daily-a');
    expect(catalog.forDate('2024-02-29').id, 'daily-b');
    expect(catalog.forDate('2024-03-01').id, 'daily-c');
    expect(catalog.forDate('2024-02-27').id, 'daily-c');
    expect(catalog.forDate('2025-02-28').id, 'daily-a');
    expect(() => catalog.forDate('2024-02-30'), throwsFormatException);
    expect(
      () => DailyCatalog.parse(
        source.replaceFirst('daily-b', 'daily-a'),
        definitions,
        engineering: true,
      ),
      throwsFormatException,
    );
    expect(
      () => DailyCatalog.parse(source, {}, engineering: true),
      throwsFormatException,
    );
    expect(
      () => DailyCatalog.parse(
        source.replaceFirst('"schema_version":1', '"schema_version":1.0'),
        definitions,
        engineering: true,
      ),
      throwsFormatException,
    );
  });
  for (final corruptHistory in [false, true]) {
    test(
      'B02-02 active tutorial rejects board outside its short guided prefix (history=$corruptHistory)',
      () {
        var s = GameInstance.create(
          id: 'guided-corrupt',
          puzzle: fixture(),
          tutorial: true,
        ).pour(0, 2).state;
        if (corruptHistory) s = s.pour(1, 0).state;
        final bad = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
        final alternate = <List<String>>[
          ['G', 'G'],
          ['O', 'O', 'G', 'G'],
          [],
          ['O', 'O'],
        ];
        if (corruptHistory) {
          (bad['undo_history'] as List<dynamic>)[1]['board'] = alternate;
        } else {
          bad['board'] = alternate;
        }
        expect(() => GameInstance.fromJson(bad), throwsFormatException);
      },
    );
  }
}
