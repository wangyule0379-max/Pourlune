import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/presentation/motion.dart';

void main() {
  testWidgets(
    'outgoing visual rejects touches, focus and semantics; reduction snaps mid-flight',
    (t) async {
      final oldFocus = FocusNode(), newFocus = FocusNode();
      var oldTaps = 0, newTaps = 0;
      var page = 0;
      var reduced = false;
      Widget content(int n) => Column(
        children: [
          SizedBox(height: n == 0 ? 200 : 20),
          TextButton(
            focusNode: n == 0 ? oldFocus : newFocus,
            onPressed: () {
              if (n == 0) {
                oldTaps++;
              } else {
                newTaps++;
              }
            },
            child: Text(n == 0 ? 'Old action' : 'Current action'),
          ),
        ],
      );
      Future<void> show() => t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: PageMotion(page: page, child: content(page)),
          ),
        ),
      );
      final semantics = t.ensureSemantics();
      await show();
      final oldPoint = t.getCenter(find.text('Old action'));
      page = 1;
      await show();
      await t.pump(const Duration(milliseconds: 40));
      expect(find.byKey(const Key('page-outgoing')), findsOneWidget);
      await t.tapAt(oldPoint);
      expect(oldTaps, 0);
      expect(find.bySemanticsLabel('Old action'), findsNothing);
      oldFocus.requestFocus();
      await t.pump();
      expect(oldFocus.hasFocus, isFalse);
      await t.tap(find.text('Current action'));
      expect(newTaps, 1);
      reduced = true;
      await show();
      expect(find.byKey(const Key('page-outgoing')), findsNothing);
      expect(
        t
            .widget<FadeThroughTransition>(
              find.descendant(
                of: find.byKey(const Key('page-enter')),
                matching: find.byType(FadeThroughTransition),
              ),
            )
            .animation
            .value,
        1,
      );
      await t.pumpWidget(const SizedBox());
      semantics.dispose();
      oldFocus.dispose();
      newFocus.dispose();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'backgrounding and destruction cancel a pending page transition',
    (t) async {
      Future<void> show(int page) => t.pumpWidget(
        MaterialApp(
          home: PageMotion(page: page, child: Text('$page')),
        ),
      );
      await show(0);
      await show(1);
      await t.pump(const Duration(milliseconds: 30));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(find.byKey(const Key('page-outgoing')), findsNothing);
      expect(
        t
            .widget<FadeThroughTransition>(
              find.descendant(
                of: find.byKey(const Key('page-enter')),
                matching: find.byType(FadeThroughTransition),
              ),
            )
            .animation
            .value,
        1,
      );
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await show(2);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    },
  );
}
