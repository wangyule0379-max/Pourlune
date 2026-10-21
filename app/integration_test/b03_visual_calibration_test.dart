// Native rendering of the same runtime components after geometric calibration.
// Controlled QA states only; no player progression, ad reward or human-play claim.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/presentation/bottle.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('B03 calibrated native scene layers and foreground pour', (
    t,
  ) async {
    final output = Directory(
      '${await getDatabasesPath()}/b03-evidence/calibrated',
    );
    await output.create(recursive: true);
    const rootKey = Key('calibrated-root');
    Future<void> show(Widget child, {bool systemReduced = false}) async {
      await t.pumpWidget(
        RepaintBoundary(
          key: rootKey,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(fontFamily: 'Nunito'),
            builder: (context, body) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: systemReduced),
              child: body!,
            ),
            home: Scaffold(
              body: SafeArea(child: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      );
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> capture(String name, Key key) async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${output.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
      expect(t.takeException(), isNull);
    }

    for (final scene in ['color_studio', 'garden_nook', 'seaside_corner']) {
      for (var n = 0; n <= 5; n++) {
        await show(
          ScenePreview(
            scene: scene,
            pieces: [for (var i = 1; i <= n; i++) '$scene:$i'],
          ),
        );
        await capture('$scene-$n', Key('scene-$scene-composition'));
        if (n == 5) await capture('$scene-full-ui', rootKey);
      }
    }
    final puzzle = Puzzle.parse(
      await rootBundle.loadString('assets/puzzles/main/main-012.json'),
    );
    final before = GameInstance.create(
      id: 'calibration-controlled-pour',
      puzzle: puzzle,
    );
    final first = puzzle.referenceMoves.first;
    final after = before.pour(first.from, first.to).state;
    // Load all bottle resources before starting the motion clock.
    await show(BoardView(state: before, selected: null, onTap: null));
    await show(
      BoardView(
        state: after,
        selected: null,
        onTap: null,
        motion: PourMotion(
          token: 1,
          from: first.from,
          to: first.to,
          units: 1,
          before: before.board,
          after: after.board,
          instanceId: after.id,
          revision: after.revision,
          reducedMotion: false,
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 250));
    await capture('main012-foreground-pour', rootKey);

    await show(
      BoardView(state: before, selected: null, onTap: null),
      systemReduced: true,
    );
    await show(
      BoardView(
        state: after,
        selected: null,
        onTap: null,
        motion: PourMotion(
          token: 2,
          from: first.from,
          to: first.to,
          units: 1,
          before: before.board,
          after: after.board,
          instanceId: after.id,
          revision: after.revision,
          reducedMotion: false,
        ),
      ),
      systemReduced: true,
    );
    final quietBottle = t.widget<BottleButton>(
      find.byKey(Key('bottle-${first.from}')),
    );
    expect(quietBottle.angle, 0);
    expect(quietBottle.lift, 0);
    await capture('main012-system-reduced-pour', rootKey);
    final dbPath =
        '${await getDatabasesPath()}/b03_calibration_feedback.sqlite';
    await deleteDatabase(
      dbPath,
    ); // Explicitly isolated, controlled QA store only.
    final store = await GameStore.open(dbPath);
    final c = GameController(store);
    try {
      await c.initialize();
      final main = Puzzle.parse(
        await rootBundle.loadString('assets/puzzles/main/main-001.json'),
      );
      final daily = Puzzle.parse(
        await rootBundle.loadString('assets/puzzles/daily/daily-025.json'),
      );
      final states = [
        GameInstance.create(id: 'visual-success-main', puzzle: main),
        GameInstance.create(
          id: 'visual-success-daily',
          puzzle: daily,
          slot: 'daily',
          puzzleDate: '2026-10-22',
          timeZone: 'QA controlled date',
          offsetMinutes: 0,
          catalogVersion: 1,
        ),
        GameInstance.create(
          id: 'visual-success-replay',
          puzzle: main,
          isReplay: true,
        ),
      ];
      for (var state in states) {
        for (final move in state.puzzle.referenceMoves) {
          state = state.pour(move.from, move.to).state;
        }
        c.current = state;
        c.receipt = await store.settle(state, replace: true);
        final receipts = (await store.progress()).receipts;
        await show(CompletionPage(controller: c, onPlay: (_) {}));
        await t.pump(const Duration(milliseconds: 100));
        await capture('${state.id}-mid-fade', rootKey);
        await t.pump(const Duration(milliseconds: 600));
        await capture('${state.id}-settled', rootKey);
        expect((await store.progress()).receipts, receipts);
      }
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await store.close();
    }
    await t.pumpWidget(const SizedBox());
    await File('${output.path}/COMPLETE.txt').writeAsString(
      '18 native ScenePreview compositions and3 fullUI; controlled main012 foreground/system-reduced pour; main/daily/replay success midfade/settled. Isolated nativeStore settlements for QA, not real player or independent visual acceptance.\n',
      flush: true,
    );
    debugPrint('B03_CALIBRATED_NATIVE_DIRECTORY=${output.path}');
    await Future<void>.delayed(const Duration(seconds: 2));
  });
}
