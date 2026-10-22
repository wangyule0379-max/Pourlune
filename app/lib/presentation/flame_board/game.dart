import 'dart:math' as math;

import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../../application/game_controller.dart';
import '../../data/player_settings.dart';
import 'frame.dart';
import 'geometry.dart';
import 'paint.dart';

class _ProgressEffect extends Effect {
  _ProgressEffect(this.write, double seconds, {super.onComplete})
    : super(EffectController(duration: seconds));
  final ValueChanged<double> write;
  @override
  void apply(double progress) => write(progress);
}

enum BoardArtStatus { loading, ready, failed }

/// Presentation owner only: immutable snapshots in, one guarded token release
/// out. It cannot submit moves, write SQLite, or grant a reward.
class FlameBoardGame extends FlameGame {
  FlameBoardGame({this.onMotionComplete});
  final ValueChanged<int>? onMotionComplete;
  final visual = ValueNotifier<BoardVisualFrame?>(null);
  final artStatus = ValueNotifier(BoardArtStatus.loading);
  BottleArt? art;
  FlameBoardPainter? _painter;
  bool closed = false, _failed = false, _background = false, _reduced = false;
  GameInstance? _state;
  BoardLayout? _layout;
  PlayerSettings _settings = const PlayerSettings();
  PourMotion? _motion;
  (String, int, int)? _ignored;
  SequenceEffect? _pourEffect;
  _ProgressEffect? _selectionEffect, _errorEffect;
  final _pressEffects = List<_ProgressEffect?>.filled(7, null);
  final _press = List<double>.filled(7, 0);
  double _elapsed = 0,
      _lift = 0,
      _initialLift = 0,
      _shake = 0,
      _selectionTarget = 0;
  int? _selected, _suggested, _shaking;
  int _rejectionRevision = 0;
  (String, int, int) _key(PourMotion m) => (m.instanceId, m.revision, m.token);
  BoardVisualFrame get frame => BoardVisualFrame(
    state: _state!,
    layout: _layout!,
    motion: _motion,
    elapsedMs: _elapsed,
    reduced: _reduced,
    initialLift: _initialLift,
  );
  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    try {
      final loaded = await BottleArt.load();
      if (closed) {
        loaded.dispose();
        return;
      }
      art = loaded;
      _painter = FlameBoardPainter(loaded);
      artStatus.value = BoardArtStatus.ready;
      if (_motion != null) {
        _animate(_motion!);
      } else {
        _select();
      }
      _publish();
      _wake();
    } catch (_) {
      if (!closed) {
        _failed = true;
        _cancel(release: true);
        _publish();
        artStatus.value = BoardArtStatus.failed;
      }
      rethrow;
    }
  }

  void show({
    required GameInstance state,
    required BoardLayout layout,
    required PlayerSettings settings,
    required bool systemReduced,
    PourMotion? motion,
    int? selected,
    int? suggested,
    int? rejectedBottle,
    int rejectionRevision = 0,
  }) {
    if (closed) return;
    final previousLayout = _layout;
    final resized =
        previousLayout != null &&
        (previousLayout.width != layout.width ||
            previousLayout.height != layout.height);
    final reduce =
        systemReduced ||
        settings.reducedMotion ||
        (motion?.reducedMotion ?? false);
    final reduceChanged = _reduced != reduce;
    _state = state;
    _layout = layout;
    _settings = settings;
    _reduced = reduce;
    _selected = selected;
    _suggested = suggested;
    if (_motion != null &&
        (resized || reduceChanged || !matchesMotion(state, _motion!))) {
      _cancel(release: true);
    }
    final m = motion != null && matchesMotion(state, motion) ? motion : null;
    if (m == null) {
      if (_motion != null) _cancel();
      if (!_background) _select();
    } else if (!_background &&
        _ignored != _key(m) &&
        (_motion == null || _key(_motion!) != _key(m))) {
      final previousLift = _lift;
      _cancel();
      _initialLift = previousLift;
      _motion = m;
      _elapsed = 0;
      if (_failed) {
        _cancel(release: true);
      } else if (art != null) {
        _animate(m);
      }
    }
    if (rejectionRevision != _rejectionRevision) {
      _rejectionRevision = rejectionRevision;
      if (!_background &&
          rejectedBottle != null &&
          rejectedBottle >= 0 &&
          rejectedBottle < state.board.length) {
        _error(rejectedBottle);
      }
    }
    _publish();
    _wake();
  }

  void _animate(PourMotion m) {
    if (closed || art == null || _pourEffect != null) return;
    final geometry = geometryFor(_layout!, m, initialLift: _initialLift);
    final boundaries = _reduced
        ? [0.0, 120.0]
        : [
            0.0,
            200.0,
            290.0,
            290 + geometry.flowMs,
            500 + geometry.flowMs,
            geometry.totalMs,
          ];
    final budget = _reduced ? .12 : m.duration.inMicroseconds / 1000000;
    final total = boundaries.last;
    late final SequenceEffect effect;
    effect = SequenceEffect(
      [
        for (var i = 0; i < boundaries.length - 1; i++)
          _ProgressEffect(
            (p) => _elapsed =
                boundaries[i] + (boundaries[i + 1] - boundaries[i]) * p,
            (boundaries[i + 1] - boundaries[i]) / total * budget,
          ),
      ],
      onComplete: () {
        if (closed ||
            !identical(_pourEffect, effect) ||
            _motion == null ||
            _key(_motion!) != _key(m)) {
          return;
        }
        _ignored = _key(m);
        _motion = null;
        _pourEffect = null;
        _lift = 0;
        _elapsed = 0;
        _publish();
        _release(m);
        _wake();
      },
    );
    _pourEffect = effect;
    add(effect);
    _wake();
  }

  void _release(PourMotion m) {
    if (closed ||
        _state?.id != m.instanceId ||
        _state?.revision != m.revision) {
      return;
    }
    onMotionComplete?.call(m.token);
  }

  void _cancel({bool release = false}) {
    final m = _motion;
    _pourEffect?.onComplete = null;
    _pourEffect?.removeFromParent();
    _pourEffect = null;
    _selectionEffect?.onComplete = null;
    _selectionEffect?.removeFromParent();
    _selectionEffect = null;
    _errorEffect?.onComplete = null;
    _errorEffect?.removeFromParent();
    _errorEffect = null;
    for (var i = 0; i < _pressEffects.length; i++) {
      _pressEffects[i]?.onComplete = null;
      _pressEffects[i]?.removeFromParent();
      _pressEffects[i] = null;
      _press[i] = 0;
    }
    _motion = null;
    _elapsed = 0;
    _lift = 0;
    _selectionTarget = 0;
    _shake = 0;
    _shaking = null;
    if (release && m != null) {
      _ignored = _key(m);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!closed && _ignored == _key(m)) _release(m);
      });
    }
  }

  void _select() {
    if (_motion != null || art == null || _background) return;
    final target = _selected != null && !_reduced ? 9.0 : 0.0;
    if (_selectionEffect != null && _selectionTarget == target) return;
    if ((_lift - target).abs() < .001) return;
    _selectionEffect?.onComplete = null;
    _selectionEffect?.removeFromParent();
    _selectionTarget = target;
    final from = _lift;
    late final _ProgressEffect effect;
    effect = _ProgressEffect(
      (p) => _lift = from + (target - from) * Curves.easeOutCubic.transform(p),
      .13,
      onComplete: () {
        if (identical(_selectionEffect, effect)) _selectionEffect = null;
      },
    );
    _selectionEffect = effect;
    add(effect);
    _wake();
  }

  void press(int index, bool down) {
    if (closed ||
        _background ||
        _motion != null ||
        index < 0 ||
        index >= _press.length) {
      return;
    }
    _pressEffects[index]?.onComplete = null;
    _pressEffects[index]?.removeFromParent();
    final from = _press[index], to = down && !_reduced ? 1.0 : 0.0;
    if ((from - to).abs() < .001 && _pressEffects[index] == null) return;
    late final _ProgressEffect effect;
    effect = _ProgressEffect(
      (p) =>
          _press[index] = from + (to - from) * Curves.easeOutCubic.transform(p),
      down ? .075 : .15,
      onComplete: () {
        if (identical(_pressEffects[index], effect)) {
          _pressEffects[index] = null;
        }
      },
    );
    _pressEffects[index] = effect;
    add(effect);
    _wake();
  }

  void _error(int index) {
    _errorEffect?.onComplete = null;
    _errorEffect?.removeFromParent();
    _shaking = index;
    late final _ProgressEffect effect;
    effect = _ProgressEffect(
      (p) => _shake = _reduced ? 0 : math.sin(p * math.pi * 4) * 3 * (1 - p),
      .22,
      onComplete: () {
        if (identical(_errorEffect, effect)) {
          _errorEffect = null;
          _shaking = null;
          _shake = 0;
        }
      },
    );
    _errorEffect = effect;
    add(effect);
    _wake();
  }

  void _publish() {
    if (closed || _state == null || _layout == null) return;
    final next = frame, old = visual.value;
    if (old == null ||
        old.state.id != next.state.id ||
        old.state.revision != next.state.revision ||
        old.active?.token != next.active?.token ||
        !listEquals(old.counts, next.counts)) {
      visual.value = next;
    }
  }

  void _wake() {
    if (art != null && !closed && !_background) resumeEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    if (_background) {
      _cancel(release: true);
      _publish();
    }
    super.lifecycleStateChange(state);
    if (_background) {
      pauseEngine();
    } else {
      _wake();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _publish();
    if (_pourEffect == null &&
        _selectionEffect == null &&
        _errorEffect == null &&
        _pressEffects.every((e) => e == null) &&
        !hasLifecycleEvents) {
      pauseEngine();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (closed || _state == null || _layout == null) return;
    _painter?.paint(
      canvas,
      frame,
      _settings,
      selected: _selected,
      suggested: _suggested,
      press: _press,
      lift: _lift,
      shaking: _errorEffect == null ? null : _shaking,
      shake: _shake,
      reduced: _reduced,
    );
  }

  @override
  void onRemove() {
    if (!closed) {
      _cancel();
      closed = true;
      art?.dispose();
      art = null;
      _painter = null;
      visual.dispose();
      artStatus.dispose();
    }
    super.onRemove();
  }
}
