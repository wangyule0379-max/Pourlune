import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../data/player_settings.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'labels.dart';

bool _hasLegalMove(Board board) {
  for (var from = 0; from < board.length; from++) {
    for (var to = 0; to < board.length; to++) {
      if (pourBoard(board, from, to).units > 0) return true;
    }
  }
  return false;
}

class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.selected,
    required this.onTap,
    this.suggested,
    this.settings = const PlayerSettings(),
    this.keyPrefix = 'bottle',
  });
  final GameInstance state;
  final int? selected, suggested;
  final void Function(int)? onTap;
  final PlayerSettings settings;
  final String keyPrefix;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), board = state.board;
    return LayoutBuilder(
      builder: (context, box) {
        final width = ((box.maxWidth - 24) / 4).clamp(48.0, 84.0);
        final rows = board.length == 4
            ? [2, 2]
            : board.length == 5
            ? [3, 2]
            : board.length == 6
            ? [3, 3]
            : [4, 3];
        var offset = 0;
        return Column(
          children: [
            for (final n in rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final i in List.generate(n, (_) => offset++))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: BottleButton(
                        key: Key('$keyPrefix-$i'),
                        index: i,
                        liquid: board[i],
                        target: i < state.puzzle.targets.length
                            ? state.puzzle.targets[i]
                            : null,
                        selected: selected == i,
                        suggested: suggested == i,
                        width: width,
                        showSymbols: settings.colorSymbols,
                        strongContrast: settings.strongContrast,
                        semanticLabel:
                            '${l.bottleSemantics(i + 1, i < state.puzzle.targets.length && state.puzzle.targets[i] != null ? l.targetLabel(colorLabel(l, state.puzzle.targets[i]!)) : l.bufferLabel, board[i].isEmpty ? l.emptyLabel : l.contentsLabel(board[i].map((c) => colorLabel(l, c)).join(', ')), board[i].length)}${suggested == i ? ' ${l.suggestedTarget}' : ''}',
                        onTap: onTap == null
                            ? null
                            : () {
                                if (settings.haptics) {
                                  HapticFeedback.selectionClick();
                                }
                                onTap!(i);
                              },
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

class BoardPage extends StatelessWidget {
  const BoardPage({
    super.key,
    required this.controller,
    required this.onRestart,
    required this.onPause,
  });
  final GameController controller;
  final VoidCallback onRestart, onPause;
  @override
  Widget build(BuildContext context) {
    final c = controller,
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
        Text(
          s.slot == 'daily'
              ? '${l.dailyPuzzle} · ${s.puzzleDate}'
              : s.isReplay
              ? l.replayLevel(s.puzzle.mainLevel!)
              : l.level(s.puzzle.mainLevel!),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          s.slot == 'daily'
              ? '${s.moveCount}'
              : l.levelMoves(s.puzzle.mainLevel!, s.moveCount),
          key: const Key('move-count'),
        ),
        if (kDebugMode)
          Text(
            '${s.puzzle.id} · v${s.puzzle.contentVersion} · revision ${s.revision} · ${s.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        Text(l.goal),
        if (lesson?.active ?? false)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(l.lessonTitle),
                  Text(
                    l.lessonAction(
                      lesson!.step + 1,
                      s.tutorialLength,
                      s.puzzle.referenceMoves[lesson.step].from + 1,
                      s.puzzle.referenceMoves[lesson.step].to + 1,
                    ),
                  ),
                  TextButton(
                    key: const Key('skip-tutorial'),
                    onPressed: c.busy ? null : c.skipTutorial,
                    child: Text(l.skip),
                  ),
                ],
              ),
            ),
          ),
        BoardView(
          state: s,
          selected: c.selectedSource,
          suggested: suggestion?.to,
          settings: c.settings,
          onTap: c.busy ? null : c.tapBottle,
        ),
        if (unmatched) Text(l.matchLabels),
        if (c.rejection != null)
          Semantics(
            liveRegion: true,
            child: Text(rejectionLabel(l, c.rejection!)),
          ),
        if (noMoves && !c.hintSearching && c.hint?.status != HintStatus.noMoves)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [Text(l.noMoves), Text(l.noMovesBody)]),
            ),
          ),
        if (c.hintSearching)
          Card(
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
          Card(
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('undo'),
              onPressed: c.busy || s.history.isEmpty ? null : c.undo,
              child: Text(l.undo),
            ),
            if (!(lesson?.active ?? false))
              FilledButton(
                key: const Key('hint'),
                onPressed: c.busy || c.hintSearching ? null : c.requestHint,
                child: Text(l.hint),
              ),
            OutlinedButton(
              key: const Key('restart'),
              onPressed: c.busy ? null : onRestart,
              child: Text(l.restart),
            ),
            OutlinedButton(
              key: const Key('pause'),
              onPressed: c.busy ? null : onPause,
              child: Text(l.pause),
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
