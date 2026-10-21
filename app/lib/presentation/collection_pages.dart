import 'package:flutter/material.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'labels.dart';

Future<void> _finalNavigate(GameController c, GamePage target) async {
  final piece = c.receipt?.piece;
  if (piece != null && !c.progress.revealedPieces.contains(piece)) {
    await c.acknowledgeReveal(destination: target);
  } else {
    await c.navigate(target);
  }
}

class ScenePreview extends StatelessWidget {
  const ScenePreview({super.key, required this.scene, required this.pieces});
  final String scene;
  final List<String> pieces;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), owned = ownedRegions(pieces, scene);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sceneTitle(scene),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l.sceneCount(owned.length)),
            LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 1; i <= 5; i++)
                    SizedBox(
                      width: (box.maxWidth - 16) / 3,
                      child: Semantics(
                        label:
                            '${regionLabel(l, scene, i)} · ${owned.contains(i) ? l.sceneOwned : l.sceneLocked}',
                        child: Column(
                          children: [
                            ExcludeSemantics(
                              child: Container(
                                height: 64,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: owned.contains(i)
                                      ? const Color(0xffb9d89f)
                                      : const Color(0xffe3e2d8),
                                  border: Border.all(color: ink, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: owned.contains(i)
                                      ? Text(
                                          '$i',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Icon(Icons.lock_outline),
                                ),
                              ),
                            ),
                            ExcludeSemantics(
                              child: Text(
                                regionLabel(l, scene, i),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              l.scenePendingArt,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScenePreview(scene: scene, pieces: controller.progress.pieces),
            OutlinedButton(
              key: Key('scene-$scene'),
              onPressed: controller.busy
                  ? null
                  : () => controller.navigate(GamePage.scene, scene: scene),
              child: Text(sceneTitle(scene)),
            ),
          ],
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
        if (ownedRegions(c.progress.pieces, c.selectedScene).length == 5)
          Text(l.chapterComplete),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          unseen ? l.newPatch : sceneTitle(c.selectedScene),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        ScenePreview(scene: c.selectedScene, pieces: c.progress.pieces),
        Text(l.addedCollection),
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
            onPressed: c.busy
                ? null
                : () => _finalNavigate(c, GamePage.chapters),
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
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          finalStory
              ? l.storyComplete
              : kind == SettlementKind.daily
              ? l.dailyComplete
              : kind == SettlementKind.replay
              ? l.puzzleComplete
              : l.beautifullySorted,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
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
            scene: sceneForLevel(s.puzzle.mainLevel!),
            pieces: c.progress.pieces,
          ),
        ],
        if (finalStory) ...[
          Text(l.storyCompleteBody),
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
            onPressed: c.busy
                ? null
                : () => _finalNavigate(c, GamePage.chapters),
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
      ],
    );
  }
}
