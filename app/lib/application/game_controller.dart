import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../data/game_store.dart';
import '../data/content_library.dart';
import '../data/player_settings.dart';
import '../data/scenes.dart';
import '../data/reward_attempt.dart';
import '../services/service_hub.dart';
import '../services/ad_coordinator.dart';
import '../services/telemetry.dart';
import '../services/play_metrics.dart';
import 'hint_worker.dart';

/// A presentation of one already committed move. Never serialized or settled.
class PourMotion {
  const PourMotion({
    required this.token,
    required this.from,
    required this.to,
    required this.units,
    required this.before,
    required this.after,
    required this.instanceId,
    required this.revision,
    required this.reducedMotion,
  });
  final int token, from, to, units, revision;
  final Board before, after;
  final String instanceId;
  final bool reducedMotion;
  Duration get duration => Duration(milliseconds: reducedMotion ? 180 : 900);
}

enum GameFeedback { select, pour, error, complete }

enum SavePhase { clean, saving, failed }

enum GamePage {
  home,
  board,
  progress,
  chapters,
  daily,
  collection,
  scene,
  settings,
  rules,
  completion,
  reward,
}

enum SettlementKind { normal, patch, chapter, finalStory, replay, daily }

enum FlowNotice {
  locked,
  unavailable,
  replaceRequired,
  viewPatchFirst,
  settingsUnreadable,
}

enum _Write { snapshot, candidate, settings, reveal, reset }

typedef _Navigation = ({GamePage page, String? slot, String? scene});

class GameController extends ChangeNotifier {
  GameController(
    this.store, {
    ContentLibrary? library,
    LocalClock? clock,
    HintLauncher? hintLauncher,
    this.onFeedback,
    this.services,
  }) : library = library ?? ContentLibrary(main: {}),
       clock = clock ?? LocalDay.now,
       _launchHint = hintLauncher ?? runHint {
    services?.addListener(_notify);
  }
  final ServiceHub? services;
  final GameStore store;
  final void Function(GameFeedback)? onFeedback;
  PourMotion? motion;
  int _motionToken = 0;
  bool _motionPresenter = false;
  ({String instanceId, int revision})? _pendingCompletionFeedback;
  int? rejectedBottle;
  int rejectionRevision = 0;

  void attachMotionPresenter() => _motionPresenter = true;
  void detachMotionPresenter() {
    _motionPresenter = false;
    _finishMotion();
  }

  /// Token check prevents a late frame from clearing a newer presentation.
  void completeMotion(int token) {
    if (motion?.token != token) return;
    _finishMotion();
    _notify();
  }

  void _finishMotion() {
    final m = motion;
    motion = null;
    if (m != null &&
        current?.id == m.instanceId &&
        current?.revision == m.revision &&
        current!.completed &&
        page == GamePage.board) {
      page = GamePage.completion;
    }
    _presentCompletionFeedback();
  }

  void _presentCompletionFeedback() {
    final pending = _pendingCompletionFeedback;
    if (pending == null) return;
    if (current?.id != pending.instanceId ||
        current?.revision != pending.revision) {
      _pendingCompletionFeedback = null;
      return;
    }
    if (!_alive ||
        !_foreground ||
        phase != SavePhase.clean ||
        !current!.completed ||
        receipt?.instanceId != pending.instanceId ||
        motion != null ||
        page != GamePage.completion ||
        _pendingNav != null ||
        _afterWrite != null) {
      return;
    }
    // Consume before the callback: feedback cannot replay on Retry or re-entry.
    _pendingCompletionFeedback = null;
    onFeedback?.call(GameFeedback.complete);
  }

  ContentLibrary library;
  final LocalClock clock;
  final HintLauncher _launchHint;
  final _slots = <String, GameInstance?>{};
  final _receipts = <String, CompletionReceipt>{};
  final _freshCompletions = <String>{};
  GameInstance? current;
  GameInstance? get ordinary => _slots['ordinary'];
  GameInstance? get daily => _slots['daily'];
  CompletionReceipt? receipt;
  LocalProgress progress = LocalProgress(0, [], [1], 0, 0, []);
  PlayerSettings settings = const PlayerSettings();
  bool tutorialComplete = false;
  late LocalDay today = clock();
  SavePhase phase = SavePhase.clean;
  GamePage page = GamePage.home;
  String? error, recoveryNotice, rejection;
  final recoveryNotices = <String, String>{};
  FlowNotice? notice;
  String selectedScene = 'color_studio';
  _Navigation? _pendingNav;
  GameInstance? _candidate;
  String? _afterCompletion, _revealPiece;
  Future<void> Function()? _afterWrite;
  _Write _write = _Write.snapshot;
  bool _alive = true, _navigating = false, _foreground = true;
  final _metrics = <String, PlayMetrics>{};
  bool _paused = false;
  final _tutorialEvents = <String, ({TutorialStatus status, int step})>{};
  String? _failedSaveId;
  void setPaused(bool value) {
    _paused = value;
    _notify();
  }

