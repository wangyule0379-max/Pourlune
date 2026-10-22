import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/services/service_policy.dart';

void main() {
  test('AC17 shared cooldown exact179/180, monotonic session ignores wall jumps and includes background', () {
    var wall = DateTime.fromMillisecondsSinceEpoch(1000000),
        elapsed = Duration.zero;
    final c = FullscreenCooldown(wall: () => wall, monotonic: () => elapsed);
    c.restore(null);
    expect(c.remaining, Duration.zero);
    c.shown();
    elapsed = const Duration(seconds: 179);
    wall = wall.add(const Duration(days: 999));
    expect(c.remaining, const Duration(seconds: 1));
    elapsed = const Duration(seconds: 180);
    expect(c.remaining, Duration.zero);
    expect(c.remaining, Duration.zero);
  });
  test('AC17 restart restores normal wall time, rollback and extreme future use conservative180 window', () {
    var wall = DateTime.fromMillisecondsSinceEpoch(1000000),
        elapsed = Duration.zero;
    final c = FullscreenCooldown(wall: () => wall, monotonic: () => elapsed);
    c.restore(wall.millisecondsSinceEpoch - 179000);
    expect(c.remaining, const Duration(seconds: 1));
    elapsed = const Duration(seconds: 1);
    expect(c.remaining, Duration.zero);
    c.restore(wall.millisecondsSinceEpoch + 1);
    expect(c.remaining, const Duration(seconds: 180));
    elapsed += const Duration(seconds: 180);
    expect(c.remaining, Duration.zero);
    c.restore(wall.subtract(const Duration(days: 30)).millisecondsSinceEpoch);
    expect(c.remaining, const Duration(seconds: 180));
  });
  test('AC34 strict RC rejects malformed bool/unknown content, never changes active definitions or confirmed grants', () {
    final raw = {
      'ads_enabled': 'true',
      'interstitial_enabled': 'false',
      'rewarded_enabled': 'true',
      'disabled_puzzle_ids': '["main-012"]',
    };
    final p = RemotePolicy.fromRaw(raw, knownPuzzleIds: {'main-012'});
    expect(p.adsEnabled, isTrue);
    expect(p.interstitialEnabled, isFalse);
    expect(p.disabledPuzzleIds, {'main-012'});
    for (final bad in ['yes', '0', 'NaN', '']) {
      expect(
        () => RemotePolicy.fromRaw(
          {...raw, 'ads_enabled': bad},
          knownPuzzleIds: {'main-012'},
        ),
        throwsFormatException,
      );
    }
    expect(
      () => RemotePolicy.fromRaw(
        {...raw, 'disabled_puzzle_ids': '["not-a-puzzle"]'},
        knownPuzzleIds: {'main-012'},
      ),
      throwsFormatException,
    );
    expect(
      () => RemotePolicy.fromRaw(
        {...raw, 'disabled_puzzle_ids': '{}'},
        knownPuzzleIds: {'main-012'},
      ),
      throwsFormatException,
    );
    expect(const RemotePolicy().adsEnabled, isTrue);
  });
}
