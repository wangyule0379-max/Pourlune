import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../data/player_settings.dart';
import '../l10n/app_localizations.dart';
import 'flame_board/board.dart';
import 'board_feedback.dart';
import 'labels.dart';
import 'knit_components.dart';
import 'motion.dart';
import 'reference_play_art.dart';
import 'service_views.dart';
import 'large_text_board_page.dart';

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
  final void Function(int)? onTap;
  final VoidCallback? onFlowStart, onFlowEnd;
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
          hintSource: widget.hintSource,
          addedBottle: widget.addedBottle,
          settings: widget.settings,
          keyPrefix: widget.keyPrefix,
          motion: widget.motion,
          onMotionComplete: widget.onMotionComplete,
          onFlowStart: widget.onFlowStart,
          onFlowEnd: widget.onFlowEnd,
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
    this.onFlowStart,
    this.onFlowEnd,
    this.debugBoardPresentation,
  });
  final GameController controller;
  final VoidCallback onRestart, onPause;
  final VoidCallback? onExtra, onFlowStart, onFlowEnd;

  /// Isolated presentation review only; normal and release entries ignore it.
  final Widget Function(BoardView)? debugBoardPresentation;
  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  String? _failedInstance;
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
    // Keep the unsaved warning during Retry until its transaction acknowledges.
    if (c.phase == SavePhase.failed) {
      _failedInstance = s.id;
    } else if (c.phase == SavePhase.clean || _failedInstance != s.id) {
      _failedInstance = null;
    }
    final showSaveFailure = _failedInstance == s.id;
    final suggestion = c.hint?.move;
    final noMoves = !s.completed && !_hasLegalMove(s.board);
    final unmatched =
        s.board
            .where((b) => b.isNotEmpty)
            .every((b) => b.toSet().length == 1) &&
        !s.completed;
    return LayoutBuilder(
      builder: (context, box) {
        if (MediaQuery.textScalerOf(context).scale(14) > 28) {
          return LargeTextBoardPage(
            controller: c,
            onPause: () {
              final token = c.motion?.token;
              if (token != null) c.completeMotion(token);
              widget.onPause();
            },
            onExtra: widget.onExtra,
            onFlowStart: widget.onFlowStart,
            onFlowEnd: widget.onFlowEnd,
            showSaveFailure: showSaveFailure,
          );
        }
        final bounded = box.hasBoundedHeight;
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18.2;
        final hasPriorityNotice =
            showSaveFailure ||
            c.rewardSaveFailed ||
            c.rewardIssue != null ||
            c.pendingRewards.isNotEmpty;
        final extraDetails = <Widget>[
          if (c.recoveryNotice != null)
            Text(
              c.recoveryNotice == 'recovered'
                  ? l.recoveredSave
                  : l.unavailableSave,
            ),
          if (c.notice != null)
            Semantics(liveRegion: true, child: Text(noticeLabel(l, c.notice!))),
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
        ];
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSaveFailure)
              SaveFailureNotice(
                key: const Key('save-failed'),
                controller: c,
                compact: bounded,
              )
            else
              RewardStatus(controller: c, compact: bounded),
            ...extraDetails,
          ],
        );
        final boardView = BoardView(
          key: ValueKey('active-board-${s.id}'),
          state: s,
          selected: c.selectedSource,
          suggested: suggestion?.to,
          hintSource: suggestion?.from,
          addedBottle: hasPriorityNotice
              ? null
              : c.extraBottlePresentation?.bottleIndex,
          settings: c.settings,
          motion: c.motion,
          onMotionComplete: c.completeMotion,
          onFlowStart: widget.onFlowStart,
          onFlowEnd: widget.onFlowEnd,
          rejectedBottle: c.rejectedBottle,
          rejectionRevision: c.rejectionRevision,
          onTap: c.busy ? null : c.tapBottle,
        );
        final board = kDebugMode && widget.debugBoardPresentation != null
            ? widget.debugBoardPresentation!(boardView)
            : boardView;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label:
                  '${s.slot == 'daily' ? '${s.puzzleDate} · ${s.moveCount}' : l.levelMoves(s.puzzle.mainLevel!, s.moveCount)}. ${c.phase == SavePhase.saving
                      ? l.saving
                      : c.phase == SavePhase.clean
                      ? l.saved
                      : l.pauseMemory}',
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const Key('home'),
                      tooltip: l.home,
                      padding: EdgeInsets.zero,
                      onPressed: c.phase == SavePhase.saving ? null : c.goHome,
                      icon: const ReferencePlayArt(
                        source: Rect.fromLTWH(714, 61, 85, 82),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!largeText) ...[
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: ReferenceMoonArt(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            s.slot == 'daily'
                                ? l.dailyPuzzle
                                : s.isReplay
                                ? l.replayLevel(s.puzzle.mainLevel!)
                                : l.level(s.puzzle.mainLevel!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 22,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const Key('pause'),
                      tooltip: l.pause,
                      padding: EdgeInsets.zero,
                      onPressed: c.phase == SavePhase.saving
                          ? null
                          : () {
                              final token = c.motion?.token;
                              if (token != null) c.completeMotion(token);
                              widget.onPause();
                            },
                      icon: const ReferencePlayArt(
                        source: Rect.fromLTWH(1248, 61, 88, 82),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (hasPriorityNotice)
              if (!bounded)
                details
              else if (showSaveFailure)
                SaveFailureNotice(
                  key: const Key('save-failed'),
                  controller: c,
                  compact: true,
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight * .4),
                  child: SingleChildScrollView(
                    key: PageStorageKey('board-explanations-${s.id}'),
                    child: details,
                  ),
                )
            else ...[
              if (c.recoveryNotice != null || c.notice != null)
                KnitPanel(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    c.recoveryNotice != null
                        ? c.recoveryNotice == 'recovered'
                              ? l.recoveredSave
                              : l.unavailableSave
                        : noticeLabel(l, c.notice!),
                    textAlign: TextAlign.center,
                  ),
                ),
              BoardFeedback(
                controller: c,
                noMoves: noMoves,
                unmatched: unmatched,
                extraDetails: extraDetails,
              ),
            ],
            if (hasPriorityNotice)
              BoardFeedback(
                controller: c,
                noMoves: noMoves,
                unmatched: unmatched,
                extraDetails: extraDetails,
                auxiliaryOnly: true,
              ),
            if (bounded) Expanded(child: board) else board,
            LayoutBuilder(
              builder: (context, box) {
                final actions = <(String, IconData, String, VoidCallback?)>[
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
                  if (c.offersExtraBottle)
                    (
                      'extra-bottle',
                      s.extraBottleGranted
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                      s.extraBottleGranted ? l.bottleAdded : l.extraBottle,
                      c.busy || s.extraBottleGranted ? null : widget.onExtra,
                    ),
                ];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    largeText ? 0 : 20,
                    0,
                    largeText ? 0 : 20,
                    hasPriorityNotice &&
                            MediaQuery.textScalerOf(context).scale(14) > 22.4
                        ? 0
                        : largeText
                        ? 4
                        : 12,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              key: Key(actions[i].$1),
                              style:
                                  OutlinedButton.styleFrom(
                                    minimumSize: Size(48, largeText ? 48 : 80),
                                    padding: largeText
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          )
                                        : const EdgeInsets.fromLTRB(
                                            4,
                                            43,
                                            4,
                                            10,
                                          ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ).copyWith(
                                    backgroundBuilder:
                                        (
                                          context,
                                          states,
                                          child,
                                        ) => knitPressFeedback(
                                          context,
                                          states,
                                          Stack(
                                            clipBehavior: Clip.none,
                                            fit: StackFit.passthrough,
                                            children: [
                                              Positioned.fill(
                                                child: ReferencePlayActionArt(
                                                  index: actions[i].$1 == 'undo'
                                                      ? 0
                                                      : actions[i].$1 == 'hint'
                                                      ? 1
                                                      : 2,
                                                  emphasized:
                                                      actions[i].$1 == 'hint' &&
                                                      (c.hintSearching ||
                                                          c.hint != null),
                                                  enabled: !states.contains(
                                                    WidgetState.disabled,
                                                  ),
                                                  showIcon: !largeText,
                                                  usedExtraBottle:
                                                      actions[i].$1 ==
                                                          'extra-bottle' &&
                                                      s.extraBottleGranted,
                                                ),
                                              ),
                                              ?child,
                                            ],
                                          ),
                                        ),
                                  ),
                              onPressed: actions[i].$4,
                              child: Text(
                                actions[i].$3,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