  PlayMetrics _metric(GameInstance s) =>
      _metrics.putIfAbsent(s.id, PlayMetrics.new);
  void _syncMetrics() {
    for (final entry in _metrics.entries) {
      entry.value.sync(
        entry.key == current?.id &&
            _foreground &&
            !_paused &&
            !_adFlow &&
            !hintSearching &&
            page == GamePage.board &&
            current?.completed == false,
      );
    }
  }

  Map<String, Object> _eventPuzzle(GameInstance s) => {
    'instance_id': s.id,
    'puzzle_id': s.puzzle.id,
    'version': s.puzzle.contentVersion,
    'mode': s.slot == 'daily'
        ? 'daily'
        : s.isReplay
        ? 'replay'
        : 'main',
    'first': s.isReplay ? 0 : 1,
    'replay': s.isReplay ? 1 : 0,
  };
  void _event(ProductEvent e, String identity, Map<String, Object> fields) {
    final telemetry = services?.telemetry;
    if (telemetry != null) unawaited(telemetry.log(e, identity, fields));
  }

  Future<void> _saveMetrics() async {
    final s = current;
    if (s == null || services == null) return;
    try {
      await store.writeServiceValue('metrics:${s.id}', _metric(s).toJson());
    } catch (_) {}
  }

  bool _adFlow = false,
      _rewardSaving = false,
      _rewardDrainScheduled = false,
      _initialized = false;
  bool rewardSaveFailed = false;
  String? rewardIssue;
  final _rewardConfirmations = <String, String>{};
  final _rewardCloses = <String>{};
  final _checkedInterstitial = <String>{};
  List<RewardAttempt> pendingRewards = [];
  Future<void> Function()? _afterForeground;
  bool get busy =>
      phase == SavePhase.saving ||
      _navigating ||
      motion != null ||
      _adFlow ||
      _rewardSaving ||
      (services?.ads.showing ?? false);
  bool get offersExtraBottle =>
      current != null &&
      !current!.completed &&
      (current!.slot == 'daily' || current!.puzzle.mainLevel! >= 4);
  bool get canWatchExtraBottle =>
      offersExtraBottle &&
      !busy &&
      phase == SavePhase.clean &&
      _foreground &&
      !current!.extraBottleGranted &&
      !rewardSaveFailed &&
      !pendingRewards.any((r) => r.origin.slot == current!.slot) &&
      services != null &&
      services!.ads.ready(AdKind.rewarded) &&
      services!.ads.cooldown == Duration.zero &&
      !services!.ads.timingSaveFailed;

  bool get continueLabelIsReplay =>
      ordinary != null && !ordinary!.completed && ordinary!.isReplay;
  bool get canContinueOrdinary => ordinary != null && !ordinary!.completed;
  bool get canNext =>
      phase == SavePhase.clean &&
      current != null &&
      current!.completed &&
      current!.slot == 'ordinary' &&
      !current!.isReplay &&
      receipt?.firstClear == true &&
      receipt?.nextInstanceId == null &&
      current!.puzzle.mainLevel! < 60;

  /// Structural eligibility for a future Next-triggered SDK check, never permission to show an ad.
  bool get canCheckInterstitialOnNext =>
      canNext &&
      (page == GamePage.completion || page == GamePage.reward) &&
      _freshCompletions.contains(current!.id) &&
      !_checkedInterstitial.contains(current!.id) &&
      progress.qualifyingClears >= 3 &&
      !{20, 40}.contains(current!.puzzle.mainLevel) &&
      library.main.containsKey(current!.puzzle.mainLevel! + 1);
  SettlementKind? get settlementKind {
    final s = current;
    if (s == null || !s.completed) return null;
    if (s.slot == 'daily') return SettlementKind.daily;
    if (s.isReplay || (receipt != null && !receipt!.firstClear)) {
      return SettlementKind.replay;
    }
    if (s.puzzle.mainLevel == 60) return SettlementKind.finalStory;
    if (s.puzzle.mainLevel == 20 || s.puzzle.mainLevel == 40) {
      return SettlementKind.chapter;
    }
    return (receipt?.piece != null ||
            (receipt == null &&
                !progress.completedLevels.contains(s.puzzle.mainLevel) &&
                s.puzzle.mainLevel! % 4 == 0))
        ? SettlementKind.patch
        : SettlementKind.normal;
  }

