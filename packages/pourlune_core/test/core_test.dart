import 'dart:convert';
import 'dart:io';

import 'package:pourlune_core/pourlune_core.dart';
import 'package:test/test.dart';

Puzzle fixture([String id = '001']) => Puzzle.parse(
  File('../../docs/content/fixtures/main-$id.reference.json')
      .readAsStringSync(),
);
GameInstance game([Puzzle? puzzle]) =>
    GameInstance.create(id: 'test-instance', puzzle: puzzle ?? fixture());
void main() {
  group('B01-02 strict contract', () {
    for (final id in ['001', '021', '012']) {
      test('AC-35 sample $id reference replay', () {
        final p = fixture(id);
        var s = game(p);
        for (final move in p.referenceMoves) {
          final r = s.pour(move.from, move.to);
          expect(r.changed, isTrue);
          expect(r.units, greaterThan(0));
          s = r.state;
        }
        expect(s.completed, isTrue);
        expect(s.moveCount, p.referenceMoves.length);
      });
    }
    test('original Level 12 independently recorded units/colors/boards', () {
      final original = jsonDecode(
        File(
          '../../docs/design/original/Pourlune_Design_Pack/Level12_Example_Validated.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      var s = game(fixture('012'));
      for (final dynamic raw in original['moves'] as List) {
        final m = raw as Map<String, dynamic>;
        final r = s.pour(
          (m['from_bottle'] as int) - 1,
          (m['to_bottle'] as int) - 1,
        );
        expect(r.units, m['units']);
        expect(s.board[(m['from_bottle'] as int) - 1].last, m['color']);
        expect(r.state.board, m['board_after_bottom_to_top']);
        s = r.state;
      }
      expect(s.completed, isTrue);
    });
    test('reject duplicate escaped keys and non-integer JSON tokens', () {
      final raw = File('../../docs/content/fixtures/main-001.reference.json')
          .readAsStringSync();
      for (final bad in [
        raw.replaceFirst(
          '"schema_version": 1',
          '"schema_version": 1, "schema_version": 1',
        ),
        raw.replaceFirst(
          '"schema_version": 1',
          '"schema_version": 1, "\\u0073chema_version": 1',
        ),
        raw.replaceFirst('"capacity": 4', '"capacity": 4.0'),
        raw.replaceFirst('"capacity": 4', '"capacity": 4e0'),
        raw.replaceFirst('"capacity": 4', '"capacity": NaN'),
        raw.replaceFirst('"schema_version": 1', '"schema_version": 2'),
      ]) {
        expect(() => Puzzle.parse(bad), throwsFormatException);
      }
    });
    test('reject shape, counts, labels, range and unknown fields', () {
      for (final edit in <void Function(Map<String, dynamic>)>[
        (m) => m['surprise'] = 1,
        (m) => m['target_labels'] = ['O', 'O', null, null],
        (m) => m['target_labels'] = [null, 'G', 'O', null],
        (m) => m['initial_bottom_to_top'] = [
          ['G', 'O'],
          ['O', 'O', 'G', 'G'],
          <String>[],
          <String>[],
        ],
        (m) => m['reference_moves'] = [
          {'from_index': 4, 'to_index': 0},
        ],
        (m) => m['reference_moves'] = [
          {'from_index': 0.0, 'to_index': 1},
        ],
        (m) => m['main_level'] = 2,
        (m) => m['content_version'] = 0,
      ]) {
        final m = jsonDecode(
          File('../../docs/content/fixtures/main-001.reference.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>;
        edit(m);
        expect(() => Puzzle.fromJson(m), throwsFormatException);
      }
    });
  });
  group('B01-03 rules', () {
    test(
      'AC-01 independently calculated capacity truncation and immutable move',
      () {
        final s = game().withBoardForTest([
          ['G', 'O', 'O', 'O'],
          ['O', 'G', 'G'],
          <String>[],
          ['G'],
        ]);
        final r = s.pour(0, 2);
        expect(r.units, 3);
        expect(r.state.board, [
          ['G'],
          ['O', 'G', 'G'],
          ['O', 'O', 'O'],
          ['G'],
        ]);
        expect(s.board[0], ['G', 'O', 'O', 'O']);
        final t = game().withBoardForTest([
          ['O', 'G', 'G', 'G'],
          ['O', 'O'],
          ['O', 'G'],
          <String>[],
        ]);
        final cut = t.pour(0, 2);
        expect(cut.units, 2);
        expect(cut.state.board, [
          ['O', 'G'],
          ['O', 'O'],
          ['O', 'G', 'G', 'G'],
          <String>[],
        ]);
        expect(cut.state.moveCount, 1);
      },
    );
    test('AC-02 illegal actions preserve identity, steps and history', () {
      final s = game();
      for (final pair in [(0, 0), (0, 1), (2, 0), (-1, 0), (0, 99)]) {
        final r = s.pour(pair.$1, pair.$2);
        expect(identical(r.state, s), isTrue);
        expect(r.changed, isFalse);
        expect(s.moveCount, 0);
        expect(s.history, isEmpty);
      }
    });
    test('AC-03 wrong target and nonempty buffer are not victory', () {
      final p = fixture();
      expect(
        p.isWon([
          ['G', 'G', 'G', 'G'],
          ['O', 'O', 'O', 'O'],
          <String>[],
          <String>[],
        ]),
        isFalse,
      );
      expect(
        p.isWon([
          ['O', 'O', 'O', 'O'],
          ['G', 'G', 'G'],
          ['G'],
          <String>[],
        ]),
        isFalse,
      );
      expect(
        p.isWon([
          ['O', 'O', 'O', 'O'],
          ['G', 'G', 'G', 'G'],
          <String>[],
          <String>[],
        ]),
        isTrue,
      );
    });
    test('target label does not prohibit temporary receiver', () {
      var s = game();
      s = s.pour(0, 2).state;
      final r = s.pour(1, 0);
      expect(r.units, 2);
      expect(r.state.board[0], ['G', 'G', 'G', 'G']);
      expect(r.state.completed, isFalse);
    });
    test(
      'completed instance locks moves, undo, restart and extra entitlement',
      () {
        var s = game();
        for (final m in s.puzzle.referenceMoves) {
          s = s.pour(m.from, m.to).state;
        }
        expect(s.completed, isTrue);
        expect(s.pour(0, 2).changed, isFalse);
        expect(identical(s.undo(), s), isTrue);
        expect(identical(s.restart(), s), isTrue);
        expect(identical(s.grantExtraBottle(), s), isTrue);
      },
    );
  });
  group('B01-04 instance', () {
    test(
      'AC-07 undo before/after extra bottle and restart keep entitlement',
      () {
        final original = game();
        final one = original.pour(0, 2).state;
        final added = one.grantExtraBottle();
        expect(added.board.length, 5);
        expect(added.revision, 2);
        final two = added.pour(1, 0).state;
        final undone = two.undo();
        expect(undone.board, added.board);
        expect(undone.extraBottleGranted, isTrue);
        final beforeGrant = undone.undo();
        expect(beforeGrant.board, [...original.board, <String>[]]);
        expect(beforeGrant.revision, 5);
        expect(beforeGrant.extraBottleGranted, isTrue);
        final restarted = two.restart();
        expect(restarted.id, original.id);
        expect(restarted.board, [...original.board, <String>[]]);
        expect(restarted.moveCount, 0);
        expect(restarted.history, isEmpty);
        expect(restarted.revision, 4);
        expect(identical(restarted.grantExtraBottle(), restarted), isTrue);
      },
    );
    test(
      'AC-23 round trip pins original definition and rejects corrupt snapshot',
      () {
        final s = game().pour(0, 2).state.grantExtraBottle();
        final loaded = GameInstance.parse(jsonEncode(s.toJson()));
        expect(loaded.board, s.board);
        expect(loaded.puzzle.toJson(), s.puzzle.toJson());
        expect(loaded.undo().board.length, 5);
        final bad = s.toJson();
        bad['board'] = List.generate(5, (_) => <String>[]);
        expect(() => GameInstance.fromJson(bad), throwsFormatException);
        expect(() => loaded.board[0].add('O'), throwsUnsupportedError);
      },
    );
  });
}

extension on GameInstance {
  GameInstance withBoardForTest(List<List<String>> board) {
    final data = toJson();
    data['board'] = board;
    return GameInstance.fromJson(data);
  }
}
