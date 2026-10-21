import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_audio.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;
import 'store_test.dart' show fixture;

class _Transport implements GameAudioTransport {
  int starts = 0, stops = 0, effects = 0;
  @override
  Future<void> startMusic() async {
    starts++;
  }

  @override
  Future<void> stopMusic() async {
    stops++;
  }

  @override
  Future<void> play(GameSound sound) async {
    effects++;
  }

  @override
  Future<void> stopEffects() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  sqfliteFfiInit();
  testWidgets(
    'B03 real Pause and lifecycle/settings gates reach audio without blocking saved board',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('b03-audio-ui-');
      final store = (await t.runAsync(
        () => GameStore.open('${dir.path}/g.db', factory: databaseFactoryFfi),
      ))!;
      final c = GameController(store, library: testLibrary());
      final transport = _Transport(), audio = GameAudio(transport: transport);
      try {
        await t.runAsync(() async {
          await c.initialize();
          await c.start(fixture());
        });
        final state = c.current!.toJson();
        await t.pumpWidget(PourluneApp(controller: c, audio: audio));
        await t.pumpAndSettle();
        expect(transport.starts, 1);
        final pause = find.byKey(const Key('pause'));
        await t.ensureVisible(pause);
        await t.tap(pause);
        await t.pumpAndSettle();
        expect(transport.stops, 1);
        await t.tap(find.byKey(const Key('resume-pause')));
        await t.pumpAndSettle();
        expect(transport.starts, 2);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await t.pumpAndSettle();
        expect(transport.stops, 2);
        await t.runAsync(() => c.updateSetting('music', false));
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pumpAndSettle();
        expect(transport.starts, 2);
        await t.runAsync(() => c.updateSetting('sound', false));
        audio.play(GameSound.select);
        await t.pumpAndSettle();
        expect(transport.effects, 0);
        expect(c.current!.toJson(), state);
        expect(
          (await t.runAsync(() => store.load('ordinary')))!.instance!.toJson(),
          state,
        );
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        var audioClosed = false;
        audio.dispose().then((_) => audioClosed = true);
        for (var i = 0; i < 100 && !audioClosed; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 1)),
          );
          await t.pump();
        }
        expect(audioClosed, isTrue);
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
}