  int? selectedSource;
  HintResult? hint;
  bool hintSearching = false;
  int _hintGeneration = 0;
  HintTask? _hintTask;
  ({String request, String instance, Stopwatch timer})? _hintEvent;
  void _finishHintEvent(String result) {
    final event = _hintEvent;
    _hintEvent = null;
    if (event == null) return;
    _event(ProductEvent.hintResult, event.request, {
      'instance_id': event.instance,
      'result': result,
      'duration_ms': event.timer.elapsedMilliseconds,
    });
    unawaited(_saveMetrics());
  }

  void _notify() {
    if (!_alive) return;
    _syncMetrics();
    notifyListeners();
    if (_rewardConfirmations.isNotEmpty &&
        !rewardSaveFailed &&
        !_rewardSaving &&
        phase == SavePhase.clean &&
        !_navigating &&
        motion == null &&
        !_rewardDrainScheduled) {
      _rewardDrainScheduled = true;
      scheduleMicrotask(() {
        _rewardDrainScheduled = false;
        unawaited(_drainRewards());
      });
    }
  }

  Future<void> _refresh() async {
    progress = await store.progress();
    tutorialComplete = await store.tutorialDone();
  }

  Future<void> initialize() async {
    if (!_initialized) {
      await store.recoverRewardIntents();
      _initialized = true;
    }
    pendingRewards = await store.pendingRewards();
    for (final slot in ['ordinary', 'daily']) {
      final saved = await store.load(slot);
      _slots[slot] = saved.instance;
      if (saved.instance != null && services != null) {
        try {
          _metrics[saved.instance!.id] = PlayMetrics.parse(
            await store.readServiceValue('metrics:${saved.instance!.id}'),
          );
        } catch (_) {}
      }
      if (saved.recovered) recoveryNotices[slot] = 'recovered';
      if (saved.unavailable) recoveryNotices[slot] = 'unavailable';
    }
    current = ordinary;
    recoveryNotice = recoveryNotices['ordinary'];
    try {
      settings = await store.readSettings();
    } catch (_) {
      notice = FlowNotice.settingsUnreadable;
    }
    for (final slot in ['ordinary', 'daily']) {
      final s = _slots[slot];
      if (s?.completed ?? false) {
        try {
          _receipts[s!.id] = await store.settle(s);
        } catch (e) {
          current = s;
          phase = SavePhase.failed;
          error = e.toString();
          break;
        }
      }
    }
    receipt = current == null ? null : _receipts[current!.id];
    if (receipt?.piece != null) {
      selectedScene = receipt!.piece!.split(':').first;
    }
    await _refresh();
    refreshToday();
    _notify();
  }

  void refreshToday() {
    if (page == GamePage.home || page == GamePage.daily) today = clock();
  }

  String _id() =>
      'dev-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  /// Explicit engineering/test entry. Product navigation uses startLevel/startToday.
  Future<void> start(
    Puzzle puzzle, {
    bool replace = false,
    bool replay = false,
  }) async {
    if (!kDebugMode) throw StateError('Engineering entry unavailable');
    if (busy || phase == SavePhase.failed) return;
    if (ordinary != null && !ordinary!.completed && !replace) {
      throw StateError('Confirm replacement');
    }
    await _startNew(
      GameInstance.create(id: _id(), puzzle: puzzle, isReplay: replay),
    );
  }

  Future<bool> startLevel(int level, {bool replace = false}) async {
    if (busy || phase == SavePhase.failed) return false;
    notice = null;
    if (!progress.unlockedLevels.contains(level)) {
      notice = FlowNotice.locked;
      _notify();
      return false;
    }
    final puzzle = library.main[level];
    if (puzzle == null ||
        (services?.policy.disabledPuzzleIds.contains(puzzle.id) ?? false)) {
      notice = FlowNotice.unavailable;
      _notify();
      return false;
    }
    if (ordinary != null && !ordinary!.completed && !replace) {
      notice = FlowNotice.replaceRequired;
      _notify();
      return false;
    }
    final replay = progress.completedLevels.contains(level);
    await _startNew(
      GameInstance.create(
        id: _id(),
        puzzle: puzzle,
        isReplay: replay,
        tutorial: level == 1 && !replay && !tutorialComplete,
      ),
    );
    return phase == SavePhase.clean;
  }

