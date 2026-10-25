import 'package:flutter/material.dart';

import 'settings_reference_art.dart';

/// The transparent native Switch still owns focus, keyboard input, semantics
/// and hit testing. The knit layers are decorative and never intercept input.
class KnittedSwitch extends StatelessWidget {
  const KnittedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.reducedMotion = false,
  });
  final bool value, reducedMotion;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    height: 48,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: IgnorePointer(
            child: Opacity(
              opacity: onChanged == null ? .55 : 1,
              child: SizedBox(
                width: 68,
                height: 36,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Row(
                          children: [
                            for (var half = 0; half < 2; half++)
                              Expanded(
                                child: Transform.flip(
                                  flipX: value ? half == 1 : half == 0,
                                  child: SettingsReferenceArt(
                                    source: value
                                        ? const Rect.fromLTWH(340, 187, 49, 53)
                                        : const Rect.fromLTWH(388, 431, 50, 53),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 2,
                      ),
                      child: AnimatedAlign(
                        duration:
                            reducedMotion ||
                                MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        alignment: value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: const SizedBox(
                          width: 31,
                          height: 31,
                          child: ClipOval(
                            child: SettingsReferenceArt(
                              source: Rect.fromLTWH(389, 191, 44, 44),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Semantics(
            label: semanticLabel,
            child: Opacity(
              opacity: 0,
              alwaysIncludeSemantics: true,
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
