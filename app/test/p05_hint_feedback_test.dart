import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_feedback.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/nunito/Nunito[wght].ttf'))).load();
  });
  for (final width in [343.0, 768.0]) {
    testWidgets(
      'compact Hint at width $width and 2x text fits without moving board',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 700);
        addTearDown(t.view.reset);
        final dir = Directory.systemTemp.createTempSync('p05-hint-');
        final store = (await t.runAsync(
          () => GameStore.open(
            '${dir.path}/qa.sqlite',
            factory: databaseFactoryFfi,
          ),
        ))!;
        final puzzle = Puzzle.parse(
          File('assets/puzzles/main/main-012.json').readAsStringSync(),
        );
        final response = Completer<HintResult>();
        final c = GameController(
          store,
          library: ContentLibrary(main: {12: puzzle}),
          hintLauncher: (_) => (
            result: response.future,
            cancel: () {
              if (!response.isCompleted) {
                response.complete(const HintResult(HintStatus.cancelled));
              }
            },
            released: Future<void>.value(),
          ),
        );
        try {
          await t.runAsync(() async {
            await store.save(
              GameInstance.create(id: 'p05-hint', puzzle: puzzle),
            );
            await c.initialize();
            await c.resumeSlot('ordinary');
          });
          await t.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 700),
                  textScaler: const TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: AnimatedBuilder(
                    animation: c,
                    builder: (context, _) => Column(
                      children: [
                        BoardFeedback(
                          controller: c,
                          noMoves: false,
                          unmatched: false,
                        ),
                        const SizedBox(key: Key('board-anchor'), height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          final anchor = t.getRect(find.byKey(const Key('board-anchor')));
          final pending = c.requestHint();
          await t.pump();
          void fits() {
            expect(t.takeException(), isNull);
            final panel = t.getRect(find.byKey(const Key('feedback-badge')));
            final title = t.getRect(find.byKey(const Key('feedback-title')));
            expect(panel.width, lessThanOrEqualTo(width));
            expect(
              panel.width,
              greaterThan(280),
              reason: 'Large type gets the available badge width before wrapping, while normal stays compact.',
            );
            final paragraph = t.renderObject<RenderParagraph>(
              find.byKey(const Key('feedback-title')),
            );
            expect(
              paragraph.getMinIntrinsicHeight(title.width),
              lessThanOrEqualTo(title.height + .01),
              reason: 'all wrapped title lines must be visible, without height clipping',
            );
            expect(title.top, greaterThanOrEqualTo(panel.top));
            expect(title.bottom, lessThanOrEqualTo(panel.bottom));
            expect(
              t.getRect(find.byKey(const Key('cancel-hint'))).size,
              const Size(48, 48),
            );
            expect(t.getRect(find.byKey(const Key('board-anchor'))), anchor);
          }

          fits();
          response.complete(
            HintResult(HintStatus.found, move: puzzle.referenceMoves.first),
          );
          await t.runAsync(() => pending);
          await t.pumpAndSettle();
          fits();
          await t.tap(find.byKey(const Key('cancel-hint')));
          await t.pumpAndSettle();
          expect(c.hint, isNull);
          expect(t.getRect(find.byKey(const Key('board-anchor'))), anchor);
        } finally {
          c.dispose();
          await t.runAsync(store.close);
          dir.deleteSync(recursive: true);
        }
      },
    );
  }
}
