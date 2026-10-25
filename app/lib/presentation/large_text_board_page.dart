import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart' show ink;
import 'flame_board/board.dart';
import 'labels.dart';
import 'reference_extra_art.dart';
import 'service_views.dart';

// The parent BoardPage owns the single motion presenter and failure latch.
class LargeTextBoardPage extends StatefulWidget {
  const LargeTextBoardPage({
    super.key,
    required this.controller,
    required this.onPause,
    required this.onExtra,
    required this.showSaveFailure,
  });
  final GameController controller;
  final VoidCallback onPause;
  final VoidCallback? onExtra;
  final bool showSaveFailure;
  @override
  State<LargeTextBoardPage> createState() => LargeTextBoardPageState();
}

class LargeTextBoardPageState extends State<LargeTextBoardPage> {
  GameController get c => widget.controller;
  static const labelStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    height: 1.1,
    fontWeight: FontWeight.w900,
    color: ink,
  );
  bool get noMoves {
    final board = c.current!.board;
    for (var a = 0; a < board.length; a++) {
      for (var b = 0; b < board.length; b++) {
        if (pourBoard(board, a, b).units > 0) return false;
      }
    }
    return true;
  }

  String get shortStatus {
    final l = AppLocalizations.of(context);
    if (c.hintSearching) return l.compactSearching;
    if (c.hint?.move case final move?) {
      return '${move.from + 1} → ${move.to + 1}';
    }
    if (c.hint != null) {
      return switch (c.hint!.status) {
        HintStatus.provenUnsolvable => l.undo,
        HintStatus.noMoves => l.compactNoMoves,
        HintStatus.alreadyComplete => l.compactSorted,
        _ => l.tryAgain,
      };
    }
    if (noMoves) return l.compactNoMoves;
    return switch (c.rejection) {
      'That bottle is full' => l.compactFull,
      'Choose a bottle with liquid' => l.emptyLabel,
      'Empty or matching top color only' => l.compactMismatch,
      null => l.compactRules,
      _ => l.compactCheck,
    };
  }

  Future<void> showInformation() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final l = AppLocalizations.of(context), state = c.current!;
          final hint = c.hint;
          final title = c.hintSearching
              ? l.searchingHint
              : hint != null
              ? hintLabel(l, hint)
              : (state.tutorial?.active ?? false)
              ? l.rulesTitle
              : noMoves
              ? l.noMoves
              : c.rejection == 'Empty or matching top color only'
              ? l.cantPourHere
              : c.rejection == 'Choose a bottle with liquid'
              ? l.emptyLabel
              : c.rejection != null
              ? rejectionLabel(l, c.rejection!)
              : l.rulesTitle;
          final reason = c.hintSearching
              ? l.hintKeepPlaying
              : hint != null
              ? switch (hint.status) {
                  HintStatus.found => l.hintReason(
                    hint.move!.to + 1,
                    colorLabel(l, state.board[hint.move!.from].last),
                  ),
                  HintStatus.provenUnsolvable => l.hintUnsolvableBody,
                  HintStatus.noMoves => l.noMovesBody,
                  HintStatus.alreadyComplete => '',
                  _ => l.hintKeepPlaying,
                }
              : noMoves
              ? l.noMovesBody
              : c.rejection == 'Empty or matching top color only'
              ? l.matchingTopBody
              : c.rejection == 'Choose a bottle with liquid'
              ? l.chooseLiquid
              : '';
          final feedback =
              c.hintSearching || hint != null || noMoves || c.rejection != null;
          return Dialog(
            key: const Key('board-information'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 360,
                maxHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    32,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ReferenceExtraSurface(kind: ExtraSurfaceKind.pause),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                feedback ? title : l.howToPlay,
                                style: feedback
                                    ? labelStyle.copyWith(fontSize: 18)
                                    : labelStyle,
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                key: const Key('board-info-close'),
                                tooltip: l.close,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: SingleChildScrollView(
                            key: const Key('board-info-scroll'),
                            child: Column(
                              children: [
                                if (!feedback)
                                  Text(
                                    title,
                                    style: labelStyle.copyWith(fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                if (widget.showSaveFailure) ...[
                                  Text(l.progressNotSaved, style: labelStyle),
                                  Text(
                                    l.pauseMemory,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (c.rewardSaveFailed ||
                                    c.rewardIssue != null ||
                                    c.pendingRewards.isNotEmpty)
                                  RewardStatus(controller: c),
                                if (state.tutorial?.active ?? false)
                                  Text(
                                    l.lessonAction(
                                      state.tutorial!.step + 1,
                                      state.tutorialLength,
                                      state
                                              .puzzle
                                              .referenceMoves[state
                                                  .tutorial!
                                                  .step]
                                              .from +
                                          1,
                                      state
                                              .puzzle
                                              .referenceMoves[state
                                                  .tutorial!
                                                  .step]
                                              .to +
                                          1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                if (c.recoveryNotice != null)
                                  Text(
                                    c.recoveryNotice == 'recovered'
                                        ? l.recoveredSave
                                        : l.unavailableSave,
                                  ),
                                if (c.notice != null)
                                  Text(noticeLabel(l, c.notice!)),
                                if (reason.isNotEmpty)
                                  Text(reason, textAlign: TextAlign.center),
                                if (!feedback) ...[
                                  const SizedBox(height: 8),
                                  Text(l.goal, textAlign: TextAlign.center),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget action(
    String key,
    String text,
    VoidCallback? onPressed, {
    bool primary = false,
  }) => OutlinedButton(
    key: Key(key),
    onPressed: onPressed,
    style:
        OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          textStyle: labelStyle,
          side: BorderSide.none,
          foregroundColor: ink,
        ).copyWith(
          backgroundBuilder: (_, _, child) => Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: ReferenceExtraSurface(
                  tileEdges: true,
                  kind: primary
                      ? ExtraSurfaceKind.primary
                      : ExtraSurfaceKind.secondary,
                ),
              ),
              ?child,
            ],
          ),
        ),
    child: Text(text, textAlign: TextAlign.center),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), s = c.current!;
    final hint = c.hint?.move;
    final hintActive = c.hintSearching || c.hint != null;
    return Column(
      key: const Key('large-text-board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: math.max(
            MediaQuery.textScalerOf(context).scale(22) * 1.1,
            MediaQuery.textScalerOf(context).scale(14) * 2.2,
          ),
          child: Row(
            children: [
              Semantics(
                label:
                    '${s.slot == 'daily' ? '${l.dailyPuzzle} ${s.puzzleDate}' : l.levelMoves(s.puzzle.mainLevel!, s.moveCount)}. ${widget.showSaveFailure
                        ? l.saveFailed
                        : c.phase == SavePhase.saving
                        ? l.saving
                        : l.saved}',
                excludeSemantics: true,
                child: Text(
                  s.slot == 'daily' ? l.compactDaily : '${s.puzzle.mainLevel!}',
                  key: const Key('board-level'),
                  style: labelStyle.copyWith(fontSize: 22),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    widget.showSaveFailure
                        ? '${l.compactNotSaved}\n$shortStatus'
                        : (c.rewardSaveFailed ||
                              c.rewardIssue != null ||
                              c.pendingRewards.isNotEmpty)
                        ? l.compactReward
                        : (s.tutorial?.active ?? false)
                        ? '${s.tutorial!.step + 1}/${s.tutorialLength}'
                        : shortStatus,
                    key: const Key('board-status'),
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  key: const Key('board-info'),
                  tooltip: l.howToPlay,
                  onPressed: showInformation,
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlameBoard(
            state: s,
            selected: c.selectedSource,
            onTap: c.busy ? null : c.tapBottle,
            suggested: hint?.to,
            hintSource: hint?.from,
            settings: c.settings,
            motion: c.motion,
            onMotionComplete: c.completeMotion,
            rejectedBottle: c.rejectedBottle,
            rejectionRevision: c.rejectionRevision,
            addedBottle: widget.showSaveFailure
                ? null
                : c.extraBottlePresentation?.bottleIndex,
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  key: const Key('home'),
                  tooltip: l.home,
                  onPressed: c.busy ? null : c.goHome,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: action(
                  'undo',
                  l.undo,
                  c.busy || s.history.isEmpty ? null : c.undo,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: hintActive
                    ? IconButton(
                        key: const Key('cancel-hint'),
                        tooltip: l.cancelHint,
                        onPressed: c.cancelHint,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : (s.tutorial?.active ?? false)
                    ? action(
                        'skip-tutorial',
                        l.skip,
                        c.busy ? null : c.skipTutorial,
                      )
                    : action('hint', l.hint, c.busy ? null : c.requestHint),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: IconButton(
                  key: const Key('pause'),
                  tooltip: l.pause,
                  onPressed: c.busy ? null : widget.onPause,
                  icon: const Icon(Icons.pause_rounded),
                ),
              ),
            ],
          ),
        ),
        if (widget.showSaveFailure) ...[
          const SizedBox(height: 4),
          Row(
            key: const Key('save-failed'),
            children: [
              Expanded(
                child: action(
                  'retry',
                  l.retry,
                  c.phase == SavePhase.saving ? null : c.retry,
                  primary: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: action(
                  'stay',
                  l.stayHere,
                  c.phase == SavePhase.saving ? null : c.stayHere,
                ),
              ),
            ],
          ),
        ],
        if (c.rewardSaveFailed || c.rewardIssue != null) ...[
          const SizedBox(height: 4),
          action(
            'retry-reward',
            l.retry,
            c.busy ? null : c.retryReward,
            primary: true,
          ),
        ],
        if (c.offersExtraBottle) ...[
          const SizedBox(height: 4),
          action(
            'extra-bottle',
            s.extraBottleGranted ? l.bottleAdded : l.extraBottle,
            c.busy || s.extraBottleGranted ? null : widget.onExtra,
          ),
        ],
      ],
    );
  }
}