  Future<bool> startToday({bool replace = false}) async {
    if (busy || phase == SavePhase.failed) return false;
    today = clock();
    notice = null;
    if (daily != null && !daily!.completed && daily!.puzzleDate == today.date) {
      await resumeSlot('daily');
      return true;
    }
    final catalog = library.daily;
    if (catalog == null) {
      notice = FlowNotice.unavailable;
      _notify();
      return false;
    }
    if (daily != null && !daily!.completed && !replace) {
      notice = FlowNotice.replaceRequired;
      _notify();
      return false;
    }
    final puzzle = catalog.forDate(today.date);
    if (services?.policy.disabledPuzzleIds.contains(puzzle.id) ?? false) {
      notice = FlowNotice.unavailable;
      _notify();
      return false;
    }
    await _startNew(
      GameInstance.create(
        id: _id(),
        puzzle: puzzle,
        slot: 'daily',
        isReplay: progress.dailyStamps.contains(today.date),
        puzzleDate: today.date,
        timeZone: today.zone,
        offsetMinutes: today.offsetMinutes,
        catalogVersion: catalog.version,
      ),
    );
    return phase == SavePhase.clean;
  }

  Future<void> _startNew(GameInstance s, {String? afterCompletion}) async {
    _cancelHint();
    _metric(s);
    _candidate = s;
    _afterCompletion = afterCompletion;
    _write = _Write.candidate;
    _navigating = true;
    await _persist();
  }

  void resume() {
    if (current != null &&
        !busy &&
        _candidate == null &&
        _write == _Write.snapshot) {
      _cancelHint();
      page = current!.completed ? GamePage.completion : GamePage.board;
      receipt = _receipts[current!.id];
      _notify();
    }
  }

  Future<void> resumeSlot(String slot) async {
    final state = _slots[slot];
    if (state == null) return;
    await navigate(
      state.completed ? GamePage.completion : GamePage.board,
      slot: slot,
    );
  }

  /// UI actions that need validation/confirmation after a failed save share the
  /// same first-intent queue as page navigation. Stay cancels either kind.
  bool deferNavigationUntilSaved(Future<void> Function() action) {
    if (_adFlow || _rewardSaving) return true;
    _pendingCompletionFeedback = null;
    _finishMotion();
    if (!busy && phase != SavePhase.failed) return false;
    if (_pendingNav == null) _afterWrite ??= action;
    _notify();
    return true;
  }

  Future<void> navigate(GamePage target, {String? slot, String? scene}) async {
    if (_adFlow || _rewardSaving) return;
    _pendingCompletionFeedback = null;
    _finishMotion();
    _cancelHint();
    final intent = (page: target, slot: slot, scene: scene);
    if (busy || phase == SavePhase.failed) {
      if (_afterWrite == null) _pendingNav ??= intent;
      _notify();
      return;
    }
    _applyNavigation(intent);
    _notify();
  }

  void _applyNavigation(_Navigation intent) {
    if (current != null &&
        intent.page != GamePage.completion &&
        intent.page != GamePage.reward) {
      _freshCompletions.remove(current!.id);
    }
    if (intent.slot != null) {
      current = _slots[intent.slot];
      receipt = current == null ? null : _receipts[current!.id];
      if (receipt?.piece != null) {
        selectedScene = receipt!.piece!.split(':').first;
      }
      recoveryNotice = recoveryNotices[intent.slot];
    }
    if (intent.scene != null) selectedScene = intent.scene!;
    page = intent.page;
    refreshToday();
    notice = null;
  }

  Future<void> goHome() => navigate(GamePage.home);
  void showProgress() {
    navigate(GamePage.progress);
  }

  Future<void> tapBottle(int index) async {
    final s = current;
    if (!_canMutate || s == null || s.completed) return;
    if (index < 0 || index >= s.board.length) return;
    if (hintSearching) _cancelHint(clearSelection: false);
    if (selectedSource == index) {
      _cancelHint();
      _notify();
      return;
    }
    if (selectedSource == null) {
      if (s.board[index].isNotEmpty) {
        selectedSource = index;
        onFeedback?.call(GameFeedback.select);
      }
      _notify();
      return;
    }
    await pour(selectedSource!, index);
  }

  void clearSelection() {
    _cancelHint();
    _notify();
  }

