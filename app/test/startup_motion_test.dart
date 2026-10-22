import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/main.dart';
import 'package:pourlune_dev/presentation/knit_components.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'local initialization failure retains branded shell and Retry opens real database',
    (t) async {
      final oldFactory = sql.databaseFactoryOrNull;
      final dir = Directory.systemTemp.createTempSync('startup-motion-');
      sql.databaseFactory = databaseFactoryFfi;
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      final blocked = Directory('${dir.path}/pourlune_dev.sqlite')
        ..createSync();
      final flutterHandler = FlutterError.onError;
      final platformHandler = PlatformDispatcher.instance.onError;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      // The host has no UMP plugin: report an actual platform failure to exercise
      // the offline fallback, rather than claim a native SDK result.
      messenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads/ump',
        (_) async => const StandardMethodCodec().encodeErrorEnvelope(
          code: 'offline',
          message: 'host test offline',
        ),
      );
      try {
        await t.pumpWidget(const Bootstrap());
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.byWidgetPredicate((w) => w is KnitArt && w.name == 'logo'),
          findsOneWidget,
        );
        Future<void> until(bool Function() ready) async {
          for (var i = 0; i < 500 && !ready(); i++) {
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await t.pump(const Duration(milliseconds: 20));
          }
          expect(ready(), isTrue);
        }

        await until(
          () => find.byKey(const Key('startup-retry')).evaluate().isNotEmpty,
        );
        blocked.deleteSync();
        await t.runAsync(() async {
          final store = await GameStore.open(
            '${dir.path}/pourlune_dev.sqlite',
            factory: databaseFactoryFfi,
          );
          await store.saveSettings(
            const PlayerSettings(music: false, sound: false),
          );
          await store.close();
        });
        await t.tap(find.byKey(const Key('startup-retry')));
        await until(() => find.byType(PourluneApp).evaluate().isNotEmpty);
        expect(find.byKey(const Key('sample-main-001')), findsOneWidget);
        expect(File('${dir.path}/pourlune_dev.sqlite').existsSync(), isTrue);
      } finally {
        await t.pumpWidget(const SizedBox());
        FlutterError.onError = flutterHandler;
        PlatformDispatcher.instance.onError = platformHandler;
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        messenger.setMockMessageHandler(
          'plugins.flutter.io/google_mobile_ads/ump',
          null,
        );
        sql.databaseFactoryOrNull = oldFactory;
        dir.deleteSync(recursive: true);
      }
    },
  );
}
