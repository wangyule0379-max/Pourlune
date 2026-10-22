import 'dart:convert';

/// Fixed product interval. A monotonic session clock includes background time.
class FullscreenCooldown {
  FullscreenCooldown({
    DateTime Function()? wall,
    Duration Function()? monotonic,
  }) : wall = wall ?? DateTime.now,
       _stopwatch = Stopwatch()..start() {
    this.monotonic = monotonic ?? () => _stopwatch.elapsed;
  }
  final DateTime Function() wall;
  final Stopwatch _stopwatch;
  late final Duration Function() monotonic;
  static const interval = Duration(seconds: 180);
  Duration _anchor = Duration.zero, _initial = Duration.zero;
  void restore(int? savedMillis) {
    _anchor = monotonic();
    if (savedMillis == null) {
      _initial = Duration.zero;
      return;
    }
    final delta = wall().millisecondsSinceEpoch - savedMillis;
    // Untrusted backwards or very large restart jumps cannot bypass cooldown.
    _initial = delta < 0 || delta > const Duration(days: 7).inMilliseconds
        ? interval
        : Duration(
            milliseconds: (interval.inMilliseconds - delta).clamp(
              0,
              interval.inMilliseconds,
            ),
          );
  }

  int shown() {
    _anchor = monotonic();
    _initial = interval;
    return wall().millisecondsSinceEpoch;
  }

  Duration get remaining {
    final millis = (_initial - (monotonic() - _anchor)).inMilliseconds;
    return Duration(milliseconds: millis.clamp(0, interval.inMilliseconds));
  }
}

class RemotePolicy {
  const RemotePolicy({
    this.adsEnabled = true,
    this.interstitialEnabled = true,
    this.rewardedEnabled = true,
    this.disabledPuzzleIds = const {},
  });
  final bool adsEnabled, interstitialEnabled, rewardedEnabled;
  final Set<String> disabledPuzzleIds;
  static const defaults = <String, Object>{
    'ads_enabled': true,
    'interstitial_enabled': true,
    'rewarded_enabled': true,
    'disabled_puzzle_ids': '[]',
  };
  factory RemotePolicy.fromRaw(
    Map<String, String> raw, {
    required Set<String> knownPuzzleIds,
  }) {
    bool boolean(String key) => switch (raw[key]) {
      'true' => true,
      'false' => false,
      _ => throw FormatException('Invalid remote boolean: $key'),
    };
    final ids = jsonDecode(raw['disabled_puzzle_ids'] ?? 'invalid');
    if (ids is! List ||
        ids.length > 90 ||
        ids.any((e) => e is! String || !knownPuzzleIds.contains(e)) ||
        ids.toSet().length != ids.length) {
      throw const FormatException('Invalid disabled puzzle list');
    }
    return RemotePolicy(
      adsEnabled: boolean('ads_enabled'),
      interstitialEnabled: boolean('interstitial_enabled'),
      rewardedEnabled: boolean('rewarded_enabled'),
      disabledPuzzleIds: Set.unmodifiable(ids.cast<String>()),
    );
  }
  Map<String, String> toRaw() => {
    'ads_enabled': '$adsEnabled',
    'interstitial_enabled': '$interstitialEnabled',
    'rewarded_enabled': '$rewardedEnabled',
    'disabled_puzzle_ids': jsonEncode(disabledPuzzleIds.toList()),
  };
}
