import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../data/player_settings.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'labels.dart';
import 'knit_components.dart';

bool _hasLegalMove(Board board) {
  for (var from = 0; from < board.length; from++) {
    for (var to = 0; to < board.length; to++) {
      if (pourBoard(board, from, to).units > 0) return true;
    }
  }
  return false;
}

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.selected,
    required this.onTap,
    this.suggested,
    this.settings = const PlayerSettings(),
    this.keyPrefix = 'bottle',
    this.motion,
    this.onMotionComplete,
    this.rejectedBottle,
    this.rejectionRevision = 0,
  });
  final GameInstance state;
  final int? selected, suggested, rejectedBottle;
  final void Function(int)? onTap;
  final PlayerSettings settings;
  final String keyPrefix;
  final PourMotion? motion;
  final void Function(int)? onMotionComplete;
  final int rejectionRevision;
  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with TickerProviderStateMixin {
  bool _systemReduced = false;
  bool get _reduced =>
      _systemReduced ||
      widget.settings.reducedMotion ||
      (widget.motion?.reducedMotion ?? false);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _systemReduced) {
      _systemReduced = reduced;
      _startPour();
    }
  }

  late final AnimationController _pour = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.motion != null) {
        widget.onMotionComplete?.call(widget.motion!.token);
      }
    });
  late final AnimationController _error = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  @override
  void initState() {
    super.initState();
    _startPour();
  }

  void _startPour() {
    final motion = widget.motion;
    if (motion == null) {
      _pour.stop();
    } else {
      _pour.duration = _reduced
          ? const Duration(milliseconds: 180)
          : motion.duration;
      _pour.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion?.token != widget.motion?.token ||
        oldWidget.settings.reducedMotion != widget.settings.reducedMotion) {
      _startPour();
    }
    if (oldWidget.rejectionRevision != widget.rejectionRevision) {
      _error.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pour.dispose();
    _error.dispose();
    super.dispose();
  }

  List<LiquidBand> _liquid(int index, double amount) {
    final m = widget.motion!;
    final bands = <LiquidBand>[
      for (final color in m.before[index]) (color: color, units: 1.0),
    ];
    if (index == m.from) {
      var remaining = amount;
      while (remaining > 0 && bands.isNotEmpty) {
        final last = bands.removeLast();
        if (last.units > remaining) {
          bands.add((color: last.color, units: last.units - remaining));
          break;
        }
        remaining -= last.units;
      }
    } else if (index == m.to && amount > 0) {
      bands.add((color: m.before[m.from].last, units: amount));
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, l = AppLocalizations.of(context), board = w.state.board;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, box) {
          final width = ((box.maxWidth - 24) / 4).clamp(48.0, 84.0);
          final rows = board.length == 4
              ? [2, 2]
              : board.length == 5
              ? [3, 2]
              : board.length == 6
              ? [3, 3]
              : [4, 3];
          final positions = <Offset>[];
          for (var row = 0; row < rows.length; row++) {
            for (var column = 0; column < rows[row]; column++) {
              positions.add(
                Offset(
                  (box.maxWidth - rows[row] * (width + 6)) / 2 +
                      column * (width + 6) +
                      3,
                  row * 184.0,
                ),
              );
            }
          }
          return AnimatedBuilder(
            animation: Listenable.merge([_pour, _error]),
            builder: (context, _) {
              final m = w.motion, t = _pour.value;
              final flow = ((t - .28) / .46).clamp(0.0, 1.0);
              final returning = t < .78
                  ? 1.0
                  : 1 - Curves.easeInOut.transform((t - .78) / .22);
              final envelope = t < .10
                  ? 0.0
                  : t < .28
                  ? Curves.easeInOut.transform((t - .10) / .18)
                  : returning;
              final liftEnvelope = t < .10
                  ? Curves.easeOut.transform(t / .10)
                  : returning;
              final direction =
                  m == null || positions[m.to].dx >= positions[m.from].dx
                  ? 1.0
                  : -1.0;
              final angle = m == null || _reduced
                  ? 0.0
                  : direction * 1.05 * envelope;
              final travel = m == null || _reduced
                  ? Offset.zero
                  : (positions[m.to] -
                            positions[m.from] +
                            Offset(-direction * 52, -85)) *
                        envelope;
              final lift = m == null || _reduced ? 0.0 : 14 * liftEnvelope;
              var offset = 0;
              Widget bottle(int i) => AnimatedContainer(
                duration: Duration(milliseconds: _reduced ? 80 : 140),
                transform: Matrix4.translationValues(
                  0,
                  w.selected == i && !_reduced ? -8 : 0,
                  0,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(
                    w.rejectedBottle == i && !_reduced
                        ? math.sin(_error.value * math.pi * 6) *
                              4 *
                              (1 - _error.value)
                        : 0,
                    0,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: w.rejectedBottle == i && _error.isAnimating
                          ? Border.all(color: ink, width: 2)
                          : null,
                    ),
                    child: BottleButton(
                      key: Key('${w.keyPrefix}-$i'),
                      index: i,
                      liquid: board[i],
                      visualLiquid: m == null
                          ? null
                          : _liquid(i, m.units * flow),
                      angle: i == m?.from ? angle : 0,
                      lift: i == m?.from ? lift : 0,
                      target: i < w.state.puzzle.targets.length
                          ? w.state.puzzle.targets[i]
                          : null,
                      selected:
                          w.selected == i ||
                          (m != null && _reduced && (i == m.from || i == m.to)),
                      suggested: w.suggested == i,
                      width: width,
                      showSymbols: w.settings.colorSymbols,
                      strongContrast: w.settings.strongContrast,
                      semanticLabel:
                          '${l.bottleSemantics(i + 1, i < w.state.puzzle.targets.length && w.state.puzzle.targets[i] != null ? l.targetLabel(colorLabel(l, w.state.puzzle.targets[i]!)) : l.bufferLabel, board[i].isEmpty ? l.emptyLabel : l.contentsLabel(board[i].map((c) => colorLabel(l, c)).join(', ')), board[i].length)}${w.suggested == i ? ' ${l.suggestedTarget}' : ''}',
                      onTap: w.onTap == null
                          ? null
                          : () {
                              if (w.settings.haptics) {
                                HapticFeedback.selectionClick();
                              }
                              w.onTap!(i);
                            },
                    ),
                  ),
                ),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      for (final n in rows)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final i in List.generate(n, (_) => offset++))
                              if (i == m?.from)
                                SizedBox(width: width + 6, height: 184)
                              else
                                bottle(i),
                          ],
                        ),
                    ],
                  ),
                  if (m != null && !_reduced && t > .28 && t < .76)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _StreamPainter(
                            from:
                                positions[m.from] +
                                travel +
                                Offset(
                                  width / 2 + math.sin(angle) * 60,
                                  84 - math.cos(angle) * 60 - lift,
                                ),
                            to: positions[m.to] + Offset(width / 2, 24),
                            color: liquidColors[m.before[m.from].last]!,
                            progress: flow,
                          ),
                        ),
                      ),
                    ),
                  if (m != null)
                    Positioned(
                      left: positions[m.from].dx - 3 + travel.dx,
                      top: positions[m.from].dy + travel.dy,
                      child: bottle(m.from),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StreamPainter extends CustomPainter {
  const _StreamPainter({
    required this.from,
    required this.to,
    required this.color,
    required this.progress,
  });
  final Offset from, to;
  final Color color;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, from.dy + 20, to.dx, to.dy - 24, to.dx, to.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5,
    );
    canvas.drawCircle(
      Offset(to.dx, to.dy + math.sin(progress * math.pi * 8) * 2),
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _StreamPainter old) =>
      old.from != from ||
      old.to != to ||
      old.progress != progress ||
      old.color != color;
}

