import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/bottle.dart';

void main() {
  testWidgets(
    'B03 bottle runtime layers are separate from current contents and fixed target',
    (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottleButton(
                index: 0,
                liquid: const ['G'],
                target: 'O',
                selected: false,
                width: 84,
                onTap: () {},
                visualLiquid: const [(color: 'G', units: .5)],
                angle: .25,
                lift: 4,
              ),
            ),
          ),
        ),
      );
      for (final layer in ['back', 'front', 'shadow']) {
        expect(find.byKey(Key('bottle-0-$layer')), findsOneWidget);
      }
      final painter =
          t
                  .widget<CustomPaint>(
                    find
                        .descendant(
                          of: find.byType(BottleButton),
                          matching: find.byType(CustomPaint),
                        )
                        .first,
                  )
                  .painter!
              as BottlePainter;
      expect(painter.liquid, ['G']);
      expect(painter.target, 'O');
      expect(painter.visualLiquid!.single.units, .5);
      expect(
        find.bySemanticsLabel(
          RegExp('Bottle 1. Target Orange circle.*Green triangle'),
        ),
        findsOneWidget,
      );
      expect(t.getSize(find.byType(BottleButton)), const Size(84, 184));
      handle.dispose();
    },
  );
}
