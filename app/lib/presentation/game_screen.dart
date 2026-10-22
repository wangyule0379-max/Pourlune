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
import 'service_views.dart';
import 'motion.dart';
import 'scene_art.dart';

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
  bool _pauseOpen = false;
  GamePage _motionPage = GamePage.home;
  String? _motionInstance;
  KnitPageTransition _transition = KnitPageTransition.fadeThrough;
  bool _motionBack = false, _retainPrevious = true;
  String? _warmedInstance;
  void _warmUpcoming() {
    final state = c.current;
    if (!mounted ||
        c.page != GamePage.board ||
        state == null ||
        _warmedInstance == state.id) {
      return;
    }
    _warmedInstance = state.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        precacheImage(
          knitArtImage(context, 'success', width: 96),
          context,
          onError: (_, _) {},
        ),
      );
      final level = state.puzzle.mainLevel;
      if (level == null || level % 4 != 0) return;
      final scene = sceneForLevel(level);
      unawaited(
        warmScene(context, scene, [
          ...c.progress.pieces,
          '$scene:${((level - 1) % 20) ~/ 4 + 1}',
        ], (MediaQuery.sizeOf(context).width - 32).clamp(0.0, 1254.0)),
      );
    });
  }

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
    c.addListener(_warmUpcoming);
    _warmUpcoming();
    _syncAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && c.page == GamePage.home) {
        unawaited(c.services?.prepareAdsPrivacy());
      }
    });
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
    c.removeListener(_warmUpcoming);
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
      await showKnitDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
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
    await showKnitDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
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
    if (_pauseOpen || !mounted) return;
    _pauseOpen = true;
    String? action;
    if (c.motion != null) c.completeMotion(c.motion!.token);
    c.cancelHint();
    _audioPaused = true;
    c.services?.ads.update(modal: true);
    c.setPaused(true);
    _syncAudio();
    try {
      action = await showKnitDialog<String>(
        context: context,
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
                          Navigator.pop(dialogContext, 'restart');
                        },
                        child: Text(l.restart, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('pause-home'),
                        onPressed: () {
                          Navigator.pop(dialogContext, 'home');
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
      _pauseOpen = false;
      _audioPaused = false;
      c.services?.ads.update(modal: false);
      c.setPaused(false);
      if (mounted) _syncAudio();
    }
    if (!mounted) return;
    if (action == 'restart') await _restart();
    if (action == 'home') await c.goHome();
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
      final instance =
          {
            GamePage.board,
            GamePage.completion,
            GamePage.reward,
          }.contains(c.page)
          ? c.current?.id
          : null;
      if (_motionPage != c.page || _motionInstance != instance) {
        final previous = _motionPage;
        final related =
            (previous == GamePage.settings && c.page == GamePage.rules) ||
            (previous == GamePage.rules && c.page == GamePage.settings);
        final detail =
            (previous == GamePage.collection && c.page == GamePage.scene) ||
            (previous == GamePage.scene && c.page == GamePage.collection);
        _transition = c.page == GamePage.board || related
            ? KnitPageTransition.horizontal
            : detail ||
                  c.page == GamePage.completion ||
                  c.page == GamePage.reward ||
                  (previous == GamePage.reward && c.page == GamePage.scene) ||
                  (previous == GamePage.completion && c.page == GamePage.scene)
            ? KnitPageTransition.scaled
            : KnitPageTransition.fadeThrough;
        _motionBack =
            c.page == GamePage.home ||
            (_motionPage == GamePage.rules && c.page == GamePage.settings) ||
            (_motionPage == GamePage.scene && c.page == GamePage.collection);
        // A live outgoing board would own a second motion presenter. Dispose it
        // on departure; the incoming page still fades over the fixed background.
        _retainPrevious =
            _motionPage != GamePage.board && c.page != GamePage.board;
        _motionPage = c.page;
        _motionInstance = instance;
      }
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
          onPrivacy: () => showPrivacyChoices(context, c),
          onFeedback: () => openSupportEntry(context, c, feedback: true),
        ),
        GamePage.rules => RulesPage(controller: c),
        GamePage.board => BoardPage(
          controller: c,
          onRestart: _restart,
          onPause: _pause,
          onExtra: () => showExtraBottle(context, c),
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
                  child: PageMotion(
                    page: (
                      c.page,
                      c.page == GamePage.scene ? c.selectedScene : '',
                      instance,
                    ),
                    back: _motionBack,
                    transition: _transition,
                    animateInitial: c.page == GamePage.home,
                    retainPrevious: _retainPrevious,
                    immediate: c.phase == SavePhase.failed,
                    child: SingleChildScrollView(
                      key: PageStorageKey(
                        instance != null
                            ? 'scroll-${c.page.name}-$instance'
                            : c.page == GamePage.scene
                            ? 'scroll-scene-${c.selectedScene}'
                            : 'scroll-${c.page.name}',
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (c.page != GamePage.home &&
                              c.page != GamePage.board)
                            KnitHeader(
                              title:
                                  c.page == GamePage.completion ||
                                      c.page == GamePage.reward
                                  ? (c.current?.slot == 'daily'
                                        ? l.dailyPuzzle
                                        : l.level(c.current!.puzzle.mainLevel!))
                                  : title,
                              backLabel: c.page == GamePage.rules
                                  ? l.settings
                                  : l.home,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
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
                          RewardStatus(controller: c),
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
        ),
      );
    },
  );
}
