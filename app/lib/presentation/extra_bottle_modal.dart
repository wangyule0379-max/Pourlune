import 'package:flutter/material.dart';

import 'reference_extra_art.dart';

/// P16/P17 share one cushion and real, separately focusable controls.
class ExtraBottleModal extends StatelessWidget {
  const ExtraBottleModal({
    super.key,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.closeLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.unavailable = false,
    this.footnote = '',
    this.primaryIcon,
  });
  final String title, body, primaryLabel, secondaryLabel, closeLabel, footnote;
  final VoidCallback? onPrimary;
  final VoidCallback onSecondary;
  final bool unavailable;
  final Widget? primaryIcon;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final largeText = media.textScaler.scale(14) > 18.2;
    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: media.size.height - media.padding.vertical - 48,
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: ReferenceExtraSurface()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            width: unavailable ? 172 : 125,
                            height: largeText
                                ? 100
                                : unavailable
                                ? 120
                                : 146,
                            child: ExtraBottleHero(unavailable: unavailable),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 25,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff080a74),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 17,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff101d80),
                            ),
                          ),
                          if (footnote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              footnote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff18277b),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  _ExtraAction(
                    key: const Key('watch-ad'),
                    primary: true,
                    onPressed: onPrimary,
                    label: primaryLabel,
                    icon: primaryIcon,
                  ),
                  const SizedBox(height: 10),
                  _ExtraAction(
                    key: const Key('extra-secondary'),
                    primary: false,
                    onPressed: onSecondary,
                    label: secondaryLabel,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  key: const Key('extra-close'),
                  tooltip: closeLabel,
                  padding: EdgeInsets.zero,
                  onPressed: onSecondary,
                  icon: const ReferenceExtraArt(
                    source: Rect.fromLTWH(383, 308, 72, 72),
                    radius: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraAction extends StatelessWidget {
  const _ExtraAction({
    super.key,
    required this.primary,
    required this.onPressed,
    required this.label,
    this.icon,
  });
  final bool primary;
  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style:
        OutlinedButton.styleFrom(
          minimumSize: Size(48, primary ? 72 : 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          side: BorderSide.none,
          foregroundColor: primary
              ? const Color(0xff133000)
              : const Color(0xff080a74),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 19,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ).copyWith(
          backgroundBuilder: (_, states, child) => Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: states.contains(WidgetState.disabled) ? .5 : 1,
                  child: ReferenceExtraSurface(
                    kind: primary
                        ? ExtraSurfaceKind.primary
                        : ExtraSurfaceKind.secondary,
                  ),
                ),
              ),
              ?child,
            ],
          ),
        ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          SizedBox(width: 28, height: 25, child: icon),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
