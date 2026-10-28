import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/service_views.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  const configured = ServiceConfig(
    feedbackEmail: 'wangyule0379@gmail.com',
    supportUrl: 'https://wangyule0379-max.github.io/pourlune-support/',
  );
  sqfliteFfiInit();

  Future<void> open(
    WidgetTester t, {
    ServiceConfig config = configured,
    bool feedback = true,
    bool succeeds = false,
    bool throws = false,
  }) async {
    final dir = Directory.systemTemp.createTempSync('support-launch-');
    final store = (await t.runAsync(
      () => GameStore.open(
        '${dir.path}/test.sqlite',
        factory: databaseFactoryFfi,
      ),
    ))!;
    final hub = ServiceHub(store: store, config: config, knownPuzzleIds: {});
    final c = GameController(store, services: hub);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      expect(call.method, 'launch');
      expect(
        Uri.parse((call.arguments as Map)['url'] as String).scheme,
        feedback ? 'mailto' : 'https',
      );
      if (throws) throw PlatformException(code: 'no_handler');
      return succeeds;
    });
    addTearDown(() async {
      await store.close();
      dir.deleteSync(recursive: true);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openSupportEntry(context, c, feedback: feedback),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    c.dispose();
    hub.dispose();
  }

  testWidgets(
    'configured feedback with no mail handler gives the real address',
    (t) async {
      await open(t);
      expect(find.textContaining('wangyule0379@gmail.com'), findsOneWidget);
      expect(find.textContaining('not been configured'), findsNothing);
    },
  );

  testWidgets('browser launch error is not reported as missing configuration', (
    t,
  ) async {
    await open(t, feedback: false, throws: true);
    expect(
      find.text("Couldn't open this page. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('not been configured'), findsNothing);
  });

  testWidgets('missing destination keeps the unconfigured message', (t) async {
    await open(t, config: const ServiceConfig());
    expect(find.textContaining('not been configured'), findsOneWidget);
  });

  testWidgets('successful external launch does not show an error', (t) async {
    await open(t, succeeds: true);
    expect(find.byType(SnackBar), findsNothing);
  });
}
