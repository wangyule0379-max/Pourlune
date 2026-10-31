import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../../data/player_settings.dart';
import '../bottle.dart' show ink;
import '../bottle_foot_label.dart';
import '../reference_extra_art.dart';
import 'frame.dart';

const dockNumberStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 12,
  height: 1.2,
  fontWeight: FontWeight.w900,
  color: ink,
);
const dockCountStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 14,
  height: 1.2,
  fontWeight: FontWeight.w900,
  color: ink,
);

/// Same complete readouts in a stable region outside the painted flight.
class ReadoutDock extends StatelessWidget {
  const ReadoutDock({
    super.key,
    required this.state,
    required this.frame,
    required this.settings,
    required this.prefix,
    required this.columns,
    required this.rowHeight,
    required this.dense,
  });
  final GameInstance state;
  final BoardVisualFrame frame;
  final PlayerSettings settings;
  final String prefix;
  final int columns;
  final double rowHeight;
  final bool dense;

  static double capacityWidth(BuildContext context) {
    var width = 0.0;
    for (var count = 0; count <= 4; count++) {
      final painter = TextPainter(
        text: TextSpan(
          text: '$count/4',
          style: DefaultTextStyle.of(context).style.merge(dockCountStyle),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      width = math.max(width, painter.width);
      painter.dispose();
    }
    return width;
  }

  static double denseWidth(BuildContext context, double targetSize) {
    var numberWidth = 0.0;
    for (var number = 1; number <= 8; number++) {
      final painter = TextPainter(
        text: TextSpan(
          text: '$number',
          style: DefaultTextStyle.of(context).style.merge(dockNumberStyle),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      numberWidth = math.max(numberWidth, painter.width);
      painter.dispose();
    }
    return math.max(capacityWidth(context), numberWidth + 4 + targetSize);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = (box.maxWidth - (columns - 1) * 4) / columns;
      final targetSize = settings.colorSymbols
          ? 28.0
          : math.max(28.0, MediaQuery.textScalerOf(context).scale(12) + 6);
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < state.board.length; i++)
            ExcludeSemantics(
              key: Key('dock-readout-$i'),
              child: SizedBox(
                width: width,
                height: rowHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Positioned.fill(
                      child: ReferenceExtraSurface(
                        tileEdges: true,
                        kind: ExtraSurfaceKind.secondary,
                      ),
                    ),
                    DecoratedBox(
                      key: Key('dock-group-$i'),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              i == frame.active?.from || i == frame.active?.to
                              ? ink
                              : const Color(0xffcabda8),
                          width:
                              i == frame.active?.from || i == frame.active?.to
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (dense)
                            SizedBox(
                              height: math.max(
                                MediaQuery.textScalerOf(context).scale(12) *
                                    1.2,
                                targetSize,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${i + 1}', style: dockNumberStyle),
                                  if (i < state.puzzle.targets.length &&
                                      state.puzzle.targets[i] != null) ...[
                                    const SizedBox(width: 4),
                                    TargetCushion(
                                      key: Key('$prefix-target-$i'),
                                      size: targetSize,
                                      target: state.puzzle.targets[i]!,
                                      symbolsEnabled: settings.colorSymbols,
                                      strongContrast: settings.strongContrast,
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else ...[
                            SizedBox(
                              height: math.max(34, targetSize),
                              child:
                                  i < state.puzzle.targets.length &&
                                      state.puzzle.targets[i] != null
                                  ? TargetCushion(
                                      key: Key('$prefix-target-$i'),
                                      size: targetSize,
                                      target: state.puzzle.targets[i]!,
                                      symbolsEnabled: settings.colorSymbols,
                                      strongContrast: settings.strongContrast,
                                    )
                                  : null,
                            ),
                            Text('${i + 1}', style: dockNumberStyle),
                          ],
                          Text(
                            '${frame.counts[i]}/4',
                            key: Key('$prefix-count-$i'),
                            style: dockCountStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
