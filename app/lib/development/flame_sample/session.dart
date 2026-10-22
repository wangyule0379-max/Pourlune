import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:sqflite/sqflite.dart';

import '../../application/game_controller.dart';
import '../../data/content_library.dart';
import '../../data/game_store.dart';

/// A legal four-bottle engineering fixture; only indices 0 and 2 are projected.
/// The other color and second empty buffer remain in the authoritative core.
Puzzle pourFixture(int units) {
  if (units < 1 || units > 4) throw ArgumentError.value(units);
  return Puzzle.fromJson({
    'schema_version': 1,
    'puzzle_id': 'main-001',
    'content_version': 10000 + units,
    'mode': 'main',
    'content_status': 'reference_fixture',
    'main_level': 1,
    'capacity': 4,
    'initial_bottom_to_top': [
      [...List.filled(4 - units, 'G'), ...List.filled(units, 'O')],
      [...List.filled(4 - units, 'O'), ...List.filled(units, 'G')],
      [],
      [],
    ],
    'target_labels': ['G', 'O', null, null],
    'reference_moves': [
      {'from_index': 0, 'to_index': 2},
      {'from_index': 1, 'to_index': 0},
      if (units < 4) {'from_index': 1, 'to_index': 2},
      {'from_index': 2, 'to_index': 1},
    ],
    'difficulty_intent': 'flame-sample-$units',
    'source_reference': 'lib/development/flame_sample/session.dart',
  });
}

GameInstance _finish(GameInstance state, {int? take}) {
  for (final move in state.puzzle.referenceMoves.take(
    take ?? state.puzzle.referenceMoves.length,
  )) {
    final result = state.pour(move.from, move.to);
    if (!result.changed) throw StateError('Invalid QA reference');
    state = result.state;
  }
  return state;
}

class FlameSampleSession {
  FlameSampleSession(this.bottles, this.patch);
  final GameController bottles, patch;
  static Future<FlameSampleSession> open() async {
    if (!kDebugMode ||
        const String.fromEnvironment('POURLUNE_DATABASE') !=
            'flame_sample.sqlite') {
      throw StateError('Isolated debug sample database required');
    }
    final base = await getDatabasesPath();
    final a = await GameStore.open('$base/flame_sample.sqlite');
    GameStore? b;
    try {
      b = await GameStore.open('$base/flame_patch.sqlite');
      final library = ContentLibrary(
        main: {
          for (var n = 1; n <= 4; n++)
            n: Puzzle.fromJson(
              jsonDecode(
                await rootBundle.loadString(
                  'assets/puzzles/main/main-${n.toString().padLeft(3, '0')}.json',
                ),
              ) as Map<String, dynamic>,
            ),
        },
      );
      final session = FlameSampleSession(
        GameController(a),
        GameController(b, library: library),
      );
      await session.bottles.initialize();
      await session.patch.initialize();
      if (session.bottles.current == null) await session.resetPour(2);
      await session.prepareReward();
      return session;
    } catch (_) {
      await a.close();
      await b?.close();
      rethrow;
    }
  }

  int get units =>
      int.tryParse(
        bottles.current?.puzzle.difficultyIntent.split('-').last ?? '',
      ) ??
      2;
  Future<void> resetPour(int units) async {
    final token = bottles.motion?.token;
    if (token != null) bottles.completeMotion(token);
    if (bottles.phase != SavePhase.clean) return;
    await bottles.start(pourFixture(units), replace: true, replay: true);
  }

  Future<void> prepareReward() async {
    final c = patch;
    if (c.current?.puzzle.mainLevel == 4) return;
    for (var n = 1; n <= 3; n++) {
      await c.store.settle(
        _finish(
          GameInstance.create(
            id: 'flame-qa-seed-$n',
            puzzle: c.library.main[n]!,
          ),
        ),
        replace: true,
      );
    }
    final puzzle = c.library.main[4]!;
    await c.store.save(
      _finish(
        GameInstance.create(
          id: 'flame-qa-main004-${DateTime.now().microsecondsSinceEpoch}',
          puzzle: puzzle,
        ),
        take: puzzle.referenceMoves.length - 1,
      ),
      replace: true,
    );
    await c.initialize();
    c.resume();
  }

  Future<void> finishReward() async {
    final c = patch;
    if (c.busy || c.phase != SavePhase.clean || c.current!.completed) return;
    c.resume();
    final move = c.current!.puzzle.referenceMoves.last;
    await c.pour(move.from, move.to);
  }

  Future<void> resetReward() async {
    if (patch.phase != SavePhase.clean || patch.busy) return;
    await patch.resetProgress();
    await prepareReward();
  }

  Future<void> close() async {
    bottles.dispose();
    patch.dispose();
    await bottles.store.close();
    await patch.store.close();
  }
}
