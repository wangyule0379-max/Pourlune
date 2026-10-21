import 'dart:async';
import 'dart:isolate';

import 'package:pourlune_core/pourlune_core.dart';

typedef HintTask = ({
  Future<HintResult> result,
  void Function() cancel,
  Future<void> released,
});
typedef HintLauncher = HintTask Function(GameInstance state);
HintTask runHint(
  GameInstance state, {
  Duration budget = const Duration(seconds: 2),
  int maxStates = 50000,
}) {
  final worker = _HintWorker(state, budget, maxStates);
  return (
    result: worker.result.future,
    cancel: worker.cancel,
    released: worker.released.future,
  );
}

class _HintWorker {
  _HintWorker(GameInstance state, Duration budget, int maxStates) {
    response.listen((message) {
      try {
        final data = message as List<Object?>;
        final move = data[1] == null
            ? null
            : PourMove(data[1]! as int, data[2]! as int);
        finish(
          HintResult(
            HintStatus.values[data[0]! as int],
            move: move,
            visited: data[3]! as int,
            elapsed: watch.elapsed,
          ),
        );
      } catch (_) {
        finish(HintResult(HintStatus.timeout, elapsed: watch.elapsed));
      }
    });
    errors.listen(
      (_) => finish(HintResult(HintStatus.timeout, elapsed: watch.elapsed)),
    );
    deadline = Timer(
      budget,
      () => finish(HintResult(HintStatus.timeout, elapsed: watch.elapsed)),
    );
    spawn(state, budget, maxStates);
  }
  final response = ReceivePort(), errors = ReceivePort();
  final result = Completer<HintResult>(), released = Completer<void>();
  final watch = Stopwatch()..start();
  late final Timer deadline;
  Isolate? isolate;
  bool done = false, spawnFinished = false;
  Future<void> spawn(GameInstance s, Duration budget, int maxStates) async {
    try {
      isolate = await Isolate.spawn(
        _entry,
        <String, Object?>{
          'send': response.sendPort,
          'puzzle': s.puzzle.toJson(),
          'board': s.board,
          'extra': s.extraBottleGranted,
          'budget_us': budget.inMicroseconds,
          'max_states': maxStates,
        },
        onError: errors.sendPort,
        errorsAreFatal: true,
        debugName: 'Pourlune hint',
      );
    } catch (_) {
      finish(HintResult(HintStatus.timeout, elapsed: watch.elapsed));
    } finally {
      spawnFinished = true;
      if (done) release();
    }
  }

  void cancel() =>
      finish(HintResult(HintStatus.cancelled, elapsed: watch.elapsed));
  void finish(HintResult value) {
    if (done) return;
    done = true;
    deadline.cancel();
    response.close();
    errors.close();
    result.complete(value);
    if (spawnFinished) release();
  }

  void release() {
    isolate?.kill(priority: Isolate.immediate);
    isolate = null;
    if (!released.isCompleted) released.complete();
  }
}

void _entry(Map<String, Object?> message) {
  final result = solveHint(
    Puzzle.fromJson(object(message['puzzle'])),
    readBoard(message['board']),
    extra: message['extra']! as bool,
    budget: Duration(microseconds: message['budget_us']! as int),
    maxStates: message['max_states']! as int,
  );
  (message['send']! as SendPort).send(<Object?>[
    result.status.index,
    result.move?.from,
    result.move?.to,
    result.visited,
  ]);
}
