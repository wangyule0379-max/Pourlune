import 'dart:math' as math;

import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  FlameBoardGame({this.onMotionComplete, this.onFlowStart, this.onFlowEnd});
  final VoidCallback? onFlowStart, onFlowEnd;
  bool _flowing = false;
  final ValueChanged<int>? onMotionComplete;
  final visual = ValueNotifier<BoardVisualFrame?>(null);
  final poseTick = ValueNotifier(0);
  bool _posePublishScheduled = false;
  bool _publishScheduled = false;
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
  final _pressEffects = List<_ProgressEffect?>.filled(8, null);
  final _press = List<double>.filled(8, 0);
  final _selectionLifts = List<double>.filled(8, 0);
  int? _selectionTarget;
  double _elapsed = 0, _initialLift = 0, _shake = 0;
  int? _selected, _suggested, _hintSource, _shaking, _addedBottle;
  int _rejectionRevision = 0;
  (String, int, int) _key(PourMotion m) => (m.instanceId, m.revision, m.token);
  BoardVisualFrame get frame => BoardVisualFrame(
    state: _state!,
    layout: _layout!,
    motion: _motion,
    elapsedMs: _elapsed,
    reduced: _reduced,
    initialLift: _initialLift,
    selectionLifts: _selectionLifts,
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
    int? hintSource,
    int? addedBottle,
    int? rejectedBottle,
    int rejectionRevision = 0,
  }) {
    if (closed) return;
    final instanceChanged = _state != null && _state!.id != state.id;
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
    _hintSource = hintSource;
    _addedBottle = addedBottle;
    if (_motion == null && (instanceChanged || resized || reduceChanged)) {
      _cancel();
    }
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
      final previousLift = _selectionLifts[m.from];
      final returningLifts = List<double>.of(_selectionLifts);
      _cancel();
      for (var i = 0; i < returningLifts.length; i++) {
        if (i != m.from) {
          _selectionLifts[i] = returningLifts[i];
        }
      }
      _initialLift = previousLift;
      _motion = m;
      _elapsed = 0;
      _select();
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

  void _flow(bool value) {
    if (_flowing == value) return;
    _flowing = value;
    if (value) {
      onFlowStart?.call();
    } else {
      onFlowEnd?.call();
    }
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
    final total = boundaries.last;
    // Geometry milliseconds are real presentation time, including the flow.
    final budget = total / 1000;
    late final SequenceEffect effect;
    effect = SequenceEffect(
      [
        for (var i = 0; i < boundaries.length - 1; i++)
          _ProgressEffect((p) {
            _elapsed = boundaries[i] + (boundaries[i + 1] - boundaries[i]) * p;
            _flow(
              _reduced
                  ? _elapsed > 0 && _elapsed < 120
                  : _elapsed >= 290 && _elapsed < 290 + geometry.flowMs,
            );
          }, (boundaries[i + 1] - boundaries[i]) / total * budget),
      ],
      onComplete: () {
        if (closed ||
            !identical(_pourEffect, effect) ||
            _motion == null ||
            _key(_motion!) != _key(m)) {
          return;
        }
        _flow(false);
        _ignored = _key(m);
        _motion = null;
        _pourEffect = null;
        _selectionLifts.fillRange(0, _selectionLifts.length, 0);
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
    _flow(false);
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
    _selectionLifts.fillRange(0, _selectionLifts.length, 0);
    _selectionTarget = null;
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
    if (art == null || _background) return;
    final target =
        _motion == null &&
            !_reduced &&
            _selected != null &&
            _selected! >= 0 &&
            _selected! < _state!.board.length &&
            _state!.board[_selected!].isNotEmpty
        ? _selected
        : null;
    if (_reduced) {
      _selectionEffect?.onComplete = null;
      _selectionEffect?.removeFromParent();
      _selectionEffect = null;
      _selectionTarget = null;
      _selectionLifts.fillRange(0, _selectionLifts.length, 0);
      return;
    }
    if (_selectionEffect != null && _selectionTarget == target) return;
    if (List.generate(
      _selectionLifts.length,
      (i) => (_selectionLifts[i] - (i == target ? 8.0 : 0.0)).abs() < .001,
    ).every((v) => v)) {
      return;
    }
    _selectionEffect?.onComplete = null;
    _selectionEffect?.removeFromParent();
    _selectionTarget = target;
    final from = List<double>.of(_selectionLifts);
    late final _ProgressEffect effect;
    effect = _ProgressEffect(
      (p) {
        final eased = Curves.easeOutCubic.transform(p);
        for (var i = 0; i < from.length; i++) {
          _selectionLifts[i] =
              from[i] + ((i == target ? 8.0 : 0.0) - from[i]) * eased;
        }
      },
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
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (!_publishScheduled) {
        _publishScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _publishScheduled = false;
          _publish();
        });
      }
      return;
    }
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
    if (art != null && !closed && !_background) {
      // An idle game needs an explicit first frame when its inputs change.
      if (paused) stepEngine(stepTime: 0);
      resumeEngine();
    }
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
    if (_motion != null && !closed) {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        if (!_posePublishScheduled) {
          _posePublishScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _posePublishScheduled = false;
            if (!closed) poseTick.value++;
          });
        }
      } else {
        poseTick.value++;
      }
    }
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
    _paintBoard(canvas, BoardPaintLayer.stationary);
  }

  // Flutter places this one moving layer above the fixed native readouts.
  void renderMoving(Canvas canvas) =>
      _paintBoard(canvas, BoardPaintLayer.moving);

  void _paintBoard(Canvas canvas, BoardPaintLayer layer) {
    if (closed || _state == null || _layout == null) return;
    _painter?.paint(
      canvas,
      frame,
      _settings,
      selected: _selected,
      suggested: _suggested,
      hintSource: _hintSource,
      addedBottle: _addedBottle,
      press: _press,
      shaking: _errorEffect == null ? null : _shaking,
      shake: _shake,
      reduced: _reduced,
      layer: layer,
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
      poseTick.dispose();
      artStatus.dispose();
    }
    super.onRemove();
  }
}
