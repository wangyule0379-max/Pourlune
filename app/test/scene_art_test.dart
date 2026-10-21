import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/scene_art.dart';

void main() {
  testWidgets(
    'B03 every scene uses exact owned object IDs across all18 progress combinations',
    (t) async {
      for (final scene in ['color_studio', 'garden_nook', 'seaside_corner']) {
        for (var count = 0; count <= 5; count++) {
          await t.pumpWidget(
            MaterialApp(
              home: SizedBox(
                width: 320,
                child: SceneArt(
                  scene: scene,
                  pieces: [for (var i = 1; i <= count; i++) '$scene:$i'],
                ),
              ),
            ),
          );
          expect(find.byKey(Key('scene-$scene-base')), findsOneWidget);
          for (var i = 1; i <= 5; i++) {
            expect(
              find.byKey(Key('scene-$scene-piece-$i')),
              i <= count ? findsOneWidget : findsNothing,
            );
          }
        }
      }
      await t.pumpWidget(
        const MaterialApp(
          home: SceneArt(
            scene: 'color_studio',
            pieces: ['color_studio:4', 'garden_nook:1'],
          ),
        ),
      );
      expect(
        find.byKey(const Key('scene-color_studio-piece-4')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('scene-color_studio-piece-1')), findsNothing);
    },
  );
}
