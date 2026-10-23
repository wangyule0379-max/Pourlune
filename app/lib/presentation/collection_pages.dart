import 'package:flutter/material.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'board_page.dart';
import 'knit_components.dart';
import 'labels.dart';
import 'scene_art.dart';
import 'motion.dart';

Future<void> _finalNavigate(GameController c, GamePage target) async {
  final piece = c.receipt?.piece;
  if (piece != null && !c.progress.revealedPieces.contains(piece)) {
    await c.acknowledgeReveal(destination: target);
  } else {
    await c.navigate(target);
  }
}

class ScenePreview extends StatelessWidget {
  const ScenePreview({
    super.key,
    required this.scene,
    required this.pieces,
    this.reveal,
    this.compact = false,
  });
  final String scene;
  final List<String> pieces;
  final int? reveal;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          SizedBox(
            width: 96,
            child: SceneArt(scene: scene, pieces: pieces, reveal: reveal),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  sceneTitle(scene),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                PatchProgress(scene: scene, pieces: pieces, compact: true),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SceneArt(scene: scene, pieces: pieces, reveal: reveal),
        Text(
          sceneTitle(scene),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        KnitPanel(
          child: PatchProgress(scene: scene, pieces: pieces),
        ),
      ],
    );
  }
}

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final scene in ['color_studio', 'garden_nook', 'seaside_corner'])
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            button: true,
            enabled: !controller.busy,
            child: InkWell(
              key: Key('scene-$scene'),
              borderRadius: BorderRadius.circular(28),
              onTap: controller.busy
                  ? null
                  : () => controller.navigate(GamePage.scene, scene: scene),
              child: KnitPanel(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow =
                        constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.4;
                    final thumbnail = SizedBox(
                      width: narrow ? 160 : 136,
                      child: SceneArt(
                        scene: scene,
                        pieces: controller.progress.pieces,
                      ),
                    );
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          sceneTitle(scene),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        PatchProgress(
                          scene: scene,
                          pieces: controller.progress.pieces,
                          compact: true,
                        ),
                      ],
                    );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: thumbnail),
                          details,
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.chevron_right),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        thumbnail,
                        const SizedBox(width: 12),
                        Expanded(child: details),
                        const Icon(Icons.chevron_right),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class ScenePage extends StatelessWidget {
  const ScenePage({super.key, required this.controller, required this.onPlay});
  final GameController controller;
  final void Function(int) onPlay;
  @override
  Widget build(BuildContext context) {
    final c = controller, l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScenePreview(scene: c.selectedScene, pieces: c.progress.pieces),
        const SizedBox(height: 16),
        if (ownedRegions(c.progress.pieces, c.selectedScene).length == 5)
          Text(l.chapterComplete, textAlign: TextAlign.center),
        if (c.canContinueOrdinary)
          FilledButton(
            key: const Key('scene-continue'),
            onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
            child: Text(
              c.continueLabelIsReplay
                  ? l.continueReplay(c.ordinary!.puzzle.mainLevel!)
                  : l.continueLevel(c.ordinary!.puzzle.mainLevel!),
            ),
          )
        else if (c.progress.storyComplete)
          FilledButton(
            key: const Key('scene-daily'),
            onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
            child: Text(l.dailyPuzzle),
          )
        else
          FilledButton(
            key: const Key('play-from-scene'),
            onPressed:
                c.busy ||
                    c.progress.nextUnfinished == null ||
                    !c.library.main.containsKey(c.progress.nextUnfinished)
                ? null
                : () => onPlay(c.progress.nextUnfinished!),
            child: Text(l.playLevel(c.progress.nextUnfinished ?? 1)),
          ),
        OutlinedButton(
          key: const Key('collection-back'),
          onPressed: c.busy ? null : () => c.navigate(GamePage.collection),
          child: Text(l.collection),
        ),
      ],
    );
  }
}

