import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/flame_board_ready.dart';
import 'support/flame_board_support.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'));
    await font.load();
  });

  for (final spec in [
    (size: const Size(320, 568), top: 20.0, bottom: 0.0, scale: 1.0),
    (size: const Size(320, 568), top: 20.0, bottom: 0.0, scale: 2.0),
    (size: const Size(375, 667), top: 20.0, bottom: 0.0, scale: 1.65),
    (size: const Size(390, 844), top: 47.0, bottom: 34.0, scale: 1.0),
    (size: const Size(430, 932), top: 59.0, bottom: 34.0, scale: 2.0),
    (size: const Size(375, 667), top: 20.0, bottom: 0.0, scale: 3.2),
  ]) {
    for (final count in [4, 5, 6, 7]) {
      testWidgets(
        'feedback $count bottles ${spec.size}/${spec.scale} stays stationary',
        (t) async {
          final semantics = t.ensureSemantics();
          final maximum = spec.scale > 2;
          addTearDown(t.view.reset);
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = spec.size;
          t.view.padding = FakeViewPadding(top: spec.top, bottom: spec.bottom);
          final dir = Directory.systemTemp.createTempSync('feedback-ui-');
          final store = (await t.runAsync(
            () => GameStore.open(
              '${dir.path}/ui.sqlite',
              factory: databaseFactoryFfi,
            ),
          ))!;
          // A five-bottle persisted instance keeps its own earlier definition.
          final colors = count == 7 ? 4 : count - 2;
          final puzzle = Puzzle.fromJson(
            boardFixture(colors: colors).puzzle.toJson()
              ..['main_level'] = 24
              ..['puzzle_id'] = 'main-024',
          );
          var saved = GameInstance.create(
            id: 'feedback-$count',
            puzzle: puzzle,
          ).pour(0, colors).state;
          if (count == 7) saved = saved.grantExtraBottle();
          final responses = <Completer<HintResult>>[];
          final c = GameController(
            store,
            library: ContentLibrary(main: {24: puzzle}),
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
              await store.save(saved);
              await c.initialize();
              await c.resumeSlot('ordinary');
            });
            await t.pumpWidget(
              RepaintBoundary(
                key: const Key('feedback-capture'),
                child: PourluneApp(
                  controller: c,
                  textScaler: TextScaler.linear(spec.scale),
                ),
              ),
            );
            await t.pumpAndSettle();
            await settleFlameBoard(t, c);
            if (count == 7 && spec.size.width == 320 && spec.scale == 2) {
              final boundary = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('feedback-capture')),
              );
              await t.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final output = File(
                  '../build/fidelity-320-2x-actual-flutter-render.png',
                );
                output.parent.createSync(recursive: true);
                output.writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            final keys = [
              PageStorageKey('board-viewport-${saved.id}'),
              const Key('bottle-count-0'),
              Key('bottle-count-${count - 1}'),
              const Key('extra-bottle'),
              const Key('undo'),
              const Key('hint'),
            ];
            final before = {
              for (final key in keys) key: t.getRect(find.byKey(key)),
            };
            expect(
              before[const Key('undo')]!.height,
              closeTo(before[const Key('extra-bottle')]!.height, .01),
              reason: 'Auxiliary buttons keep the same visual height with large text.',
            );
            for (final action in ['undo', 'hint', 'extra-bottle']) {
              final button = find.byKey(Key(action));
              final bounds = t.getRect(button);
              expect(bounds.width, greaterThanOrEqualTo(48));
              expect(bounds.height, greaterThanOrEqualTo(48));
              for (final text
                  in find
                      .descendant(of: button, matching: find.byType(Text))
                      .evaluate()) {
                final paragraph = text.renderObject! as RenderParagraph;
                expect(
                  paragraph.getMinIntrinsicHeight(paragraph.size.width),
                  lessThanOrEqualTo(paragraph.size.height + .01),
                  reason: 'Large action labels must remain complete.',
                );
              }
            }
            final viewport =
                before[PageStorageKey('board-viewport-${saved.id}')]!;
            for (var i = 0; i < count; i++) {
              final bottle = find.byKey(Key('bottle-$i'));
              final hit = t.getRect(bottle);
              final label = t.getRect(find.byKey(Key('bottle-count-$i')));
              expect(hit.width, greaterThanOrEqualTo(48));
              expect(hit.height, greaterThanOrEqualTo(48));
              expect(hit.top, greaterThanOrEqualTo(viewport.top));
              expect(
                label.bottom,
                lessThanOrEqualTo(viewport.bottom + .01),
                reason: 'Every capacity remains visible without scrolling the board.',
              );
              expect(bottle.hitTestable(), findsOneWidget);
            }
            void stationary() {
              for (final key in keys) {
                final finder =
                    key == const Key('hint') &&
                        find.byKey(key).evaluate().isEmpty
                    ? find.byKey(const Key('cancel-hint'))
                    : find.byKey(key);
                expect(t.getRect(finder), before[key], reason: '$key moved');
              }
            }

            Future<void> expectFeedback(String full, String compact) async {
              if (maximum) {
                expect(
                  t.widget<Text>(find.byKey(const Key('board-status'))).data,
                  compact,
                );
              } else {
                expect(find.text(full), findsOneWidget);
              }
              if (!maximum) return;
              await t.tap(find.byKey(const Key('board-info')));
              await t.pumpAndSettle();
              expect(
                find.descendant(
                  of: find.byKey(const Key('board-information')),
                  matching: find.text(full),
                ),
                findsOneWidget,
              );
              await t.tap(find.byKey(const Key('board-info-close')));
              await t.pumpAndSettle();
            }

            void shortRefusalStaysOneLine() {
              if (spec.scale != 1) return;
              final paragraph = t.renderObject<RenderParagraph>(
                find.byKey(const Key('feedback-title')),
              );
              final boxes = paragraph.getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: paragraph.text.toPlainText().length,
                ),
              );
              expect(
                boxes.map((box) => box.top).toSet().length,
                1,
                reason: 'Short ordinary refusal must fit one line using the actual inherited text style.',
              );
            }

            await t.tap(find.byKey(const Key('bottle-1')));
            await t.tap(find.byKey(Key('bottle-$colors')));
            await t.pumpAndSettle();
            await settleFlameBoard(t, c);
            expect(c.rejection, isNull);
            expect(c.selectedSource, colors);
            expect(c.current!.moveCount, saved.moveCount);
            expect(c.current!.board, saved.board);
            stationary();
            expect(find.text("Can't pour here"), findsNothing);
            expect(find.text('Bottle full'), findsNothing);
            expect(find.byKey(const Key('feedback-badge')), findsNothing);
            expect(find.byKey(const Key('cancel-hint')), findsNothing);
            // Explicit controller.pour remains a real rejection path below.
            for (final reason in [
              (0, 1, 'That bottle is full', 'Bottle full'),
              (colors + 1, 0, 'Choose a bottle with liquid', 'Empty'),
            ]) {
              await t.runAsync(() => c.pour(reason.$1, reason.$2));
              await t.pumpAndSettle();
              await settleFlameBoard(t, c);
              expect(c.rejection, reason.$3);
              await expectFeedback(
                reason.$4,
                reason.$4 == 'Bottle full' ? 'Full' : reason.$4,
              );
              shortRefusalStaysOneLine();
              expect(c.current!.moveCount, saved.moveCount);
              expect(c.current!.board, saved.board);
              expect(find.byKey(const Key('cancel-hint')), findsNothing);
              stationary();
            }

            final request = c.requestHint();
            await t.pumpAndSettle();
            stationary();
            expect(
              find.byKey(const Key('cancel-hint')).hitTestable(),
              findsOneWidget,
            );
            responses.last.complete(
              const HintResult(HintStatus.found, move: PourMove(1, 0)),
            );
            await t.pumpAndSettle();
            await request;
            await settleFlameBoard(t, c);
            stationary();
            await expectFeedback('Bottle 2 → 1', '2 → 1');
            expect(
              find.bySemanticsLabel(RegExp(r'Bottle 2\..*Suggested source')),
              findsOneWidget,
            );
            expect(
              c.current!.moveCount,
              saved.moveCount,
              reason: 'Hint never pours automatically.',
            );
            await t.tap(find.byKey(const Key('cancel-hint')));
            await t.pumpAndSettle();
            await settleFlameBoard(t, c);
            stationary();
            expect(c.hint, isNull);
            expect(c.selectedSource, isNull);
            expect(
              find.text(maximum ? 'Rules' : 'Match the color tags'),
              findsOneWidget,
            );
            if (spec.scale == 1.0) {
              expect(
                find.text(
                  'Match every color to its target. Leave all buffers empty.',
                ),
                findsNothing,
                reason: 'Normal PLAY follows the approved plain heading.',
              );
              await t.longPress(find.byKey(const Key('feedback-title')));
              await t.pumpAndSettle();
              expect(
                find
                    .text(
                      'Match every color to its target. Leave all buffers empty.',
                    )
                    .hitTestable(),
                findsOneWidget,
                reason: 'Full rules remain available through the normal heading help.',
              );
              await t.tap(find.text('Close'));
              await t.pumpAndSettle();
              stationary();
            }
            for (final outcome in [
              (HintStatus.timeout, 'No hint found yet'),
              (HintStatus.provenUnsolvable, 'Try Undo'),
            ]) {
              final pending = c.requestHint();
              await t.pumpAndSettle();
              responses.last.complete(HintResult(outcome.$1));
              await t.pumpAndSettle();
              await pending;
              stationary();
              await expectFeedback(
                outcome.$2,
                outcome.$1 == HintStatus.timeout ? 'Try again' : 'Undo',
              );
              final feedback = t.getRect(
                find.byKey(
                  Key(maximum ? 'large-text-board' : 'board-feedback'),
                ),
              );
              final title = t.getRect(
                find.byKey(Key(maximum ? 'board-status' : 'feedback-title')),
              );
              final cancel = t.getRect(find.byKey(const Key('cancel-hint')));
              expect(title.top, greaterThanOrEqualTo(feedback.top));
              expect(title.bottom, lessThanOrEqualTo(feedback.bottom));
              expect(cancel.height, greaterThanOrEqualTo(48));
              expect(cancel.width, greaterThanOrEqualTo(48));
              expect(cancel.bottom, lessThanOrEqualTo(feedback.bottom));
              await t.tap(find.byKey(const Key('cancel-hint')));
              await t.pumpAndSettle();
              stationary();
            }

            expect(t.takeException(), isNull);
          } finally {
            semantics.dispose();
            c.cancelHint();
            await t.pumpWidget(const SizedBox());
            c.dispose();
            await t.runAsync(store.close);
            dir.deleteSync(recursive: true);
          }
        },
      );
    }
  }
}
