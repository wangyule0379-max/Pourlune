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
import 'service_views.dart';

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
    this.preview = false,
  });
  final GameInstance state;
  final int? selected, suggested, rejectedBottle;
  final void Function(int)? onTap;
  final PlayerSettings settings;
  final String keyPrefix;
  final PourMotion? motion;
  final void Function(int)? onMotionComplete;
  final int rejectionRevision;
  final bool preview;
  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  @override
  Widget build(BuildContext context) {
    final reduced =
        widget.preview ||
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
          preview: widget.preview,
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
    return LayoutBuilder(
      builder: (context, box) {
        final bounded = box.hasBoundedHeight;
        final largeText = MediaQuery.textScalerOf(context).scale(18) > 26;
        final hasPriorityNotice =
            c.phase == SavePhase.failed ||
            c.rewardSaveFailed ||
            c.rewardIssue != null ||
            c.pendingRewards.isNotEmpty;
        final showHintAction =
            !hasPriorityNotice && (c.hintSearching || c.hint != null);
        final showTutorialAction =
            !hasPriorityNotice && !showHintAction && (lesson?.active ?? false);
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (c.phase == SavePhase.failed)
              SaveFailureNotice(
                key: const Key('save-failed'),
                controller: c,
                compact: bounded,
              )
            else if (c.rewardSaveFailed ||
                c.rewardIssue != null ||
                c.pendingRewards.isNotEmpty)
              RewardStatus(controller: c, compact: bounded)
            else if (c.hintSearching || c.hint != null)
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        c.hintSearching
                            ? l.searchingHint
                            : hintLabel(l, c.hint!),
                      ),
                    ),
                  ),
                  if (!bounded)
                    TextButton(
                      key: const Key('cancel-hint'),
                      onPressed: c.cancelHint,
                      child: Text(l.cancelHint),
                    ),
                ],
              )
            else if (lesson?.active ?? false)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.lessonAction(
                        lesson!.step + 1,
                        s.tutorialLength,
                        s.puzzle.referenceMoves[lesson.step].from + 1,
                        s.puzzle.referenceMoves[lesson.step].to + 1,
                      ),
                    ),
                  ),
                  if (!bounded)
                    TextButton(
                      key: const Key('skip-tutorial'),
                      onPressed: c.busy ? null : c.skipTutorial,
                      child: Text(l.skip),
                    ),
                ],
              )
            else if (noMoves)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Text(l.noMoves), Text(l.noMovesBody)],
              )
            else if (c.rejection != null)
              Semantics(
                liveRegion: true,
                child: Text(rejectionLabel(l, c.rejection!)),
              )
            else
              Text(
                l.rulesTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (c.recoveryNotice != null)
              Text(
                c.recoveryNotice == 'recovered'
                    ? l.recoveredSave
                    : l.unavailableSave,
              ),
            if (c.notice != null)
              Semantics(
                liveRegion: true,
                child: Text(noticeLabel(l, c.notice!)),
              ),
            if (unmatched) Text(l.matchLabels),
            if (suggestion != null)
              Text(l.hintReason(colorLabel(l, s.board[suggestion.from].last))),
            if (!bounded || suggestion == null)
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
              Text(
                l.drawingNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
        final board = BoardView(
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
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KnitHeader(
              compact: bounded,
              title: s.slot == 'daily'
                  ? l.dailyPuzzle
                  : s.isReplay
                  ? l.replayLevel(s.puzzle.mainLevel!)
                  : l.level(s.puzzle.mainLevel!),
              onBack: c.phase == SavePhase.saving ? null : c.goHome,
              backKey: const Key('home'),
              trailing: KnitIconButton(
                size: bounded ? 48 : 52,
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

            if (bounded && c.phase == SavePhase.failed)
              SaveFailureNotice(
                key: const Key('save-failed'),
                controller: c,
                compact: true,
              )
            else if (bounded)
              SizedBox(
                height: suggestion != null && !largeText && box.maxHeight >= 600
                    ? 104
                    : (lesson?.active ?? false) ||
                          c.hintSearching ||
                          c.hint != null ||
                          noMoves ||
                          c.rejection != null ||
                          c.phase == SavePhase.failed ||
                          c.pendingRewards.isNotEmpty ||
                          c.rewardSaveFailed ||
                          c.rewardIssue != null
                    ? 52
                    : 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: PageStorageKey('board-explanations-${s.id}'),
                        child: details,
                      ),
                    ),
                    if (showHintAction)
                      TextButton(
                        key: const Key('cancel-hint'),
                        onPressed: c.cancelHint,
                        child: Text(l.cancelHint),
                      )
                    else if (showTutorialAction)
                      TextButton(
                        key: const Key('skip-tutorial'),
                        onPressed: c.busy ? null : c.skipTutorial,
                        child: Text(l.skip),
                      ),
                  ],
                ),
              )
            else
              details,
            if (bounded) Expanded(child: board) else board,
            if (c.offersExtraBottle)
              OutlinedButton.icon(
                style: bounded
                    ? OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
                key: const Key('extra-bottle'),
                onPressed: c.busy ? null : widget.onExtra,
                icon: Icon(
                  s.extraBottleGranted
                      ? Icons.check_circle_outline
                      : Icons.add_circle_outline,
                ),
                label: Text(
                  s.extraBottleGranted ? l.bottleAdded : l.extraBottle,
                  textAlign: TextAlign.center,
                ),
              ),
            if (c.offersExtraBottle) const SizedBox(height: 10),
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
                final largeActions =
                    MediaQuery.textScalerOf(context).scale(bounded ? 14 : 18) >
                    26;
                final columns = largeActions ? 2 : labels.length;
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final item in labels)
                      SizedBox(
                        width: largeActions && item.$1 == 'restart'
                            ? box.maxWidth
                            : (box.maxWidth - (columns - 1) * 8) / columns,
                        child: OutlinedButton(
                          style: bounded
                              ? OutlinedButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                          key: Key(item.$1),
                          onPressed: item.$4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.$2, size: bounded ? 18 : 28),
                              SizedBox(height: bounded ? 0 : 3),
                              Text(item.$3, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.slot == 'daily'
                        ? '${s.puzzleDate} · ${s.moveCount}'
                        : l.levelMoves(s.puzzle.mainLevel!, s.moveCount),
                    key: const Key('move-count'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.1),
                  ),
                ),
                if (c.phase == SavePhase.failed)
                  Tooltip(
                    message: l.pauseMemory,
                    child: Semantics(
                      label: l.pauseMemory,
                      child: const Icon(
                        Icons.warning_amber,
                        key: Key('save-status'),
                        size: 20,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      c.phase == SavePhase.saving ? l.saving : l.saved,
                      key: const Key('save-status'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
