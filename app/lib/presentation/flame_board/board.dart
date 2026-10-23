import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../../application/game_controller.dart';
import '../../data/player_settings.dart';
import '../../l10n/app_localizations.dart';
import '../bottle.dart' show ink, cream, liquidColors, symbols;
import '../labels.dart' show colorLabel;
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
    this.settings = const PlayerSettings(),
    this.keyPrefix = 'bottle',
    this.motion,
    this.onMotionComplete,
    this.rejectedBottle,
    this.rejectionRevision = 0,
    this.preview = false,
  });
  final GameInstance state;
  final int? selected, suggested, rejectedBottle;
  final ValueChanged<int>? onTap, onMotionComplete;
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
  final states = List.generate(7, (_) => WidgetStatesController());
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
      final layout = BoardLayout(
        width: box.maxWidth,
        maxHeight: box.maxHeight,
        count: w.state.board.length,
        textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
        preview: w.preview,
      );
      game.show(
        state: w.state,
        layout: layout,
        settings: w.settings,
        systemReduced: MediaQuery.disableAnimationsOf(context),
        motion: w.motion,
        selected: w.selected,
        suggested: w.suggested,
        rejectedBottle: w.rejectedBottle,
        rejectionRevision: w.rejectionRevision,
      );
      final board = SizedBox(
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
            final visual = game.visual.value ?? game.frame;
            final canTap =
                w.onTap != null &&
                game.artStatus.value == BoardArtStatus.ready &&
                game.frame.active == null;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: canvas!),
                for (var i = 0; i < w.state.board.length; i++)
                  Positioned(
                    left: layout.cells[i].left,
                    top: layout.cells[i].top,
                    width: layout.cells[i].width,
                    height: layout.shape.height,
                    child: Semantics(
                      label:
                          '${l.bottleSemantics(i + 1, i < w.state.puzzle.targets.length && w.state.puzzle.targets[i] != null ? l.targetLabel(colorLabel(l, w.state.puzzle.targets[i]!)) : l.bufferLabel, visual.contents[i].isEmpty ? l.emptyLabel : l.contentsLabel(visual.contents[i].map((c) => colorLabel(l, c)).join(', ')), visual.counts[i])}${w.suggested == i ? ' ${l.suggestedTarget}' : ''}',
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
                for (var i = 0; i < w.state.board.length; i++)
                  Positioned.fromRect(
                    rect: layout.labelRect(i),
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: _CapacityLabel(
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
          child: board,
        ),
      );
    },
  );
}

class _CapacityLabel extends StatelessWidget {
  const _CapacityLabel({
    required this.index,
    required this.target,
    required this.count,
    required this.prefix,
    required this.symbolsEnabled,
    required this.strongContrast,
  });
  final int index, count;
  final String? target;
  final String prefix;
  final bool symbolsEnabled, strongContrast;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${index + 1} ·',
              style: const TextStyle(
                color: ink,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: target == null ? cream : liquidColors[target],
                border: Border.all(
                  color: ink,
                  width: strongContrast ? 1.4 : .7,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  target == null
                      ? '—'
                      : symbolsEnabled
                      ? symbols[target]!
                      : target!,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$count/4',
          key: Key('$prefix-count-$index'),
          style: const TextStyle(
            color: ink,
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
