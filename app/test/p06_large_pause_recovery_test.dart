import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'offline_controller_test.dart' show testLibrary;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'maximum Pause prioritizes failed-save recovery without close overlap',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(375, 667);
      t.view.padding = const FakeViewPadding(top: 20);
      final dir = Directory.systemTemp.createTempSync('pause-recovery-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store, library: testLibrary());
      try {
        await t.runAsync(() async {
          await c.initialize();
          await c.startLevel(1);
          final move = c.current!.puzzle.referenceMoves.first;
          c.failNextWrite();
          await c.pour(move.from, move.to);
        });
        expect(c.phase, SavePhase.failed);
        final memory = c.current!.toJson();
        await t.pumpWidget(
          PourluneApp(
            controller: c,
            textScaler: TextScaler.linear(3.2),
            // Isolate the actual Pause route. The unrelated canonical maximum
            // board failure remains RED and is not covered by this harness.
            debugBoardPagePresentation: (page) => TextButton(
              onPressed: page.onPause,
              child: const Text('Open actual Pause'),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.text('Open actual Pause'));
        await t.pumpAndSettle();
        expect(find.text('Your puzzle is saved.'), findsNothing);
        expect(find.text('Progress not saved'), findsOneWidget);
        final warning = t.getRect(find.text('Progress not saved'));
        final contextBox = t.getRect(find.byKey(const Key('pause-context')));
        expect(warning.bottom, lessThanOrEqualTo(contextBox.bottom));
        final close = t.getRect(find.byKey(const Key('pause-close')));
        expect(
          t.getRect(find.byKey(const Key('pause-context'))).top,
          greaterThanOrEqualTo(close.bottom),
        );
        for (final key in ['pause-retry', 'pause-stay', 'resume-pause']) {
          final action = find.byKey(Key(key));
          final box = t.getRect(action);
          expect(action.hitTestable(), findsOneWidget);
          expect(box.height, greaterThanOrEqualTo(48));
          expect(box.bottom, lessThanOrEqualTo(667));
        }
        expect(c.current!.toJson(), memory);
        late Completer<void> release, saveAcknowledged;
        late Future<void> held;
        void onSaved() {
          if (c.phase == SavePhase.clean && !saveAcknowledged.isCompleted) {
            saveAcknowledged.complete();
          }
        }

        await t.runAsync(() async {
          release = Completer<void>();
          saveAcknowledged = Completer<void>();
          final locked = Completer<void>();
          held = store.db.transaction((_) async {
            locked.complete();
            await release.future;
          });
          await locked.future;
          c.addListener(onSaved);
          await t.tap(find.byKey(const Key('pause-retry')));
        });
        try {
          await t.pumpAndSettle();
          expect(c.phase, SavePhase.saving);
          expect(find.text('Saving…'), findsOneWidget);
          expect(find.text('Your puzzle is saved.'), findsNothing);
          expect(
            t
                .widget<FilledButton>(find.byKey(const Key('pause-retry')))
                .onPressed,
            isNull,
          );
          expect(find.byKey(const Key('pause-stay')), findsOneWidget);
          await t.runAsync(() async {
            release.complete();
            await held;
            await saveAcknowledged.future.timeout(const Duration(seconds: 5));
          });
        } finally {
          c.removeListener(onSaved);
          if (!release.isCompleted) release.complete();
        }
        await t.pumpAndSettle();
        expect(c.phase, SavePhase.clean);
        final saved = (await t.runAsync(() => store.load('ordinary')))!
            .instance!;
        expect(saved.toJson(), memory);
        for (final key in ['resume-pause', 'pause-restart', 'pause-home']) {
          expect(find.byKey(Key(key)).hitTestable(), findsOneWidget);
        }
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        t.view.reset();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
