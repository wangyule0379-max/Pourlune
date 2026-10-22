import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/game_controller.dart';
import '../../presentation/bottle.dart';
import '../../presentation/scene_art.dart';
import 'geometry.dart';

class _ValueEffect extends Effect {
  _ValueEffect(this.write, double seconds, {super.onComplete})
    : super(EffectController(duration: seconds));
  final void Function(double) write;
  @override
  void apply(double progress) => write(progress);
}

/// A private, bounded image owner. No global Flame texture cache or network.
abstract class SampleGame extends FlameGame {
  final List<ui.Image> _owned = [];
  bool closed = false, assetsReady = false;
  int updates = 0, renders = 0;
  final status = ValueNotifier<String>('loading');
  int get ownedImages => _owned.length;
  @override
  Color backgroundColor() => Colors.transparent;
  Future<ui.Image?> image(String asset, int width) async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (closed) {
      frame.image.dispose();
      return null;
    }
    _owned.add(frame.image);
    return frame.image;
  }

  void wake() {
    if (assetsReady && !closed) resumeEngine();
  }

  void label(String value) {
    if (!closed && status.value != value) status.value = value;
  }

  void drawImage(
    Canvas canvas,
    ui.Image image,
    Rect rect, {
    double opacity = 1,
  }) => canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    rect,
    Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..filterQuality = FilterQuality.medium,
  );
  @override
  void onRemove() {
    if (!closed) {
      closed = true;
      for (final image in _owned) {
        image.dispose();
      }
      _owned.clear();
      status.dispose();
    }
    super.onRemove();
  }
}

class PourSampleGame extends SampleGame {
  PourSampleGame(this.controller, {this.onFlowStart, this.onFlowEnd}) {
    controller.addListener(_sync);
  }
  final GameController controller;
  final VoidCallback? onFlowStart, onFlowEnd;
  late ui.Image _back, _front;
  PourMotion? _motion;
  SequenceEffect? _pourEffect;
  _ValueEffect? _selectionEffect;
  final List<_ValueEffect?> _pressEffects = [null, null];
  final List<double> _press = [0, 0];
  double _elapsed = 0, _lift = 0, _shake = 0;
  int _shakeIndex = -1, _rejectionRevision = 0;
  _ValueEffect? _errorEffect;
  int? _ignoredToken;
  bool reverse = false,
      _systemReduced = false,
      _sounded = false,
      _flowEnded = false;
  bool get reduced => _systemReduced || controller.settings.reducedMotion;
  BottleShape get shape => BottleShape(math.min(158, size.x * .43));
  List<Offset> get restingMouths => [
    Offset(size.x * .26, 133),
    Offset(size.x * .74, 133),
  ];
  List<int> get indices => reverse ? [2, 0] : [0, 2];
  Rect hitRect(int visible) =>
      shape.imageRect.shift(restingMouths[visible]).inflate(5);
  int get sourceVisible =>
      indices.indexOf(_motion?.from ?? controller.selectedSource ?? 0);
  PourGeometry get geometry => PourGeometry(
    shape: shape,
    sourceMouth: restingMouths[sourceVisible],
    targetMouth: restingMouths[1 - sourceVisible],
    units: _motion!.units,
    sourceUnits: _motion!.before[_motion!.from].length,
    initialLift: _lift,
  );
  @override
  Future<void> onLoad() async {
    final loaded = await Future.wait([
      image('assets/art/bottles/back.png', 512),
      image('assets/art/bottles/front.png', 512),
    ]);
    if (closed) return;
    _back = loaded[0]!;
    _front = loaded[1]!;
    assetsReady = true;
    _sync();
    wake();
  }

  void setSystemReduced(bool value) {
    if (value == _systemReduced) return;
    _systemReduced = value;
    if (reduced && _motion != null) abort(release: true);
    wake();
  }