  bool get _canMutate =>
      !busy && _candidate == null && _write == _Write.snapshot;
  Future<void> pour(int from, int to) async {
    if (!_canMutate || current == null) return;
    final result = current!.pour(from, to);
    rejection = result.rejection;
    if (result.changed) {
      services?.recordLegalMove();
      if (_motionPresenter && _foreground && page == GamePage.board) {
        motion = PourMotion(
          token: ++_motionToken,
          from: from,
          to: to,
          units: current!.board[from].length - result.state.board[from].length,
          before: current!.board,
          after: result.state.board,
          instanceId: current!.id,
          revision: result.state.revision,
          reducedMotion: settings.reducedMotion,
        );
      }
      onFeedback?.call(GameFeedback.pour);
      await _change(result.state);
    } else {
      rejectedBottle = to;
      rejectionRevision++;
      onFeedback?.call(GameFeedback.error);
      _notify();
    }
  }

  Future<void> undo() async {
    if (_canMutate && current != null) {
      final next = current!.undo();
      if (!identical(next, current)) _metric(current!).undos++;
      await _change(next);
    }
  }

  Future<void> restart() async {
    if (_canMutate && current != null) {
      _metric(current!).restarts++;
      await _change(current!.restart());
    }
  }

  Future<void> skipTutorial() async {
    if (_canMutate && current != null) {
      await _change(current!.skipTutorial());
    }
  }

  Future<void> _change(GameInstance state) async {
    if (identical(current, state)) return;
    _cancelHint();
    if (current?.tutorial?.active == true && state.tutorial?.finished == true) {
      _tutorialEvents[state.id] = (
        status: state.tutorial!.status,
        step: state.tutorial!.step,
      );
    }
    current = state;
    _slots[state.slot] = state;
    receipt = null;
    rejection = null;
    _pendingCompletionFeedback =
        state.completed && _foreground && page == GamePage.board
        ? (instanceId: state.id, revision: state.revision)
        : null;
    if (state.completed) {
      if (state.slot == 'ordinary' &&
          !state.isReplay &&
          !progress.completedLevels.contains(state.puzzle.mainLevel)) {
        _freshCompletions.add(state.id);
      }
      if (motion == null) {
        page = GamePage.completion;
      }
    }
    if (phase == SavePhase.failed) {
      _notify();
      return;
    }
    await _persist();
  }

