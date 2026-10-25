import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart' show ink;
import 'knit_components.dart';
import 'labels.dart';
import 'reference_play_art.dart';
import 'reference_extra_art.dart';

/// Derived feedback only. It neither expires a status nor executes a move.
class BoardFeedback extends StatelessWidget {
  const BoardFeedback({
    super.key,
    required this.controller,
    required this.noMoves,
    required this.unmatched,
    this.extraDetails = const [],
    this.auxiliaryOnly = false,
  });

  final GameController controller;
  final bool noMoves, unmatched;
  final bool auxiliaryOnly;
  final List<Widget> extraDetails;

  static const _titleStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w900,
    color: ink,
  );
  static final _hintTitleStyle = _titleStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller, s = c.current!, l = AppLocalizations.of(context);
    final lesson = s.tutorial;
    final hint = c.hint;
    final move = hint?.move;
    final teaching = lesson?.active ?? false;
    final hintActive = c.hintSearching || hint != null;
    String title = l.rulesTitle, body = l.goal;
    String? spokenTitle;
    IconData? icon;
    if (c.hintSearching) {
      title = l.searchingHint;
      body = l.hintKeepPlaying;
      icon = Icons.hourglass_top_rounded;
    } else if (hint != null) {
      title = hintLabel(l, hint);
      icon = Icons.lightbulb_outline_rounded;
      body = switch (hint.status) {
        HintStatus.found => l.hintReason(
          move!.to + 1,
          colorLabel(l, s.board[move.from].last),
        ),
        HintStatus.provenUnsolvable => l.hintUnsolvableBody,
        HintStatus.noMoves => l.noMovesBody,
        HintStatus.alreadyComplete => '',
        _ => l.hintKeepPlaying,
      };
      if (move != null) {
        spokenTitle = l.hintDirectionSemantics(move.from + 1, move.to + 1);
      }
    } else if (teaching) {
      body = l.lessonAction(
        lesson!.step + 1,
        s.tutorialLength,
        s.puzzle.referenceMoves[lesson.step].from + 1,
        s.puzzle.referenceMoves[lesson.step].to + 1,
      );
      title = body;
    } else if (noMoves) {
      title = l.noMoves;
      body = l.noMovesBody;
      icon = Icons.info_outline_rounded;
    } else if (c.rejection != null) {
      title = c.rejection == 'Empty or matching top color only'
          ? l.cantPourHere
          : c.rejection == 'Choose a bottle with liquid'
          ? l.emptyLabel
          : rejectionLabel(l, c.rejection!);
      body = c.rejection == 'Empty or matching top color only'
          ? l.matchingTopBody
          : c.rejection == 'Choose a bottle with liquid'
          ? l.chooseLiquid
          : '';
      icon = Icons.info_outline_rounded;
    } else if (unmatched) {
      title = l.matchLabelsTitle;
      body = l.matchLabels;
    }

    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final active = hintActive || noMoves || c.rejection != null || teaching;
        final badgeActive =
            hintActive || (!teaching && (noMoves || c.rejection != null));
        final titles = [
          if (teaching) title,
          l.rulesTitle,
          l.matchLabelsTitle,
          l.cantPourHere,
          l.chooseAnother,
          l.emptyLabel,
          l.bottleFull,
          l.puzzleComplete,
          l.noMoves,
        ];
        final hintTitles = [
          l.searchingHint,
          l.hintTimeout,
          l.hintUnsolvable,
          l.noMoves,
          l.puzzleComplete,
          l.hintFound(7, 7),
        ];
        // At large text sizes use available width before growing taller.
        // The normal-type reference badge retains its compact 280px limit.
        final hintWidth = math.min(
          box.maxWidth,
          280.0 * math.max(1.0, scaler.scale(18) / 18),
        );
        final badgeTitleStyle = DefaultTextStyle.of(context).style
            .merge(_hintTitleStyle);
        final shortTitle = TextPainter(
          text: TextSpan(text: title, style: badgeTitleStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout(maxWidth: math.max(1, box.maxWidth - 90));
        final feedbackWidth = hintActive || auxiliaryOnly
            ? hintWidth
            : math.min(box.maxWidth, math.max(160.0, shortTitle.width + 90));
        shortTitle.dispose();
        double measured(String value, TextStyle style, double width) {
          final p = TextPainter(
            text: TextSpan(text: value, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: math.max(1, width));
          final h = p.height;
          p.dispose();
          return h;
        }

        final height = math.max(
          48.0,
          math.max(
                auxiliaryOnly && !teaching
                    ? 0.0
                    : titles
                          .map(
                            (t) => measured(t, _titleStyle, box.maxWidth - 80),
                          )
                          .reduce(math.max),
                // Reserve the same height before, during and after Hint. The
                // narrow badge includes padding, bulb/gap and 48px Cancel.
                hintTitles
                    .map(
                      (t) => measured(
                        t,
                        _hintTitleStyle,
                        hintWidth - (auxiliaryOnly ? 78 : 116),
                      ),
                    )
                    .reduce(math.max),
              ) +
              (auxiliaryOnly ? 0 : 12),
        );
        void showDetails() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: SingleChildScrollView(
              key: PageStorageKey('board-explanations-${s.id}'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: _titleStyle),
                    const SizedBox(height: 12),
                    Text(body, textAlign: TextAlign.center),
                    ...extraDetails,
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final titleWidget = GestureDetector(
          onLongPress: showDetails,
          child: Semantics(
            liveRegion: active,
            label: spokenTitle,
            excludeSemantics: spokenTitle != null,
            hint: body,
            child: Text(
              title,
              key: const Key('feedback-title'),
              textAlign: TextAlign.center,
              style: badgeActive || teaching ? badgeTitleStyle : _titleStyle,
            ),
          ),
        );
        final content = Row(
          children: [
            if (active && icon != null && !auxiliaryOnly) ...[
              if (hintActive && !c.hintSearching)
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: ReferencePlayIcon(index: 1),
                )
              else
                Icon(icon, color: ink, size: 24),
              const SizedBox(width: 6),
            ],
            Expanded(child: titleWidget),
            if (badgeActive && !hintActive && !teaching)
              const SizedBox(width: 30),
            if (hintActive || teaching)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  key: Key(hintActive ? 'cancel-hint' : 'skip-tutorial'),
                  tooltip: hintActive ? l.cancelHint : l.skip,
                  onPressed: hintActive
                      ? c.cancelHint
                      : c.busy
                      ? null
                      : c.skipTutorial,
                  icon: hintActive
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: ReferenceExtraArt(
                            source: Rect.fromLTWH(383, 308, 72, 72),
                            radius: 8,
                          ),
                        )
                      : const Icon(Icons.skip_next_rounded),
                ),
              ),
          ],
        );
        if (auxiliaryOnly && !active) {
          return SizedBox(key: const Key('board-feedback'), height: height);
        }
        if (!auxiliaryOnly && c.extraBottlePresentation != null && !active) {
          return Column(
            key: const Key('board-feedback'),
            children: [
              Center(
                child: Container(
                  key: const Key('extra-added-feedback'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80fff77b),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),

                  margin: const EdgeInsets.symmetric(vertical: 4),
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxWidth: 320,
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ReferenceExtraSurface(
                          kind: ExtraSurfaceKind.secondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xffa5e535),
                                    Color(0xff409000),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x55a4c92a),
                                    blurRadius: 7,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  l.extraBottleAdded,
                                  textAlign: TextAlign.center,
                                  style: _titleStyle.copyWith(fontSize: 17),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 6),
                child: titleWidget,
              ),
            ],
          );
        }
        return SizedBox(
          key: const Key('board-feedback'),
          height: height,
          child: badgeActive
              ? Center(
                  child: SizedBox(
                    key: const Key('feedback-badge'),
                    width: feedbackWidth,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Positioned.fill(
                          child: ReferenceExtraSurface(
                            kind: ExtraSurfaceKind.settings,
                            cornerRadius: 24,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
                          child: content,
                        ),
                      ],
                    ),
                  ),
                )
              : active
              ? KnitPanel(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: content,
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: titleWidget,
                  ),
                ),
        );
      },
    );
  }
}
