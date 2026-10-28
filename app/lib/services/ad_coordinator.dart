import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/game_store.dart';
import 'service_policy.dart';

enum AdKind { interstitial, rewarded }

class AdLoadFailure implements Exception {
  const AdLoadFailure(this.reason);
  final String reason;
}

enum AdLoadState { idle, loading, ready, unavailable }

class AdCallbacks {
  const AdCallbacks({
    required this.shown,
    required this.impression,
    required this.reward,
    required this.closed,
    required this.failed,
  });
  final VoidCallback shown, impression, reward, closed, failed;
}

abstract interface class AdHandle {
  Future<void> show(AdCallbacks callbacks);
  Future<void> dispose();
}

abstract interface class AdTransport {
  Future<AdHandle> load(AdKind kind);
}

class AdResult {
  const AdResult(this.shown, this.reason);
  final bool shown;
  final String reason;
}

/// One global full-screen owner. Loading is inventory only and never calls show.
class AdCoordinator extends ChangeNotifier {
  AdCoordinator({
    required this.store,
    required this.transport,
    required this.configured,
    this.rulesAllowLoad,
    this.rulesAllowShow,
    FullscreenCooldown? clock,
    this.loadTimeout = const Duration(seconds: 30),
    this.preShowTimeout = const Duration(minutes: 2),
  }) : clock = clock ?? FullscreenCooldown();
  final GameStore store;
  final AdTransport transport;
  final bool configured;
  final bool Function(AdKind)? rulesAllowLoad, rulesAllowShow;
  int _revision = 0;
  int get revision => _revision;
  final FullscreenCooldown clock;
  final Duration loadTimeout, preShowTimeout;
  bool allowed = false,
      foreground = true,
      dialogOpen = false,
      showing = false,
      _disposed = false;
  bool timingSaveFailed = false, _writingTiming = false;
  RemotePolicy policy = const RemotePolicy();
  final loadReasons = <AdKind, String>{};
  final _states = <AdKind, AdLoadState>{};
  final _generation = <AdKind, int>{};
  final _handles = <AdKind, AdHandle>{};
  final _loadedAt = <AdKind, Duration>{};
  final _pendingClear = <String>{};
  bool _initialized = false;
  final _pendingTiming = <String, ({AdKind kind, int millis})>{};
  VoidCallback? _endActive;
  void Function(String event, String request, AdKind kind, String result)?
  onEvent;
  AdLoadState state(AdKind kind) => _states[kind] ?? AdLoadState.idle;
  bool _permits(AdKind kind) =>
      configured &&
      _initialized &&
      allowed &&
      policy.adsEnabled &&
      (rulesAllowLoad?.call(kind) ?? true) &&
      (kind == AdKind.interstitial
          ? policy.interstitialEnabled
          : policy.rewardedEnabled);
  bool ready(AdKind kind) =>
      _inventoryReady(kind) && (rulesAllowShow?.call(kind) ?? true);
  bool _inventoryReady(AdKind kind) =>
      !_disposed &&
      _permits(kind) &&
      foreground &&
      _handles.containsKey(kind) &&
      clock.monotonic() - _loadedAt[kind]! < const Duration(hours: 1);
  bool get fullScreenBusy => showing || _writingTiming;
  Duration get cooldown => clock.remaining;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    _initialized = false;
    final uncertain = await store.readServiceValue('fullscreen_intent');
    clock.restore(
      uncertain == null
          ? await store.lastFullscreenMillis()
          : clock.wall().millisecondsSinceEpoch,
    );
    _initialized = true;
  }

  void update({
    bool? consent,
    bool? isForeground,
    bool? modal,
    RemotePolicy? remote,
  }) {
    final replenish = (isForeground == true && !foreground) || remote != null;
    final invalidate =
        consent != null || remote != null || isForeground == false;
    if (consent != null) allowed = consent;
    if (isForeground != null) foreground = isForeground;
    if (modal != null) dialogOpen = modal;
    if (remote != null) policy = remote;
    if (invalidate) {
      _revision++;
      for (final kind in AdKind.values) {
        _generation[kind] = (_generation[kind] ?? 0) + 1;
        final old = _handles.remove(kind);
        if (old != null) unawaited(_dispose(old));
        _states[kind] = AdLoadState.idle;
      }
    }
    _notify();
    if (replenish && _initialized && !_disposed) {
      scheduleMicrotask(() {
        for (final kind in AdKind.values) {
          unawaited(preload(kind));
        }
      });
    }
  }

  Future<void> _dispose(AdHandle h) async {
    try {
      await h.dispose();
    } catch (_) {}
  }

  Future<void> preload(AdKind kind) async {
    if (_disposed ||
        !_permits(kind) ||
        !foreground ||
        showing ||
        timingSaveFailed ||
        state(kind) == AdLoadState.loading ||
        _inventoryReady(kind)) {
      return;
    }
    final old = _handles.remove(kind);
    if (old != null) unawaited(_dispose(old));
    final token = (_generation[kind] ?? 0) + 1;
    _generation[kind] = token;
    loadReasons.remove(kind);
    _states[kind] = AdLoadState.loading;
    _notify();
    try {
      final pending = transport.load(kind).then((h) {
        if (_disposed ||
            _generation[kind] != token ||
            !_permits(kind) ||
            !foreground) {
          unawaited(_dispose(h));
        }
        return h;
      });
      final h = await pending.timeout(loadTimeout);
      if (_disposed ||
          _generation[kind] != token ||
          !_permits(kind) ||
          !foreground) {
        return;
      }
      _handles[kind] = h;
      _loadedAt[kind] = clock.monotonic();
      _states[kind] = AdLoadState.ready;
    } catch (error) {
      loadReasons[kind] = error is AdLoadFailure
          ? error.reason
          : error is TimeoutException
          ? 'timeout'
          : 'load_failed';
      if (!_disposed && _generation[kind] == token) {
        _generation[kind] = token + 1;
        _states[kind] = AdLoadState.unavailable;
      }
    }
    _notify();
  }

  Future<void> retryTiming() async {
    if (_writingTiming || (_pendingTiming.isEmpty && _pendingClear.isEmpty)) {
      return;
    }
    _writingTiming = true;
    timingSaveFailed = false;
    _notify();
    try {
      for (final entry in _pendingTiming.entries.toList()) {
        await store.recordFullscreen(
          entry.key,
          entry.value.kind.name,
          entry.value.millis,
        );
        _pendingTiming.remove(entry.key);
      }
      for (final id in _pendingClear.toList()) {
        await store.clearFullscreenIntent(id);
        _pendingClear.remove(id);
      }
    } catch (_) {
      timingSaveFailed = true;
    } finally {
      _writingTiming = false;
      _notify();
    }
  }

  Future<AdResult> show(
    AdKind kind,
    String request, {
    VoidCallback? onReward,
    int? expectedRevision,
  }) async {
    final revision = _revision;
    if (showing ||
        _disposed ||
        (expectedRevision != null && expectedRevision != revision) ||
        dialogOpen ||
        !foreground ||
        timingSaveFailed ||
        _writingTiming ||
        cooldown > Duration.zero ||
        !ready(kind)) {
      return const AdResult(false, 'unavailable');
    }
    showing = true;
    _notify();
    final handle = _handles.remove(kind)!;
    _states[kind] = AdLoadState.idle;
    try {
      await store.prepareFullscreen(request, kind.name);
    } catch (_) {
      showing = false;
      await _dispose(handle);
      _notify();
      return const AdResult(false, 'save_failed');
    }
    if (_disposed ||
        !foreground ||
        !_permits(kind) ||
        dialogOpen ||
        revision != _revision ||
        !(rulesAllowShow?.call(kind) ?? true)) {
      _pendingClear.add(request);
      await retryTiming();
      showing = false;
      await _dispose(handle);
      _notify();
      return const AdResult(false, 'stale');
    }
    final result = Completer<AdResult>();
    var shown = false, finished = false, rewarded = false, impressed = false;
    late Timer watchdog;
    void finish(String reason) {
      if (finished) return;
      finished = true;
      watchdog.cancel();
      showing = false;
      _endActive = null;
      if (!_disposed) {
        onEvent?.call(
          reason == 'dismissed' && shown ? 'dismiss' : 'error',
          request,
          kind,
          reason,
        );
      }
      if (!shown) {
        _pendingClear.add(request);
        unawaited(retryTiming());
      }
      unawaited(_dispose(handle));
      _notify();
      result.complete(AdResult(shown, reason));
      if (!_disposed) {
        scheduleMicrotask(() {
          for (final kind in AdKind.values) {
            unawaited(preload(kind));
          }
        });
      }
    }

    watchdog = Timer(preShowTimeout, () => finish('timeout'));
    _endActive = () => finish('disposed');
    final callbacks = AdCallbacks(
      shown: () {
        if (finished || shown || _disposed) return;
        shown = true;
        // A shown native overlay requires an actual dismissal/failure callback.
        // dispose removes the plugin's adId route; elapsed/background time is not closure.
        watchdog.cancel();
        _pendingTiming[request] = (kind: kind, millis: clock.shown());
        onEvent?.call('shown', request, kind, 'shown');
        unawaited(retryTiming());
      },
      impression: () {
        if (finished || impressed || _disposed) return;
        impressed = true;
        onEvent?.call('impression', request, kind, 'impression');
      },
      // Deliberately no current-request/foreground/policy test: delivered valid
      // late rewards remain owned by this closure's original durable attempt.
      reward: () {
        if (rewarded || _disposed || kind != AdKind.rewarded) return;
        rewarded = true;
        onReward?.call();
      },
      closed: () => finish('dismissed'),
      failed: () => finish('show_failed'),
    );
    unawaited(
      Future<void>.sync(() => handle.show(callbacks)).catchError((_) {
        if (!shown) finish('show_failed');
      }),
    );
    return result.future;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _endActive?.call();
    for (final h in _handles.values) {
      unawaited(_dispose(h));
    }
    _handles.clear();
    super.dispose();
  }
}
