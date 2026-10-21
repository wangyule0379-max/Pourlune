import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../application/game_audio.dart';
import '../data/content_library.dart';
import '../l10n/app_localizations.dart';
import 'board_page.dart';
import 'collection_pages.dart';
import 'navigation_pages.dart';
import 'settings_page.dart';
import 'labels.dart';
import 'knit_components.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.puzzles = const [],
    this.advanceTestDay,
    this.audio,
  });
  final GameController controller;
  final List<Puzzle> puzzles;
  final VoidCallback? advanceTestDay;
  final GameAudio? audio;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameController get c => widget.controller;
  AppLocalizations get l => AppLocalizations.of(context);
  bool _inForeground = true, _audioPaused = false;
  final _presentedRevealSounds = <String>{};
  void _syncAudio() {
    final audio = widget.audio;
    if (audio == null) return;
    unawaited(
      audio.update(
        settings: c.settings,
        foreground: _inForeground,
        paused: _audioPaused,
      ),
    );
    final piece = c.receipt?.piece;
    if ((c.page == GamePage.reward ||
            (c.page == GamePage.completion &&
                (c.settlementKind == SettlementKind.chapter ||
                    c.settlementKind == SettlementKind.finalStory))) &&
        piece != null &&
        !c.progress.revealedPieces.contains(piece) &&
        _presentedRevealSounds.add('${c.current!.id}:$piece')) {
      unawaited(audio.play(GameSound.reveal));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inForeground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    c.addListener(_syncAudio);
    _syncAudio();
    if (c.library.main.isEmpty && widget.puzzles.isNotEmpty) {
      c.library = ContentLibrary(
        main: {for (final p in widget.puzzles) p.mainLevel!: p},
        engineering: true,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_syncAudio);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    c.setForeground(_inForeground);
    _syncAudio();
  }

  Future<bool> _confirm(
    String title,
    String body,
    String action,
    String key,
  ) async =>
      await showDialog<bool>(
        context: context,
        animationStyle: c.settings.reducedMotion
            ? AnimationStyle.noAnimation
            : null,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: key == 'confirm-reset'
              ? [
                  FilledButton(
                    autofocus: true,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffb9d89f),
                      foregroundColor: const Color(0xff061b78),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.keepProgress),
                  ),
                  TextButton(
                    key: Key(key),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(action),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.keepPlaying),
                  ),
                  FilledButton(
                    key: Key(key),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(action),
                  ),
                ],
        ),
      ) ??
      false;
  Future<void> _info(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  Future<void> _play(int level) async {
    if (c.busy) return;
    if (c.deferNavigationUntilSaved(() => _play(level))) return;
    if (c.ordinary != null &&
        !c.ordinary!.completed &&
        c.ordinary!.puzzle.mainLevel == level) {
      await c.resumeSlot('ordinary');
      return;
    }
    if (!c.library.main.containsKey(level)) {
      await _info(l.missing, l.contentUnavailable);
      return;
    }
    var replace = false;
    if (c.ordinary != null && !c.ordinary!.completed) {
      replace = await _confirm(
        l.replaceTitle,
        l.replaceBody,
        l.replace,
        'confirm-replace',
      );
      if (!replace || !mounted) return;
    }
    await c.startLevel(level, replace: replace);
  }

  Future<void> _engineering(Puzzle puzzle) async {
    if (!kDebugMode || c.busy) return;
    if (c.deferNavigationUntilSaved(() => _engineering(puzzle))) return;
    var replace = false;
    if (c.ordinary != null && !c.ordinary!.completed) {
      replace = await _confirm(
        l.replaceTitle,
        l.replaceBody,
        l.replace,
        'confirm-replace',
      );
      if (!replace || !mounted) return;
    }
    await c.start(
      puzzle,
      replace: replace,
      replay: c.progress.completedLevels.contains(puzzle.mainLevel),
    );
  }

  Future<void> _today() async {
    if (c.busy) return;
    if (c.deferNavigationUntilSaved(_today)) return;
    final existing = c.daily;
    var replace = false;
    if (existing != null &&
        !existing.completed &&
        existing.puzzleDate != c.clock().date) {
      replace = await _confirm(
        l.replaceTitle,
        l.replaceDailyBody(existing.puzzleDate!),
        l.replace,
        'confirm-daily-replace',
      );
      if (!replace || !mounted) return;
    }
    await c.startToday(replace: replace);
  }

  Future<void> _restart() async {
    final extra = c.current?.extraBottleGranted ?? false;
    if (await _confirm(
      l.restartTitle,
      '${l.restartBody}${extra ? '\n${l.extraBottleStays}' : ''}',
      l.restart,
      'confirm-restart',
    )) {
      await c.restart();
    }
  }

  Future<void> _pause() async {
    if (c.motion != null) c.completeMotion(c.motion!.token);
    c.cancelHint();
    _audioPaused = true;
    _syncAudio();
    try {
      await showDialog<void>(
        context: context,
        animationStyle: c.settings.reducedMotion
            ? AnimationStyle.noAnimation
            : null,
        builder: (dialogContext) => ListenableBuilder(
          listenable: c,
          builder: (context, _) => Dialog(
            key: const Key('pause-card'),
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SingleChildScrollView(
                child: KnitPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          tooltip: l.close,
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const Center(
                        child: KnitArt(name: 'moon', width: 64, height: 64),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.pauseTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c.phase == SavePhase.clean
                            ? l.pauseSaved
                            : l.pauseMemory,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (c.phase == SavePhase.failed) ...[
                        OutlinedButton(
                          key: const Key('pause-retry'),
                          onPressed: c.retry,
                          child: Text(l.retry),
                        ),
                        TextButton(
                          key: const Key('pause-stay'),
                          onPressed: c.stayHere,
                          child: Text(l.stayHere),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FilledButton(
                        key: const Key('resume-pause'),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(l.resumeGame, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('pause-restart'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _restart();
                        },
                        child: Text(l.restart, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('pause-home'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          c.goHome();
                        },
                        child: Text(l.home, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _audioPaused = false;
      if (mounted) _syncAudio();
    }
  }

  Future<void> _reset() async {
    if (await _confirm(
      l.resetTitle,
      l.resetBody,
      l.resetProgress,
      'confirm-reset',
    )) {
      await c.resetProgress();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final title = switch (c.page) {
        GamePage.chapters => l.chapters,
        GamePage.daily => l.dailyPuzzle,
        GamePage.collection => l.collection,
        GamePage.scene => sceneTitle(c.selectedScene),
        GamePage.settings => l.settings,
        GamePage.rules => l.howToPlay,
        GamePage.progress => l.progress,
        _ => l.appTitle,
      };
      final body = switch (c.page) {
        GamePage.home => HomePage(
          controller: c,
          onPlay: _play,
          onEngineering: _engineering,
        ),
        GamePage.chapters => ChaptersPage(controller: c, onPlay: _play),
        GamePage.daily => DailyPage(controller: c, onToday: _today),
        GamePage.collection => CollectionPage(controller: c),
        GamePage.scene => ScenePage(controller: c, onPlay: _play),
        GamePage.settings => SettingsPage(
          controller: c,
          onReset: _reset,
          onPrivacy: () => _info(l.privacyChoices, l.privacyUnavailable),
          onFeedback: () => _info(l.feedback, l.supportUnavailable),
        ),
        GamePage.rules => RulesPage(controller: c),
        GamePage.board => BoardPage(
          controller: c,
          onRestart: _restart,
          onPause: _pause,
        ),
        GamePage.completion => CompletionPage(controller: c, onPlay: _play),
        GamePage.reward => RewardPage(controller: c),
        GamePage.progress =>
          kDebugMode
              ? DevelopmentProgressPage(controller: c)
              : HomePage(
                  controller: c,
                  onPlay: _play,
                  onEngineering: _engineering,
                ),
      };
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            if (c.page == GamePage.board && c.phase != SavePhase.saving) {
              _pause();
            } else if (c.page == GamePage.rules) {
              c.navigate(GamePage.settings);
            } else {
              c.goHome();
            }
          }
        },
        child: Scaffold(
          body: SizedBox.expand(
            child: DecoratedBox(
              decoration: c.settings.strongContrast
                  ? const BoxDecoration(color: Colors.white)
                  : const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/art/backgrounds/game.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: c.page == GamePage.board ? c.clearSelection : null,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.page != GamePage.home && c.page != GamePage.board)
                          KnitHeader(
                            title:
                                c.page == GamePage.completion ||
                                    c.page == GamePage.reward
                                ? (c.current?.slot == 'daily'
                                      ? l.dailyPuzzle
                                      : l.level(c.current!.puzzle.mainLevel!))
                                : title,
                            backKey: Key(
                              c.page == GamePage.completion
                                  ? 'page-back'
                                  : 'home',
                            ),
                            onBack: c.phase == SavePhase.saving
                                ? null
                                : c.page == GamePage.rules
                                ? () => c.navigate(GamePage.settings)
                                : c.goHome,
                          ),
                        if (c.library.engineering)
                          Text(
                            l.developmentNotice,
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                        if (c.phase == SavePhase.failed)
                          KnitPanel(
                            key: const Key('save-failed'),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(l.saveFailed),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilledButton(
                                        key: const Key('retry'),
                                        onPressed: c.retry,
                                        child: Text(l.retry),
                                      ),
                                      TextButton(
                                        key: const Key('stay'),
                                        onPressed: c.stayHere,
                                        child: Text(l.stayHere),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        body,
                        const SizedBox(height: 14),
                        Text(
                          c.phase == SavePhase.saving
                              ? l.saving
                              : c.phase == SavePhase.clean
                              ? l.saved
                              : l.pauseMemory,
                          key: const Key('save-status'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (kDebugMode &&
                            widget.advanceTestDay != null &&
                            c.page == GamePage.home)
                          TextButton(
                            key: const Key('advance-test-day'),
                            onPressed: widget.advanceTestDay,
                            child: const Text(
                              'Development: advance local test day',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
