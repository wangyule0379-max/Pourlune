import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../data/player_settings.dart';
import '../l10n/app_localizations.dart';
import 'flame_board/board.dart';
import 'labels.dart';
import 'knit_components.dart';
import 'motion.dart';

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

class _BoardViewState extends State<BoardView> {
  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        widget.settings.reducedMotion ||
        (widget.motion?.reducedMotion ?? false);
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('arrival-${widget.state.id}'),
        duration: reduced ? Duration.zero : KnitMotion.board,
        tween: Tween(begin: 0, end: 1),
        child: FlameBoard(
          state: widget.state,
          selected: widget.selected,
          onTap: widget.onTap,
          suggested: widget.suggested,
          settings: widget.settings,
          keyPrefix: widget.keyPrefix,
          motion: widget.motion,
          onMotionComplete: widget.onMotionComplete,
          rejectedBottle: widget.rejectedBottle,
          rejectionRevision: widget.rejectionRevision,
        ),
        builder: (_, value, child) => Opacity(
          alwaysIncludeSemantics: true,
          opacity: reduced ? 1 : value,
          child: child,
        ),
      ),
    );
  }
}

class BoardPage extends StatefulWidget {
  const BoardPage({
    super.key,
    required this.controller,
    required this.onRestart,
    required this.onPause,
    this.onExtra,
  });
  final GameController controller;
  final VoidCallback onRestart, onPause;
  final VoidCallback? onExtra;
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
          key: ValueKey('active-board-${s.id}'),
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
        if (c.offersExtraBottle)
          OutlinedButton.icon(
            key: const Key('extra-bottle'),
            onPressed: c.busy ? null : widget.onExtra,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l.extraBottle, textAlign: TextAlign.center),
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
                    width: largeText && item.$1 == 'restart'
                        ? box.maxWidth
                        : (box.maxWidth - (columns - 1) * 8) / columns,
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
            key: const PageStorageKey('board-diagnostics-state'),
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
