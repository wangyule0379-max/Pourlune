import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'motion.dart';

import 'package:intl/intl.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'knit_components.dart';
import 'scene_art.dart';
import 'labels.dart';
import 'parallel_navigation/navigation_materials.dart';
import 'parallel_navigation/home_collection_art.dart';
import 'parallel_navigation/chapter_lock_art.dart';
import 'reference_extra_art.dart';

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
    final scene = sceneForLevel(level);
    return NavigationMaterials(
      child: LayoutBuilder(
        builder: (context, box) {
          final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
          final shortMenu = MediaQuery.sizeOf(context).height < 700;
          final shortWelcome = welcome && shortMenu;
          final safeHeight =
              MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical;
          final heroWidth = box.maxWidth.clamp(
            0.0,
            largeText
                ? 220.0
                : welcome
                ? (safeHeight - (shortWelcome ? 290 : 300)).clamp(
                    160.0,
                    box.maxWidth,
                  )
                : safeHeight * (shortMenu ? .40 : .43),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (welcome) ...[
                const SizedBox(height: 4),
                Semantics(
                  label: 'Pourlune',
                  header: true,
                  child: KnitArt(name: 'logo', height: shortWelcome ? 88 : 116),
                ),
                const SizedBox(height: 6),
                Text(
                  'A little color. A little calm.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Center(
                  child: SizedBox(
                    width: heroWidth,
                    // The welcome illustration is decorative, never saved progress.
                    child: const SceneArt(
                      scene: 'color_studio',
                      pieces: [
                        'color_studio:1',
                        'color_studio:2',
                        'color_studio:3',
                        'color_studio:4',
                        'color_studio:5',
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: largeText ? 0 : 24),
                  child: FilledButton(
                    key: const Key('sample-main-001'),
                    onPressed: c.busy ? null : () => onPlay(1),
                    child: NavigationActionLabel(l.start),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Play at your own pace',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Stack(
                  children: [
                    Center(
                      heightFactor: 1,
                      child: Semantics(
                        label: 'Pourlune',
                        header: true,
                        child: KnitArt(
                          name: 'logo',
                          height: largeText
                              ? 64
                              : shortMenu
                              ? 76
                              : 88,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: KnitIconButton(
                        key: const Key('settings'),
                        icon: Icons.settings_rounded,
                        label: l.settings,
                        onPressed: c.busy
                            ? null
                            : () => c.navigate(GamePage.settings),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: shortMenu ? 0 : 2),
                Center(
                  child: SizedBox(
                    width: heroWidth,
                    height: largeText ? heroWidth : heroWidth * .94,
                    // Reuse only canvas margin. OverflowBox keeps every scene
                    // pixel; no ClipRect, crop, stretch or ownership change.
                    child: OverflowBox(
                      minWidth: heroWidth,
                      maxWidth: heroWidth,
                      minHeight: heroWidth,
                      maxHeight: heroWidth,
                      child: SceneArt(scene: scene, pieces: c.progress.pieces),
                    ),
                  ),
                ),
                Text(
                  sceneTitle(scene),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: shortMenu ? 4 : 6),
                PatchProgress(scene: scene, pieces: c.progress.pieces),
                SizedBox(height: shortMenu ? 4 : 10),
                if (c.progress.storyComplete) ...[
                  Text(
                    l.storyComplete,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(l.storyCompleteBody, textAlign: TextAlign.center),
                  FilledButton(
                    key: const Key('daily-primary'),
                    onPressed: c.busy ? null : () => c.navigate(GamePage.daily),
                    child: NavigationActionLabel(l.dailyPuzzle),
                  ),
                  if (c.progress.dailyStamps.contains(c.today.date))
                    Text(l.dailyDone),
                ] else if (c.canContinueOrdinary)
                  FilledButton(
                    key: const Key('resume'),
                    onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
                    child: NavigationActionLabel(
                      c.continueLabelIsReplay
                          ? l.continueReplay(c.ordinary!.puzzle.mainLevel!)
                          : l.continueLevel(c.ordinary!.puzzle.mainLevel!),
                    ),
                  )
                else
                  FilledButton(
                    key: Key('sample-main-${level.toString().padLeft(3, '0')}'),
                    onPressed: c.busy ? null : () => onPlay(level),
                    child: NavigationActionLabel(l.playLevel(level)),
                  ),
                if (c.progress.storyComplete && c.canContinueOrdinary)
                  OutlinedButton(
                    key: const Key('resume'),
                    onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
                    child: Text(
                      l.continueReplay(c.ordinary!.puzzle.mainLevel!),
                    ),
                  ),
                if (!c.progress.storyComplete &&
                    !c.canContinueOrdinary &&
                    !c.library.main.containsKey(level))
                  Text(l.contentUnavailable),
                SizedBox(height: shortMenu ? 4 : 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in [
                      (
                        c.progress.storyComplete ? 'replay-levels' : 'chapters',
                        'chapters',
                        c.progress.storyComplete ? l.replayLevels : l.chapters,
                        GamePage.chapters,
                      ),
                      ('daily', 'calendar', l.dailyPuzzle, GamePage.daily),
                      (
                        'collection',
                        'patch-tile',
                        l.collection,
                        GamePage.collection,
                      ),
                    ])
                      SizedBox(
                        width: largeText
                            ? box.maxWidth
                            : (box.maxWidth - 16) / 3,
                        child: OutlinedButton(
                          key: Key(entry.$1),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 104),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                          onPressed: c.busy ? null : () => c.navigate(entry.$4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry.$2 == 'calendar')
                                CalendarArt(
                                  day: parseCalendarDate(c.today.date).day,
                                  size: 52,
                                )
                              else if (entry.$2 == 'patch-tile')
                                const HomeCollectionArt()
                              else
                                KnitArt(name: entry.$2, width: 50, height: 50),
                              const SizedBox(height: 4),
                              Text(
                                entry.$3,
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (c.ordinary?.completed ?? false)
                  TextButton(
                    key: const Key('saved-result'),
                    onPressed: c.busy ? null : () => c.resumeSlot('ordinary'),
                    child: Text(l.viewResult),
                  ),
              ],
              if (kDebugMode) ...[
                KeyedSubtree(
                  key: const PageStorageKey('engineering-expansion-state'),
                  child: ExpansionTile(
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
                ),
                TextButton(
                  key: const Key('progress'),
                  onPressed: c.busy ? null : c.showProgress,
                  child: Text(l.progress),
                ),
              ],
            ],
          );
        },
      ),
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
    final next = c.progress.nextUnfinished;
    final large = MediaQuery.textScalerOf(context).scale(18) > 25;
    return NavigationMaterials(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var chapter = 0; chapter < 3; chapter++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NavigationPanel(
                key: Key('chapter-${sceneIds[chapter]}'),
                kind: ExtraSurfaceKind.chapterPanel,
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, card) {
                    final scene = sceneIds[chapter];
                    final first = chapter * 20 + 1;
                    final unlocked = c.progress.unlockedLevels.any(
                      (level) => level >= first && level < first + 20,
                    );
                    final completed = c.progress.completedLevels
                        .where((level) => sceneForLevel(level) == scene)
                        .length;
                    final columns = large ? 2 : 5;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: card.maxWidth * (large ? .26 : .43),
                              child: _ChapterSceneThumbnail(
                                scene: scene,
                                pieces: c.progress.pieces,
                                preview: !unlocked,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sceneTitle(scene),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    unlocked
                                        ? l.completionLevels(completed, 20)
                                        : chapter == 0
                                        ? l.locked
                                        : l
                                              .completeSceneToUnlock(
                                                sceneTitle(
                                                  sceneIds[chapter - 1],
                                                ),
                                              )
                                              .replaceAll('\n', ' '),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!unlocked) ...[
                              const SizedBox(width: 6),
                              Semantics(
                                label: l.locked,
                                child: const ChapterLockArt(),
                              ),
                            ],
                          ],
                        ),
                        if (unlocked) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Color(0xffdcc8a9)),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (
                                var level = first;
                                level < first + 20;
                                level++
                              )
                                SizedBox(
                                  width:
                                      (card.maxWidth - (columns - 1) * 6) /
                                      columns,
                                  child: _ChapterLevel(
                                    level: level,
                                    current: level == next,
                                    completed: c.progress.completedLevels
                                        .contains(level),
                                    unlocked: c.progress.unlockedLevels
                                        .contains(level),
                                    available: c.library.main.containsKey(
                                      level,
                                    ),
                                    busy: c.busy,
                                    onPlay: () => onPlay(level),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          if (next != null && c.library.main.containsKey(next))
            Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? 0 : 16),
              child: FilledButton(
                key: const Key('chapter-play-next'),
                onPressed: c.busy ? null : () => onPlay(next),
                child: NavigationActionLabel(l.playLevel(next)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The original chapter cards use a wide room thumbnail. Crop the lower part
/// of the decorative square scene instead of stretching its saved composition.
class _ChapterSceneThumbnail extends StatelessWidget {
  const _ChapterSceneThumbnail({
    required this.scene,
    required this.pieces,
    required this.preview,
  });
  final String scene;
  final List<String> pieces;
  final bool preview;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.45,
    child: ClipRRect(
      key: Key('chapter-$scene-thumbnail-viewport'),
      borderRadius: BorderRadius.circular(14),
      child: preview
          ? Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: SceneArt(scene: scene, pieces: pieces, preview: true),
              ),
            )
          : LayoutBuilder(
              builder: (context, box) => OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: box.maxWidth,
                maxWidth: box.maxWidth,
                minHeight: box.maxWidth,
                maxHeight: box.maxWidth,
                child: SceneArt(scene: scene, pieces: pieces),
              ),
            ),
    ),
  );
}

class _ChapterLevel extends StatelessWidget {
  const _ChapterLevel({
    required this.level,
    required this.current,
    required this.completed,
    required this.unlocked,
    required this.available,
    required this.busy,
    required this.onPlay,
  });
  final int level;
  final bool current, completed, unlocked, available, busy;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final enabled = !busy && unlocked && available;
    final status = !unlocked
        ? l.locked
        : completed
        ? l.completed
        : !available
        ? l.missing
        : l.ready;
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 3, vertical: 9),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          height: 1.1,
          fontWeight: FontWeight.w900,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      backgroundBuilder: (context, states, child) => navigationButtonBackground(
        context,
        states,
        child,
        primary: current,
        cornerRadius: 14,
        kind: current ? ExtraSurfaceKind.primary : ExtraSurfaceKind.chapterCell,
      ),
    );
    final label = Stack(
      clipBehavior: Clip.none,
      children: [
        Center(child: Text('$level')),
        if (completed || !unlocked || !available)
          Positioned(
            right: -1,
            bottom: -8,
            child: ExcludeSemantics(
              child: Icon(
                completed
                    ? Icons.check_circle_rounded
                    : !unlocked
                    ? Icons.lock_outline_rounded
                    : Icons.error_outline_rounded,
                size: 16,
                color: completed
                    ? const Color(0xff249b2c)
                    : const Color(0xff6178a8),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      label: '${l.level(level)} · $status',
      child: current
          ? FilledButton(
              key: Key('level-$level'),
              style: style,
              onPressed: enabled ? onPlay : null,
              child: label,
            )
          : OutlinedButton(
              key: Key('level-$level'),
              style: style,
              onPressed: enabled ? onPlay : null,
              child: label,
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
    await showKnitDialog<void>(
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
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    final heroSize = largeText ? 140.0 : 200.0;
    return NavigationMaterials(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: heroSize,
              height: heroSize,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CalendarArt(
                      key: const Key('daily-calendar-hero'),
                      day: parseCalendarDate(c.today.date).day,
                      size: heroSize * .88,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: KnitArt(
                      name: 'moon',
                      width: heroSize * .40,
                      height: heroSize * .40,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.progress.dailyStamps.contains(c.today.date)
                ? l.dailyDone
                : l.dailyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            DateFormat(
              'EEE, MMM d, yyyy',
              'en',
            ).format(parseCalendarDate(c.today.date)),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const NavigationPanel(
            child: Text(
              'A fresh puzzle.\nAt your own pace.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
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
          FilledButton(
            key: const Key('today'),
            onPressed: c.busy || c.library.daily == null
                ? null
                : widget.onToday,
            child: NavigationActionLabel(
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
          NavigationPanel(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l.previousMonth,
                      onPressed: month.year == 1 && month.month == 1
                          ? null
                          : () => setState(
                              () => month = DateTime.utc(
                                month.year,
                                month.month - 1,
                              ),
                            ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM('en').format(month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.nextMonth,
                      onPressed: month.year == 9999 && month.month == 12
                          ? null
                          : () => setState(
                              () => month = DateTime.utc(
                                month.year,
                                month.month + 1,
                              ),
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
                                Expanded(
                                  child: Text(day, textAlign: TextAlign.center),
                                ),
                            ],
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: leading + days,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                                  stamped = c.progress.dailyStamps.contains(
                                    date,
                                  );
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
                                      if (stamped)
                                        const Icon(Icons.check, size: 12),
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(l.historyReadOnly, textAlign: TextAlign.center),
        ],
      ),
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