  void press(int visible, bool down) {
    if (!assetsReady || closed) return;
    _pressEffects[visible]?.removeFromParent();
    final from = _press[visible], to = down && !reduced ? 1.0 : 0.0;
    if ((from - to).abs() < .001) {
      _pressEffects[visible] = null;
      return;
    }
    late final _ValueEffect effect;
    effect = _ValueEffect(
      (t) => _press[visible] =
          from + (to - from) * Curves.easeOutCubic.transform(t),
      down ? .075 : .15,
      onComplete: () {
        if (identical(_pressEffects[visible], effect)) {
          _pressEffects[visible] = null;
        }
      },
    );
    _pressEffects[visible] = effect;
    add(effect);
    wake();
  }

  void _sync() {
    if (closed || !assetsReady) return;
    final m = controller.motion;
    if (controller.rejectionRevision != _rejectionRevision &&
        controller.rejection != null) {
      _rejectionRevision = controller.rejectionRevision;
      _shakeIndex = indices.indexOf(controller.rejectedBottle ?? -1);
      _errorEffect?.removeFromParent();
      late final _ValueEffect effect;
      effect = _ValueEffect(
        (p) => _shake = reduced ? 0 : math.sin(p * math.pi * 4) * 3 * (1 - p),
        .22,
        onComplete: () {
          if (identical(_errorEffect, effect)) {
            _errorEffect = null;
            _shake = 0;
          }
        },
      );
      _errorEffect = effect;
      add(effect);
      label('invalid');
    }
    if (m == null) {
      if (_motion != null) abort();
      _select();
      wake();
      return;
    }
    if (m.token == _ignoredToken) return;
    if (reduced && _motion != null && !(_motion!.reducedMotion)) {
      abort(release: true);
      return;
    }
    if (_motion?.token == m.token) return;
    final selectedLift = _lift;
    abort();
    _lift = selectedLift;
    _motion = m;
    _elapsed = 0;
    _sounded = false;
    _flowEnded = false;
    _selectionEffect?.removeFromParent();
    _selectionEffect = null;
    if (reduced) {
      final effect = _ValueEffect(
        (p) {
          _elapsed = p * 120;
          label('reduced');
        },
        .12,
        onComplete: () => _finish(m),
      );
      _pourEffect = SequenceEffect([effect]);
    } else {
      final g = geometry;
      final boundaries = [
        0.0,
        200.0,
        290.0,
        290 + g.flowMs,
        500 + g.flowMs,
        g.totalMs,
      ];
      _pourEffect = SequenceEffect([
        for (var i = 0; i < boundaries.length - 1; i++)
          _ValueEffect((p) {
            _elapsed = boundaries[i] + (boundaries[i + 1] - boundaries[i]) * p;
          }, (boundaries[i + 1] - boundaries[i]) / 1000),
      ], onComplete: () => _finish(m));
    }
    add(_pourEffect!);
    wake();
  }

  void _select() {
    if (_motion != null) return;
    if (reduced) {
      _selectionEffect?.removeFromParent();
      _selectionEffect = null;
      _lift = 0;
      return;
    }
    final target = controller.selectedSource != null ? 9.0 : 0.0;
    if ((_lift - target).abs() < .01) return;
    _selectionEffect?.removeFromParent();
    final from = _lift;
    late final _ValueEffect effect;
    effect = _ValueEffect(
      (p) => _lift = from + (target - from) * Curves.easeOutCubic.transform(p),
      .13,
      onComplete: () {
        if (identical(_selectionEffect, effect)) _selectionEffect = null;
      },
    );
    _selectionEffect = effect;
    add(effect);
    wake();
  }

  void _finish(PourMotion m) {
    if (closed || _motion?.token != m.token) return;
    _motion = null;
    _pourEffect = null;
    _lift = 0;
    onFlowEnd?.call();
    if (controller.current?.id == m.instanceId &&
        controller.current?.revision == m.revision &&
        controller.motion?.token == m.token) {
      controller.completeMotion(m.token);
    }
    label('idle');
    wake();
  }

