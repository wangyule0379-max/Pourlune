import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/p05_max_text_review_app.dart';
import 'support/flame_board_ready.dart';

void main() {
  sqfliteFfiInit();
  for (final scale in [1.0, 2.0, 2.01, 3.2]) {
    testWidgets('isolated max candidate full GameScreen $scale', (t) async {
      final semantics = t.ensureSemantics();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(375, 667);
      t.view.padding = const FakeViewPadding(top: 20);
      final dir = Directory.systemTemp.createTempSync('max-review-');
      final store = (await t.runAsync(
        () => GameStore.open(
          '${dir.path}/qa.sqlite',
          factory: databaseFactoryFfi,
        ),
      ))!;
      final puzzle = Puzzle.parse(
        (await t.runAsync(
          () => rootBundle.loadString(
            'assets/puzzles/main/main-012.json',
            cache: false,
          ),
        ))!,
      );
      var state = GameInstance.create(id: 'max-test', puzzle: puzzle);
      for (final move in puzzle.referenceMoves.take(11)) {
        state = state.pour(move.from, move.to).state;
      }
      state = state.grantExtraBottle().pour(0, 5).state;
      final responses = <Completer<HintResult>>[];
      final c = GameController(
        store,
        library: ContentLibrary(main: {12: puzzle}),
        hintLauncher: (_) {
          final response = Completer<HintResult>();
          responses.add(response);
          return (
            result: response.future,
            cancel: () {
              if (!response.isCompleted) {
                response.complete(const HintResult(HintStatus.cancelled));
              }
            },
            released: Future<void>.value(),
          );
        },
      );
      try {
        await t.runAsync(() async {
          await store.save(state);
          await c.initialize();
          await c.resumeSlot('ordinary');
        });
        await t.pumpWidget(
          RepaintBoundary(
            key: const Key('max-capture'),
            child: MaxTextReviewApp(
              controller: c,
              textScaler: TextScaler.linear(scale),
            ),
          ),
        );
        await t.pumpAndSettle();
        await settleFlameBoard(t, c);
        if (scale <= 2) {
          expect(find.byKey(const Key('max-page')), findsNothing);
          expect(find.byKey(const Key('board-feedback')), findsOneWidget);
          final viewport = t.getRect(
            find.byKey(const PageStorageKey('board-viewport-max-test')),
          );
          for (var i = 0; i < 7; i++) {
            expect(
              t.getRect(find.byKey(Key('bottle-count-$i'))).bottom,
              lessThanOrEqualTo(viewport.bottom + .01),
            );
            expect(
              t.getRect(find.byKey(Key('bottle-$i'))).height,
              greaterThanOrEqualTo(48),
            );
          }
          expect(t.takeException(), isNull);
          return;
        }
        final viewport = t.getRect(find.byKey(const Key('max-canvas')));
        final game = t
            .widget<GameWidget<FlameBoardGame>>(
              find.byType(GameWidget<FlameBoardGame>),
            )
            .game!;
        // Check real rendered targets and text boxes, not only stored labels.
        for (var i = 0; i < 7; i++) {
          final hit = t.getRect(find.byKey(Key('max-bottle-$i')));
          final label = t.getRect(find.byKey(Key('max-label-$i')));
          expect(
            hit.height,
            greaterThanOrEqualTo(80),
            reason: 'All actual bottle bodies remain discernible.',
          );
          expect(hit.width, greaterThanOrEqualTo(48));
          expect(label.bottom, lessThanOrEqualTo(viewport.bottom + .01));
          expect(hit.top, greaterThanOrEqualTo(viewport.top));
          for (final key in ['max-index-$i', 'max-count-$i']) {
            final p = t.renderObject<RenderParagraph>(find.byKey(Key(key)));
            expect(
              p.getMinIntrinsicHeight(p.size.width),
              lessThanOrEqualTo(p.size.height + .01),
            );
          }
          if (i < 4) {
            final index = t.getRect(find.byKey(Key('max-index-$i'))),
                target = t.getRect(find.byKey(Key('max-target-$i')));
            expect(index.right, lessThanOrEqualTo(target.left));
          }
        }
        expect(
          game.frame.layout.shape.visibleRect.height,
          greaterThanOrEqualTo(80),
        );
        final stable = {
          for (var i = 0; i < 7; i++)
            i: t.getRect(find.byKey(Key('max-label-$i'))),
        };
        for (final key in [
          'max-home',
          'max-pause',
          'max-undo',
          'max-hint',
          'max-extra',
          'max-info',
        ]) {
          final rect = t.getRect(find.byKey(Key(key)));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.top, greaterThanOrEqualTo(20));
          expect(rect.bottom, lessThanOrEqualTo(667));
        }
        await t.tap(find.byKey(const Key('max-bottle-1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('max-bottle-2')));
        await t.pumpAndSettle();
        expect(c.selectedSource, 2);
        expect(c.rejection, isNull);
        expect(find.text('Full'), findsNothing);
        // Keep the real rejection/detail layout guard via explicit pour.
        await t.runAsync(() => c.pour(1, 2));
        await t.pumpAndSettle();
        expect(find.text('Full'), findsOneWidget);
        expect(c.current!.board, state.board);
        expect(c.current!.moveCount, 12);
        for (var i = 0; i < 7; i++) {
          expect(t.getRect(find.byKey(Key('max-label-$i'))), stable[i]);
        }
        await t.tap(find.byKey(const Key('max-info')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('max-information')), findsOneWidget);
        expect(find.text('Bottle full'), findsOneWidget);
        await t.tap(find.byKey(const Key('max-info-close')));
        await t.pumpAndSettle();
        expect(c.current!.board, state.board);
        for (var i = 0; i < 7; i++) {
          expect(t.getRect(find.byKey(Key('max-label-$i'))), stable[i]);
        }
        if (scale == 3.2) {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('max-capture')),
          );
          await t.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = File('../build/p05-max-c17-widget-3.2.png');
            output.parent.createSync(recursive: true);
            output.writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        // Cancel the new source, then make the same real saving transition.
        await t.tap(find.byKey(const Key('max-bottle-2')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('max-bottle-0')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('max-bottle-3')));
        await t.pump();
        expect(find.byKey(const Key('max-page')), findsOneWidget);
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await settleFlameBoard(t, c);
        expect(c.current!.moveCount, 13);
        await t.tap(find.byKey(const Key('max-undo')));
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await settleFlameBoard(t, c);
        expect(c.current!.board, state.board);
        for (final result in [
          (
            HintStatus.found,
            '1 → 4',
            'Bottle 1 → 4',
            'Tap 4 to move the top Blue square group along a solution.',
          ),
          (
            HintStatus.timeout,
            'Try again',
            'No hint found yet',
            'You can keep playing.',
          ),
          (
            HintStatus.provenUnsolvable,
            'Undo',
            'Try Undo',
            'Undo or restart to try another path.',
          ),
          (
            HintStatus.noMoves,
            'No moves',
            'No moves available',
            'Undo or restart to keep playing.',
          ),
        ]) {
          await t.tap(find.byKey(const Key('max-hint')));
          await t.pumpAndSettle();
          expect(c.hintSearching, isTrue);
          await t.tap(find.byKey(const Key('max-info')));
          await t.pumpAndSettle();
          responses.last.complete(
            HintResult(
              result.$1,
              move: result.$1 == HintStatus.found ? const PourMove(0, 3) : null,
            ),
          );
          await t.pumpAndSettle();
          expect(
            t.widget<Text>(find.byKey(const Key('max-status'))).data,
            result.$2,
          );
          expect(find.text(result.$3), findsOneWidget);
          expect(find.text(result.$4), findsOneWidget);
          expect(find.text('Finding a move…'), findsNothing);
          final infoViewport = t.getRect(
            find.byKey(const Key('max-info-scroll')),
          );
          final reason = t.getRect(find.text(result.$4));
          expect(reason.top, greaterThanOrEqualTo(infoViewport.top));
          expect(reason.bottom, lessThanOrEqualTo(infoViewport.bottom + .01));
          await t.tap(find.byKey(const Key('max-info-close')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('max-cancel-hint')));
          await t.pumpAndSettle();
          expect(c.current!.board, state.board);
          for (var i = 0; i < 7; i++) {
            expect(t.getRect(find.byKey(Key('max-label-$i'))), stable[i]);
          }
        }
        await t.tap(find.byKey(const Key('max-pause')));
        await t.pumpAndSettle();
        expect(
          t.getRect(find.byKey(const Key('pause-context'))).top,
          greaterThanOrEqualTo(
            t.getRect(find.byKey(const Key('pause-close'))).bottom,
          ),
        );
        expect(
          t.getRect(find.text('Your puzzle is saved.')).bottom,
          lessThanOrEqualTo(
            t.getRect(find.byKey(const Key('pause-context'))).bottom + .01,
          ),
        );
        for (final key in ['resume-pause', 'pause-restart', 'pause-home']) {
          final action = find.byKey(Key(key));
          final bounds = t.getRect(action);
          expect(action.hitTestable(), findsOneWidget);
          expect(bounds.top, greaterThanOrEqualTo(20));
          expect(bounds.bottom, lessThanOrEqualTo(667));
          expect(bounds.height, greaterThanOrEqualTo(48));
        }
        await t.tap(find.byKey(const Key('pause-close')));
        await t.pumpAndSettle();
        expect(c.current!.board, state.board);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        c.dispose();
        await t.runAsync(store.close);
        semantics.dispose();
        t.view.reset();
        dir.deleteSync(recursive: true);
      }
    });
  }
}