  Future<void> _persist() async {
    if (phase == SavePhase.saving) return;
    phase = SavePhase.saving;
    error = null;
    _notify();
    final operation = _write;
    try {
      CompletionReceipt? completion;
      switch (operation) {
        case _Write.snapshot:
          final s = current;
          if (s == null) throw StateError('No pending snapshot');
          if (s.completed) {
            completion = await store.settle(s);
          } else {
            await store.save(s);
          }
        case _Write.candidate:
          final s = _candidate!;
          if (s.completed) {
            completion = await store.settle(s, replace: true);
          } else {
            await store.save(
              s,
              replace: true,
              afterCompletion: _afterCompletion,
            );
          }
        case _Write.settings:
          await store.saveSettings(settings);
        case _Write.reveal:
          await store.markRevealed(_revealPiece!);
        case _Write.reset:
          await store.resetProgress();
      }
      await _refresh();
      if (operation == _Write.candidate) {
        current = _candidate;
        _slots[current!.slot] = current;
        _candidate = null;
        _afterCompletion = null;
        recoveryNotices.remove(current!.slot);
        recoveryNotice = null;
        page = current!.completed ? GamePage.completion : GamePage.board;
      }
      if (operation == _Write.reset) {
        _slots.clear();
        _receipts.clear();
        _freshCompletions.clear();
        pendingRewards = [];
        _rewardConfirmations.clear();
        _rewardCloses.clear();
        rewardSaveFailed = false;
        rewardIssue = null;
        _tutorialEvents.clear();
        _metrics.clear();
        services?.continuation.clear();
        current = null;
        receipt = null;
        recoveryNotices.clear();
        recoveryNotice = null;
        page = GamePage.home;
      }
      if (operation == _Write.candidate || operation == _Write.snapshot) {
        receipt = completion;
        if (completion != null) {
          _receipts[completion.instanceId] = completion;
          if (completion.piece != null) {
            selectedScene = completion.piece!.split(':').first;
          }
        }
      }
      _write = _Write.snapshot;
      _navigating = false;
      if (_failedSaveId != null) {
        _event(ProductEvent.saveRecovered, _failedSaveId!, {
          'operation': operation.name,
          'error_category': 'storage',
        });
        _failedSaveId = null;
      }
      final saved = current;
      if (saved != null &&
          (operation == _Write.candidate || operation == _Write.snapshot)) {
        if (operation == _Write.candidate) {
          _event(ProductEvent.puzzleStart, saved.id, _eventPuzzle(saved));
        }
        if (saved.completed && completion != null) {
          final metrics = _metric(saved)..sync(false);
          _event(ProductEvent.puzzleComplete, saved.id, {
            ..._eventPuzzle(saved),
            ...metrics.toJson(),
            'moves': saved.moveCount,
            'extra_bottles': saved.extraBottleGranted ? 1 : 0,
          });
          if (completion.piece != null && completion.firstClear) {
            _event(ProductEvent.pieceGranted, completion.piece!, {
              'scene_id': completion.piece!.split(':').first,
              'piece_id': completion.piece!,
              'first': 1,
            });
          }
        }
        final tutorialEvent = _tutorialEvents.remove(saved.id);
        if (tutorialEvent != null &&
            saved.tutorial?.status == tutorialEvent.status) {
          _event(
            tutorialEvent.status == TutorialStatus.completed
                ? ProductEvent.tutorialComplete
                : ProductEvent.tutorialSkip,
            'v1',
            {'tutorial_version': 1, 'step': tutorialEvent.step},
          );
        }
        await _saveMetrics();
      }
      phase = SavePhase.clean;
      final intent = _pendingNav;
      _pendingNav = null;
      if (intent != null) _applyNavigation(intent);
      final continuation = _afterWrite;
      _afterWrite = null;
      _notify();
      if (continuation != null) {
        await continuation();
      } else {
        _presentCompletionFeedback();
      }
    } catch (e) {
      phase = SavePhase.failed;
      _navigating = false;
      error = e.toString();
      _failedSaveId ??= _id();
      _event(ProductEvent.saveFailed, _failedSaveId!, {
        'operation': operation.name,
        'error_category': 'storage',
      });
      unawaited(
        services?.recordError('storage', StackTrace.current) ??
            Future<void>.value(),
      );
      _notify();
    }
  }

  Future<void> retry() async {
    if (phase == SavePhase.failed) await _persist();
  }

  void stayHere() {
    _pendingNav = null;
    _afterWrite = null;
    _notify();
  }

  Future<void> updateSetting(String key, bool value) async {
    if (busy || phase == SavePhase.failed) return;
    settings = settings.withValue(key, value);
    _write = _Write.settings;
    await _persist();
  }

  Future<void> resetProgress() async {
    if (busy || phase == SavePhase.failed) return;
    _cancelHint();
    _write = _Write.reset;
    await _persist();
  }

  Future<void> viewPatch() async {
    if (receipt?.piece == null &&
        phase == SavePhase.failed &&
        current?.completed == true) {
      await navigate(
        GamePage.reward,
        scene: sceneForLevel(current!.puzzle.mainLevel!),
      );
      return;
    }
    if (receipt?.piece == null) return;
    await navigate(GamePage.reward, scene: receipt!.piece!.split(':').first);
  }

  Future<void> acknowledgeReveal({
    bool next = false,
    GamePage destination = GamePage.scene,
  }) async {
    if (busy || receipt?.piece == null) return;
    if (phase == SavePhase.failed) {
      if (_write == _Write.reveal &&
          _pendingNav == null &&
          _afterWrite == null) {
        if (next) {
          _afterWrite = nextLevel;
        } else {
          _pendingNav = (page: destination, slot: null, scene: selectedScene);
        }
        _notify();
      }
      return;
    }
    _write = _Write.reveal;
    _revealPiece = receipt!.piece;
    if (next) {
      _afterWrite = nextLevel;
    } else {
      _pendingNav = (page: destination, slot: null, scene: selectedScene);
    }
    await _persist();
  }

