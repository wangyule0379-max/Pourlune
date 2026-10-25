import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_audio.dart';
import 'package:pourlune_dev/data/player_settings.dart';

// Native decoding/output is intentionally the injected boundary. These tests
// exercise the real policy, including queued work, against an observable sink.
class AudioSink implements GameAudioTransport {
  final events = <String>[];
  Completer<void>? holdMusic;
  bool failMusic = false;

  @override
  Future<void> startMusic() async {
    events.add('music');
    await holdMusic?.future;
    if (failMusic) throw StateError('decoder unavailable');
  }

  @override
  Future<void> stopMusic() async => events.add('stop music');
  @override
  Future<void> play(GameSound sound) async => events.add(sound.name);
  @override
  Future<void> stopEffects() async => events.add('stop effects');
  @override
  Future<void> dispose() async => events.add('dispose');
}

void main() {
  const enabled = PlayerSettings();

  test('music starts once and sound switch does not mute music', () async {
    final sink = AudioSink();
    final audio = GameAudio(transport: sink);
    await audio.update(settings: enabled, foreground: true, paused: false);
    await audio.update(
      settings: enabled.withValue('sound', false),
      foreground: true,
      paused: false,
    );
    await audio.play(GameSound.select);
    expect(sink.events, ['music']);
    await audio.dispose();
  });

  test(
    'music switch preserves effects and reduced motion preserves audio',
    () async {
      final sink = AudioSink();
      final audio = GameAudio(transport: sink);
      await audio.update(
        settings: enabled
            .withValue('music', false)
            .withValue('reduced_motion', true),
        foreground: true,
        paused: false,
      );
      for (final sound in GameSound.values) {
        await audio.play(sound);
      }
      expect(sink.events, ['select', 'pour', 'error', 'win', 'reveal']);
      await audio.dispose();
    },
  );

  test(
    'background and pause stop both channels until foreground resumes',
    () async {
      for (final foreground in [false, true]) {
        final sink = AudioSink();
        final audio = GameAudio(transport: sink);
        await audio.update(settings: enabled, foreground: true, paused: false);
        await audio.play(GameSound.pour);
        await audio.update(
          settings: enabled,
          foreground: foreground,
          paused: foreground,
        );
        await audio.play(GameSound.win);
        expect(sink.events, ['music', 'pour', 'stop music', 'stop effects']);
        await audio.update(settings: enabled, foreground: true, paused: false);
        expect(sink.events.last, 'music');
        await audio.dispose();
      }
    },
  );

  test('disabling sound stops an effect already playing', () async {
    final sink = AudioSink();
    final audio = GameAudio(transport: sink);
    await audio.update(settings: enabled, foreground: true, paused: false);
    await audio.play(GameSound.pour);
    await audio.update(
      settings: enabled.withValue('sound', false),
      foreground: true,
      paused: false,
    );
    expect(sink.events, ['music', 'pour', 'stop effects']);
    await audio.dispose();
  });

  test(
    'queued effects from before pause are never replayed on resume',
    () async {
      final sink = AudioSink()..holdMusic = Completer<void>();
      final audio = GameAudio(transport: sink);
      final starting = audio.update(
        settings: enabled,
        foreground: true,
        paused: false,
      );
      await Future<void>.delayed(Duration.zero);
      final effect = audio.play(GameSound.pour);
      final pausing = audio.update(
        settings: enabled,
        foreground: true,
        paused: true,
      );
      final resuming = audio.update(
        settings: enabled,
        foreground: true,
        paused: false,
      );
      sink.holdMusic!.complete();
      await Future.wait([starting, effect, pausing, resuming]);
      await audio.play(GameSound.reveal);
      expect(sink.events, ['music', 'reveal']);
      await audio.dispose();
    },
  );

  test(
    'decoder failure is contained and does not poison later effects',
    () async {
      final sink = AudioSink()..failMusic = true;
      final audio = GameAudio(transport: sink);
      await audio.update(settings: enabled, foreground: true, paused: false);
      await audio.play(GameSound.select);
      expect(sink.events, ['music', 'select']);
      sink.failMusic = false;
      await audio.update(settings: enabled, foreground: true, paused: false);
      expect(sink.events.last, 'music');
      await audio.dispose();
    },
  );

  test(
    'no audio starts before settings load or when both switches are off',
    () async {
      final sink = AudioSink();
      final audio = GameAudio(transport: sink);
      await audio.play(GameSound.select);
      await audio.update(
        settings: enabled.withValue('music', false).withValue('sound', false),
        foreground: true,
        paused: false,
      );
      await audio.play(GameSound.win);
      expect(sink.events, isEmpty);
      await audio.dispose();
    },
  );

  test('stop gates effects and dispose is final and idempotent', () async {
    final sink = AudioSink();
    final audio = GameAudio(transport: sink);
    await audio.update(settings: enabled, foreground: true, paused: false);
    await audio.play(GameSound.win);
    await audio.stop();
    await audio.play(GameSound.reveal);
    expect(sink.events, ['music', 'win', 'stop music', 'stop effects']);
    await audio.dispose();
    await audio.dispose();
    await audio.update(settings: enabled, foreground: true, paused: false);
    await audio.play(GameSound.select);
    expect(sink.events.last, 'dispose');
    expect(sink.events.where((e) => e == 'dispose'), hasLength(1));
  });
  test(
    'ending a visual cue stops its voice and preserves music and later cues',
    () async {
      final sink = AudioSink();
      final audio = GameAudio(transport: sink);
      await audio.update(settings: enabled, foreground: true, paused: false);
      await audio.play(GameSound.pour);
      await audio.finishEffect();
      await audio.finishEffect();
      expect(sink.events, ['music', 'pour', 'stop effects']);
      await audio.play(GameSound.win);
      expect(sink.events.last, 'win');
      await audio.dispose();
    },
  );
}
