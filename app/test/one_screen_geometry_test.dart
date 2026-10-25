import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';

import 'dart:ui' show SemanticsAction;

import 'package:flame/game.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/completion_bottles.dart';
import 'package:pourlune_dev/data/player_settings.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';

import 'support/flame_board_support.dart';

void main() {
  testWidgets(
    'UI-R02 actual completed targets keep readable equal rows and labels',
    (t) async {
      final semantics = t.ensureSemantics();
      try {
        for (final width in [296.0, 351.0, 406.0]) {
          for (final scale in [1.0, 1.3]) {
            for (var count = 4; count <= 7; count++) {
              var state = boardFixture(
                colors: count == 7 ? 4 : count - 2,
                extra: count == 7,
              );
              for (final move in state.puzzle.referenceMoves) {
                state = state.pour(move.from, move.to).state;
              }
              expect(state.completed, isTrue);
              await t.pumpWidget(
                MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: width,
                        height: 260,
                        child: CompletionBottles(
                          state: state,
                          settings: const PlayerSettings(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await t.pumpAndSettle();
              final targets = t
                  .widget<CompletionBottles>(find.byType(CompletionBottles))
                  .targetIndices;
              final first = t.getRect(
                find.byKey(Key('completion-bottle-${targets.first}')),
              );
              for (final i in targets) {
                final bottle = find.byKey(Key('completion-bottle-$i'));
                final rect = t.getRect(bottle);
                expect(rect.width, greaterThanOrEqualTo(32));
                expect(rect.width, closeTo(first.width, .000001));
                expect(rect.height, closeTo(first.height, .000001));
                expect(rect.top, i < 2 ? first.top : greaterThan(first.bottom));
                expect(t.getSemantics(bottle).label, contains('4 of 4'));
                expect(
                  t
                      .getSemantics(bottle)
                      .getSemanticsData()
                      .hasAction(SemanticsAction.tap),
                  isFalse,
                );
                final label = t.getRect(
                  find.byKey(Key('completion-target-$i')),
                );
                expect(label.top, greaterThanOrEqualTo(rect.bottom));
                expect(
                  label.bottom,
                  lessThanOrEqualTo(
                    t.getRect(find.byType(CompletionBottles)).bottom,
                  ),
                );
              }
              for (var i = targets.length; i < state.board.length; i++) {
                expect(find.byKey(Key('completion-target-$i')), findsNothing);
              }
              expect(t.takeException(), isNull);
            }
          }
        }
      } finally {
        await t.pumpWidget(const SizedBox());
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'LY02 production bounded 4–7 board has disjoint hits and every flight avoids readout band',
    (t) async {
      for (final width in [296.0, 351.0, 406.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          for (final available in [305.0, 380.0, 480.0]) {
            for (var count = 4; count <= 7; count++) {
              final state = boardFixture(
                colors: count == 7 ? 4 : count - 2,
                extra: count == 7,
              );
              await t.pumpWidget(
                MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: width,
                        height: available,
                        child: BoardView(
                          state: state,
                          selected: null,
                          onTap: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await t.pump();
              final game = t
                  .widget<GameWidget<FlameBoardGame>>(
                    find.byType(GameWidget<FlameBoardGame>),
                  )
                  .game!;
              final layout = game.frame.layout;
              final canvas = t.getRect(find.byKey(const Key('dock-canvas')));
              final viewport = t.getRect(
                find.byKey(const Key('board-accessibility-viewport')),
              );
              final band = Rect.fromLTRB(
                0,
                canvas.height,
                width,
                viewport.bottom - canvas.top,
              );
              for (final cell in layout.cells) {
                expect(cell.width, closeTo(layout.cells.first.width, .00001));
                expect(cell.height, closeTo(layout.cells.first.height, .00001));
              }
              for (var i = 0; i < count; i++) {
                expect(layout.cells[i].width, greaterThanOrEqualTo(48));
                expect(layout.cells[i].height, greaterThanOrEqualTo(48));
                for (var j = i + 1; j < count; j++) {
                  expect(layout.cells[i].overlaps(layout.cells[j]), isFalse);
                }
              }
              for (var from = 0; from < count; from++) {
                for (var to = 0; to < count; to++) {
                  if (from == to) continue;
                  for (final units in [1, 2, 4]) {
                    final g = PourGeometry(
                      shape: layout.shape,
                      sourceMouth: layout.mouths[from],
                      targetMouth: layout.mouths[to],
                      units: units,
                      sourceUnits: 4,
                      initialLift: 9,
                      bounds: layout.flightBounds,
                    );
                    for (var ms = 0.0; ms <= g.totalMs; ms += 15) {
                      final f = g.frame(ms);
                      final corners = [
                        layout.shape.imageRect.topLeft,
                        layout.shape.imageRect.topRight,
                        layout.shape.imageRect.bottomLeft,
                        layout.shape.imageRect.bottomRight,
                      ].map(f.source.transform).toList();
                      final art = Rect.fromLTRB(
                        corners.map((p) => p.dx).reduce(math.min),
                        corners.map((p) => p.dy).reduce(math.min),
                        corners.map((p) => p.dx).reduce(math.max),
                        corners.map((p) => p.dy).reduce(math.max),
                      );
                      expect(art.left, greaterThanOrEqualTo(-.01));
                      expect(art.right, lessThanOrEqualTo(width + .01));
                      expect(art.top, greaterThanOrEqualTo(-.01));
                      expect(
                        art.bottom,
                        lessThanOrEqualTo(layout.height + .01),
                      );
                      for (var i = 0; i < count; i++) {
                        expect(
                          art.overlaps(band)
                              ? art.intersect(band).width *
                                    art.intersect(band).height
                              : 0.0,
                          lessThanOrEqualTo(.01),
                          reason:
                              '$width/$scale/$available/$count $from->$to units$units ms$ms band$band',
                        );
                        if (f.inStream > .00001) {
                          expect(
                            Rect.fromPoints(
                              f.streamStart,
                              f.streamEnd,
                            ).inflate(2).overlaps(band),
                            isFalse,
                          );
                        }
                      }
                      expect(
                        4 - f.out + f.delivered + f.inStream,
                        closeTo(4, .00001),
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
  );
}
