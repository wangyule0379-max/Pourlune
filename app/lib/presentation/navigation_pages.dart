import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'collection_pages.dart';
import 'labels.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onPlay,
    required this.onEngineering,
  });
  final GameController controller;
  final void Function(int) onPlay;
  final void Function(Puzzle) onEngineering;
  @override
  Widget build(BuildContext context) {
    final c = controller,
        l = AppLocalizations.of(context),
        level = c.progress.nextUnfinished ?? 1;
    final welcome =
        c.ordinary == null &&
        c.daily == null &&
        c.progress.firstClears == 0 &&
        !c.tutorialComplete;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (welcome) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              l.rulesTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          FilledButton(
            key: const Key('sample-main-001'),
            onPressed: c.busy ? null : () => onPlay(1),
            child: Text(l.start),
          ),
        ] else ...[
          if (c.progress.storyComplete) ...[
            Text(
              l.storyComplete,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(l.storyCompleteBody),
            FilledButton(
              key: const Key('daily-primary'),
              onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
              child: Text(l.dailyPuzzle),
            ),
            if (c.progress.dailyStamps.contains(c.today.date))
              Text(l.dailyDone),
          ] else if (c.canContinueOrdinary)
            FilledButton(
              key: const Key('resume'),
              onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
              child: Text(
                c.continueLabelIsReplay
                    ? l.continueReplay(c.ordinary!.puzzle.mainLevel!)
                    : l.continueLevel(c.ordinary!.puzzle.mainLevel!),
              ),
            )
          else
            FilledButton(
              key: Key('sample-main-${level.toString().padLeft(3, '0')}'),
              onPressed: c.busy ? null : () => onPlay(level),
              child: Text(l.playLevel(level)),
            ),
          if (c.progress.storyComplete && c.canContinueOrdinary)
            OutlinedButton(
              key: const Key('resume'),
              onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
              child: Text(l.continueReplay(c.ordinary!.puzzle.mainLevel!)),
            ),
          if (!c.progress.storyComplete &&
              !c.canContinueOrdinary &&
              !c.library.main.containsKey(level))
            Text(l.contentUnavailable),
          if (c.ordinary?.completed ?? false)
            TextButton(
              key: const Key('saved-result'),
              onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
              child: Text(l.viewResult),
            ),
          const SizedBox(height: 16),
          ScenePreview(scene: sceneForLevel(level), pieces: c.progress.pieces),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: Key(
                  c.progress.storyComplete ? 'replay-levels' : 'chapters',
                ),
                onPressed: c.busy ? null : () => c.navigate(GamePage.chapters),
                child: Text(
                  c.progress.storyComplete ? l.replayLevels : l.chapters,
                ),
              ),
              OutlinedButton(
                key: const Key('daily'),
                onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
                child: Text(l.dailyPuzzle),
              ),
              OutlinedButton(
                key: const Key('collection'),
                onPressed: c.busy
                    ? null
                    : () => c.navigate(GamePage.collection),
                child: Text(l.collection),
              ),
              OutlinedButton(
                key: const Key('settings'),
                onPressed: c.busy ? null : () => c.navigate(GamePage.settings),
                child: Text(l.settings),
              ),
            ],
          ),
        ],
        if (kDebugMode) ...[
          ExpansionTile(
            key: const Key('development-tools'),
            title: const Text('Engineering tools'),
            children: [
              const Text(
                'Debug-only fixture bypass. These samples are not a release catalog.',
              ),
              for (final p in c.library.main.values.where(
                (p) => [1, 12, 21].contains(p.mainLevel),
              ))
                TextButton(
                  key: Key('engineering-${p.id}'),
                  onPressed: c.busy ? null : () => onEngineering(p),
                  child: Text(
                    '${p.id} · ${p.initial.expand((b) => b).toSet().length} colors',
                  ),
                ),
            ],
          ),
          TextButton(
            key: const Key('progress'),
            onPressed: c.busy ? null : c.showProgress,
            child: Text(l.progress),
          ),
        ],
      ],
    );
  }
}

