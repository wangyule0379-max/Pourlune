/// Session-only attribution; exiting with no continuation leaves only dismissal.
class AdContinuationWindow {
  AdContinuationWindow({Duration Function()? now}) {
    final watch = Stopwatch()..start();
    this.now = now ?? () => watch.elapsed;
    _anchor = this.now();
  }
  late final Duration Function() now;
  late Duration _anchor;
  Duration _elapsed = Duration.zero;
  bool _foreground = true;
  final _seen = <String>{};
  final _windows = <String, ({String format, Duration start})>{};
  Duration get _foregroundTime =>
      _elapsed + (_foreground ? now() - _anchor : Duration.zero);
  void setForeground(bool value) {
    if (value == _foreground) return;
    _elapsed = _foregroundTime;
    _anchor = now();
    _foreground = value;
  }

  void closed(String request, String format) {
    if (_seen.add(request)) {
      _windows[request] = (format: format, start: _foregroundTime);
    }
  }

  List<({String request, String format})> legalMove() {
    if (!_foreground) return [];
    final time = _foregroundTime,
        result = <({String request, String format})>[];
    for (final entry in _windows.entries) {
      if (time - entry.value.start <= const Duration(seconds: 120)) {
        result.add((request: entry.key, format: entry.value.format));
      }
    }
    _windows.clear();
    return result;
  }

  void clear() => _windows.clear();
}
