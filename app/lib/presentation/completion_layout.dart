import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart' show ink;
import 'completion_bottles.dart';
import 'labels.dart';
import 'reference_extra_art.dart';

class CompletionReferenceLayout extends StatelessWidget {
  const CompletionReferenceLayout({
    super.key,
    required this.controller,
    required this.title,
    required this.hero,
    required this.primary,
    required this.secondary,
  });
  final GameController controller;
  final String title;
  final Widget hero, primary, secondary;
  @override
  Widget build(BuildContext context) {
    final c = controller, l = AppLocalizations.of(context), s = c.current!;
    final saved = c.phase == SavePhase.clean && c.receipt != null;
    final kind = c.settlementKind;
    final scene = s.slot == 'daily' ? null : sceneForLevel(s.puzzle.mainLevel!);
    final patch = saved && c.receipt?.piece != null;
    final status = !saved
        ? l.pendingCompletion
        : kind == SettlementKind.daily
        ? (s.isReplay ? l.dailyReplayComplete : l.stampSaved(s.puzzleDate!))
        : kind == SettlementKind.replay
        ? l.replayComplete
        : l.firstClearSaved;
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (scene != null && kind != SettlementKind.replay) ...[
          Text(
            sceneTitle(scene),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l.completionLevels(
              c.progress.completedLevels
                  .where((n) => sceneForLevel(n) == scene)
                  .length,
              20,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (!saved ||
            kind == SettlementKind.daily ||
            kind == SettlementKind.replay)
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.2),
          ),
        if (patch) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: Color(0xffc8bba4)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 38,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    -7,
                    0,
                    7,
                    0,
                    0,
                  ]),
                  child: CompletionReferenceArt(
                    source: Rect.fromLTWH(92, 838, 80, 65),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.newPatch,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (kind == SettlementKind.chapter || kind == SettlementKind.finalStory)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l.chapterComplete, textAlign: TextAlign.center),
          ),
        if (kind == SettlementKind.finalStory)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 44),
            child: SingleChildScrollView(
              child: Text(
                l.storyCompleteBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
      ],
    );
    Widget card(Widget child, {Key? key}) => Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          const Positioned.fill(child: ReferenceExtraSurface()),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
    final base = Theme.of(context);
    final primaryStyle =
        FilledButton.styleFrom(
          minimumSize: const Size(48, 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          foregroundColor: const Color(0xff123a00),
          backgroundColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
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
                  child: const ReferenceExtraSurface(
                    kind: ExtraSurfaceKind.primary,
                  ),
                ),
              ),
              ?child,
            ],
          ),
        );
    final contentTheme = base.copyWith(
      filledButtonTheme: FilledButtonThemeData(style: primaryStyle),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ink,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    final heading = ArcCompletionTitle(title);
    return Theme(
      data: contentTheme,
      child: LayoutBuilder(
        builder: (context, box) {
          final large = MediaQuery.textScalerOf(context).scale(14) > 19;
          final header = Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  key: const Key('page-back'),
                  tooltip: l.home,
                  padding: EdgeInsets.zero,
                  onPressed: c.phase == SavePhase.saving ? null : c.goHome,
                  icon: const CompletionReferenceArt(
                    source: Rect.fromLTWH(26, 52, 72, 68),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!large) ...[
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CompletionReferenceArt(
                          source: Rect.fromLTWH(181, 65, 39, 42),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        s.slot == 'daily'
                            ? l.dailyPuzzle
                            : l.level(s.puzzle.mainLevel!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          );
          final progress = card(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!large) ...[details, const SizedBox(height: 8)],
                primary,
              ],
            ),
            key: const Key('completion-progress'),
          );
          if (!box.hasBoundedHeight) {
            return Column(
              children: [
                header,
                heading,
                SizedBox(height: 380, child: hero),
                progress,
                secondary,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(
                child: large
                    ? SingleChildScrollView(
                        key: const Key('completion-details'),
                        child: Column(
                          children: [
                            heading,
                            SizedBox(height: 380, child: hero),
                            card(details),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          heading,
                          Expanded(child: hero),
                        ],
                      ),
              ),
              progress,
              const SizedBox(height: 2),
              secondary,
            ],
          );
        },
      ),
    );
  }
}

/// Live text follows the mild original arch, with normal wrapping when enlarged.
class ArcCompletionTitle extends StatelessWidget {
  const ArcCompletionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const requestedStyle = TextStyle(
        fontFamily: 'Nunito',
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        color: ink,
        shadows: [
          Shadow(
            color: Color(0x440b2175),
            offset: Offset(0, 1.5),
            blurRadius: 1,
          ),
        ],
      );
      final style = DefaultTextStyle.of(context).style.merge(requestedStyle);
      var glyphWidth = 0.0;
      for (var i = 0; i < text.length; i++) {
        final painter = TextPainter(
          text: TextSpan(text: text[i], style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        glyphWidth += painter.width;
        painter.dispose();
      }
      final fits = glyphWidth <= box.maxWidth;
      if (!fits) return Text(text, textAlign: TextAlign.center, style: style);
      return Semantics(
        label: text,
        header: true,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < text.length; i++)
                  Transform.translate(
                    offset: Offset(
                      0,
                      (-5 *
                              (1 -
                                  math.pow(
                                    2 * i / math.max(1, text.length - 1) - 1,
                                    2,
                                  )))
                          .toDouble(),
                    ),
                    child: Transform.rotate(
                      angle: (2 * i / math.max(1, text.length - 1) - 1) * .08,
                      child: Text(text[i], style: style),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
