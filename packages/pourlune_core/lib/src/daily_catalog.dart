import 'puzzle.dart';

DateTime parseCalendarDate(String text) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    invalid('Invalid calendar date');
  }
  final parts = text.split('-').map(int.parse).toList();
  final d = DateTime.utc(parts[0], parts[1], parts[2]);
  if (d.year < 1 || calendarDate(d) != text) invalid('Invalid calendar date');
  return d;
}

String calendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DailyCatalog {
  DailyCatalog._(this.version, this.epoch, this.puzzles, this.engineering);
  final int version;
  final DateTime epoch;
  final List<Puzzle> puzzles;
  final bool engineering;
  factory DailyCatalog.parse(
    String source,
    Map<String, Puzzle> definitions, {
    bool engineering = false,
  }) {
    final m = object(strictJson(source));
    keys(m, {'schema_version', 'catalog_version', 'epoch_date', 'puzzle_ids'});
    if (integer(m['schema_version']) != 1) invalid('Unknown daily schema');
    final version = integer(m['catalog_version'], 1),
        epoch = parseCalendarDate(text(m['epoch_date']));
    final ids = m['puzzle_ids'];
    if (ids is! List ||
        ids.length < (engineering ? 1 : 30) ||
        ids.toSet().length != ids.length) {
      invalid('Daily catalog size/duplicates');
    }
    final puzzles = <Puzzle>[];
    for (final raw in ids) {
      final id = text(raw), p = definitions[id];
      if (!RegExp(r'^daily-[a-z0-9-]+$').hasMatch(id) ||
          p == null ||
          p.id != id ||
          p.mode != 'daily') {
        invalid('Missing daily definition');
      }
      puzzles.add(p);
    }
    return DailyCatalog._(
      version,
      epoch,
      List.unmodifiable(puzzles),
      engineering,
    );
  }
  Puzzle forDate(String date) {
    final difference = parseCalendarDate(date).difference(epoch).inDays,
        n = puzzles.length;
    return puzzles[((difference % n) + n) % n];
  }
}
