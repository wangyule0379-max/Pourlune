// Page behavior and representative layout checks only; no visual acceptance.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/navigation_pages.dart';
import 'package:pourlune_dev/presentation/knit_components.dart';
import 'package:pourlune_dev/presentation/scene_art.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show fixture, finish, sample;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late GameController controller;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('parallel-navigation-');
    store = await GameStore.open(
      '${dir.path}/navigation.sqlite',
      factory: databaseFactoryFfi,
    );
    controller = GameController(
      store,
      library: ContentLibrary(
        main: {for (var n = 1; n <= 60; n++) n: fixture(n)},
      ),
      clock: () => LocalDay('2026-10-25', 'QA', 480),
    );
  });
  tearDown(() async {
    controller.dispose();
    await store.close();
    dir.deleteSync(recursive: true);
  });

  testWidgets('locked chapter summaries preserve replay and current actions', (
    t,
  ) async {
    controller.progress = LocalProgress(
      11,
      ['color_studio:1', 'color_studio:2'],
      List.generate(12, (i) => i + 1),
      0,
      11,
      [],
      completedLevels: List.generate(11, (i) => i + 1),
    );
    final played = <int>[];
    await t.pumpWidget(
      _screen(ChaptersPage(controller: controller, onPlay: played.add)),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('level-20')), findsOneWidget);
    expect(find.byKey(const Key('level-21')), findsNothing);
    expect(find.byKey(const Key('level-41')), findsNothing);
    expect(find.text('Complete Color Studio'), findsOneWidget);
    expect(find.text('Complete Garden Nook'), findsOneWidget);
    final lockedCard = find.byKey(const Key('chapter-garden_nook'));
    final lockedPreview = t.widget<SceneArt>(
      find.descendant(of: lockedCard, matching: find.byType(SceneArt)),
    );
    expect(lockedPreview.preview, isTrue);
    expect(lockedPreview.pieces, ['color_studio:1', 'color_studio:2']);
    expect(
      find.byKey(const Key('scene-garden_nook-preview-5')),
      findsOneWidget,
    );
    final previewViewport = t.getRect(
      find.byKey(const Key('chapter-garden_nook-thumbnail-viewport')),
    );
    for (var i = 1; i <= 5; i++) {
      final object = t.getRect(find.byKey(Key('scene-garden_nook-preview-$i')));
      expect(previewViewport.contains(object.topLeft), isTrue);
      expect(previewViewport.contains(object.bottomRight), isTrue);
    }
    final current = find.byKey(const Key('level-12'));
    expect(t.widget(current), isA<FilledButton>());
    final locked = t.widget<OutlinedButton>(find.byKey(const Key('level-13')));
    expect(locked.onPressed, isNull);
    await t.ensureVisible(find.byKey(const Key('level-1')));
    await t.tap(find.byKey(const Key('level-1')));
    await t.ensureVisible(current);
    await t.tap(current);
    await t.ensureVisible(find.byKey(const Key('chapter-play-next')));
    await t.tap(find.byKey(const Key('chapter-play-next')));
    expect(played, [1, 12, 12]);
    expect(controller.progress.firstClears, 11);
    expect(controller.current, isNull);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('an unlocked later chapter retains earlier replay controls', (
    t,
  ) async {
    controller.progress = LocalProgress(
      20,
      [for (var i = 1; i <= 5; i++) 'color_studio:$i'],
      List.generate(21, (i) => i + 1),
      0,
      20,
      [],
      completedLevels: List.generate(20, (i) => i + 1),
    );
    final played = <int>[];
    await t.pumpWidget(
      _screen(ChaptersPage(controller: controller, onPlay: played.add)),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('level-1')), findsOneWidget);
    expect(find.byKey(const Key('level-40')), findsOneWidget);
    expect(find.byKey(const Key('level-41')), findsNothing);
    await t.ensureVisible(find.byKey(const Key('level-21')));
    await t.tap(find.byKey(const Key('level-21')));
    expect(played, [21]);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'unlocked chapter thumbnails retain the floor and owned objects',
    (t) async {
      await t.binding.setSurfaceSize(const Size(402, 874));
      addTearDown(() => t.binding.setSurfaceSize(null));
      // Every chapter is unlocked and fully furnished: the low floor objects
      // must remain inside the thumbnail just as they do in locked previews.
      const scenes = ['color_studio', 'garden_nook', 'seaside_corner'];
      controller.progress = LocalProgress(
        60,
        [
          for (final scene in scenes)
            for (var i = 1; i <= 5; i++) '$scene:$i',
        ],
        List.generate(60, (i) => i + 1),
        0,
        60,
        [],
        completedLevels: List.generate(60, (i) => i + 1),
      );
      await t.pumpWidget(
        _screen(ChaptersPage(controller: controller, onPlay: (_) {})),
      );
      await t.pumpAndSettle();
      for (final scene in scenes) {
        final viewport = find.byKey(Key('chapter-$scene-thumbnail-viewport'));
        await t.ensureVisible(viewport);
        final visible = t.getRect(viewport);
        final base = t.getRect(find.byKey(Key('scene-$scene-base')));
        expect(base.width, closeTo(base.height, .01));
        for (final part in ['base', for (var i = 1; i <= 5; i++) 'piece-$i']) {
          final bounds = t.getRect(find.byKey(Key('scene-$scene-$part')));
          expect(bounds.left, greaterThanOrEqualTo(visible.left - .01));
          expect(bounds.right, lessThanOrEqualTo(visible.right + .01));
          expect(bounds.top, greaterThanOrEqualTo(visible.top - .01));
          expect(
            bounds.bottom,
            lessThanOrEqualTo(visible.bottom + .01),
            reason: '$scene $part must not be cropped after chapter unlock',
          );
        }
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('chapter targets stay reachable at 320px and large text', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    for (final scale in [1.0, 2.0]) {
      await t.pumpWidget(
        _screen(
          ChaptersPage(controller: controller, onPlay: (_) {}),
          scale: scale,
        ),
      );
      await t.pumpAndSettle();
      for (final key in ['level-1', 'level-20', 'chapter-play-next']) {
        final control = find.byKey(Key(key));
        await t.ensureVisible(control);
        final rect = t.getRect(control);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      expect(t.takeException(), isNull, reason: '320px, text scale $scale');
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('welcome keeps the real start action above small-screen fold', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final played = <int>[];
    await t.pumpWidget(
      _screen(
        HomePage(
          controller: controller,
          onPlay: played.add,
          onEngineering: (_) {},
        ),
      ),
    );
    await t.pumpAndSettle();
    final start = find.byKey(const Key('sample-main-001'));
    expect(t.getRect(start).bottom, lessThanOrEqualTo(568));
    await t.tap(start);
    expect(played, [1]);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'P02 reference cards keep square corners and inset readable labels',
    (t) async {
      addTearDown(() => t.binding.setSurfaceSize(null));
      controller.tutorialComplete = true;
      for (final size in [const Size(375, 667), const Size(402, 874)]) {
        await t.binding.setSurfaceSize(size);
        await t.pumpWidget(
          _screen(
            HomePage(
              controller: controller,
              onPlay: (_) {},
              onEngineering: (_) {},
            ),
          ),
        );
        await t.pumpAndSettle();
        for (final entry in [
          ('chapters', 'Chapters'),
          ('daily', 'Daily puzzle'),
          ('collection', 'Collection'),
        ]) {
          final card = find.byKey(Key(entry.$1));
          await t.ensureVisible(card);
          final bounds = t.getRect(card);
          final label = t.getRect(
            find.descendant(of: card, matching: find.text(entry.$2)),
          );
          expect(label.left - bounds.left, greaterThanOrEqualTo(8));
          expect(bounds.right - label.right, greaterThanOrEqualTo(8));
          final material = t.widget<Material>(
            find.descendant(of: card, matching: find.byType(Material)).first,
          );
          // A default stadium clips this reference-card corner into an ellipse.
          // Check the actual resolved paint path, not a particular shape class.
          final outline = material.shape!.getOuterPath(
            Offset.zero & bounds.size,
          );
          expect(outline.contains(const Offset(12, 12)), isTrue);
        }
        expect(
          t.takeException(),
          isNull,
          reason: '$size reference card layout',
        );
      }
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('P03 level cells preserve a rectangular painted corner', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      _screen(ChaptersPage(controller: controller, onPlay: (_) {})),
    );
    await t.pumpAndSettle();
    for (final key in ['level-1', 'level-2']) {
      final cell = find.byKey(Key(key));
      final material = t.widget<Material>(
        find.descendant(of: cell, matching: find.byType(Material)).first,
      );
      final outline = material.shape!.getOuterPath(
        Offset.zero & t.getSize(cell),
      );
      expect(outline.contains(const Offset(6, 6)), isTrue);
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('story-complete entrances remain reachable with full copy', (
    t,
  ) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.runAsync(
      () => store.settle(
        finish(sample('p02-r1-final-save', level: 60)),
        replace: true,
      ),
    );
    await t.runAsync(controller.initialize);
    controller.progress = LocalProgress(
      60,
      [
        for (final scene in ['color_studio', 'garden_nook', 'seaside_corner'])
          for (var i = 1; i <= 5; i++) '$scene:$i',
      ],
      List.generate(60, (i) => i + 1),
      0,
      60,
      [],
      completedLevels: List.generate(60, (i) => i + 1),
    );
    for (final size in [const Size(375, 667), const Size(402, 874)]) {
      for (final scale in [1.0, 2.0]) {
        await t.binding.setSurfaceSize(size);
        await t.pumpWidget(
          _screen(
            HomePage(
              controller: controller,
              onPlay: (_) {},
              onEngineering: (_) {},
            ),
            scale: scale,
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('Story complete'), findsOneWidget);
        expect(
          find.textContaining('Your story is complete. Return'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('saved-result')), findsOneWidget);
        for (final entry in [
          ('replay-levels', GamePage.chapters),
          ('daily', GamePage.daily),
          ('collection', GamePage.collection),
        ]) {
          final control = find.byKey(Key(entry.$1));
          await t.ensureVisible(control);
          final rect = t.getRect(control);
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          await t.runAsync(() => t.tap(control));
          await t.pumpAndSettle();
          expect(controller.page, entry.$2);
        }
        expect(t.takeException(), isNull, reason: '$size/$scale story home');
      }
    }
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'P02 normal home centers branding and keeps core entries before saved result',
    (t) async {
      addTearDown(t.view.reset);
      await t.runAsync(
        () => store.settle(
          finish(sample('p02-composition-saved', level: 12)),
          replace: true,
        ),
      );
      await t.runAsync(controller.initialize);
      controller.progress = LocalProgress(
        12,
        ['color_studio:1', 'color_studio:2', 'color_studio:3'],
        List.generate(13, (i) => i + 1),
        0,
        12,
        [],
        completedLevels: List.generate(12, (i) => i + 1),
      );
      for (final spec in [
        (size: const Size(375, 667), top: 20.0, bottom: 0.0),
        (size: const Size(402, 874), top: 62.0, bottom: 34.0),
      ]) {
        await t.pumpWidget(const SizedBox());
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = spec.size;
        final padding = FakeViewPadding(top: spec.top, bottom: spec.bottom);
        t.view.padding = padding;
        t.view.viewPadding = padding;
        await t.pumpWidget(
          _screen(
            HomePage(
              controller: controller,
              onPlay: (_) {},
              onEngineering: (_) {},
            ),
            safeArea: true,
          ),
        );
        await t.pumpAndSettle();
        final logo = find.byWidgetPredicate(
          (w) => w is KnitArt && w.name == 'logo',
        );
        expect(t.getCenter(logo).dx, closeTo(spec.size.width / 2, .5));
        final result = t.getRect(find.byKey(const Key('saved-result')));
        for (final key in ['chapters', 'daily', 'collection']) {
          final rect = t.getRect(find.byKey(Key(key)));
          expect(rect.top, greaterThanOrEqualTo(spec.top));
          expect(
            rect.bottom,
            lessThanOrEqualTo(spec.size.height - spec.bottom),
          );
          expect(rect.bottom, lessThanOrEqualTo(result.top));
          expect(rect.shortestSide, greaterThanOrEqualTo(48));
        }
        expect(controller.progress.pieces.length, 3);
        expect(
          t.takeException(),
          isNull,
          reason: '${spec.size} home composition',
        );
      }
      await t.pumpWidget(const SizedBox());
    },
  );
}

Widget _screen(Widget child, {double scale = 1, bool safeArea = false}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(fontFamily: 'Nunito'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(
          top: safeArea,
          bottom: safeArea,
          left: safeArea,
          right: safeArea,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