  Future<void> nextLevel() async {
    if (phase == SavePhase.failed &&
        (_write == _Write.snapshot || _write == _Write.reveal) &&
        current?.completed == true) {
      if (_pendingNav == null) _afterWrite ??= nextLevel;
      _notify();
      return;
    }
    if (busy || !canNext) return;
    if (receipt?.piece != null &&
        !progress.revealedPieces.contains(receipt!.piece)) {
      if (page != GamePage.reward && settlementKind != SettlementKind.chapter) {
        notice = FlowNotice.viewPatchFirst;
        _notify();
        return;
      }
      await acknowledgeReveal(next: true);
      return;
    }
    final source = current!,
        level = source.puzzle.mainLevel! + 1,
        puzzle = library.main[level];
    if (puzzle == null ||
        !progress.unlockedLevels.contains(level) ||
        (services?.policy.disabledPuzzleIds.contains(puzzle.id) ?? false)) {
      notice = FlowNotice.unavailable;
      _notify();
      return;
    }
    _adFlow = true;
    _notify();
    // A delayed fullscreen write may consume an older boundary after this
    // settlement was rendered. Never qualify a new show using that cached count.
    var check = false;
    try {
      await _refresh();
      check = canCheckInterstitialOnNext;
    } catch (_) {
      // An optional ad check cannot block free navigation. The next snapshot
      // still uses the existing save-failure handling if persistence fails.
    }
    _checkedInterstitial.add(source.id);
    Future<void> advance() async {
      if (!_alive) return;
      try {
        if (current?.id == source.id && canNext) {
          await _startNew(
            GameInstance.create(
              id: _id(),
              puzzle: puzzle,
              isReplay: progress.completedLevels.contains(level),
            ),
            afterCompletion: source.id,
          );
        }
      } finally {
        _adFlow = false;
        _notify();
      }
    }

    if (check && services != null) {
      final result = await services!.ads.show(AdKind.interstitial, _id());
      _event(ProductEvent.interstitialCheck, source.id, {
        'completion_id': source.id,
        'qualifying': progress.qualifyingClears,
        'result': result.shown ? 'shown' : result.reason,
      });
      await services!.ads.retryTiming();
      try {
        await _refresh();
      } catch (_) {
        // Optional ad statistics must not strand the navigation lock. Advance
        // still persists the next snapshot through the normal Retry flow.
      }
    }
    if (!_alive) return;
    if (!_foreground) {
      _afterForeground = advance;
    } else {
      await advance();
    }
  }

  Future<void> watchExtraBottle() async {
    if (!canWatchExtraBottle) return;
    final origin = current!, id = _id();
    _adFlow = true;
    rewardIssue = null;
    _cancelHint();
    _notify();
    var prepared = false;
    try {
      await store.beginReward(id, origin);
      prepared = true;
      final result = await services!.ads.show(
        AdKind.rewarded,
        id,
        onReward: () {
          if (!_alive) return;
          _event(ProductEvent.rewardConfirmed, id, {
            'request_id': id,
            'instance_id': origin.id,
          });
          _rewardConfirmations[id] = origin.id;
          _notify();
        },
      );
      if (!result.shown) rewardIssue = result.reason;
    } catch (_) {
      rewardIssue = 'prepare_failed';
    } finally {
      if (prepared) {
        try {
          await store.closeReward(id);
        } catch (_) {
          _rewardCloses.add(id);
          rewardIssue = 'close_failed';
          rewardSaveFailed = true;
        }
      }
      _adFlow = false;
      if (_alive) {
        pendingRewards = await store.pendingRewards();
        _notify();
        await _drainRewards();
      }
    }
  }

  Future<void> _reloadRewardSlots() async {
    for (final slot in ['ordinary', 'daily']) {
      _slots[slot] = (await store.load(slot)).instance;
    }
    final s = current;
    if (s != null && _slots[s.slot]?.id == s.id) current = _slots[s.slot];
    pendingRewards = await store.pendingRewards();
    await _refresh();
  }

  Future<void> _drainRewards() async {
    if (!_alive ||
        _rewardSaving ||
        rewardSaveFailed ||
        phase != SavePhase.clean ||
        _navigating ||
        motion != null ||
        _rewardConfirmations.isEmpty) {
      return;
    }
    _rewardSaving = true;
    _notify();
    try {
      for (final id in _rewardConfirmations.keys.toList()) {
        final result = await store.confirmReward(id);
        if (result != null && !result.needsRestore) {
          _event(ProductEvent.rewardGranted, result.origin.id, {
            'request_id': id,
            'instance_id': result.origin.id,
            'result': result.origin.completed
                ? 'satisfied_completed'
                : 'granted',
          });
        }
        _rewardConfirmations.remove(id);
      }
      await _reloadRewardSlots();
      rewardIssue = null;
    } catch (_) {
      rewardSaveFailed = true;
      rewardIssue = 'confirmation_save_failed';
    } finally {
      _rewardSaving = false;
      _notify();
    }
  }

