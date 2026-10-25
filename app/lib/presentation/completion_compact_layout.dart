import 'package:flutter/material.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart' show ink;
import 'completion_bottles.dart';
import 'labels.dart';
import 'reference_extra_art.dart';

/// User-approved P10 exception, based on available content space and actual
/// text scale rather than device model. Normal room keeps the original layout.
bool compactCompletion(BoxConstraints box, TextScaler scaler) =>
    box.maxHeight < 700 || scaler.scale(14) > 18;

class CompactCompletionLayout extends StatelessWidget {
  const CompactCompletionLayout({
    super.key,
    required this.controller,
    required this.title,
    required this.hero,
    required this.badge,
    required this.actions,
    required this.availableHeight,
  });
  final GameController controller;
  final String title;
  final Widget hero;
  final Widget? badge;
  final List<Widget> actions;
  final double availableHeight;
  @override
  Widget build(BuildContext context) {
    final c = controller,
        l = AppLocalizations.of(context),
        s = c.current!,
        kind = c.settlementKind;
    final scene = s.slot == 'daily' ? null : sceneForLevel(s.puzzle.mainLevel!);
    final saved = c.phase == SavePhase.clean && c.receipt != null;
    final finalStory = kind == SettlementKind.finalStory;
    final media = MediaQuery.of(context);
    final dense = availableHeight < 650 && media.textScaler.scale(14) > 19;
    // SE's short screen has only a 20px top safe area. Its content can exceed
    // 600px even when the largest system text needs this denser hierarchy.
    final tight = dense && media.textScaler.scale(14) > 28;
    final style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: tight
          ? 12
          : dense
          ? 14
          : 16,
      height: 1.1,
      letterSpacing: 0,
      fontWeight: FontWeight.w900,
      color: ink,
    );
    double textWidth(String value, TextStyle textStyle) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: DefaultTextStyle.of(context).style.merge(textStyle),
        ),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final secondaryTextStyle = style.copyWith(fontSize: tight ? 12 : 14);
    Widget surface(Widget child, {bool primary = false}) => Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ReferenceExtraSurface(
            tileEdges: true,
            kind: primary
                ? ExtraSurfaceKind.primary
                : ExtraSurfaceKind.secondary,
          ),
        ),
        child,
      ],
    );
    final primaryStyle =
        FilledButton.styleFrom(
          minimumSize: Size(
            48,
            tight
                ? 48
                : dense
                ? 56
                : 64,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: tight ? 8 : 12,
          ),
          textStyle: style,
          foregroundColor: ink,
          backgroundColor: Colors.transparent,
        ).copyWith(
          backgroundBuilder: (_, _, child) => surface(child!, primary: true),
        );
    final secondaryStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(48, 56),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 4 : 12,
        vertical: dense ? 8 : 10,
      ),
      textStyle: style.copyWith(fontSize: tight ? 12 : 14),
      foregroundColor: ink,
      side: BorderSide.none,
      backgroundColor: Colors.transparent,
    ).copyWith(backgroundBuilder: (_, _, child) => surface(child!));
    final info = SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        key: const Key('completion-info'),
        tooltip: l.storyComplete,
        style: IconButton.styleFrom(padding: const EdgeInsets.all(12)).copyWith(
          backgroundBuilder: (_, _, child) => ClipOval(child: surface(child!)),
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 360,
                maxHeight: media.size.height - media.padding.vertical - 48,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ReferenceExtraSurface(tileEdges: true),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.storyComplete,
                          textAlign: TextAlign.center,
                          style: style.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              l.storyCompleteBody,
                              style: style.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: const Key('completion-info-dismiss'),
                          style: secondaryStyle,
                          onPressed: () => Navigator.pop(context),
                          child: Text(l.close),
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
                        key: const Key('completion-info-close'),
                        tooltip: l.close,
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
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
          ),
        ),
        icon: const Icon(Icons.info_outline, color: ink),
      ),
    );
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(style: primaryStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryStyle),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: style.copyWith(fontSize: tight ? 12 : 14),
            foregroundColor: ink,
          ),
        ),
      ),
      child: Column(
        key: const Key('compact-completion-layout'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  key: const Key('page-back'),
                  tooltip: l.home,
                  onPressed: c.phase == SavePhase.saving ? null : c.goHome,
                  icon: const CompletionReferenceArt(
                    source: Rect.fromLTWH(26, 52, 72, 68),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  s.slot == 'daily'
                      ? l.dailyPuzzle
                      : l.level(s.puzzle.mainLevel!),
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              if (finalStory && tight) info,
              SizedBox(width: 48, height: 48, child: badge),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    fontSize: tight
                        ? 13
                        : dense
                        ? 16
                        : 20,
                  ),
                ),
              ),
              if (finalStory && !tight) info,
            ],
          ),
          Expanded(child: hero),
          Stack(
            key: const Key('completion-progress'),
            children: [
              const Positioned.fill(
                child: ReferenceExtraSurface(tileEdges: true),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tight ? 4 : 14,
                  vertical: tight ? 8 : 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (scene != null && kind != SettlementKind.replay) ...[
                      Text(
                        sceneTitle(scene),
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                          fontSize: tight
                              ? 14
                              : dense
                              ? 16
                              : 17,
                        ),
                      ),
                      Text(
                        l.completionLevels(
                          c.progress.completedLevels
                              .where((n) => sceneForLevel(n) == scene)
                              .length,
                          20,
                        ),
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                          fontSize: tight
                              ? 12
                              : dense
                              ? 14
                              : 16,
                        ),
                      ),
                    ],
                    if (saved && c.receipt?.piece != null) ...[
                      const Divider(height: 9),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!(dense &&
                              (finalStory ||
                                  kind == SettlementKind.chapter))) ...[
                            SizedBox(
                              width: dense ? 24 : 34,
                              height: dense ? 24 : 28,
                              child: const CompletionReferenceArt(
                                source: Rect.fromLTWH(92, 838, 80, 65),
                              ),
                            ),
                            SizedBox(width: dense ? 4 : 6),
                          ],
                          Flexible(
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final patchStyle = style.copyWith(
                                  fontSize: dense ? 12 : 14,
                                );
                                final label =
                                    tight &&
                                        textWidth(l.newPatch, patchStyle) >
                                            box.maxWidth
                                    ? l.newPatchCompact
                                    : l.newPatch;
                                return Semantics(
                                  label: l.newPatch,
                                  excludeSemantics: true,
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: patchStyle,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (kind == SettlementKind.chapter || finalStory)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (dense &&
                              (finalStory || kind == SettlementKind.chapter) &&
                              saved &&
                              c.receipt?.piece != null) ...[
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CompletionReferenceArt(
                                source: Rect.fromLTWH(92, 838, 80, 65),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              l.chapterComplete,
                              textAlign: TextAlign.center,
                              style: style.copyWith(fontSize: dense ? 12 : 14),
                            ),
                          ),
                        ],
                      ),
                    if (!saved ||
                        kind == SettlementKind.daily ||
                        kind == SettlementKind.replay)
                      Text(
                        !saved
                            ? l.pendingCompletion
                            : kind == SettlementKind.replay
                            ? l.replayComplete
                            : s.isReplay
                            ? l.dailyReplayComplete
                            : l.stampSaved(s.puzzleDate!),
                        textAlign: TextAlign.center,
                        style: style.copyWith(fontSize: 14),
                      ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        width: double.infinity,
                        child: actions.first,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (actions.length > 3)
            LayoutBuilder(
              builder: (context, box) {
                // Keep whole action words readable. A single full-width line can
                // take less height than splitting one long word into three lines.
                final halfWidth = (box.maxWidth - 6) / 2 - (dense ? 8 : 24);
                final stack = [l.viewCollection, l.replayLevels]
                    .expand((label) => label.split(' '))
                    .any(
                      (word) => textWidth(word, secondaryTextStyle) > halfWidth,
                    );
                return stack
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          actions[1],
                          const SizedBox(height: 6),
                          actions[2],
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: actions[1]),
                          const SizedBox(width: 6),
                          Expanded(child: actions[2]),
                        ],
                      );
              },
            )
          else if (actions.length > 2)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(width: double.infinity, child: actions[1]),
              ),
            ),
          actions.last,
        ],
      ),
    );
  }
}
