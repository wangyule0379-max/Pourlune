import 'package:flutter/material.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'knit_components.dart';
import 'labels.dart';
import 'scene_art.dart';
import 'motion.dart';
import 'completion_bottles.dart';
import 'completion_layout.dart';
import 'daily_reference.dart';
import 'completion_compact_layout.dart';
import 'parallel_collection/collection_visuals.dart';
import 'parallel_collection/scene_detail.dart';

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
    this.remainingLevels,
  });
  final String scene;
  final List<String> pieces;
  final int? reveal, remainingLevels;
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
            child: CollectionProgressText(
              scene: scene,
              pieces: pieces,
              showTitle: true,
            ),
          ),
        ],
      );
    }
    final l = AppLocalizations.of(context);
    final progress = CollectionSurface(
      key: const Key('scene-progress-tray'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.sceneCount(ownedRegions(pieces, scene).length),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          CollectionPatchSlots(
            scene: scene,
            pieces: pieces,
            showLocks: true,
            raised: false,
          ),
          if (remainingLevels != null) ...[
            const SizedBox(height: 8),
            Text(
              remainingLevels == 0
                  ? l.chapterComplete
                  : l.sceneLevelsRemaining(remainingLevels!),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
    final hero = CollectionSceneDetail(
      scene: scene,
      pieces: pieces,
      reveal: reveal,
    );
    final strip = CollectionObjectStrip(scene: scene, pieces: pieces);
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final slotHeight = (box.maxWidth - 36 - 24) / 5;
        final progressHeight =
            28 +
            scaler.scale(20) * 1.1 +
            8 +
            slotHeight +
            (remainingLevels == null ? 0 : 8 + scaler.scale(14) * 1.15);
        final captionHeight = scaler.scale(14) * 1.1 + 2;
        final stripHeight =
            (box.maxWidth - 20) / 5 / .92 +
            (captionHeight < 24 ? 24 : captionHeight);
        final fixedHeight = progressHeight + stripHeight + 12;
        final scroll =
            box.hasBoundedHeight &&
            box.maxWidth > box.maxHeight &&
            box.maxHeight < fixedHeight + 128;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (box.hasBoundedHeight && !scroll)
              Expanded(child: Center(child: hero))
            else
              hero,
            const SizedBox(height: 4),
            progress,
            const SizedBox(height: 8),
            strip,
          ],
        );
        return scroll
            ? SingleChildScrollView(
                key: const Key('scene-preview-scroll'),
                child: content,
              )
            : content;
      },
    );
  }
}

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        for (var index = 0; index < sceneIds.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Builder(
              builder: (context) {
                final scene = sceneIds[index];
                final locked = !controller.progress.unlockedLevels.contains(
                  index * 20 + 1,
                );
                final requirement = index == 0
                    ? null
                    : l.completeSceneToUnlock(sceneTitle(sceneIds[index - 1]));
                return Semantics(
                  button: true,
                  enabled: !controller.busy,
                  child: InkWell(
                    key: Key('scene-$scene'),
                    borderRadius: BorderRadius.circular(28),
                    onTap: controller.busy
                        ? null
                        : () =>
                              controller.navigate(GamePage.scene, scene: scene),
                    child: CollectionSurface(
                      key: Key('collection-card-$scene'),
                      locked: locked,
                      padding: const EdgeInsets.all(12),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final stacked =
                              MediaQuery.textScalerOf(context).scale(20) > 28;
                          final thumbnail = SizedBox(
                            width: stacked
                                ? 164
                                : box.maxWidth * (locked ? .50 : .43),
                            child: CollectionSurface(
                              key: Key('collection-art-frame-$scene'),
                              locked: locked,
                              padding: const EdgeInsets.all(4),
                              cornerRadius: 14,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRect(
                                      child: Transform.scale(
                                        scale: 1.12,
                                        child: Opacity(
                                          opacity: locked ? .55 : 1,
                                          child: SceneArt(
                                            scene: scene,
                                            pieces: controller.progress.pieces,
                                            preview: locked,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (locked)
                                      CollectionLock(
                                        key: Key('collection-lock-$scene'),
                                        size: 48,
                                        purple: true,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          final details = Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: locked
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sceneTitle(scene),
                                      textAlign: locked
                                          ? TextAlign.center
                                          : TextAlign.start,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        height: 1.1,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (!locked) const CollectionChevron(),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (locked && requirement != null)
                                Text(
                                  requirement,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.3,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              else ...[
                                Text(
                                  l.sceneCount(
                                    ownedRegions(
                                      controller.progress.pieces,
                                      scene,
                                    ).length,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CollectionPatchSlots(
                                  scene: scene,
                                  pieces: controller.progress.pieces,
                                ),
                              ],
                            ],
                          );
                          if (stacked) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(child: thumbnail),
                                details,
                              ],
                            );
                          }
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxWidth * (locked ? .52 : .44),
                            ),
                            child: Row(
                              children: [
                                thumbnail,
                                const SizedBox(width: 8),
                                Expanded(child: details),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Text(
          l.collectionTagline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class ScenePage extends StatelessWidget {
  const ScenePage({super.key, required this.controller, required this.onPlay});
  final GameController controller;
  final void Function(int) onPlay;
  @override
  Widget build(BuildContext context) {
    final c = controller, l = AppLocalizations.of(context);
    final actions = <Widget>[
      if (c.canContinueOrdinary)
        FilledButton(
          key: const Key('scene-continue'),
          onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
          child: CollectionActionLabel(
            c.continueLabelIsReplay
                ? l.continueReplay(c.ordinary!.puzzle.mainLevel!)
                : l.continueLevel(c.ordinary!.puzzle.mainLevel!),
          ),
        )
      else if (c.progress.storyComplete)
        FilledButton(
          key: const Key('scene-daily'),
          onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
          child: CollectionActionLabel(l.dailyPuzzle),
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
          child: CollectionActionLabel(
            l.playLevel(c.progress.nextUnfinished ?? 1),
          ),
        ),
      OutlinedButton(
        key: const Key('collection-back'),
        onPressed: c.busy ? null : () => c.navigate(GamePage.collection),
        child: CollectionActionLabel(
          l.backToCollection,
          icon: Icons.collections_bookmark_rounded,
          leading: true,
        ),
      ),
    ];
    final preview = ScenePreview(
      scene: c.selectedScene,
      pieces: c.progress.pieces,
      remainingLevels: sceneRemainingLevels(
        c.selectedScene,
        c.progress.completedLevels,
      ),
    );
    final controls = CollectionActions(children: actions);
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [preview, const SizedBox(height: 12), controls],
          );
        }
        final enlarged = MediaQuery.textScalerOf(context).scale(18) > 25;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: enlarged
                  ? SingleChildScrollView(
                      key: PageStorageKey('scene-details-${c.selectedScene}'),
                      child: preview,
                    )
                  : preview,
            ),
            const SizedBox(height: 12),
            controls,
          ],
        );
      },
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
          child: CollectionActionLabel(
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
    return LayoutBuilder(
      builder: (context, box) {
        final largeText = MediaQuery.textScalerOf(context).scale(18) > 25;
        final remaining = sceneRemainingLevels(
          c.selectedScene,
          c.progress.completedLevels,
        );
        final heading = ArcCompletionTitle(
          ownedRegions(c.progress.pieces, c.selectedScene).length == 5
              ? l.chapterComplete
              : unseen
              ? l.newPatch
              : sceneTitle(c.selectedScene),
        );
        final scene = CollectionCelebrationHero(
          child: SceneArt(
            scene: c.selectedScene,
            pieces: c.progress.pieces,
            reveal: unseen ? int.parse(piece.split(':').last) : null,
          ),
        );
        final progress = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CollectionSurface(
              key: const Key('reward-patch-tray'),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: CollectionPatchSlots(
                scene: c.selectedScene,
                pieces: c.progress.pieces,
              ),
            ),
            const SizedBox(height: 4),
            CollectionProgressText(
              scene: c.selectedScene,
              pieces: c.progress.pieces,
              remainingLevels: remaining == 0 ? null : remaining,
              showTitle: true,
            ),
          ],
        );
        final controls = CollectionActions(
          compactSecondary:
              box.hasBoundedHeight &&
              actions.length > 2 &&
              (box.maxHeight < 620 || largeText),
          children: actions,
        );
        final footer = piece != null && c.progress.pieces.contains(piece)
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.addedCollection,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : const SizedBox.shrink();
        if (!box.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              scene,
              progress,
              const SizedBox(height: 12),
              controls,
              footer,
            ],
          );
        }
        final details = Column(children: [heading, progress, scene, footer]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: largeText
                  ? SingleChildScrollView(
                      key: const Key('reward-details'),
                      child: details,
                    )
                  : Column(
                      children: [
                        heading,
                        Expanded(child: Center(child: scene)),
                        progress,
                      ],
                    ),
            ),
            SizedBox(height: largeText ? 6 : 10),
            controls,
            if (!largeText) footer,
          ],
        );
      },
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
    if (kind == SettlementKind.daily &&
        MediaQuery.textScalerOf(context).scale(16) <= 22) {
      return DailyReferenceCompletion(controller: c);
    }
    final finalStory = kind == SettlementKind.finalStory,
        patch = kind == SettlementKind.patch || kind == SettlementKind.chapter;
    final title = finalStory
        ? l.storyComplete
        : kind == SettlementKind.daily
        ? l.dailyComplete
        : kind == SettlementKind.replay
        ? l.puzzleComplete
        : l.beautifullySorted;
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
      ] else if (kind == SettlementKind.daily) ...[
        FilledButton(
          key: const Key('daily-calendar'),
          onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
          child: Text(l.dailyPuzzle),
        ),
        if (s.puzzleDate == c.today.date && c.library.daily != null)
          OutlinedButton(
            key: const Key('daily-replay'),
            onPressed: c.busy ? null : c.startToday,
            child: Text(l.replayToday),
          ),
      ] else if (patch)
        FilledButton(
          key: const Key('view-patch'),
          onPressed: c.busy ? null : c.viewPatch,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(l.viewPatch, textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        )
      else
        FilledButton(
          key: const Key('next'),
          onPressed: c.busy ? null : c.nextLevel,
          child: Text(l.nextLevel),
        ),
      TextButton(
        key: const Key('home'),
        onPressed: c.busy ? null : c.goHome,
        child: Text(l.home),
      ),
    ];
    final saved = c.phase == SavePhase.clean && c.receipt != null;
    final badge = saved
        ? _CompletionFeedback(
            key: Key('completion-feedback-${s.id}'),
            child: Semantics(
              label: l.firstClearSaved,
              liveRegion: true,
              child: ClipPath(
                clipper: const CompletionMedallionClipper(),
                child: const ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    4,
                    0,
                    -4,
                    0,
                    225,
                  ]),
                  child: CompletionReferenceArt(
                    source: Rect.fromLTWH(166, 164, 157, 147),
                  ),
                ),
              ),
            ),
          )
        : null;
    return LayoutBuilder(
      builder: (context, box) {
        final compact = compactCompletion(
          box,
          MediaQuery.textScalerOf(context),
        );
        final Widget hero = kind == SettlementKind.daily
            ? _CompletionFeedback(
                key: saved ? Key('completion-feedback-${s.id}') : null,
                child: Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      children: [
                        CalendarArt(
                          day: int.parse(s.puzzleDate!.split('-').last),
                          size: 180,
                        ),
                        if (saved)
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: KnitArt(
                              name: 'success',
                              width: 64,
                              height: 64,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : CompletionBottles(
                key: const Key('completion-preview'),
                state: s,
                settings: c.settings,
                badge: compact ? null : badge,
                singleRow: compact,
              );
        if (compact) {
          return CompactCompletionLayout(
            controller: c,
            title: title,
            hero: hero,
            badge: kind == SettlementKind.daily ? null : badge,
            actions: actions,
            availableHeight: box.maxHeight,
          );
        }
        return CompletionReferenceLayout(
          controller: c,
          title: title,
          hero: hero,
          primary: actions.first,
          secondary: _SettlementActions(
            referenceCompletion: true,
            children: actions.skip(1).toList(),
          ),
        );
      },
    );
  }
}

/// Buttons are laid out from their real text height, never scaled or clipped.
/// Only the read-only celebration/description region above them can scroll.
class _SettlementActions extends StatelessWidget {
  const _SettlementActions({
    required this.children,
    this.referenceCompletion = false,
  });
  final List<Widget> children;
  final bool referenceCompletion;
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
          style: compact(theme.outlinedButtonTheme.style).copyWith(
            minimumSize: WidgetStatePropertyAll(
              Size(48, referenceCompletion ? 60 : 48),
            ),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
          final secondary = children.skip(1).toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (referenceCompletion)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: SizedBox(
                      width: double.infinity,
                      child: children.first,
                    ),
                  ),
                )
              else
                children.first,
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < secondary.length; i++)
                      SizedBox(
                        width:
                            largeText ||
                                secondary.length == 1 ||
                                (secondary.length.isOdd &&
                                    i == secondary.length - 1)
                            ? box.maxWidth
                            : (box.maxWidth - 8) / 2,
                        child: secondary[i],
                      ),
                  ],
                ),
              ],
            ],
          );
        },
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
