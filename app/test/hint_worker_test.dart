import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/hint_worker.dart';

import 'store_test.dart' show sample;

void main() {
  test('B02-04 actual isolate returns valid current-board hint and releases worker', () async {
    final s = sample('hint').pour(0, 2).state;
    final job = runHint(s);
    final result = await job.result;
    await job.released;
    expect(result.status, HintStatus.found);
    expect(s.pour(result.move!.from, result.move!.to).changed, isTrue);
    expect(result.elapsed, lessThan(const Duration(seconds: 2)));
  });
  test(
    'B02-04 immediate cancel including spawn race, then immediate retry',
    () async {
      final jobs = List.generate(8, (_) => runHint(sample('cancel')));
      for (final j in jobs) {
        j.cancel();
        j.cancel();
      }
      final results = await Future.wait(jobs.map((j) => j.result));
      await Future.wait(jobs.map((j) => j.released));
      expect(results.every((r) => r.status == HintStatus.cancelled), isTrue);
      final retry = runHint(sample('retry'));
      expect((await retry.result).status, HintStatus.found);
      await retry.released;
    },
  );
  test('B02-04 parent watchdog budget includes startup', () async {
    final job = runHint(sample('timeout'), budget: Duration.zero);
    expect((await job.result).status, HintStatus.timeout);
    await job.released;
  });
}
