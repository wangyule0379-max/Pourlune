import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/knit_components.dart';
import 'package:pourlune_dev/presentation/startup_view.dart';

void main() {
  testWidgets(
    'initial Flutter shell matches centered native wordmark on blue',
    (t) async {
      await t.binding.setSurfaceSize(const Size(402, 874));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StartupView(failed: false, onRetry: () {}),
        ),
      );
      final brand = find.byWidgetPredicate(
        (w) => w is KnitArt && w.name == 'logo',
      );
      expect(t.getCenter(brand), const Offset(201, 437));
      expect(t.getSize(brand).width, 176);
      expect(
        t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        const Color(0xff82dff1),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'small large-text startup failure keeps real retry action usable',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      var retries = 0;
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: StartupView(failed: true, onRetry: () => retries++),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('startup-retry')));
      await t.tap(find.byKey(const Key('startup-retry')));
      expect(retries, 1);
      expect(t.takeException(), isNull);
    },
  );
}
