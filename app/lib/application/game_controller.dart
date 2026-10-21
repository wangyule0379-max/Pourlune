import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../data/game_store.dart';

enum SavePhase { clean, saving, failed }

enum GamePage { home, board, progress }

class GameController extends ChangeNotifier {
  GameController(this.store);
  final GameStore store;
  GameInstance? current;
  CompletionReceipt? receipt;
  SavePhase phase = SavePhase.clean;
  GamePage page = GamePage.home;
  String? error, recoveryNotice;
  String? rejection;
  bool _pendingHome = false;
  GameInstance? _candidate;
  bool _replaceCandidate = false;
  bool get busy => phase == SavePhase.saving;
  Future<void> initialize() async {
    final saved = await store.load('ordinary');
    current = saved.instance;
    recoveryNotice = saved.recovered
        ? 'Recovered the last valid local snapshot.'
        : saved.unavailable
        ? 'The ordinary save is unreadable. Other local progress is preserved. Choose a sample to replace this slot.'
        : null;
    if (current?.completed ?? false) {
      await _persist();
    }
    notifyListeners();
  }

  Future<void> start(
    Puzzle puzzle, {
    bool replace = false,
    bool replay = false,
  }) async {
    if (busy || phase == SavePhase.failed) return;
    if (current != null && !current!.completed && !replace) {
      throw StateError('Confirm replacement');
    }
    _candidate = GameInstance.create(
      id: 'dev-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
      puzzle: puzzle,
      isReplay: replay,
    );
    _replaceCandidate = current != null || recoveryNotice != null;
    await _persist();
  }

  void resume() {
    if (current != null && !busy && _candidate == null) {
      page = GamePage.board;
      notifyListeners();
    }
  }

  Future<void> pour(int from, int to) async {
    if (busy || current == null || _candidate != null) return;
    final r = current!.pour(from, to);
    rejection = r.rejection;
    if (!r.changed) {
      notifyListeners();
      return;
    }
    await _change(r.state);
  }

  Future<void> undo() async {
    if (!busy && current != null && _candidate == null) {
      await _change(current!.undo());
    }
  }

  Future<void> restart() async {
    if (!busy && current != null && _candidate == null) {
      await _change(current!.restart());
    }
  }

  Future<void> _change(GameInstance next) async {
    if (identical(next, current)) return;
    current = next;
    receipt = null;
    if (phase == SavePhase.failed) {
      notifyListeners();
      return;
    }
    await _persist();
  }

  Future<void> _persist() async {
    final s = _candidate ?? current;
    if (s == null || busy) return;
    phase = SavePhase.saving;
    error = null;
    notifyListeners();
    try {
      if (s.completed) {
        receipt = await store.settle(s);
      } else {
        await store.save(s, replace: _candidate != null && _replaceCandidate);
      }
      if (_candidate != null) {
        current = s;
        _candidate = null;
        receipt = null;
        page = GamePage.board;
        recoveryNotice = null;
      }
      phase = SavePhase.clean;
      if (_pendingHome) {
        page = GamePage.home;
        _pendingHome = false;
      }
    } catch (e) {
      phase = SavePhase.failed;
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> retry() async {
    if (phase == SavePhase.failed) await _persist();
  }

  void stayHere() {
    _pendingHome = false;
    notifyListeners();
  }

  Future<void> goHome() async {
    if (busy) return;
    if (phase == SavePhase.failed) {
      _pendingHome = true;
      notifyListeners();
      return;
    }
    page = GamePage.home;
    notifyListeners();
  }

  void showProgress() {
    if (phase == SavePhase.clean) {
      page = GamePage.progress;
      notifyListeners();
    }
  }

  void failNextWrite() {
    store.fault = (stage) {
      if (stage == 'snapshot') {
        store.fault = null;
        throw StateError('Development disk-write failure (SQLite rolled back)');
      }
    };
    notifyListeners();
  }
}
