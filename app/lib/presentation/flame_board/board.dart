import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../../application/game_controller.dart';
import '../../data/player_settings.dart';
import '../../l10n/app_localizations.dart';
import '../bottle.dart' show ink;
import '../bottle_foot_label.dart';
import '../labels.dart' show colorLabel;
import 'readout_dock.dart';
import 'game.dart';
import 'geometry.dart';

/// Flutter owns text, hit targets, focus and semantics. Flame receives no input
/// callbacks, and this widget never owns a controller/presenter or writes state.
class FlameBoard extends StatefulWidget {
  const FlameBoard({
    super.key,
    required this.state,
    required this.selected,
    required this.onTap,
    this.suggested,
    this.hintSource,
    this.addedBottle,
    this.settings = const PlayerSettings(),
    this.keyPrefix = 'bottle',
    this.motion,
    this.onMotionComplete,
    this.onFlowStart,
    this.onFlowEnd,
    this.rejectedBottle,
    this.rejectionRevision = 0,
    this.preview = false,
  });
  final GameInstance state;
  final int? selected, suggested, hintSource, rejectedBottle, addedBottle;
  final ValueChanged<int>? onTap, onMotionComplete;
  final VoidCallback? onFlowStart, onFlowEnd;
  final PlayerSettings settings;
  final String keyPrefix;
  final PourMotion? motion;
  final int rejectionRevision;
  final bool preview;
  @override
  State<FlameBoard> createState() => _FlameBoardState();
}

class _FlameBoardState extends State<FlameBoard> {
  late FlameBoardGame game;
  final states = List.generate(8, (_) => WidgetStatesController());
  @override
  void initState() {
    super.initState();
    game = _newGame();
    for (var i = 0; i < states.length; i++) {
      states[i].addListener(
        () => game.press(i, states[i].value.contains(WidgetState.pressed)),
      );
    }
  }

  FlameBoardGame _newGame() => FlameBoardGame(
    onFlowStart: () => widget.onFlowStart?.call(),
    onFlowEnd: () => widget.onFlowEnd?.call(),
    onMotionComplete: (token) {
      if (mounted) widget.onMotionComplete?.call(token);
    },
  );

  @override
  void dispose() {
    for (final state in states) {
      state.dispose();
    }
    super.dispose();
  }

