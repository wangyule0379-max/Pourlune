import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/service_views.dart';
import 'package:pourlune_dev/services/gamemunchies_reporting.dart';
import 'package:pourlune_dev/services/service_config.dart';
import 'package:pourlune_dev/services/service_hub.dart';

class _UnusedStore extends Fake implements GameStore {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> open(
    WidgetTester tester, {
    bool gameAnalytics = false,
    bool saveFailed = false,
    bool syncFailed = false,
  }) async {
    // This rendering path does not read or write gameplay storage.
    final store = _UnusedStore();
    final reporting = gameAnalytics
        ? GameMunchiesReporting(
            createClient: () =>
                throw StateError('UI fixture never starts network'),
          )
        : GameMunchiesReporting();
    final hub =
        ServiceHub(
            store: store,
            config: const ServiceConfig(),
            knownPuzzleIds: {},
            reporting: reporting,
          )
          ..privacySaveFailed = saveFailed
          ..privacySyncFailed = syncFailed;
    final controller = GameController(store, services: hub);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPrivacyChoices(context, controller),
              child: const Text('Privacy'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    controller.dispose();
    hub.dispose();
  }

  testWidgets(
    'available GM analytics is not described as entirely unavailable when Firebase is absent',
    (tester) async {
      await open(tester, gameAnalytics: true);
      expect(
        find.text(
          'Optional diagnostics are unavailable in this build. Choices are saved locally.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Crash reporting is currently unavailable. Gameplay analytics follows your saved choice below.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'no reporting provider keeps the existing unavailable explanation',
    (tester) async {
      await open(tester);
      expect(
        find.text(
          'Optional diagnostics are unavailable in this build. Choices are saved locally.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'a provider sync failure does not claim all other sharing is blocked',
    (tester) async {
      await open(tester, gameAnalytics: true, syncFailed: true);
      expect(
        find.text(
          'Privacy choices could not be saved or synchronized. Sharing is blocked by the app until Retry succeeds.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Your choices are saved, but a reporting service could not apply them. Other enabled reporting may continue. Retry to apply your saved choices.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('local save failure still explains that sharing is blocked', (
    tester,
  ) async {
    await open(tester, gameAnalytics: true, saveFailed: true);
    expect(
      find.text(
        'Privacy choices could not be saved or synchronized. Sharing is blocked by the app until Retry succeeds.',
      ),
      findsOneWidget,
    );
  });
}