  Future<void> retryReward() async {
    if (busy || phase != SavePhase.clean) return;
    _rewardSaving = true;
    try {
      for (final id in _rewardCloses.toList()) {
        await store.closeReward(id);
        _rewardCloses.remove(id);
      }
      rewardSaveFailed = false;
      rewardIssue = null;
    } catch (_) {
      rewardSaveFailed = true;
    } finally {
      _rewardSaving = false;
    }
    await _drainRewards();
    _notify();
  }

  Future<void> dismissUnconfirmedReward(String id) async {
    if (busy || phase != SavePhase.clean) return;
    _rewardSaving = true;
    try {
      await store.dismissUnconfirmedReward(id);
      pendingRewards = await store.pendingRewards();
    } catch (_) {
      rewardIssue = 'close_failed';
    } finally {
      _rewardSaving = false;
      _notify();
    }
  }

  Future<void> resumeRewardedPuzzle(
    String id, {
    required String? replacingInstance,
  }) async {
    if (busy || phase != SavePhase.clean) return;
    _rewardSaving = true;
    try {
      final attempt = await store.rewardAttempt(id);
      if (attempt == null || !attempt.needsRestore) return;
      await store.restoreReward(id, replacingInstance: replacingInstance);
      await _reloadRewardSlots();
      current = _slots[attempt.origin.slot];
      _event(ProductEvent.rewardGranted, attempt.origin.id, {
        'request_id': id,
        'instance_id': attempt.origin.id,
        'result': 'restored',
      });
      receipt = current == null ? null : _receipts[current!.id];
      page = current?.completed == true ? GamePage.completion : GamePage.board;
      rewardIssue = null;
    } catch (_) {
      rewardIssue = 'restore_failed';
    } finally {
      _rewardSaving = false;
      _notify();
    }
  }

  void failNextWrite() {
    if (!kDebugMode) return;
    store.fault = (stage) {
      if (stage == 'snapshot') {
        store.fault = null;
        throw StateError('Development disk-write failure (SQLite rolled back)');
      }
    };
    _notify();
  }

  Future<void> requestHint() async {
    final state = current;
    if (state == null ||
        state.completed ||
        busy ||
        page != GamePage.board ||
        !_foreground ||
        (state.tutorial?.active ?? false)) {
      return;
    }
    _cancelHint();
    final generation = _hintGeneration;
    _hintEvent = (
      request: _id(),
      instance: state.id,
      timer: Stopwatch()..start(),
    );
    _metric(state).hints++;
    hintSearching = true;
    _notify();
    final task = _launchHint(state);
    _hintTask = task;
    HintResult result;
    try {
      result = await task.result;
    } catch (_) {
      result = const HintResult(HintStatus.timeout);
    }
    if (!_alive || generation != _hintGeneration) return;
    _hintTask = null;
    hintSearching = false;
    if (current?.id != state.id ||
        current?.revision != state.revision ||
        current!.completed ||
        page != GamePage.board ||
        !_foreground) {
      _finishHintEvent('cancelled');
      hint = null;
      selectedSource = null;
      _notify();
      return;
    }
    if (result.status == HintStatus.found &&
        (result.move == null ||
            !current!.pour(result.move!.from, result.move!.to).changed)) {
      result = const HintResult(HintStatus.timeout);
    }
    _finishHintEvent(result.status.name);
    hint = result;
    if (result.status == HintStatus.found) selectedSource = result.move!.from;
    _notify();
  }

  void _cancelHint({bool clearSelection = true}) {
    _finishHintEvent('cancelled');
    rejection = null;
    rejectedBottle = null;
    _hintGeneration++;
    _hintTask?.cancel();
    _hintTask = null;
    hintSearching = false;
    hint = null;
    if (clearSelection) selectedSource = null;
  }

  void cancelHint() {
    _cancelHint();
    _notify();
  }

  void setForeground(bool value) {
    _foreground = value;
    services?.setForeground(value);
    _syncMetrics();
    if (!value) unawaited(_saveMetrics());
    if (!value) {
      _pendingCompletionFeedback = null;
      _finishMotion();
      _cancelHint();
    } else {
      refreshToday();
      final continuation = _afterForeground;
      _afterForeground = null;
      if (continuation != null) unawaited(continuation());
    }
    _notify();
  }

  @override
  void dispose() {
    services?.removeListener(_notify);
    _alive = false;
    _pendingCompletionFeedback = null;
    _finishMotion();
    _cancelHint();
    super.dispose();
  }
}