class RewardPage extends StatelessWidget {
  const RewardPage({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller,
        l = AppLocalizations.of(context),
        piece = c.receipt?.piece,
        unseen = piece != null && !c.progress.revealedPieces.contains(piece);
    final actions = <Widget>[
      if (c.settlementKind == SettlementKind.finalStory) ...[
        FilledButton(
          key: const Key('daily-final'),
          onPressed: c.busy
              ? null
              : () async {
                  if (unseen) {
                    await c.acknowledgeReveal(destination: GamePage.daily);
                  } else {
                    await c.navigate(GamePage.daily);
                  }
                },
          child: Text(l.dailyPuzzle),
        ),
        OutlinedButton(
          key: const Key('replay-levels'),
          onPressed: c.busy ? null : () => _finalNavigate(c, GamePage.chapters),
          child: Text(l.replayLevels),
        ),
      ] else if (c.canNext ||
          (c.current?.completed == true &&
              c.current!.slot == 'ordinary' &&
              !c.current!.isReplay &&
              c.current!.puzzle.mainLevel! < 60))
        FilledButton(
          key: const Key('next'),
          onPressed: c.busy ? null : c.nextLevel,
          child: Text(
            c.settlementKind == SettlementKind.chapter
                ? l.continueChapter
                : l.nextLevel,
          ),
        ),
      OutlinedButton(
        key: const Key('view-collection'),
        onPressed: c.busy
            ? null
            : () async {
                if (unseen) {
                  await c.acknowledgeReveal();
                } else {
                  await c.navigate(GamePage.scene, scene: c.selectedScene);
                }
              },
        child: Text(l.viewCollection),
      ),
    ];
    final details = Column(
      children: [
        Text(
          unseen ? l.newPatch : sceneTitle(c.selectedScene),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        ScenePreview(
          compact: true,
          scene: c.selectedScene,
          pieces: c.progress.pieces,
          reveal: unseen ? int.parse(piece.split(':').last) : null,
        ),
        Text(l.addedCollection, textAlign: TextAlign.center),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (box.hasBoundedHeight)
            Expanded(
              child: SingleChildScrollView(
                key: const Key('reward-details'),
                child: details,
              ),
            )
          else
            details,
          _SettlementActions(children: actions),
        ],
      ),
    );
  }
}

class CompletionPage extends StatelessWidget {
  const CompletionPage({
    super.key,
    required this.controller,
    required this.onPlay,
  });
  final GameController controller;
  final void Function(int) onPlay;
  @override
  Widget build(BuildContext context) {
    final c = controller,
        l = AppLocalizations.of(context),
        s = c.current!,
        kind = c.settlementKind;
    final finalStory = kind == SettlementKind.finalStory,
        patch = kind == SettlementKind.patch || kind == SettlementKind.chapter;
    final title = Text(
      finalStory
          ? l.storyComplete
          : kind == SettlementKind.daily
          ? l.dailyComplete
          : kind == SettlementKind.replay
          ? l.puzzleComplete
          : l.beautifullySorted,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    );
    final actions = <Widget>[
      if (finalStory) ...[
        FilledButton(
          key: const Key('daily-final'),
          onPressed: c.busy ? null : () => _finalNavigate(c, GamePage.daily),
          child: Text(l.dailyPuzzle),
        ),
        OutlinedButton(
          key: const Key('view-collection'),
          onPressed: c.busy
              ? null
              : () => _finalNavigate(c, GamePage.collection),
          child: Text(l.viewCollection),
        ),
        OutlinedButton(
          key: const Key('replay-levels'),
          onPressed: c.busy ? null : () => _finalNavigate(c, GamePage.chapters),
          child: Text(l.replayLevels),
        ),
      ] else if (kind == SettlementKind.chapter) ...[
        FilledButton(
          key: const Key('next'),
          onPressed: c.busy ? null : c.nextLevel,
          child: Text(l.continueChapter),
        ),
        OutlinedButton(
          key: const Key('view-collection'),
          onPressed: c.busy
              ? null
              : () => c.receipt?.piece == null
                    ? c.navigate(
                        GamePage.scene,
                        scene: sceneForLevel(s.puzzle.mainLevel!),
                      )
                    : c.acknowledgeReveal(),
          child: Text(l.viewCollection),
        ),
      ] else if (kind == SettlementKind.replay) ...[
        FilledButton(
          key: const Key('replay-again'),
          onPressed: c.busy ? null : () => onPlay(s.puzzle.mainLevel!),
          child: Text(l.replayAgain),
        ),
        OutlinedButton(
          key: const Key('choose-level'),
          onPressed: c.busy ? null : () => c.navigate(GamePage.chapters),
          child: Text(l.chooseLevel),
        ),
      ] else if (kind == SettlementKind.daily)
        FilledButton(
          key: const Key('daily-calendar'),
          onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
          child: Text(l.dailyPuzzle),
        )
      else if (patch)
        FilledButton(
          key: const Key('view-patch'),
          onPressed: c.busy ? null : c.viewPatch,
          child: Text(l.viewPatch),
        )
      else
        FilledButton(
          key: const Key('next'),
          onPressed: c.busy ? null : c.nextLevel,
          child: Text(l.nextLevel),
        ),
      OutlinedButton(
        key: const Key('home'),
        onPressed: c.busy ? null : c.goHome,
        child: Text(l.home),
      ),
    ];
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.phase != SavePhase.clean || c.receipt == null)
          Text(l.pendingCompletion)
        else if (kind == SettlementKind.daily)
          Text(s.isReplay ? l.dailyReplayComplete : l.stampSaved(s.puzzleDate!))
        else
          Text(
            kind == SettlementKind.replay
                ? l.replayComplete
                : l.firstClearSaved,
          ),
        if ((kind == SettlementKind.chapter || finalStory) &&
            c.phase == SavePhase.clean) ...[
          Text(l.chapterComplete),
          ScenePreview(
            compact: true,
            scene: sceneForLevel(s.puzzle.mainLevel!),
            pieces: c.progress.pieces,
            reveal:
                c.receipt?.piece != null &&
                    !c.progress.revealedPieces.contains(c.receipt!.piece)
                ? int.parse(c.receipt!.piece!.split(':').last)
                : null,
          ),
        ],
        if (finalStory) Text(l.storyCompleteBody),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final heading = c.phase == SavePhase.clean && c.receipt != null
            ? _CompletionFeedback(
                key: Key('completion-feedback-${s.id}'),
                child: Row(
                  children: [
                    const KnitArt(name: 'success', width: 36, height: 36),
                    const SizedBox(width: 8),
                    Expanded(child: title),
                  ],
                ),
              )
            : title;
        final preview = BoardView(
          key: const Key('completion-preview'),
          state: s,
          selected: null,
          onTap: null,
          settings: c.settings,
          preview: true,
          keyPrefix: 'preview-bottle',
        );
        if (!box.hasBoundedHeight) {
          return Column(
            children: [
              heading,
              preview,
              info,
              _SettlementActions(children: actions),
            ],
          );
        }
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!largeText) heading,
            Expanded(
              child: LayoutBuilder(
                builder: (context, space) {
                  // A large accessibility font may need to inspect the read-only
                  // preview/details; the actual settlement actions stay outside it.
                  final minPreview =
                      32 * 3 +
                      (32 * MediaQuery.textScalerOf(context).scale(1) + 8) * 2 +
                      12;
                  final previewHeight = largeText
                      ? minPreview
                      : 32 * MediaQuery.textScalerOf(context).scale(1) +
                            8 +
                            (space.maxWidth / s.board.length - 8).clamp(0, 48) *
                                1.5 +
                            4;
                  return SingleChildScrollView(
                    key: const Key('completion-details'),
                    child: Column(
                      children: [
                        if (largeText) heading,
                        SizedBox(height: previewHeight, child: preview),
                        info,
                      ],
                    ),
                  );
                },
              ),
            ),
            _SettlementActions(children: actions),
          ],
        );
      },
    );
  }
}

/// Buttons are laid out from their real text height, never scaled or clipped.
/// Only the read-only celebration/description region above them can scroll.
class _SettlementActions extends StatelessWidget {
  const _SettlementActions({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ButtonStyle compact(ButtonStyle? style) =>
        (style ?? const ButtonStyle()).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: compact(theme.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: compact(theme.outlinedButtonTheme.style),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width:
                    MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                        (children.length.isOdd && i == children.length - 1)
                    ? box.maxWidth
                    : (box.maxWidth - 8) / 2,
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}

/// Pure presentation: rebuilding or finishing this animation never writes progress.
class _CompletionFeedback extends StatelessWidget {
  const _CompletionFeedback({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduced
          ? const Duration(milliseconds: 150)
          : KnitMotion.success,
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: reduced
            ? child
            : Transform.scale(
                scale: .94 + .06 * value,
                alignment: Alignment.centerLeft,
                child: child,
              ),
      ),
    );
  }
}
