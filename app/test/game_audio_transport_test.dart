import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_audio.dart';
import 'package:pourlune_dev/data/player_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'music resumes the existing source after pause and music toggle',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const native = MethodChannel('xyz.luan/audioplayers');
      const global = MethodChannel('xyz.luan/audioplayers.global');
      const globalEvents = MethodChannel('xyz.luan/audioplayers.global/events');
      final calls = <MethodCall>[];
      final eventChannels = <MethodChannel>[];
      final originalCache = AudioCache.instance;
      AudioCache.instance = AudioCache()
        ..loadedFiles['audio/dream-culture.mp3'] = File(
          'assets/audio/dream-culture.mp3',
        ).absolute.uri;
      messenger.setMockMethodCallHandler(global, (_) async => null);
      messenger.setMockMethodCallHandler(globalEvents, (_) async => null);
      messenger.setMockMethodCallHandler(native, (call) async {
        calls.add(call);
        final id = (call.arguments as Map)['playerId'];
        final events = MethodChannel('xyz.luan/audioplayers/events/$id');
        if (call.method == 'create') {
          eventChannels.add(events);
          messenger.setMockMethodCallHandler(events, (_) async => null);
        }
        if (call.method == 'setSourceUrl') {
          await messenger.handlePlatformMessage(
            events.name,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            }),
            (_) {},
          );
        }
        return switch (call.method) {
          'getCurrentPosition' => 23000,
          'getDuration' => 200000,
          _ => null,
        };
      });
      final audio = GameAudio(); // Real transport/player; only the native decoder is stubbed.
      try {
        const enabled = PlayerSettings();
        await audio.update(settings: enabled, foreground: true, paused: false);
        await audio.update(settings: enabled, foreground: true, paused: true);
        await audio.update(settings: enabled, foreground: true, paused: false);
        await audio.update(
          settings: enabled.withValue('music', false),
          foreground: true,
          paused: false,
        );
        await audio.update(settings: enabled, foreground: true, paused: false);
        final methods = calls.map((c) => c.method).toList();
        expect(methods.where((m) => m == 'pause'), hasLength(2));
        expect(methods.where((m) => m == 'resume'), hasLength(3));
        expect(methods.where((m) => m == 'setSourceUrl'), hasLength(1));
        expect(methods, isNot(contains('stop')));
        expect(methods, isNot(contains('seek')));
      } finally {
        await audio.dispose();
        AudioCache.instance = originalCache;
        messenger.setMockMethodCallHandler(native, null);
        messenger.setMockMethodCallHandler(global, null);
        messenger.setMockMethodCallHandler(globalEvents, null);
        for (final channel in eventChannels) {
          messenger.setMockMethodCallHandler(channel, null);
        }
      }
    },
  );
}