  void abort({bool release = false}) {
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
    _shake = 0;
    for (var i = 0; i < _pressEffects.length; i++) {
      _pressEffects[i]?.onComplete = null;
      _pressEffects[i]?.removeFromParent();
      _pressEffects[i] = null;
      _press[i] = 0;
    }
    _motion = null;
    _elapsed = 0;
    _lift = 0;
    onFlowEnd?.call();
    if (release && m != null) {
      _ignoredToken = m.token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!closed &&
            controller.current?.id == m.instanceId &&
            controller.current?.revision == m.revision) {
          controller.completeMotion(m.token);
        }
      });
    }
    if (!closed) label('idle');
  }

  @override
  void lifecycleStateChange(ui.AppLifecycleState state) {
    if (state != ui.AppLifecycleState.resumed) abort(release: true);
    super.lifecycleStateChange(state);
  }

  @override
  void update(double dt) {
    super.update(dt);
    updates++;
    if (_motion != null) {
      if (reduced) {
        if (!_sounded) {
          _sounded = true;
          onFlowStart?.call();
        }
      } else {
        final f = geometry.frame(_elapsed);
        label(f.stage);
        if (!_sounded && f.out > 0) {
          _sounded = true;
          onFlowStart?.call();
        }
        if (_sounded &&
            !_flowEnded &&
            (f.stage == 'return' || f.stage == 'settle')) {
          _flowEnded = true;
          onFlowEnd?.call();
        }
      }
    }
    if (_motion == null &&
        _selectionEffect == null &&
        _pressEffects.every((e) => e == null) &&
        _errorEffect == null &&
        !hasLifecycleEvents) {
      label('idle');
      pauseEngine();
    }
  }

  Map<String, Object?> snapshot() {
    final m = _motion;
    final f = m == null || reduced ? null : geometry.frame(_elapsed);
    return {
      'assetsReady': assetsReady,
      'stage': status.value,
      'elapsed_ms': _elapsed,
      'token': m?.token,
      'invalid_flash': _errorEffect != null,
      'instance': controller.current?.id,
      'revision': controller.current?.revision,
      'source_out': f?.out,
      'target_in': f?.delivered,
      'stream_units': f?.inStream,
      'stream_start': f == null ? null : [f.streamStart.dx, f.streamStart.dy],
      'stream_end': f == null ? null : [f.streamEnd.dx, f.streamEnd.dy],
      'paused': paused,
      'owned_images': ownedImages,
      'updates': updates,
      'renders': renders,
    };
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    renders++;
    if (!assetsReady || closed || controller.current == null) return;
    final state = controller.current!, m = _motion;
    PourFrame? frame;
    if (m != null && !reduced) frame = geometry.frame(_elapsed);
    final amount = m == null
        ? 0.0
        : reduced
        ? m.units.toDouble() * (_elapsed / 120).clamp(0.0, 1.0)
        : frame!.out;
    final delivered = m == null
        ? 0.0
        : reduced
        ? amount
        : frame!.delivered;
    final poses = [
      for (var i = 0; i < 2; i++)
        BottlePose(
          restingMouths[i] +
              Offset(i == _shakeIndex ? _shake : 0, 0) +
              Offset(0, indices[i] == controller.selectedSource ? -_lift : 0),
          0,
          scale: reduced ? 1 : 1 - .035 * _press[i],
        ),
    ];
    if (frame != null) {
      poses[sourceVisible] = frame.source;
      poses[1 - sourceVisible] = frame.target;
    }
    for (var i = 0; i < 2; i++) {
      final shadow = Rect.fromCenter(
        center: Offset(
          restingMouths[i].dx,
          restingMouths[i].dy + shape.height * .77,
        ),
        width: shape.width * .62,
        height: 10,
      );
      canvas.drawOval(
        shadow,
        Paint()
          ..color = ink.withValues(
            alpha: i == sourceVisible && m != null ? .09 : .16,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    final order = m == null ? [0, 1] : [1 - sourceVisible, sourceVisible];
    for (final i in order) {
      final index = indices[i];
      final before = m?.before[index] ?? state.board[index];
      final bands = <LiquidBand>[
        for (final c in before) (color: c, units: 1.0),
      ];
      if (m != null && index == m.from) {
        var remaining = amount;
        while (remaining > 0 && bands.isNotEmpty) {
          final last = bands.removeLast();
          if (last.units > remaining) {
            bands.add((color: last.color, units: last.units - remaining));
            break;
          }
          remaining -= last.units;
        }
      } else if (m != null && index == m.to && delivered > 0) {
        bands.add((color: m.before[m.from].last, units: delivered));
      }
      _bottle(
        canvas,
        poses[i],
        bands,
        highlight:
            controller.selectedSource == index ||
            reduced && m != null ||
            _errorEffect != null && i == _shakeIndex,
        wave: frame?.stage == 'settle'
            ? math.sin((_elapsed - (500 + geometry.flowMs)) / 100 * math.pi)
            : 0,
      );
    }
    if (frame != null && frame.inStream > .000001) {
      final top = Offset.lerp(
        frame.streamStart,
        frame.streamEnd,
        frame.streamTail,
      )!;
      final bottom = Offset.lerp(
        frame.streamStart,
        frame.streamEnd,
        frame.streamHead,
      )!;
      final color = liquidColors[m!.before[m.from].last]!;
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + 1.2,
          (top.dy + bottom.dy) / 2,
          bottom.dx,
          bottom.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.8 + m.units * .35,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
      for (var n = 0; n < 3; n++) {
        final p = ((_elapsed / 95 + n * .31) % 1);
        final point = Offset.lerp(top, bottom, p)!;
        canvas.drawCircle(
          point,
          .65,
          Paint()..color = Colors.white.withValues(alpha: .45),
        );
      }
    }
  }

  void _bottle(
    Canvas canvas,
    BottlePose pose,
    List<LiquidBand> bands, {
    required bool highlight,
    double wave = 0,
  }) {
    void layer(ui.Image image) {
      canvas.save();
      canvas.translate(pose.mouth.dx, pose.mouth.dy);
      canvas.rotate(pose.angle);
      canvas.scale(pose.scale);
      drawImage(canvas, image, shape.imageRect);
      canvas.restore();
    }

    layer(_back);
    final hull = shape.worldHull(pose), path = Path()..addPolygon(hull, true);
    canvas.save();
    canvas.clipPath(path);
    var cumulative = 0.0;
    var bottom = hull.map((p) => p.dy).reduce(math.max);
    final left = hull.map((p) => p.dx).reduce(math.min),
        right = hull.map((p) => p.dx).reduce(math.max);
    final merged = <LiquidBand>[];
    for (final band in bands) {
      if (band.units <= .000001) continue;
      if (merged.isNotEmpty && merged.last.color == band.color) {
        final last = merged.removeLast();
        merged.add((color: band.color, units: last.units + band.units));
      } else {
        merged.add(band);
      }
    }
    for (final band in merged) {
      cumulative += band.units;
      final top = waterline(
        hull,
        cumulative * shape.unitArea * pose.scale * pose.scale,
      );
      final rect = Rect.fromLTRB(left - 1, top, right + 1, bottom + .2);
      final color = liquidColors[band.color]!;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bottom), [
            Color.lerp(color, Colors.white, .13)!,
            color,
          ]),
      );
      if (controller.settings.colorSymbols && band.units > .5) {
        final center = Offset((left + right) / 2, (top + bottom) / 2);
        final paint = Paint()
          ..color = ink.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
        if (band.color == 'O') {
          canvas.drawCircle(center, 3.3, paint);
        } else {
          canvas.drawPath(
            Path()
              ..moveTo(center.dx, center.dy - 4)
              ..lineTo(center.dx + 4, center.dy + 3)
              ..lineTo(center.dx - 4, center.dy + 3)
              ..close(),
            paint,
          );
        }
      }
      bottom = top;
    }
    if (bands.isNotEmpty) {
      final line = Path()
        ..moveTo(left, bottom)
        ..cubicTo(
          left + (right - left) * .3,
          bottom - 1.1 * wave,
          left + (right - left) * .7,
          bottom + 1.1 * wave,
          right,
          bottom,
        );
      canvas.drawPath(
        line,
        Paint()
          ..color = Colors.white.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
    layer(_front);
    for (var u = 1; u <= 4; u++) {
      final y = waterline(shape.interior, u * shape.unitArea);
      canvas.drawLine(
        pose.transform(Offset(shape.width * .165, y)),
        pose.transform(Offset(shape.width * .205, y)),
        Paint()
          ..color = ink.withValues(alpha: .45)
          ..strokeWidth = .8,
      );
    }
    if (highlight) {
      canvas.drawCircle(
        pose.transform(Offset(0, shape.height * .76)),
        3,
        Paint()..color = ink,
      );
    }
  }

  @override
  void onRemove() {
    if (!closed) {
      controller.removeListener(_sync);
      abort();
      _selectionEffect?.removeFromParent();
      _errorEffect?.removeFromParent();
      for (final e in _pressEffects) {
        e?.removeFromParent();
      }
    }
    super.onRemove();
  }
}

class PatchSampleGame extends SampleGame {
  PatchSampleGame(this.controller, {this.onFlightStart, this.onFlightEnd}) {
    controller.addListener(_sync);
  }
  final GameController controller;
  final VoidCallback? onFlightStart, onFlightEnd;
  late ui.Image _base, _piece;
  SequenceEffect? _flight;
  double _progress = 1, _response = 0;
  String? _reservedInstance;
  int? _reservedRevision;
  int _reservation = 0;
  bool _waiting = false, _systemReduced = false;
  bool get active => _waiting || _flight != null;
  // The sample-wide preference (plus OS preference) is supplied by MediaQuery.
  bool get reduced => _systemReduced;
  Rect get sceneRect {
    final w = math.min(size.x - 24, 300.0);
    return Rect.fromLTWH((size.x - w) / 2, 112, w, w);
  }

  Rect get targetRect {
    final n = sceneObjectRects['color_studio']!.first, r = sceneRect;
    final slot = Rect.fromLTWH(
      r.left + n.left * r.width,
      r.top + n.top * r.height,
      n.width * r.width,
      n.height * r.height,
    );
    // Existing SceneArt uses BoxFit.contain for this square PNG.
    final edge = math.min(slot.width, slot.height);
    return Rect.fromCenter(center: slot.center, width: edge, height: edge);
  }

  @override
  Future<void> onLoad() async {
    final loaded = await Future.wait([
      image('assets/art/scenes/color_studio/base.png', 1024),
      image('assets/art/scenes/color_studio/piece-1.png', 512),
    ]);
    if (closed) return;
    _base = loaded[0]!;
    _piece = loaded[1]!;
    assetsReady = true;
    label('idle');
    wake();
  }

  void setSystemReduced(bool value) {
    if (value == _systemReduced) return;
    _systemReduced = value;
    if (reduced && active) cancel();
    wake();
  }

  int reserve() {
    final reservation = ++_reservation;
    _reservedInstance = controller.current?.id;
    _reservedRevision = controller.current?.revision;
    _waiting = true;
    _progress = 0;
    label('saving');
    wake();
    return reservation;
  }

  bool get _valid =>
      controller.current?.id == _reservedInstance &&
      controller.current?.revision == _reservedRevision &&
      controller.phase == SavePhase.clean &&
      controller.progress.revealedPieces.contains('color_studio:1');
  void fly(int reservation) {
    if (closed || !_waiting || reservation != _reservation || !_valid) {
      cancel();
      return;
    }
    _waiting = false;
    _progress = 0;
    _flight?.onComplete = null;
    _flight?.removeFromParent();
    onFlightStart?.call();
    _response = 0;
    label(reduced ? 'reduced' : 'flight');
    late final SequenceEffect effect;
    effect = SequenceEffect(
      [
        _ValueEffect((p) {
          _progress = p;
          label(reduced ? 'reduced' : 'flight');
        }, reduced ? .12 : .85),
        if (!reduced)
          _ValueEffect((p) {
            _progress = 1;
            _response = p;
            label('attach');
          }, .16),
      ],
      onComplete: () {
        if (identical(_flight, effect)) {
          _flight = null;
          _progress = 1;
          _response = 0;
          label('placed');
          onFlightEnd?.call();
        }
      },
    );
    _flight = effect;
    add(effect);
    wake();
  }

  void cancel() {
    _reservation++;
    _reservedInstance = null;
    _reservedRevision = null;
    _waiting = false;
    _response = 0;
    _flight?.onComplete = null;
    _flight?.removeFromParent();
    _flight = null;
    _progress = controller.progress.revealedPieces.contains('color_studio:1')
        ? 1
        : 0;
    onFlightEnd?.call();
    if (!closed) label('idle');
    wake();
  }

  void _sync() {
    if (closed) return;
    if (active &&
        (controller.current?.id != _reservedInstance ||
            controller.current?.revision != _reservedRevision)) {
      cancel();
    }
    wake();
  }

  @override
  void lifecycleStateChange(ui.AppLifecycleState state) {
    if (state != ui.AppLifecycleState.resumed) cancel();
    super.lifecycleStateChange(state);
  }

  @override
  void update(double dt) {
    super.update(dt);
    updates++;
    if (_flight == null && !hasLifecycleEvents) pauseEngine();
  }

  Map<String, Object?> snapshot() => {
    'stage': status.value,
    'scene_response': _response,
    'progress': active
        ? _progress
        : controller.progress.revealedPieces.contains('color_studio:1')
        ? 1.0
        : 0.0,
    'waiting_for_save': _waiting,
    'active': active,
    'paused': paused,
    'owned_images': ownedImages,
    'updates': updates,
    'renders': renders,
    'piece': 'color_studio:1',
    'first_clears': controller.progress.firstClears,
    'receipts': controller.progress.receipts,
    'revealed': controller.progress.revealedPieces,
  };
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    renders++;
    if (!assetsReady || closed) return;
    drawImage(canvas, _base, sceneRect);
    final saved = controller.progress.pieces.contains('color_studio:1');
    if (!saved) return;
    final revealed = controller.progress.revealedPieces.contains(
      'color_studio:1',
    );
    if (!active && revealed) {
      drawImage(canvas, _piece, targetRect);
      return;
    }
    final p =
            (active
                    ? _progress
                    : revealed
                    ? 1.0
                    : 0.0)
                .clamp(0.0, 1.0),
        ease = Curves.easeInOutCubic.transform(p);
    final start = Offset(size.x * .74, 80),
        end = targetRect.center,
        control = Offset(size.x * .16, 70);
    final shortFeedback = reduced && active && revealed;
    final center = shortFeedback
        ? end
        : start * ((1 - ease) * (1 - ease)) +
              control * (2 * (1 - ease) * ease) +
              end * (ease * ease);
    final scale = shortFeedback ? 1.0 : 1.18 - .18 * ease;
    final rect = Rect.fromCenter(
      center: center,
      width: targetRect.width * scale,
      height: targetRect.height * scale,
    );
    if (active && !reduced && _response > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          targetRect.inflate(3),
          const Radius.circular(8),
        ),
        Paint()
          ..color = cream.withValues(alpha: .32 * math.sin(_response * math.pi))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(reduced ? 0 : -.13 * math.sin(p * math.pi));
    canvas.translate(-center.dx, -center.dy);
    drawImage(canvas, _piece, rect, opacity: shortFeedback ? p : 1);
    canvas.restore();
  }

  @override
  void onRemove() {
    if (!closed) {
      controller.removeListener(_sync);
      cancel();
    }
    super.onRemove();
  }
}
