import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/services/ad_continuation.dart';

void main() {
  test('AC36 continuation consumes once, background does not use120 foreground seconds, expires after120', () {
    var now = Duration.zero;
    final windows = AdContinuationWindow(now: () => now);
    windows.closed('first', 'rewarded');
    now = const Duration(seconds: 119);
    windows.setForeground(false);
    now += const Duration(days: 1);
    expect(windows.legalMove(), isEmpty);
    windows.setForeground(true);
    now += const Duration(seconds: 1);
    expect(windows.legalMove().single.request, 'first');
    expect(windows.legalMove(), isEmpty);
    windows.closed('first', 'rewarded');
    expect(windows.legalMove(), isEmpty);
    windows.closed('expired', 'interstitial');
    now += const Duration(seconds: 121);
    expect(windows.legalMove(), isEmpty);
    windows.closed('withdrawn', 'rewarded');
    windows.clear();
    expect(windows.legalMove(), isEmpty);
  });
}
