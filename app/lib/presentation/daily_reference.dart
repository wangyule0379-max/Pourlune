import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/game_controller.dart';

import 'package:pourlune_core/pourlune_core.dart';

import '../l10n/app_localizations.dart';
import 'knit_components.dart';
import 'completion_feedback.dart';
import 'parallel_navigation/navigation_materials.dart';
import 'reference_extra_art.dart';
import 'reference_play_art.dart';

/// The design's current-week strip. History remains a separate read-only view.
class DailyWeekStrip extends StatelessWidget {
  const DailyWeekStrip({
    super.key,
    required this.date,
    required this.stamps,
    this.onDate,
  });
  final String date;
  final Iterable<String> stamps;
  final ValueChanged<String>? onDate;

  @override
  Widget build(BuildContext context) {
    final current = parseCalendarDate(date);
    final monday = current.subtract(Duration(days: current.weekday - 1));
    final l = AppLocalizations.of(context);
    return Column(
      key: const Key('daily-week-strip'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Builder(
                    builder: (context) {
                      final day = monday.add(Duration(days: index));
                      final value = calendarDate(day),
                          stamped = stamps.contains(calendarDate(day));
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Semantics(
                            label: l.dateState(
                              value,
                              stamped ? l.stampOwned : l.noStamp,
                            ),
                            child: SizedBox(
                              height: 56,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: ReferenceExtraSurface(
                                      kind: ExtraSurfaceKind.secondary,
                                      cornerRadius: 12,
                                      tileEdges: true,
                                    ),
                                  ),
                                  if (value == date)
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xff8dc72a),
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned.fill(
                                    child: TextButton(
                                      key: Key(
                                        onDate == null
                                            ? 'week-$value'
                                            : 'date-$value',
                                      ),
                                      onPressed: onDate == null
                                          ? null
                                          : () => onDate!(value),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(48, 48),
                                        disabledForegroundColor: const Color(
                                          0xff00217c,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${day.day}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          if (stamped)
                                            Icon(
                                              Icons.check_circle,
                                              size: 20,
                                              color: value == date
                                                  ? const Color(0xff5ea900)
                                                  : const Color(0xff1678dc),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          DateFormat.yMMMM('en').format(current),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

/// Normal-size daily settlement has its own stamp layout, not story progress.
class DailyReferenceCompletion extends StatelessWidget {
  const DailyReferenceCompletion({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller, l = AppLocalizations.of(context), s = c.current!;
    final date = s.puzzleDate!;
    final saved = c.phase == SavePhase.clean && c.receipt != null;
    return NavigationMaterials(
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxHeight < 600;
          final size = ((box.maxHeight - 520).clamp(64.0, 210.0)).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KnitHeader(
                title: l.dailyPuzzle,
                backLabel: l.home,
                backKey: const Key('page-back'),
                onBack: c.phase == SavePhase.saving ? null : c.goHome,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 2 : 10),
                      SizedBox(
                        width: size,
                        height: size,
                        child: saved
                            ? CompletionFeedback(
                                key: Key('completion-feedback-${s.id}'),
                                child: _DailyStampArt(
                                  day: parseCalendarDate(date).day,
                                ),
                              )
                            : CalendarArt(
                                day: parseCalendarDate(date).day,
                                size: size,
                              ),
                      ),
                      SizedBox(height: compact ? 4 : 12),
                      Text(
                        l.dailyDone,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat(
                          'EEE, MMM d, yyyy',
                          'en',
                        ).format(parseCalendarDate(date)),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 20),
                      DailyWeekStrip(
                        date: date,
                        stamps: c.progress.dailyStamps,
                      ),
                      SizedBox(height: compact ? 6 : 14),
                      SizedBox(
                        width: double.infinity,
                        child: NavigationPanel(
                          child: Center(
                            child: Text(
                              !saved
                                  ? l.pendingCompletion
                                  : s.isReplay
                                  ? l.dailyReplayComplete
                                  : l.stampSaved(date),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              FilledButton(
                key: const Key('daily-calendar'),
                onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
                child: const NavigationActionLabel('Back to daily'),
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    key: const Key('home'),
                    onPressed: c.busy ? null : c.goHome,
                    child: Text(l.home),
                  ),
                ),
              ),
              if (date == c.today.date && c.library.daily != null)
                TextButton(
                  key: const Key('daily-replay'),
                  onPressed: c.busy ? null : c.startToday,
                  child: Text(l.replayToday),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DailyStampArt extends StatelessWidget {
  const _DailyStampArt({required this.day});
  final int day;
  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: const _DailyStampClipper(),
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          const Positioned.fill(
            child: ReferencePlayArt(
              asset: 'assets/art/p05-reference/reference-scene.png',
              imageSize: Size(1477, 1065),
              source: Rect.fromLTWH(1096, 144, 272, 258),
            ),
          ),
          Positioned(
            left: box.maxWidth * 87 / 272,
            top: box.maxHeight * 105 / 258,
            width: box.maxWidth * 103 / 272,
            height: box.maxHeight * 76 / 258,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ReferencePlayArt(
                    asset: 'assets/art/p05-reference/reference-scene.png',
                    imageSize: Size(1477, 1065),
                    source: Rect.fromLTWH(1154, 250, 29, 72),
                  ),
                ),
                Center(
                  child: Text(
                    '$day',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: box.maxWidth * .26,
                      height: 1,
                      color: const Color(0xff003daa),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DailyStampClipper extends CustomClipper<Path> {
  const _DailyStampClipper();
  @override
  Path getClip(Size size) =>
      (Path()
            ..addOval(const Rect.fromLTWH(0, 0, 265, 258))
            ..addOval(const Rect.fromLTWH(166, 160, 103, 94)))
          .transform(
            Matrix4.diagonal3Values(
              size.width / 272,
              size.height / 258,
              1,
            ).storage,
          );
  @override
  bool shouldReclip(_DailyStampClipper oldClipper) => false;
}
