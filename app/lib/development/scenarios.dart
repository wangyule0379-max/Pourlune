import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../data/game_store.dart';
import '../data/content_library.dart';

/// Generated IDs reuse engineering samples ONLY for debug flow verification.
class DevelopmentScenario {
  DevelopmentScenario._(this.library, this.day);
  final ContentLibrary library;
  LocalDay day;
  LocalDay now() => day;
  void advanceDay() {
    day = LocalDay(
      calendarDate(parseCalendarDate(day.date).add(const Duration(days: 1))),
      day.zone,
      day.offsetMinutes,
    );
  }

  static Future<DevelopmentScenario> prepare(
    String name,
    List<Puzzle> fixtures,
    GameStore store,
  ) async {
    if (!kDebugMode ||
        !{'flow', 'milestone', 'final', 'old-daily'}.contains(name)) {
      throw StateError('Unknown debug scenario');
    }
    final base = fixtures.firstWhere((p) => p.mainLevel == 1);
    final main = {
      for (var level = 1; level <= 60; level++)
        level: Puzzle.fromJson(
          base.toJson()
            ..['puzzle_id'] = 'main-${level.toString().padLeft(3, '0')}'
            ..['main_level'] = level,
        ),
    };
    final daily = {
      for (final name in ['daily-engineering-a', 'daily-engineering-b'])
        name: Puzzle.fromJson(
          base.toJson()
            ..['puzzle_id'] = name
            ..['mode'] = 'daily'
            ..['main_level'] = null,
        ),
    };
    final library = ContentLibrary(
      main: main,
      daily: DailyCatalog.parse(
        jsonEncode({
          'schema_version': 1,
          'catalog_version': 1,
          'epoch_date': '2026-10-21',
          'puzzle_ids': daily.keys.toList(),
        }),
        daily,
        engineering: true,
      ),
      engineering: true,
    );
    final setup = DevelopmentScenario._(library, LocalDay.now());
    final applied = await store.db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: ['development_seed_$name'],
    );
    if (applied.isEmpty) {
      final clears = name == 'final'
          ? 59
          : name == 'milestone'
          ? 19
          : 0;
      for (var level = 1; level <= clears; level++) {
        var s = GameInstance.create(
          id: 'seed-$name-$level',
          puzzle: main[level]!,
        );
        for (final move in s.puzzle.referenceMoves) {
          s = s.pour(move.from, move.to).state;
        }
        await store.settle(s, replace: true);
      }
      if (clears > 0) {
        await store.save(
          GameInstance.create(
            id: 'seed-$name-active',
            puzzle: main[clears + 1]!,
          ),
          replace: true,
        );
      }
      if (name == 'old-daily') {
        final yesterday = calendarDate(
          parseCalendarDate(setup.day.date).subtract(const Duration(days: 1)),
        );
        final s = GameInstance.create(
          id: 'seed-old-daily',
          puzzle: library.daily!.forDate(yesterday),
          slot: 'daily',
          puzzleDate: yesterday,
          timeZone: setup.day.zone,
          offsetMinutes: setup.day.offsetMinutes,
          catalogVersion: library.daily!.version,
        ).pour(0, 2).state;
        await store.save(s, replace: true);
      }
      await store.db.insert('metadata', {
        'key': 'development_seed_$name',
        'value': 1,
      });
    }
    return setup;
  }
}
