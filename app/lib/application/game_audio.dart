import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/player_settings.dart';

enum GameSound { select, pour, error, win, reveal }

abstract interface class GameAudioTransport {
  Future<void> startMusic();
  Future<void> stopMusic();
  Future<void> play(GameSound sound);
  Future<void> stopEffects();
  Future<void> dispose();
}

class GameAudio {
  GameAudio({GameAudioTransport? transport})
    : _transport = transport ?? _AssetAudioTransport();

  final GameAudioTransport _transport;
  Future<void> _pending = Future<void>.value();
  bool _musicAllowed = false, _soundAllowed = false;
  bool _musicPlaying = false, _effectsActive = false, _disposed = false;
  bool _effectsStopRequested = false;
  int _soundRevision = 0;

  /// Best effort only. Call without awaiting from gameplay/save/navigation.
  /// Gates change synchronously, so queued effects cannot survive a pause.
  Future<void> update({
    required PlayerSettings settings,
    required bool foreground,
    required bool paused,
  }) {
    if (_disposed) return _pending;
    final active = foreground && !paused;
    _musicAllowed = active && settings.music;
    final soundAllowed = active && settings.sound;
    if (_soundAllowed != soundAllowed) {
      _soundRevision++;
      if (!soundAllowed) _effectsStopRequested = true;
    }
    _soundAllowed = soundAllowed;
    return _enqueue(_sync);
  }

  Future<void> play(GameSound sound) {
    if (_disposed || !_soundAllowed) return _pending;
    final revision = _soundRevision;
    return _enqueue(() async {
      if (_effectsStopRequested) await _stopEffects();
      if (_disposed || !_soundAllowed || revision != _soundRevision) return;
      _effectsActive = true;
      await _transport.play(sound);
    });
  }

  /// Ends a finite visual cue without stopping the background music.
  Future<void> finishEffect() {
    _soundRevision++; // A decoder delay must not start water after flow ended.
    if (_disposed) return _pending;
    _effectsStopRequested = true;
    return _enqueue(_stopEffects);
  }

  Future<void> stop() {
    _musicAllowed = _soundAllowed = false;
    _effectsStopRequested = true;
    _soundRevision++;
    if (_disposed) return _pending;
    return _enqueue(_sync);
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    _musicAllowed = _soundAllowed = false;
    _soundRevision++;
    return _enqueue(() async {
      await _sync();
      await _attempt(_transport.dispose);
    });
  }

  Future<void> _sync() async {
    // Independent attempts ensure a failed music decoder cannot prevent SFX
    // from stopping. Reduced motion changes visual movement, not these gates.
    await _attempt(() async {
      if (_musicAllowed && !_disposed && !_musicPlaying) {
        await _transport.startMusic();
        _musicPlaying = true;
      } else if ((!_musicAllowed || _disposed) && _musicPlaying) {
        await _transport.stopMusic();
        _musicPlaying = false;
      }
    });
    await _attempt(() async {
      // Preserve an interruption even if a resume reached the queue first.
      // Only music resumes; a previous visual cue must never restart.
      if (_effectsStopRequested || !_soundAllowed || _disposed) {
        await _stopEffects();
      }
    });
  }

  Future<void> _stopEffects() async {
    if (_effectsActive) {
      await _transport.stopEffects();
      _effectsActive = false;
    }
    // A failed native stop leaves this request and the active voice intact so
    // the next lifecycle update can retry without blocking gameplay.
    _effectsStopRequested = false;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _pending = _pending.then((_) => _attempt(operation));
    return _pending;
  }

  Future<void> _attempt(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Audio failure must never fail an action, save, or lifecycle callback.
      debugPrint('Pourlune audio unavailable; gameplay continues.');
    }
  }
}

class _AssetAudioTransport implements GameAudioTransport {
  AudioPlayer? _music, _effects;
  bool _musicReady = false;

  AudioContext _context({required bool music}) => AudioContext(
    android: AudioContextAndroid(
      contentType: music
          ? AndroidContentType.music
          : AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
      stayAwake: false,
    ),
    // Ambient implicitly mixes and respects the iOS Ring/Silent switch.
    // Explicit mixWithOthers is invalid for this category.
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  @override
  Future<void> startMusic() async {
    final player = _music ??= AudioPlayer();
    if (_musicReady) {
      await player.resume();
      return;
    }
    await player.setAudioContext(_context(music: true));
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/dream-culture.mp3'), volume: 0.12);
    _musicReady = true;
  }

  @override
  Future<void> stopMusic() async => _music?.pause();

  @override
  Future<void> play(GameSound sound) async {
    final player = _effects ??= AudioPlayer();
    // A single effects voice intentionally replaces the previous short cue.
    await player.stop();
    await player.setAudioContext(_context(music: false));
    await player.setReleaseMode(
      sound == GameSound.pour ? ReleaseMode.loop : ReleaseMode.stop,
    );
    await player.play(AssetSource('audio/${sound.name}.wav'), volume: 0.65);
  }

  @override
  Future<void> stopEffects() async => _effects?.stop();

  @override
  Future<void> dispose() async {
    try {
      await _music?.dispose();
    } finally {
      await _effects?.dispose();
    }
  }
}
