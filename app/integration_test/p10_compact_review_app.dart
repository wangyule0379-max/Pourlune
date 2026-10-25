// Unapproved responsive-composition candidate. Never imported by main/Bootstrap.
import 'package:flutter/material.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/bottle.dart' show ink, cream;
import 'package:pourlune_dev/presentation/completion_bottles.dart';
import 'package:pourlune_dev/presentation/labels.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/reference_extra_art.dart';

import 'p10_completion_review_app.dart' show runP10Review;

Future<void> main() => runP10Review(
  expectedDatabase: 'p10_compact_review.sqlite',
  initialCase: 'final60',
  reviewApp: (c) => CompactCompletionReview(controller: c),
);

class CompactCompletionReview extends StatelessWidget {
  const CompactCompletionReview({
    super.key,
    required this.controller,
    this.textScaler,
  });
  final GameController controller;
  final TextScaler? textScaler;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) {
      if (controller.page != GamePage.completion) {
        return PourluneApp(controller: controller, textScaler: textScaler);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          fontFamily: 'Nunito',
          colorScheme: ColorScheme.fromSeed(seedColor: ink, surface: cream),
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'Nunito',
            bodyColor: ink,
            displayColor: ink,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler ?? MediaQuery.textScalerOf(context),
          ),
          child: child!,
        ),
        home: _CompactResult(controller),
      );
    },
  );
}

class _CompactResult extends StatelessWidget {
  const _CompactResult(this.c);
  final GameController c;
  Future<void> navigate(GamePage page) async {
    final piece = c.receipt?.piece;
    if (piece != null && !c.progress.revealedPieces.contains(piece)) {
      await c.acknowledgeReveal(destination: page);
    } else {
      await c.navigate(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        s = c.current!,
        kind = c.settlementKind;
    final finalStory = kind == SettlementKind.finalStory;
    final scene = s.slot == 'daily' ? null : sceneForLevel(s.puzzle.mainLevel!);
    final saved = c.phase == SavePhase.clean && c.receipt != null;
    final title = finalStory
        ? l.storyComplete
        : kind == SettlementKind.daily
        ? l.dailyComplete
        : kind == SettlementKind.replay
        ? l.puzzleComplete
        : l.beautifullySorted;
    final small = MediaQuery.sizeOf(context).height < 700;
    final textStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: small ? 14 : 16,
      height: 1.05,
      fontWeight: FontWeight.w900,
      color: ink,
    );
    Widget button(
      String key,
      String text,
      VoidCallback action, {
      bool primary = false,
    }) => SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: Key(key),
        onPressed: c.busy ? null : action,
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              backgroundColor: Colors.transparent,
              foregroundColor: ink,
              textStyle: textStyle,
            ).copyWith(
              backgroundBuilder: (_, _, child) => Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: ReferenceExtraSurface(
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
      ),
    );
    Widget card(Widget child) => Stack(
      children: [
        const Positioned.fill(child: ReferenceExtraSurface()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: child,
        ),
      ],
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/art/backgrounds/game.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The review label is deliberately visible; this is not a release screen.
                const Text(
                  'UNAPPROVED · compact layout QA',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 10),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: l.home,
                        onPressed: c.goHome,
                        icon: const CompletionReferenceArt(
                          source: Rect.fromLTWH(26, 52, 72, 68),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.slot == 'daily'
                            ? l.dailyPuzzle
                            : l.level(s.puzzle.mainLevel!),
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Semantics(
                        label: saved ? l.firstClearSaved : l.pendingCompletion,
                        child: ClipPath(
                          clipper: const CompletionMedallionClipper(),
                          child: const CompletionReferenceArt(
                            source: Rect.fromLTWH(166, 164, 157, 147),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textStyle.copyWith(fontSize: small ? 20 : 24),
                      ),
                    ),
                    if (finalStory)
                      IconButton(
                        tooltip: l.storyComplete,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l.storyComplete),
                            content: Text(l.storyCompleteBody),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l.close),
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(Icons.info_outline),
                      ),
                  ],
                ),
                Expanded(
                  child: CompletionBottles(
                    key: const Key('completion-preview'),
                    state: s,
                    settings: c.settings,
                    singleRow: true,
                  ),
                ),
                card(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (scene != null && kind != SettlementKind.replay) ...[
                        Text(
                          sceneTitle(scene),
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(fontSize: small ? 17 : 20),
                        ),
                        Text(
                          l.completionLevels(
                            c.progress.completedLevels
                                .where((n) => sceneForLevel(n) == scene)
                                .length,
                            20,
                          ),
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(fontSize: 16),
                        ),
                      ],
                      if (saved && c.receipt?.piece != null) ...[
                        const Divider(height: 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 34,
                              height: 28,
                              child: CompletionReferenceArt(
                                source: Rect.fromLTWH(92, 838, 80, 65),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l.newPatch,
                                textAlign: TextAlign.center,
                                style: textStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (kind == SettlementKind.chapter || finalStory)
                        Text(
                          l.chapterComplete,
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(fontSize: 14),
                        ),
                      if (kind == SettlementKind.replay ||
                          kind == SettlementKind.daily ||
                          !saved)
                        Text(
                          !saved
                              ? l.pendingCompletion
                              : kind == SettlementKind.replay
                              ? l.replayComplete
                              : l.stampSaved(s.puzzleDate!),
                          textAlign: TextAlign.center,
                          style: textStyle,
                        ),
                      const SizedBox(height: 6),
                      button(
                        finalStory
                            ? 'daily-final'
                            : kind == SettlementKind.replay
                            ? 'replay-again'
                            : kind == SettlementKind.patch
                            ? 'view-patch'
                            : 'next',
                        finalStory || kind == SettlementKind.daily
                            ? l.dailyPuzzle
                            : kind == SettlementKind.replay
                            ? l.replayAgain
                            : kind == SettlementKind.patch
                            ? l.viewPatch
                            : kind == SettlementKind.chapter
                            ? l.continueChapter
                            : l.nextLevel,
                        () {
                          if (finalStory || kind == SettlementKind.daily) {
                            navigate(GamePage.daily);
                          } else if (kind == SettlementKind.patch) {
                            c.viewPatch();
                          } else if (kind == SettlementKind.replay) {
                            c.startLevel(s.puzzle.mainLevel!);
                          } else {
                            c.nextLevel();
                          }
                        },
                        primary: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (finalStory)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: button(
                          'view-collection',
                          l.viewCollection,
                          () => navigate(GamePage.collection),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: button(
                          'replay-levels',
                          l.replayLevels,
                          () => navigate(GamePage.chapters),
                        ),
                      ),
                    ],
                  )
                else if (kind == SettlementKind.chapter)
                  button(
                    'view-collection',
                    l.viewCollection,
                    () => navigate(GamePage.collection),
                  ),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    key: const Key('home'),
                    onPressed: c.goHome,
                    child: Text(l.home, style: textStyle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
