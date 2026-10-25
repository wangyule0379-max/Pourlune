// Functional/accessibility guards. Native screenshots remain a separate gate.
import 'dart:io';

import 'package:flutter/material.dart';

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/parallel_navigation/knitted_switch.dart';
import 'package:pourlune_dev/presentation/settings_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('knit decoration retains a native accessible switch', (t) async {
    final semantics = t.ensureSemantics();
    try {
      var enabled = true;
      var value = true;
      late StateSetter rebuild;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return KnittedSwitch(
                  value: value,
                  semanticLabel: 'Sound',
                  onChanged: enabled
                      ? (next) => setState(() => value = next)
                      : null,
                );
              },
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final native = find.byType(Switch);
      expect(native, findsOneWidget);
      expect(t.getRect(native).height, greaterThanOrEqualTo(48));
      expect(
        t.getSemantics(native).flagsCollection.isToggled != Tristate.none,
        isTrue,
      );
      expect(
        t.getSemantics(native).flagsCollection.isToggled == Tristate.isTrue,
        isTrue,
      );
      await t.tap(native);
      await t.pumpAndSettle();
      expect(value, isFalse);
      expect(
        t.getSemantics(native).flagsCollection.isToggled == Tristate.isTrue,
        isFalse,
      );
      rebuild(() => enabled = false);
      await t.pumpAndSettle();
      await t.tap(native);
      expect(value, isFalse);
      expect(t.widget<Switch>(native).onChanged, isNull);
      await t.pumpWidget(const SizedBox());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'settings still save and guard a failed write at narrow large text',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final dir = Directory.systemTemp.createTempSync('parallel-settings-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/settings.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final c = GameController(store);
      var privacy = 0, reset = 0, feedback = 0;
      Widget screen() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: 'Nunito'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: c,
              builder: (context, child) => SettingsPage(
                controller: c,
                onPrivacy: () => privacy++,
                onReset: () => reset++,
                onFeedback: () => feedback++,
              ),
            ),
          ),
        ),
      );
      try {
        await t.runAsync(c.initialize);
        await t.pumpWidget(screen());
        await t.pumpAndSettle();
        final row = find.byKey(const Key('setting-music'));
        final toggle = find.descendant(of: row, matching: find.byType(Switch));
        await t.ensureVisible(toggle);
        await t.runAsync(() async {
          await t.tap(toggle);
          for (var i = 0; i < 100 && c.busy; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        });
        await t.pumpAndSettle();
        expect(c.settings.music, isFalse);
        expect((await t.runAsync(store.readSettings))!.music, isFalse);
        for (final key in ['privacy', 'reset-progress', 'feedback']) {
          final entry = find.byKey(Key(key));
          await t.ensureVisible(entry);
          expect(t.getRect(entry).right, lessThanOrEqualTo(320));
          await t.tap(entry);
        }
        expect([privacy, reset, feedback], [1, 1, 1]);
        c.phase = SavePhase.failed;
        await t.pumpWidget(screen());
        await t.pumpAndSettle();
        expect(t.widget<Switch>(toggle).onChanged, isNull);
        expect(
          t
              .widget<OutlinedButton>(find.byKey(const Key('reset-progress')))
              .onPressed,
          isNull,
        );
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        dir.deleteSync(recursive: true);
      }
    },
  );
}
