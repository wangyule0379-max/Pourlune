import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/application/game_controller.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  for (final returningIndex in [2, 0]) {
    testWidgets(
      'returning bottle $returningIndex stays continuous during a quick new pour',
      (t) async {
        final before = returningIndex == 0
            ? boardMove(boardFixture(), 0, 4).after
            : boardFixture();
        final move = returningIndex == 0
            ? boardMove(before, 1, 0)
            : boardMove(before, 0, 4);
        var state = before;
        int? selected = returningIndex;
        PourMotion? motion;
        late StateSetter update;
        await t.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (_, setState) {
                  update = setState;
                  return SizedBox(
                    width: 351,
                    height: 430,
                    child: BoardView(
                      state: state,
                      selected: selected,
                      motion: motion,
                      onTap: (_) {},
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await waitForFlameArt(t);
        await t.pumpAndSettle();
        final game = t
            .widget<GameWidget<FlameBoardGame>>(
              find.byType(GameWidget<FlameBoardGame>),
            )
            .game!;
        final baseline = game.frame.layout.mouths[returningIndex].dy;
        expect(
          game.frame.poses[returningIndex].mouth.dy,
          closeTo(baseline - 8, .01),
        );
        update(() => selected = move.motion.from);
        await t.pump();
        await t.pump(const Duration(milliseconds: 40));
        final returning = game.frame.poses[returningIndex].mouth.dy;
        expect(returning, lessThan(baseline));
        update(() {
          state = move.after;
          motion = move.motion;
          selected = null;
        });
        await t.pump();
        expect(
          game.frame.poses[returningIndex].mouth.dy,
          closeTo(returning, .01),
          reason: 'Starting a different pour cannot snap an unfinished return.',
        );
        await t.pump(const Duration(milliseconds: 40));
        expect(
          game.frame.poses[returningIndex].mouth.dy,
          greaterThan(returning),
        );
        expect(game.frame.poses[returningIndex].mouth.dy, lessThan(baseline));
        await t.pump(const Duration(milliseconds: 150));
        expect(
          game.frame.poses[returningIndex].mouth.dy,
          closeTo(baseline, .01),
        );
        expect(game.frame.active, isNotNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'selected bottle lifts while fixed readouts stay still; switch, clear and reduction restore poses',
    (t) async {
      int? selected;
      int? suggestion;
      var reduced = false;
      late StateSetter update;
      const key = Key('selection-live-canvas');
      final state = boardFixture();
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 351,
                    height: 430,
                    child: BoardView(
                      state: state,
                      selected: selected,
                      suggested: suggestion,
                      settings: PlayerSettings(reducedMotion: reduced),
                      onTap: (i) =>
                          update(() => selected = selected == i ? null : i),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await waitForFlameArt(t);
      await t.pumpAndSettle();
      Future<List<int>> pixels() async {
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
        final image = (await t.runAsync(() => boundary.toImage()))!;
        final bytes = (await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final result = bytes.buffer.asUint8List().toList();
        image.dispose();
        return result;
      }

      final normal = await pixels();
      final game = t
          .widget<GameWidget<FlameBoardGame>>(
            find.byType(GameWidget<FlameBoardGame>),
          )
          .game!;
      final baseline = game.frame.poses.map((p) => p.mouth).toList();
      final hit = t.getRect(find.byKey(const Key('bottle-0')));
      await t.tap(find.byKey(const Key('bottle-0')));
      await t.pumpAndSettle();
      await t.pump(const Duration(milliseconds: 160));
      expect(selected, 0);
      expect(game.frame.poses[0].mouth.dy, closeTo(baseline[0].dy - 8, .01));
      expect(
        game.frame.layout.shape
            .worldOutline(game.frame.poses[0])
            .getBounds()
            .top,
        greaterThanOrEqualTo(14),
        reason: 'The cyan halo needs its three-sigma spread before the canvas edge.',
      );
      expect(game.frame.poses[1].mouth, baseline[1]);
      final canvasOrigin = t.getTopLeft(
        find.byType(GameWidget<FlameBoardGame>),
      );
      final raisedBody = game.frame.layout.shape.visibleRect.shift(
        game.frame.poses[0].mouth + canvasOrigin,
      );
      expect(
        hit.top,
        lessThanOrEqualTo(raisedBody.top),
        reason: 'The raised cap remains inside the real tappable area.',
      );
      expect(hit.bottom, greaterThanOrEqualTo(raisedBody.bottom));
      final active = await pixels();
      var changed = 0;
      for (var i = 0; i < normal.length; i += 4) {
        if (normal[i] != active[i] ||
            normal[i + 1] != active[i + 1] ||
            normal[i + 2] != active[i + 2] ||
            normal[i + 3] != active[i + 3]) {
          changed++;
        }
      }
      expect(
        changed,
        greaterThan(80),
        reason: 'native semantics alone must not claim selection when idle canvas has not repainted',
      );
      expect(t.getRect(find.byKey(const Key('bottle-0'))), hit);
      // Exercise the real hit-test path at the newly raised cap, rather than
      // only comparing a rectangle or invoking the button's center action.
      await t.tapAt(Offset(raisedBody.center.dx, raisedBody.top + 2));
      await t.pumpAndSettle();
      expect(selected, isNull);
      expect(game.frame.poses[0].mouth, baseline[0]);
      await t.tapAt(hit.center);
      await t.pumpAndSettle();
      expect(selected, 0);
      await t.pump(const Duration(milliseconds: 160));
      expect(game.frame.poses[0].mouth.dy, closeTo(baseline[0].dy - 8, .01));
      await t.tap(find.byKey(const Key('bottle-1')));
      await t.pump(const Duration(milliseconds: 50));
      expect(game.frame.poses[0].mouth.dy, lessThan(baseline[0].dy));
      await t.pump(const Duration(milliseconds: 160));
      expect(game.frame.poses[0].mouth, baseline[0]);
      expect(game.frame.poses[1].mouth.dy, closeTo(baseline[1].dy - 8, .01));
      await t.tap(find.byKey(const Key('bottle-1')));
      await t.pumpAndSettle();
      await t.pump(const Duration(milliseconds: 160));
      expect(selected, isNull);
      expect(
        await pixels(),
        normal,
        reason: 'clearing removes static halo and restores exact idle image',
      );
      update(() => suggestion = 1);
      await t.pumpAndSettle();
      expect(
        game.frame.poses[1].mouth,
        baseline[1],
        reason: 'A suggested destination is highlighted without lifting.',
      );
      update(() {
        suggestion = null;
        reduced = true;
        selected = 0;
      });
      await t.pumpAndSettle();
      expect(
        game.frame.poses[0].mouth,
        baseline[0],
        reason: 'Reduced Motion retains static selection feedback.',
      );
      await t.pumpWidget(const SizedBox());
    },
  );
}
