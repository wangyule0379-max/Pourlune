import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/bottle.dart';

import 'store_test.dart' show fixture;

void main() {
  testWidgets(
    'AC-31 system Reduce Motion overrides default app preference for pour selection and rejection',
    (t) async {
      final before = GameInstance.create(
        id: 'system-reduce',
        puzzle: fixture(),
      );
      final after = before.pour(0, 2).state;
      var completed = 0;
      Future<void> show({
        PourMotion? motion,
        int? selected,
        int rejection = 0,
      }) => t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: BoardView(
              state: motion == null ? before : after,
              selected: selected,
              onTap: (_) {},
              motion: motion,
              onMotionComplete: (_) => completed++,
              rejectedBottle: rejection == 0 ? null : 0,
              rejectionRevision: rejection,
            ),
          ),
        ),
      );
      await show();
      final resting = t.getTopLeft(find.byKey(const Key('bottle-0')));
      await show(selected: 0);
      await t.pump(const Duration(milliseconds: 70));
      expect(
        t.getTopLeft(find.byKey(const Key('bottle-0'))),
        resting,
        reason: 'system preference must stop selection lift',
      );
      await show(rejection: 1);
      await t.pump(const Duration(milliseconds: 70));
      expect(
        t.getTopLeft(find.byKey(const Key('bottle-0'))),
        resting,
        reason: 'system preference must stop rejection shake',
      );
      await show(
        motion: PourMotion(
          token: 1,
          from: 0,
          to: 2,
          units: 2,
          before: before.board,
          after: after.board,
          instanceId: after.id,
          revision: after.revision,
          reducedMotion: false,
        ),
      );
      await t.pump(const Duration(milliseconds: 90));
      final bottle = t.widget<BottleButton>(find.byKey(const Key('bottle-0')));
      expect(bottle.angle, 0);
      expect(bottle.lift, 0);
      expect(t.getTopLeft(find.byKey(const Key('bottle-0'))), resting);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              '${w.painter.runtimeType}' == '_StreamPainter',
        ),
        findsNothing,
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(
        completed,
        1,
        reason: 'system preference must use short180ms presentation',
      );
      await t.pumpWidget(const SizedBox());
    },
  );
}
