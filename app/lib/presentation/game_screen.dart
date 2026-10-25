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
import 'reference_extra_art.dart';
import 'reference_play_art.dart';
import 'parallel_navigation/settings_reference_art.dart';

ButtonStyle _gameDialogActionStyle(bool primary, {bool largeText = false}) =>
    OutlinedButton.styleFrom(
      minimumSize: Size(48, primary ? 64 : 60),
      padding: EdgeInsets.symmetric(
        horizontal: largeText ? 0 : 14,
        vertical: largeText ? 8 : 12,
      ),
      foregroundColor: primary
          ? const Color(0xff133000)
          : const Color(0xff080a74),
      backgroundColor: Colors.transparent,
      side: BorderSide.none,
      textStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        height: 1.1,
        fontWeight: FontWeight.w900,
      ),
    ).copyWith(
      backgroundBuilder: (_, states, child) => Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: states.contains(WidgetState.disabled) ? .5 : 1,
              child: ReferenceExtraSurface(
                tileEdges: true,
                kind: primary
                    ? ExtraSurfaceKind.primary
                    : ExtraSurfaceKind.secondary,
              ),
            ),
          ),
          ?child,
        ],
      ),
    );

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.puzzles = const [],
    this.advanceTestDay,
    this.audio,
    this.debugBoardPresentation,
    this.debugBoardPagePresentation,
  });
  final GameController controller;
  final List<Puzzle> puzzles;
  final VoidCallback? advanceTestDay;
  final GameAudio? audio;
  final Widget Function(BoardView)? debugBoardPresentation;
  final Widget Function(BoardPage)? debugBoardPagePresentation;
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
        barrierColor: key == 'confirm-restart'
            ? const Color(0x6639659a)
            : Colors.black54,
        builder: (context) => key == 'confirm-restart'
            ? _restartCard(context, title, body, action)
            : key == 'confirm-reset'
            ? Builder(
                builder: (context) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(22) > 44;
                  return Dialog(
                    key: const Key('reset-card'),
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                    insetPadding: EdgeInsets.all(largeText ? 8 : 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ReferenceExtraSurface(
                              kind: ExtraSurfaceKind.pause,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(largeText ? 16 : 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Flexible(
                                  child: SingleChildScrollView(
                                    key: const Key('reset-details'),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SettingsReferenceIcon(
                                          source: Rect.fromLTWH(
                                            63,
                                            890,
                                            53,
                                            57,
                                          ),
                                          destructive: true,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            height: 1.1,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          body,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  autofocus: true,
                                  style: _gameDialogActionStyle(
                                    true,
                                    largeText: largeText,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    l.keepProgress,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  key: Key(key),
                                  style: _gameDialogActionStyle(
                                    false,
                                    largeText: largeText,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    action,
                                    textAlign: TextAlign.center,
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
              )
            : AlertDialog(
                scrollable: true,
                title: Text(title),
                content: Text(body),
                actions: [
                  FilledButton(
                    autofocus: true,
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.keepPlaying),
                  ),
                  TextButton(
                    key: Key(key),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(action),
                  ),
                ],
              ),
      ) ??
      false;
  Widget _restartCard(
    BuildContext context,
    String title,
    String body,
    String action,
  ) {
    final largeText = MediaQuery.textScalerOf(context).scale(22) > 44;
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!largeText) ...[
          const Center(
            child: SizedBox(
              width: 84,
              height: 84,
              child: ColorFiltered(
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
                  -25,
                  0,
                  25,
                  0,
                  0,
                ]),
                child: ReferencePlayArt(
                  asset: 'assets/art/p05-reference/reference-recovery.png',
                  imageSize: Size(1477, 1065),
                  source: Rect.fromLTWH(1186, 343, 94, 94),
                  radius: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final panel = Stack(
      children: [
        const Positioned.fill(
          child: ReferenceExtraSurface(kind: ExtraSurfaceKind.pause),
        ),
        Padding(
          padding: largeText
              ? const EdgeInsets.fromLTRB(16, 60, 16, 16)
              : const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (largeText)
                Flexible(
                  child: SingleChildScrollView(
                    key: const Key('restart-context'),
                    child: details,
                  ),
                )
              else
                details,
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('restart-keep'),
                autofocus: true,
                style: _gameDialogActionStyle(true, largeText: largeText),
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.keepPlaying, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('confirm-restart'),
                style: _gameDialogActionStyle(false, largeText: largeText),
                onPressed: () => Navigator.pop(context, true),
                child: Text(action, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const Key('restart-close'),
              tooltip: l.close,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context, false),
              icon: const ReferenceExtraArt(
                source: Rect.fromLTWH(383, 308, 72, 72),
                radius: 12,
              ),
            ),
          ),
        ),
      ],
    );
    final dialog = Dialog(
      key: const Key('restart-card'),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      elevation: 0,
      insetPadding: EdgeInsets.all(largeText ? 8 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeText ? 360 : 340),
        child: largeText ? panel : SingleChildScrollView(child: panel),
      ),
    );
    return largeText
        ? Semantics(namesRoute: true, label: title, child: dialog)
        : dialog;
  }

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
    var failureVisible = c.phase == SavePhase.failed;
    if (c.motion != null) c.completeMotion(c.motion!.token);
    c.cancelHint();
    _audioPaused = true;
    c.services?.ads.update(modal: true);
    c.setPaused(true);
    _syncAudio();
    try {
      action = await showKnitDialog<String>(
        context: context,
        barrierColor: const Color(0x6639659a),
        builder: (dialogContext) => ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            if (c.phase == SavePhase.failed) failureVisible = true;
            if (c.phase == SavePhase.clean) failureVisible = false;
            final failed = failureVisible;
            final scaledTitle = MediaQuery.textScalerOf(context).scale(22);
            final largeText =
                scaledTitle > 44 || (failed && scaledTitle > 28.6);
            final saving = c.phase == SavePhase.saving;
            final status = c.phase == SavePhase.saving
                ? l.saving
                : c.phase == SavePhase.clean
                ? l.pauseSaved
                : failed && largeText
                ? l.progressNotSaved
                : l.pauseMemory;
            final details = <Widget>[
              if (!largeText) ...[
                if (!failed)
                  const Center(
                    child: KnitArt(name: 'moon', width: 52, height: 52),
                  ),
                if (!failed) const SizedBox(height: 8),
                Text(
                  failed ? l.progressNotSaved : l.pauseTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (c.current?.puzzle.mainLevel != null)
                  Text(
                    l.levelMoves(
                      c.current!.puzzle.mainLevel!,
                      c.current!.moveCount,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ] else ...[
                Semantics(
                  label: failed && !saving ? l.pauseMemory : null,
                  excludeSemantics: failed && !saving,
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ];
            final recoveryAndResume = <Widget>[
              if (failed) ...[
                FilledButton(
                  key: const Key('pause-retry'),
                  style: _gameDialogActionStyle(true, largeText: largeText),
                  onPressed: saving ? null : c.retry,
                  child: Text(l.retry, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('pause-stay'),
                  style: _gameDialogActionStyle(false, largeText: largeText),
                  onPressed: saving ? null : c.stayHere,
                  child: Text(l.stayHere, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                key: const Key('resume-pause'),
                style: _gameDialogActionStyle(!failed, largeText: largeText),
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l.resumeGame, textAlign: TextAlign.center),
              ),
            ];
            final navigation = <Widget>[
              SizedBox(height: largeText ? 12 : 8),
              OutlinedButton(
                key: const Key('pause-restart'),
                style: _gameDialogActionStyle(false, largeText: largeText),
                onPressed: () {
                  Navigator.pop(dialogContext, 'restart');
                },
                child: Text(l.restart, textAlign: TextAlign.center),
              ),
              SizedBox(height: largeText ? 12 : 8),
              OutlinedButton(
                key: const Key('pause-home'),
                style: _gameDialogActionStyle(false, largeText: largeText),
                onPressed: () {
                  Navigator.pop(dialogContext, 'home');
                },
                child: Text(l.home, textAlign: TextAlign.center),
              ),
            ];
            // At large system text, keep real actions in view and let only
            // repeated context scroll. Never reduce the user's text scale.
            final recover = largeText && failed;
            final panel = Stack(
              children: [
                const Positioned.fill(
                  child: ReferenceExtraSurface(kind: ExtraSurfaceKind.pause),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    largeText && failed ? 8 : 24,
                    largeText || failed ? 60 : 26,
                    largeText && failed ? 8 : 24,
                    largeText || failed ? 24 : 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (largeText)
                        Flexible(
                          child: SingleChildScrollView(
                            key: const Key('pause-context'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...details,
                                if (recover) ...navigation,
                              ],
                            ),
                          ),
                        )
                      else
                        ...details,
                      SizedBox(height: largeText || failed ? 16 : 12),
                      ...recoveryAndResume,
                      if (!recover) ...navigation,
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const Key('pause-close'),
                      tooltip: l.close,
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const ReferenceExtraArt(
                        source: Rect.fromLTWH(383, 308, 72, 72),
                        radius: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
            return Dialog(
              key: const Key('pause-card'),
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: largeText && failed ? 8 : 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: largeText && failed ? 360 : 340,
                ),
                child: largeText ? panel : SingleChildScrollView(child: panel),
              ),
            );
          },
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
      // A retained outgoing page must keep its own scroll/constraint policy.
      // Its LayoutBuilder can run after the live controller navigates elsewhere.
      final renderedPage = c.page;
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
        GamePage.collection => l.yourCollection,
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
        GamePage.board => Builder(
          builder: (context) {
            final board = BoardPage(
              controller: c,
              onRestart: _restart,
              onPause: _pause,
              onExtra: () => showExtraBottle(context, c),
              debugBoardPresentation: widget.debugBoardPresentation,
            );
            return kDebugMode && widget.debugBoardPagePresentation != null
                ? widget.debugBoardPagePresentation!(board)
                : board;
          },
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
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final bounded = {
                          GamePage.board,
                          GamePage.completion,
                          GamePage.reward,
                          GamePage.scene,
                        }.contains(renderedPage);
                        final notices = Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (renderedPage != GamePage.board)
                              RewardStatus(controller: c, compact: bounded),
                            if (c.library.engineering &&
                                renderedPage != GamePage.board)
                              Text(
                                l.developmentNotice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (c.recoveryNotice != null &&
                                renderedPage != GamePage.board)
                              Text(
                                c.recoveryNotice == 'recovered'
                                    ? l.recoveredSave
                                    : l.unavailableSave,
                              ),
                            if (c.notice != null &&
                                renderedPage != GamePage.board)
                              Semantics(
                                liveRegion: true,
                                child: Text(noticeLabel(l, c.notice!)),
                              ),
                          ],
                        );
                        final header =
                            renderedPage == GamePage.home ||
                                renderedPage == GamePage.board ||
                                renderedPage == GamePage.completion
                            ? null
                            : KnitHeader(
                                title: renderedPage == GamePage.reward
                                    ? l.yourCollection
                                    : renderedPage == GamePage.completion
                                    ? (c.current?.slot == 'daily'
                                          ? l.dailyPuzzle
                                          : l.level(
                                              c.current!.puzzle.mainLevel!,
                                            ))
                                    : title,
                                compact:
                                    bounded && renderedPage != GamePage.scene,
                                backLabel: renderedPage == GamePage.rules
                                    ? l.settings
                                    : l.home,
                                backKey: Key(
                                  renderedPage == GamePage.completion
                                      ? 'page-back'
                                      : 'home',
                                ),
                                onBack: c.phase == SavePhase.saving
                                    ? null
                                    : renderedPage == GamePage.rules
                                    ? () => c.navigate(GamePage.settings)
                                    : c.goHome,
                              );
                        final content = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (bounded && header != null) header,
                            if (c.phase == SavePhase.failed &&
                                renderedPage != GamePage.board)
                              SaveFailureNotice(
                                key: const Key('save-failed'),
                                controller: c,
                                compact: bounded,
                              ),
                            if (bounded)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 56,
                                ),
                                child: SingleChildScrollView(
                                  key: const Key('session-explanations'),
                                  child: notices,
                                ),
                              )
                            else
                              notices,
                            if (bounded) Expanded(child: body) else body,
                            SizedBox(height: bounded ? 2 : 14),
                            if (renderedPage != GamePage.board &&
                                !(c.phase == SavePhase.clean &&
                                    c.receipt != null &&
                                    (renderedPage == GamePage.completion ||
                                        (renderedPage == GamePage.reward &&
                                            c.receipt!.piece != null &&
                                            c.progress.pieces.contains(
                                              c.receipt!.piece,
                                            )))))
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
                                renderedPage == GamePage.home)
                              TextButton(
                                key: const Key('advance-test-day'),
                                onPressed: widget.advanceTestDay,
                                child: const Text(
                                  'Development: advance local test day',
                                ),
                              ),
                          ],
                        );
                        if (bounded) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: content,
                          );
                        }
                        final scroll = SingleChildScrollView(
                          key: PageStorageKey(
                            instance != null
                                ? 'scroll-${renderedPage.name}-$instance'
                                : renderedPage == GamePage.scene
                                ? 'scroll-scene-${c.selectedScene}'
                                : 'scroll-${renderedPage.name}',
                          ),
                          primary: false,
                          // These are menu panels over a stationary backdrop,
                          // not a pull-to-refresh surface. Keep their edges in
                          // the viewport; dialogs and board input are unchanged.
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: content,
                        );
                        return Column(
                          children: [
                            if (header != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  0,
                                ),
                                child: header,
                              ),
                            Expanded(
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(overscroll: false),
                                child: scroll,
                              ),
                            ),
                          ],
                        );
                      },
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
