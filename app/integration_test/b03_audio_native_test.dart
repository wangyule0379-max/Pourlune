import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('B03 actual native WAV decode and player transport', (t) async {
    final results = <Map<String, Object?>>[];
    final player = AudioPlayer();
    try {
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          android: AudioContextAndroid(
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.stop);
      for (final name in [
        'select',
        'pour',
        'error',
        'win',
        'reveal',
        'background',
      ]) {
        final asset = name == 'background'
            ? 'audio/dream-culture.mp3'
            : 'audio/$name.wav';
        await player.setSource(AssetSource(asset));
        Duration? duration;
        for (var i = 0; i < 100 && duration == null; i++) {
          duration = await player.getDuration();
          if (duration == null) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
        }
        expect(duration, isNotNull);
        expect(duration!.inMilliseconds, greaterThan(100));
        int? loopWrap;
        final looping = name == 'pour' || name == 'background';
        await player.setReleaseMode(
          looping ? ReleaseMode.loop : ReleaseMode.stop,
        );
        await player.setVolume(name == 'background' ? .12 : .65);
        await player.resume();
        expect(player.state, PlayerState.playing);
        if (looping) {
          await player.seek(duration - const Duration(milliseconds: 250));
          await Future<void>.delayed(const Duration(milliseconds: 700));
          final position = await player.getCurrentPosition();
          // Darwin emits onComplete even for native loops; Dart state alone
          // cannot prove playback. Direct native positions must wrap and advance.
          expect(position, isNotNull);
          expect(position!.inMilliseconds, lessThan(1500));
          loopWrap = position.inMilliseconds;
          await Future<void>.delayed(const Duration(milliseconds: 200));
          final advanced = await player.getCurrentPosition();
          expect(advanced!.inMilliseconds, greaterThan(loopWrap + 50));
        }
        await player.pause();
        expect(player.state, PlayerState.paused);
        await player.stop();
        expect(player.state, PlayerState.stopped);
        results.add({
          'asset': asset,
          'duration_ms': duration.inMilliseconds,
          'native_decode': true,
          'loop_wrap_position_ms': loopWrap,
          'playing_paused_stopped': true,
        });
      }
      final directory = Directory('${await getDatabasesPath()}/b03-evidence');
      await directory.create(recursive: true);
      debugPrint('B03_NATIVE_AUDIO_RESULTS: ${jsonEncode(results)}');
      await File('${directory.path}/native-audio.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'scope': 'iOS Simulator actual audioplayers backend decode + transport states; not subjective listening; policy bridge/settings tested separately',
          'results': results,
        }),
      );
    } finally {
      await player.dispose();
    }
  });
}
