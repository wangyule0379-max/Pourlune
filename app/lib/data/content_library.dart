import 'package:pourlune_core/pourlune_core.dart';

Map<String, Puzzle> parsePuzzleDefinitions(Iterable<String> sources) {
  final definitions = <String, Puzzle>{};
  final seen = <String>{};
  for (final source in sources) {
    try {
      final puzzle = Puzzle.parse(source);
      if (!seen.add(puzzle.id)) {
        definitions.remove(puzzle.id);
      } else {
        definitions[puzzle.id] = puzzle;
      }
    } on FormatException {
      /* Invalid content remains unavailable; embedded saves still load. */
    }
  }
  return definitions;
}

class ContentLibrary {
  ContentLibrary({
    required Map<int, Puzzle> main,
    this.daily,
    this.dailyError,
    this.engineering = false,
  }) : main = Map.unmodifiable(main);
  final Map<int, Puzzle> main;
  final DailyCatalog? daily;
  final String? dailyError;
  final bool engineering;
}

class LocalDay {
  LocalDay(this.date, this.zone, this.offsetMinutes) {
    parseCalendarDate(date);
    if (zone.isEmpty || offsetMinutes.abs() > 840) {
      throw ArgumentError('Local clock identity');
    }
  }
  factory LocalDay.now() {
    final now = DateTime.now();
    return LocalDay(
      calendarDate(now),
      now.timeZoneName,
      now.timeZoneOffset.inMinutes,
    );
  }
  final String date, zone;
  final int offsetMinutes;
}

typedef LocalClock = LocalDay Function();