class BoardPage extends StatefulWidget {
  const BoardPage({
    super.key,
    required this.controller,
    required this.onRestart,
    required this.onPause,
  });
  final GameController controller;
  final VoidCallback onRestart, onPause;
  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.attachMotionPresenter();
  }

  @override
  void didUpdateWidget(covariant BoardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detachMotionPresenter();
      widget.controller.attachMotionPresenter();
    }
  }

  @override
  void dispose() {
    widget.controller.detachMotionPresenter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller,
        s = c.current!,
        l = AppLocalizations.of(context),
        lesson = s.tutorial;
    final suggestion = c.hint?.move;
    final noMoves = !s.completed && !_hasLegalMove(s.board);
    final unmatched =
        s.board
            .where((b) => b.isNotEmpty)
            .every((b) => b.toSet().length == 1) &&
        !s.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KnitHeader(
          title: s.slot == 'daily'
              ? l.dailyPuzzle
              : s.isReplay
              ? l.replayLevel(s.puzzle.mainLevel!)
              : l.level(s.puzzle.mainLevel!),
          onBack: c.phase == SavePhase.saving ? null : c.goHome,
          backKey: const Key('home'),
          trailing: KnitIconButton(
            key: const Key('pause'),
            icon: Icons.pause_rounded,
            label: l.pause,
            onPressed: c.phase == SavePhase.saving
                ? null
                : () {
                    final token = c.motion?.token;
                    if (token != null) c.completeMotion(token);
                    widget.onPause();
                  },
          ),
        ),
        if (lesson?.active ?? false)
          KnitPanel(
            child: Column(
              children: [
                Text(
                  l.lessonTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  l.lessonAction(
                    lesson!.step + 1,
                    s.tutorialLength,
                    s.puzzle.referenceMoves[lesson.step].from + 1,
                    s.puzzle.referenceMoves[lesson.step].to + 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l.rulesTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
        BoardView(
          state: s,
          selected: c.selectedSource,
          suggested: suggestion?.to,
          settings: c.settings,
          motion: c.motion,
          onMotionComplete: c.completeMotion,
          rejectedBottle: c.rejectedBottle,
          rejectionRevision: c.rejectionRevision,
          onTap: c.busy ? null : c.tapBottle,
        ),
        if (unmatched) Text(l.matchLabels),
        if (c.rejection != null)
          Semantics(
            liveRegion: true,
            child: Text(rejectionLabel(l, c.rejection!)),
          ),
        if (noMoves && !c.hintSearching && c.hint?.status != HintStatus.noMoves)
          KnitPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [Text(l.noMoves), Text(l.noMovesBody)]),
            ),
          ),
        if (c.hintSearching)
          KnitPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Semantics(liveRegion: true, child: Text(l.searchingHint)),
                  TextButton(
                    key: const Key('cancel-hint'),
                    onPressed: c.cancelHint,
                    child: Text(l.cancelHint),
                  ),
                ],
              ),
            ),
          )
        else if (c.hint != null)
          KnitPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(hintLabel(l, c.hint!)),
                  ),
                  if (suggestion != null)
                    Text(
                      l.hintReason(
                        colorLabel(l, s.board[suggestion.from].last),
                      ),
                    ),
                  TextButton(
                    key: const Key('cancel-hint'),
                    onPressed: c.cancelHint,
                    child: Text(l.cancelHint),
                  ),
                ],
              ),
            ),
          ),
        if (lesson?.active ?? false)
          TextButton(
            key: const Key('skip-tutorial'),
            onPressed: c.busy ? null : c.skipTutorial,
            child: Text(l.skip),
          ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final labels = <(String, IconData, String, VoidCallback?)>[
              (
                'undo',
                Icons.undo_rounded,
                l.undo,
                c.busy || s.history.isEmpty ? null : c.undo,
              ),
              if (!(lesson?.active ?? false))
                (
                  'hint',
                  Icons.lightbulb_outline_rounded,
                  l.hint,
                  c.busy || c.hintSearching ? null : c.requestHint,
                ),
              (
                'restart',
                Icons.replay_rounded,
                l.restart,
                c.busy ? null : widget.onRestart,
              ),
            ];
            final largeText = MediaQuery.textScalerOf(context).scale(18) > 26;
            final columns = largeText ? 2 : labels.length;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final item in labels)
                  SizedBox(
                    width: (box.maxWidth - (columns - 1) * 8) / columns,
                    child: OutlinedButton(
                      key: Key(item.$1),
                      onPressed: item.$4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.$2, size: 28),
                          const SizedBox(height: 3),
                          Text(item.$3, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          s.slot == 'daily'
              ? '${s.puzzleDate} · ${s.moveCount}'
              : l.levelMoves(s.puzzle.mainLevel!, s.moveCount),
          key: const Key('move-count'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          l.goal,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (kDebugMode)
          ExpansionTile(
            title: const Text('Board diagnostics'),
            children: [
              Text(
                '${s.puzzle.id} · v${s.puzzle.contentVersion} · revision ${s.revision} · ${s.id}',
              ),
            ],
          ),
        if (c.library.engineering)
          Text(l.drawingNotice, style: Theme.of(context).textTheme.bodySmall),
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(
              key: const Key('fail-next'),
              onPressed: c.busy ? null : c.failNextWrite,
              child: Text(
                c.store.fault == null
                    ? 'Development: fail next disk write'
                    : 'Development: failure armed',
              ),
            ),
          ),
      ],
    );
  }
}
