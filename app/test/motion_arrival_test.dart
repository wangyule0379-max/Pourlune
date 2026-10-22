import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';

import 'store_test.dart' show fixture;

void main() {
  testWidgets(
    'board arrival animates but immediate first input remains enabled',
    (t) async {
      var taps = 0;
      final state = GameInstance.create(id: 'arrival', puzzle: fixture());
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BoardView(state: state, selected: null, onTap: (_) => taps++),
          ),
        ),
      );
      final bottle = find.byKey(const Key('bottle-0'));
      final fades = find.ancestor(of: bottle, matching: find.byType(Opacity));
      expect(fades, findsOneWidget);
      expect(t.widget<Opacity>(fades).opacity, lessThan(1));
      await t.tap(bottle);
      expect(taps, 1);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.widget<Opacity>(fades).opacity, 1);
      await t.pumpWidget(const SizedBox());
    },
  );
}
