/// Optional product diagnostics; never part of puzzle or reward correctness.
class PlayMetrics {
  PlayMetrics({Duration Function()? now}) : now = now ?? _timer.elapsedDuration;
  static final _timer = _MetricClock();
  final Duration Function() now;
  int _millis = 0, hints = 0, undos = 0, restarts = 0;
  Duration? _start;
  int get durationMillis =>
      (_millis + (_start == null ? 0 : (now() - _start!).inMilliseconds)).clamp(
        0,
        604800000,
      );
  void sync(bool running) {
    if (!running && _start != null) {
      _millis = durationMillis;
      _start = null;
    }
    if (running && _start == null) _start = now();
  }

  factory PlayMetrics.parse(Object? raw, {Duration Function()? now}) {
    final m = PlayMetrics(now: now);
    if (raw is Map) {
      int n(String k) => raw[k] is int && raw[k] >= 0 && raw[k] <= 604800000
          ? raw[k] as int
          : 0;
      m._millis = n('duration_ms');
      m.hints = n('hints');
      m.undos = n('undos');
      m.restarts = n('restarts');
    }
    return m;
  }
  Map<String, int> toJson() => {
    'duration_ms': durationMillis,
    'hints': hints,
    'undos': undos,
    'restarts': restarts,
  };
}

class _MetricClock {
  final watch = Stopwatch()..start();
  Duration elapsedDuration() => watch.elapsed;
}
