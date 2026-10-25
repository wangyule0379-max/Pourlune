import 'package:flutter/material.dart';

import '../bottle.dart';
import '../knit_components.dart';
import '../reference_extra_art.dart';

Widget navigationButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child, {
  required bool primary,
  double? cornerRadius,
  ExtraSurfaceKind? kind,
}) => knitPressFeedback(
  context,
  states,
  Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: Opacity(
          opacity: states.contains(WidgetState.disabled) ? .62 : 1,
          child: ReferenceExtraSurface(
            kind:
                kind ??
                (primary
                    ? ExtraSurfaceKind.primary
                    : ExtraSurfaceKind.secondary),
            tileEdges: true,
            cornerRadius: cornerRadius,
          ),
        ),
      ),
      ?child,
    ],
  ),
);

/// Page-local styling over the shared, blank reference surfaces. Labels,
/// disabled state, focus and hit testing remain ordinary Flutter controls.
class NavigationMaterials extends StatelessWidget {
  const NavigationMaterials({
    super.key,
    required this.child,
    this.secondarySurfaceKind = ExtraSurfaceKind.secondary,
  });
  final Widget child;
  final ExtraSurfaceKind secondarySurfaceKind;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    ButtonStyle surface(ButtonStyle style, bool primary) => style.copyWith(
      backgroundBuilder: (context, states, child) => navigationButtonBackground(
        context,
        states,
        child,
        primary: primary,
        kind: primary ? ExtraSurfaceKind.primary : secondarySurfaceKind,
      ),
    );
    return Theme(
      data: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: surface(
            FilledButton.styleFrom(
              minimumSize: const Size(48, 64),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xff123a00),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            true,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: surface(
            OutlinedButton.styleFrom(
              minimumSize: const Size(48, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: ink,
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            false,
          ),
        ),
      ),
      child: child,
    );
  }
}

class NavigationPanel extends StatelessWidget {
  const NavigationPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.kind = ExtraSurfaceKind.secondary,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ExtraSurfaceKind kind;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ReferenceExtraSurface(kind: kind, tileEdges: true),
      ),
      Padding(padding: padding, child: child),
    ],
  );
}

class NavigationActionLabel extends StatelessWidget {
  const NavigationActionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(child: Text(label, textAlign: TextAlign.center)),
      const SizedBox(width: 8),
      const ExcludeSemantics(
        child: Icon(Icons.arrow_forward_rounded, size: 26),
      ),
    ],
  );
}
