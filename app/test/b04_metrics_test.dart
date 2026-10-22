import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/services/play_metrics.dart';

void main() {
  test('AC36 effective foreground time excludes pause/hint/ad/background and restores totals', () {
    var now = Duration.zero;
    final m = PlayMetrics(now: () => now);
    m.sync(true);
    now += const Duration(seconds: 5);
    m.sync(false);
    now += const Duration(seconds: 90);
    expect(m.durationMillis, 5000);
    m.sync(true);
    now += const Duration(seconds: 3);
    m.hints++;
    final saved = m.toJson();
    m.sync(false);
    final restored = PlayMetrics.parse(saved, now: () => now);
    expect(restored.durationMillis, 8000);
    expect(restored.hints, 1);
    now += const Duration(seconds: 100);
    expect(restored.durationMillis, 8000);
  });
}
