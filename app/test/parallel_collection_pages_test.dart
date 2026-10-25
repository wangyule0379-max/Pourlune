import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/collection_pages.dart';
import 'package:pourlune_dev/presentation/scene_art.dart';
import 'package:pourlune_dev/presentation/parallel_collection/scene_detail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show finish, sample;

void main() {
  sqfliteFfiInit();

  test('lock display regions stay inside their objects and do not overlap', () {
    for (final entry in sceneLockDisplayRects.entries) {
      final objects = sceneObjectRects[entry.key]!;
      for (var i = 0; i < entry.value.length; i++) {
        final cover = entry.value[i], object = objects[i];
        expect(cover.left, greaterThanOrEqualTo(object.left - 1e-9));
        expect(cover.top, greaterThanOrEqualTo(object.top - 1e-9));
        expect(cover.right, lessThanOrEqualTo(object.right + 1e-9));
        expect(cover.bottom, lessThanOrEqualTo(object.bottom + 1e-9));
        for (var j = i + 1; j < entry.value.length; j++) {
          expect(
            cover.overlaps(entry.value[j]),
            isFalse,
            reason: '${entry.key}: $i / $j',
          );
        }
      }
    }
  });

  testWidgets('locked chapter previews never become owned pieces', (t) async {
    await _withController(t, (c) async {
      c.progress = _progress(12);
      final ownedBefore = List<String>.of(c.progress.pieces);
      final unlockedBefore = List<int>.of(c.progress.unlockedLevels);
      await t.pumpWidget(_screen(CollectionPage(controller: c)));
      await t.pumpAndSettle();
      for (final scene in ['garden_nook', 'seaside_corner']) {
        for (var i = 1; i <= 5; i++) {
          expect(find.byKey(Key('scene-$scene-preview-$i')), findsOneWidget);
          expect(find.byKey(Key('scene-$scene-piece-$i')), findsNothing);
        }
        expect(find.byKey(Key('collection-lock-$scene')), findsOneWidget);
        final frame = t.getRect(find.byKey(Key('collection-art-frame-$scene')));
        final card = t.getRect(find.byKey(Key('collection-card-$scene')));
        expect(card.contains(frame.topLeft), isTrue);
        expect(card.contains(frame.bottomRight), isTrue);
      }
      expect(c.progress.pieces, ownedBefore);
      expect(c.progress.unlockedLevels, unlockedBefore);
      expect(find.text('3 / 5 patches'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('collection thumbnails keep the whole room inside their clip', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await _withController(t, (c) async {
      c.progress = _progress(12);
      await t.pumpWidget(_screen(CollectionPage(controller: c)));
      await t.pumpAndSettle();
      for (final scene in ['color_studio', 'garden_nook', 'seaside_corner']) {
        final art = find.byKey(Key('scene-$scene-composition'));
        final clip = find
            .ancestor(of: art, matching: find.byType(ClipRect))
            .first;
        final visible = t.getRect(clip);
        final box = t.renderObject<RenderBox>(art);
        final painted = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        expect(painted.left, greaterThanOrEqualTo(visible.left - .01));
        expect(painted.top, greaterThanOrEqualTo(visible.top - .01));
        expect(painted.right, lessThanOrEqualTo(visible.right + .01));
        expect(painted.bottom, lessThanOrEqualTo(visible.bottom + .01));
      }
      expect(t.takeException(), isNull);
    });
  });

  testWidgets(
    'chapter locks follow unlocked levels, including zero-patch entry',
    (t) async {
      await _withController(t, (c) async {
        c.progress = _progress(12);
        await t.pumpWidget(_screen(CollectionPage(controller: c)));
        await t.pumpAndSettle();
        expect(find.text('3 / 5 patches'), findsOneWidget);
        expect(find.text('Complete\nColor Studio'), findsOneWidget);
        expect(find.text('Complete\nGarden Nook'), findsOneWidget);
        expect(
          find.byKey(const Key('collection-lock-garden_nook')),
          findsOneWidget,
        );

        // Opening an unlocked chapter with no piece yet must not look locked.
        c.progress = _progress(20);
        await t.pumpWidget(_screen(CollectionPage(controller: c)));
        await t.pumpAndSettle();
        expect(
          find.byKey(const Key('collection-lock-garden_nook')),
          findsNothing,
        );
        expect(find.text('0 / 5 patches'), findsOneWidget);
        expect(find.text('Complete\nGarden Nook'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    },
  );

  testWidgets('scene uses owned region IDs and actual completed-level count', (
    t,
  ) async {
    await _withController(t, (c) async {
      c.progress = LocalProgress(
        13,
        ['color_studio:1', 'color_studio:2', 'color_studio:3'],
        List.generate(14, (i) => i + 1),
        0,
        13,
        [],
        completedLevels: List.generate(13, (i) => i + 1),
      );
      await t.pumpWidget(_screen(ScenePage(controller: c, onPlay: (_) {})));
      await t.pumpAndSettle();
      expect(find.text('7 levels to complete this scene'), findsOneWidget);
      expect(find.byKey(const Key('scene-region-lock-4')), findsOneWidget);
      expect(find.byKey(const Key('scene-region-lock-5')), findsOneWidget);
      expect(find.byKey(const Key('scene-region-lock-3')), findsNothing);
      for (var i = 1; i <= 5; i++) {
        expect(find.byKey(Key('scene-object-$i')), findsOneWidget);
      }
      final scene = t.widget<SceneArt>(find.byType(SceneArt));
      expect(scene.pieces, c.progress.pieces);
      expect(scene.reveal, isNull);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets(
    'reward revisit does not replay reveal or alter saved ownership',
    (t) async {
      await _withController(t, (c) async {
        await t.runAsync(() async {
          for (var level = 1; level <= 12; level++) {
            await c.store.settle(
              finish(sample('saved-$level', level: level)),
              replace: true,
            );
          }
          await c.store.markRevealed('color_studio:3');
          await c.initialize();
          await c.resumeSlot('ordinary');
          await c.viewPatch();
        });
        await t.pumpWidget(_screen(RewardPage(controller: c)));
        await t.pumpAndSettle();
        expect(find.text('8 levels to complete this scene'), findsOneWidget);
        expect(find.text('3 / 5 patches'), findsOneWidget);
        expect(t.widget<SceneArt>(find.byType(SceneArt)).reveal, isNull);
        final before = await t.runAsync(c.store.progress);
        await t.pump(const Duration(seconds: 2));
        final after = await t.runAsync(c.store.progress);
        expect(after!.pieces, before!.pieces);
        expect(after.receipts, before.receipts);
        expect(t.takeException(), isNull);
      });
    },
  );

  testWidgets('final patch has one completion heading and no next level', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    try {
      await _withController(t, (c) async {
        c.progress = _progress(60);
        c.current = finish(sample('final-patch', level: 60));
        c.selectedScene = 'seaside_corner';
        c.receipt = CompletionReceipt(
          'final-patch',
          'main-060',
          true,
          'seaside_corner:5',
        );
        await t.pumpWidget(_screen(RewardPage(controller: c)));
        await t.pumpAndSettle();
        expect(find.bySemanticsLabel('Scene complete'), findsOneWidget);
        expect(find.text('5 / 5 patches'), findsOneWidget);
        expect(find.byKey(const Key('next')), findsNothing);
        expect(find.byKey(const Key('daily-final')), findsOneWidget);
        expect(find.byKey(const Key('replay-levels')), findsOneWidget);
        expect(find.byKey(const Key('view-collection')), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'bounded scene keeps both actions and progress in the first view',
    (t) async {
      await _withController(t, (c) async {
        c.progress = _progress(12);
        for (final size in [const Size(402, 720), const Size(375, 560)]) {
          await t.binding.setSurfaceSize(size);
          await t.pumpWidget(
            _screen(ScenePage(controller: c, onPlay: (_) {}), bounded: true),
          );
          await t.pumpAndSettle();
          final viewport = Offset.zero & size;
          for (final key in [
            'play-from-scene',
            'collection-back',
            'scene-progress-tray',
          ]) {
            final rect = t.getRect(find.byKey(Key(key)));
            expect(
              viewport.contains(rect.topLeft),
              isTrue,
              reason: '$key / $size top',
            );
            expect(
              viewport.contains(rect.bottomRight),
              isTrue,
              reason: '$key / $size bottom',
            );
          }
          expect(
            t.getSize(find.byType(SceneArt)).shortestSide,
            greaterThanOrEqualTo(128),
          );
          expect(find.text('8 levels to complete this scene'), findsOneWidget);
          expect(t.takeException(), isNull);
        }
      });
      await t.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'wide short scene scrolls details while both actions stay fixed',
    (t) async {
      await t.binding.setSurfaceSize(const Size(808, 368));
      try {
        await _withController(t, (c) async {
          c.progress = _progress(12);
          await t.pumpWidget(
            _screen(ScenePage(controller: c, onPlay: (_) {}), bounded: true),
          );
          await t.pumpAndSettle();
          final back = find.byKey(const Key('collection-back'));
          final primary = find.byKey(const Key('play-from-scene'));
          final backBefore = t.getRect(back),
              primaryBefore = t.getRect(primary);
          expect(find.byKey(const Key('scene-preview-scroll')), findsOneWidget);
          await t.ensureVisible(find.text('3 / 5 patches'));
          await t.pumpAndSettle();
          expect(t.getRect(back), backBefore);
          expect(t.getRect(primary), primaryBefore);
          expect(
            t.getRect(find.text('3 / 5 patches')).bottom,
            lessThan(primaryBefore.top),
          );
          expect(backBefore.bottom, lessThanOrEqualTo(368));
          expect(primaryBefore.left, greaterThanOrEqualTo(0));
          expect(t.takeException(), isNull);
          await t.tap(back);
          await t.pumpAndSettle();
          expect(c.page, GamePage.collection);
        });
      } finally {
        await t.binding.setSurfaceSize(null);
      }
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('collection and scene remain readable at 320px / $scale', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await _withController(t, (c) async {
        c.progress = _progress(12);
        await t.pumpWidget(
          _screen(CollectionPage(controller: c), scale: scale),
        );
        await t.pumpAndSettle();
        final lastCard = find.byKey(const Key('scene-seaside_corner'));
        await t.ensureVisible(lastCard);
        await t.tap(lastCard);
        await t.pumpAndSettle();
        expect(c.selectedScene, 'seaside_corner');
        expect(c.page, GamePage.scene);
        expect(t.takeException(), isNull);
        await t.pumpWidget(
          _screen(
            ScenePage(controller: c, onPlay: (_) {}),
            scale: scale,
          ),
        );
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(const Key('collection-back')));
        expect(find.text('Back to collection'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    });
  }
}

LocalProgress _progress(int complete, {bool revealed = false}) {
  final pieces = [
    for (var n = 4; n <= complete; n += 4)
      '${['color_studio', 'garden_nook', 'seaside_corner'][(n - 1) ~/ 20]}:${((n - 1) % 20) ~/ 4 + 1}',
  ];
  return LocalProgress(
    complete,
    pieces,
    List.generate(complete < 60 ? complete + 1 : 60, (i) => i + 1),
    0,
    complete,
    [],
    completedLevels: List.generate(complete, (i) => i + 1),
    revealedPieces: revealed ? pieces : [],
  );
}

Future<void> _withController(
  WidgetTester t,
  Future<void> Function(GameController) body,
) async {
  final dir = Directory.systemTemp.createTempSync('parallel-collection-');
  final store = (await t.runAsync(
    () => GameStore.open(
      '${dir.path}/collection.sqlite',
      factory: databaseFactoryFfi,
    ),
  ))!;
  final c = GameController(store);
  try {
    await t.runAsync(c.initialize);
    await body(c);
  } finally {
    await t.pumpWidget(const SizedBox());
    c.dispose();
    await t.runAsync(store.close);
    dir.deleteSync(recursive: true);
  }
}

Widget _screen(Widget child, {double scale = 1, bool bounded = false}) =>
    MaterialApp(
      theme: ThemeData(fontFamily: 'Nunito'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: bounded
            ? Padding(padding: const EdgeInsets.all(16), child: child)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
      ),
    );