class ChaptersPage extends StatelessWidget {
  const ChaptersPage({
    super.key,
    required this.controller,
    required this.onPlay,
  });
  final GameController controller;
  final void Function(int) onPlay;
  @override
  Widget build(BuildContext context) {
    final c = controller, l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var chapter = 0; chapter < 3; chapter++) ...[
            Text(
              sceneTitle(
                ['color_studio', 'garden_nook', 'seaside_corner'][chapter],
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (
                  var level = chapter * 20 + 1;
                  level <= chapter * 20 + 20;
                  level++
                )
                  SizedBox(
                    width: (box.maxWidth - 8) / 2,
                    child: OutlinedButton(
                      key: Key('level-$level'),
                      onPressed:
                          c.busy ||
                              !c.progress.unlockedLevels.contains(level) ||
                              !c.library.main.containsKey(level)
                          ? null
                          : () => onPlay(level),
                      child: Column(
                        children: [
                          Text(l.level(level)),
                          Text(
                            !c.progress.unlockedLevels.contains(level)
                                ? l.locked
                                : c.progress.completedLevels.contains(level)
                                ? l.completed
                                : c.library.main.containsKey(level)
                                ? l.ready
                                : l.missing,
                          ),
                          if (c.progress.completedLevels.contains(level) &&
                              !c.library.main.containsKey(level))
                            Text(l.missing),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class DailyPage extends StatefulWidget {
  const DailyPage({super.key, required this.controller, required this.onToday});
  final GameController controller;
  final VoidCallback onToday;
  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  late DateTime month;
  late final Timer dayRefresh;
  @override
  void initState() {
    super.initState();
    final today = parseCalendarDate(widget.controller.today.date);
    month = DateTime.utc(today.year, today.month);
    dayRefresh = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDay(),
    );
  }

  void _refreshDay() {
    final c = widget.controller, previous = c.today.date;
    c.refreshToday();
    if (previous != c.today.date) setState(() {});
  }

  @override
  void dispose() {
    dayRefresh.cancel();
    super.dispose();
  }

  Future<void> _date(String date) async {
    _refreshDay();
    final c = widget.controller, l = AppLocalizations.of(context);
    if (date == c.today.date) {
      widget.onToday();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(date),
        content: Text(
          '${date.compareTo(c.today.date) > 0 ? l.futureReadOnly : l.historyReadOnly}\n${c.progress.dailyStamps.contains(date) ? l.stampOwned : l.noStamp}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller,
        l = AppLocalizations.of(context),
        days = DateTime.utc(month.year, month.month + 1, 0).day,
        leading = month.weekday - 1;
    final active = c.daily;
    final minimumCalendarWidth =
        7 *
            (MediaQuery.textScalerOf(context).scale(24) + 16).clamp(
              48.0,
              160.0,
            ) +
        12;
    final dayExtent = MediaQuery.textScalerOf(context).scale(24) + 40;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.dailyDate(c.today.date),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (c.library.daily == null) Text(l.dailyUnavailable),
        if (active != null && !active.completed)
          OutlinedButton(
            key: const Key('daily-resume'),
            onPressed: c.busy ? null : () => c.resumeSlot('daily'),
            child: Text(
              active.puzzleDate == c.today.date
                  ? l.resumeDaily(active.puzzleDate!)
                  : l.continuePrevious(active.puzzleDate!),
            ),
          ),
        if (c.progress.dailyStamps.contains(c.today.date)) Text(l.dailyDone),
        FilledButton(
          key: const Key('today'),
          onPressed: c.busy || c.library.daily == null ? null : widget.onToday,
          child: Text(
            c.progress.dailyStamps.contains(c.today.date)
                ? l.replayToday
                : active != null &&
                      !active.completed &&
                      active.puzzleDate != c.today.date
                ? l.startToday
                : l.dailyTitle,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              tooltip: l.previousMonth,
              onPressed: month.year == 1 && month.month == 1
                  ? null
                  : () => setState(
                      () => month = DateTime.utc(month.year, month.month - 1),
                    ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM('en').format(month),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: l.nextMonth,
              onPressed: month.year == 9999 && month.month == 12
                  ? null
                  : () => setState(
                      () => month = DateTime.utc(month.year, month.month + 1),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: box.maxWidth < minimumCalendarWidth
                  ? minimumCalendarWidth
                  : box.maxWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final day in l.weekdays.split(','))
                        Expanded(child: Text(day, textAlign: TextAlign.center)),
                    ],
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leading + days,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisExtent: dayExtent,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      if (index < leading) return const SizedBox();
                      final day = index - leading + 1,
                          date = calendarDate(
                            DateTime.utc(month.year, month.month, day),
                          ),
                          stamped = c.progress.dailyStamps.contains(date);
                      return Semantics(
                        label: l.dateState(
                          date,
                          stamped ? l.stampOwned : l.noStamp,
                        ),
                        button: true,
                        child: TextButton(
                          key: Key('date-$date'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(2),
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: c.busy ? null : () => _date(date),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$day'),
                              if (stamped) const Icon(Icons.check, size: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(l.historyReadOnly),
      ],
    );
  }
}

class DevelopmentProgressPage extends StatelessWidget {
  const DevelopmentProgressPage({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final p = controller.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).progress),
        Text('First clears: ${p.firstClears}'),
        Text('Unlocked levels: ${p.unlockedLevels.join(', ')}'),
        Text('Owned pieces: ${p.pieces.join(', ')}'),
        Text('Qualifying first clears: ${p.qualifyingClears}'),
        Text('Settlement receipts: ${p.receipts}'),
      ],
    );
  }
}