  void tap(int index) {
    if (widget.onTap == null ||
        game.artStatus.value != BoardArtStatus.ready ||
        game.frame.active != null) {
      return;
    }
    if (widget.settings.haptics) unawaited(HapticFeedback.selectionClick());
    widget.onTap!(index);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = widget, l = AppLocalizations.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final capacityWidth = ReadoutDock.capacityWidth(context);
      final ordinaryColumns = math.min(
        w.state.board.length,
        math.max(1, ((box.maxWidth + 4) / (capacityWidth + 8)).floor()),
      );
      final ordinaryRows = (w.state.board.length / ordinaryColumns).ceil();
      final targetSize = w.settings.colorSymbols
          ? 28.0
          : math.max(28.0, scaler.scale(12) + 6);
      final ordinaryRowHeight =
          math.max(34, targetSize) +
          scaler.scale(12) * 1.2 +
          scaler.scale(14) * 1.2 +
          8;
      final ordinaryDockHeight =
          ordinaryRows * ordinaryRowHeight + (ordinaryRows - 1) * 4;
      final labelHeight =
          math.max(34, scaler.scale(12) + 12) + 3 + scaler.scale(14) * 1.2 + 1;
      final denseDock =
          !w.preview &&
          (scaler.scale(14) > 28 ||
              box.maxHeight <
                  ordinaryDockHeight + 2 * (48 + labelHeight + 5) + 28);
      final columns = denseDock
          ? math.min(
              w.state.board.length,
              math.max(
                1,
                ((box.maxWidth + 4) /
                        (ReadoutDock.denseWidth(context, targetSize) + 8))
                    .floor(),
              ),
            )
          : ordinaryColumns;
      final rows = (w.state.board.length / columns).ceil();
      final rowHeight = denseDock
          ? math.max(scaler.scale(12) * 1.2, targetSize) +
                scaler.scale(14) * 1.2 +
                2
          : ordinaryRowHeight;
      // Only the existing large-text fallback needs a permanent readout area.
      // Ordinary play keeps labels at each bottle, including during a pour.
      final dockHeight = denseDock ? rows * rowHeight + (rows - 1) * 4 : 0.0;
      final layout = BoardLayout(
        width: box.maxWidth,
        maxHeight: math.max(0, box.maxHeight - dockHeight),
        count: w.state.board.length,
        textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
        preview: w.preview,
        footLabels: !denseDock,
        targetCount:
            w.state.puzzle.targets.lastIndexWhere((t) => t != null) + 1,
      );
      // Reconcile all inputs atomically before building controls. The game
      // defers notifier publication during layout, rather than its state.
      game.show(
        state: w.state,
        layout: layout,
        settings: w.settings,
        systemReduced: MediaQuery.disableAnimationsOf(context),
        motion: w.motion,
        selected: w.selected,
        suggested: w.suggested,
        hintSource: w.hintSource,
        addedBottle: w.addedBottle,
        rejectedBottle: w.rejectedBottle,
        rejectionRevision: w.rejectionRevision,
      );
      final board = SizedBox(
        key: const Key('dock-canvas'),
        width: box.maxWidth,
        height: layout.height,
        child: AnimatedBuilder(
          animation: Listenable.merge([game.visual, game.artStatus]),
          child: ClipRect(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: GameWidget<FlameBoardGame>(
                  key: ObjectKey(game),
                  game: game,
                  autofocus: false,
                  errorBuilder: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          builder: (context, canvas) {
            final visual = game.frame;
            final canTap =
                w.onTap != null &&
                game.artStatus.value == BoardArtStatus.ready &&
                game.frame.active == null;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: canvas!),
                for (var i = 0; i < w.state.board.length; i++)
                  Positioned.fromRect(
                    rect: w.preview ? layout.cells[i] : layout.hitRect(i),
                    child: Semantics(
                      label:
                          '${l.bottleSemantics(i + 1, i < w.state.puzzle.targets.length && w.state.puzzle.targets[i] != null ? l.targetLabel(colorLabel(l, w.state.puzzle.targets[i]!)) : l.bufferLabel, visual.contents[i].isEmpty ? l.emptyLabel : l.contentsLabel(visual.contents[i].map((c) => colorLabel(l, c)).join(', ')), visual.counts[i])}${w.hintSource == i ? ' ${l.suggestedSource}' : ''}${w.suggested == i ? ' ${l.suggestedTarget}' : ''}',
                      button: !w.preview,
                      enabled: canTap,
                      selected: w.selected == i,
                      onTap: canTap ? () => tap(i) : null,
                      child: ExcludeSemantics(
                        child: OutlinedButton(
                          key: Key('${w.keyPrefix}-$i'),
                          statesController: states[i],
                          onPressed: canTap ? () => tap(i) : null,
                          style:
                              OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                overlayColor: Colors.transparent,
                                splashFactory: NoSplash.splashFactory,
                                side: BorderSide.none,
                              ).copyWith(
                                side: WidgetStateProperty.resolveWith(
                                  (s) => s.contains(WidgetState.focused)
                                      ? const BorderSide(color: ink, width: 1.5)
                                      : BorderSide.none,
                                ),
                                backgroundBuilder: (_, _, child) => child!,
                              ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                if (game.artStatus.value == BoardArtStatus.failed)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: const Text('Could not load bottle art.'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => game = _newGame()),
                            child: Text(l.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!denseDock)
                  for (var i = 0; i < w.state.board.length; i++)
                    Positioned.fromRect(
                      rect: layout.labelRect(i),
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: BottleFootLabel(
                            index: i,
                            target: i < w.state.puzzle.targets.length
                                ? w.state.puzzle.targets[i]
                                : null,
                            count: visual.counts[i],
                            prefix: w.keyPrefix,
                            symbolsEnabled: w.settings.colorSymbols,
                            strongContrast: w.settings.strongContrast,
                          ),
                        ),
                      ),
                    ),
                Positioned.fill(
                  child: ClipRect(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _MovingBottleLayer(game)),
                    ),
                  ),
                ),
                if (denseDock)
                  if (visual.active case final active?)
                    AnimatedBuilder(
                      animation: game.poseTick,
                      builder: (context, _) => Positioned(
                        left: (game.frame.poses[active.from].mouth.dx - 22)
                            .clamp(0.0, math.max(0, box.maxWidth - 44)),
                        top: (game.frame.poses[active.from].mouth.dy - 48)
                            .clamp(0.0, math.max(0, layout.height - 44)),
                        child: ExcludeSemantics(
                          child: DecoratedBox(
                            key: const Key('dock-moving-index'),
                            decoration: BoxDecoration(
                              color: const Color(0xfffff9ed),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ink, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              child: Text(
                                '${active.from + 1}',
                                style: dockNumberStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      );
      // Keep the same widget ancestry on resize/text changes: removing a
      // GameWidget disposes its Flame game and its visual notifiers.
      return KeyedSubtree(
        key: const Key('board-accessibility-viewport'),
        child: SingleChildScrollView(
          key: PageStorageKey('board-viewport-${w.state.id}'),
          child: Column(
            children: [
              board,
              if (denseDock)
                SizedBox(
                  height: dockHeight,
                  child: ValueListenableBuilder(
                    valueListenable: game.visual,
                    builder: (context, _, _) {
                      final frame = game.frame;
                      return ReadoutDock(
                        state: frame.state,
                        frame: frame,
                        settings: w.settings,
                        prefix: w.keyPrefix,
                        columns: columns,
                        rowHeight: rowHeight,
                        dense: denseDock,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _MovingBottleLayer extends CustomPainter {
  _MovingBottleLayer(this.game) : super(repaint: game.poseTick);
  final FlameBoardGame game;
  @override
  void paint(Canvas canvas, Size size) => game.renderMoving(canvas);
  @override
  bool shouldRepaint(_MovingBottleLayer old) => old.game != game;
}
