import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:sqflite/sqflite.dart';

import 'application/game_controller.dart';
import 'data/game_store.dart';
import 'l10n/app_localizations.dart';
import 'presentation/bottle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  GameController? controller;
  List<Puzzle>? puzzles;
  String? error;
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => error = null);
    GameStore? store;
    try {
      final loaded = <Puzzle>[];
      for (final id in ['001', '012', '021']) {
        loaded.add(
          Puzzle.parse(
            await rootBundle.loadString(
              'assets/fixtures/main-$id.reference.json',
            ),
          ),
        );
      }
      store = await GameStore.open(
        '${await getDatabasesPath()}/${const String.fromEnvironment('POURLUNE_DATABASE', defaultValue: 'pourlune_dev.sqlite')}',
      );
      final c = GameController(store);
      await c.initialize();
      if (!mounted) {
        c.dispose();
        await store.close();
        return;
      }
      setState(() {
        controller = c;
        puzzles = loaded;
      });
    } catch (e) {
      await store?.close();
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    controller?.store.close();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => controller == null
      ? MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: error == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Couldn’t open local data. Your files were kept.',
                            ),
                            Text(error!),
                            FilledButton(
                              onPressed: _open,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        )
      : PourluneApp(controller: controller!, puzzles: puzzles!);
}

class PourluneApp extends StatelessWidget {
  const PourluneApp({
    super.key,
    required this.controller,
    required this.puzzles,
    this.textScaler,
  });
  final GameController controller;
  final List<Puzzle> puzzles;
  final TextScaler? textScaler;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pourlune Dev',
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        surface: cream,
      ),
      scaffoldBackgroundColor: cream,
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    builder: (context, child) => textScaler == null
        ? child!
        : MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: GameScreen(controller: controller, puzzles: puzzles),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.puzzles,
  });
  final GameController controller;
  final List<Puzzle> puzzles;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? selected;
  GameController get c => widget.controller;
  AppLocalizations get l => AppLocalizations.of(context);
  Future<bool> _confirm(String title, String action, Key key) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: const Text(
            'Your current sample will restart or be replaced. Local completed progress stays on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              key: key,
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _choose(Puzzle p) async {
    if (c.current != null &&
        !c.current!.completed &&
        !await _confirm(
          'Replace the saved sample?',
          'Replace',
          const Key('confirm-replace'),
        )) {
      return;
    }
    if (!mounted) return;
    selected = null;
    final progress = await c.store.progress();
    await c.start(
      p,
      replace: c.current != null,
      replay:
          progress.unlockedLevels.contains(p.mainLevel! + 1) ||
          (p.mainLevel == 60 && progress.firstClears == 60),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) c.goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff82dff1),
          title: Text(l.appTitle),
          actions: [
            if (c.page != GamePage.home)
              IconButton(
                key: const Key('home'),
                tooltip: l.home,
                onPressed: c.busy ? null : c.goHome,
                icon: const Icon(Icons.home_outlined),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.developmentNotice,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (c.recoveryNotice != null) Text(c.recoveryNotice!),
                if (c.phase == SavePhase.failed)
                  Card(
                    key: const Key('save-failed'),
                    color: const Color(0xffffe2c3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.saveFailed, semanticsLabel: l.saveFailed),
                          Text(c.error ?? ''),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                key: const Key('retry'),
                                onPressed: c.retry,
                                child: Text(l.retry),
                              ),
                              TextButton(
                                key: const Key('stay'),
                                onPressed: c.stayHere,
                                child: Text(l.stayHere),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  c.phase == SavePhase.saving
                      ? l.saving
                      : c.phase == SavePhase.clean
                      ? l.saved
                      : 'Memory changes are not yet saved',
                  key: const Key('save-status'),
                ),
                const SizedBox(height: 16),
                switch (c.page) {
                  GamePage.home => _home(),
                  GamePage.board => _board(),
                  GamePage.progress => ProgressPanel(store: c.store),
                },
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(l.chooseSample, style: Theme.of(context).textTheme.headlineSmall),
      for (final p in widget.puzzles)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: FilledButton(
            key: Key('sample-${p.id}'),
            onPressed: c.phase == SavePhase.clean ? () => _choose(p) : null,
            child: Text(
              '${p.initial.expand((b) => b).toSet().length} colors · ${p.id} · v${p.contentVersion}',
            ),
          ),
        ),
      if (c.current != null)
        OutlinedButton(
          key: const Key('resume'),
          onPressed: c.busy ? null : c.resume,
          child: Text(
            '${l.resume} · ${c.current!.puzzle.id} · ${c.current!.moveCount} moves',
          ),
        ),
      TextButton(
        key: const Key('progress'),
        onPressed: c.phase == SavePhase.clean ? c.showProgress : null,
        child: Text(l.progress),
      ),
      const Text(
        'Hint solving, full daily play and teaching arrive in B02. Production content/art in B03; service SDKs in B04.',
      ),
    ],
  );
  Widget _board() {
    final s = c.current!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${s.puzzle.id} · v${s.puzzle.contentVersion} · ${s.moveCount} moves',
          key: const Key('move-count'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Revision ${s.revision} · ${s.id}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(l.goal),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final width = ((box.maxWidth - 24) / 4).clamp(48.0, 84.0);
            final rows = s.board.length == 4
                ? [2, 2]
                : s.board.length == 5
                ? [3, 2]
                : s.board.length == 6
                ? [3, 3]
                : [4, 3];
            var offset = 0;
            return Column(
              children: [
                for (final n in rows)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final i in List.generate(n, (_) => offset++))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: BottleButton(
                            key: Key('bottle-$i'),
                            index: i,
                            liquid: s.board[i],
                            target: i < s.puzzle.targets.length
                                ? s.puzzle.targets[i]
                                : null,
                            selected: selected == i,
                            width: width,
                            onTap: c.busy || s.completed
                                ? null
                                : () async {
                                    if (selected == null) {
                                      if (s.board[i].isNotEmpty) {
                                        setState(() => selected = i);
                                      }
                                      return;
                                    }
                                    if (selected == i) {
                                      setState(() => selected = null);
                                      return;
                                    }
                                    final from = selected!;
                                    await c.pour(from, i);
                                    if (mounted && c.rejection == null) {
                                      setState(() => selected = null);
                                    }
                                  },
                          ),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        if (c.rejection != null)
          Semantics(liveRegion: true, child: Text(c.rejection!)),
        Text(l.drawingNotice, style: Theme.of(context).textTheme.bodySmall),
        if (s.completed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Sample complete',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    c.receipt == null
                        ? 'Completion is waiting for a successful save.'
                        : c.receipt!.firstClear
                        ? 'First clear saved on this device.'
                        : 'Replay saved. No repeated reward.',
                  ),
                  if (c.receipt?.piece != null)
                    Text('Piece: ${c.receipt!.piece}'),
                ],
              ),
            ),
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('undo'),
                onPressed: c.busy || s.history.isEmpty
                    ? null
                    : () {
                        selected = null;
                        c.undo();
                      },
                child: Text(l.undo),
              ),
              OutlinedButton(
                key: const Key('restart'),
                onPressed: c.busy
                    ? null
                    : () async {
                        if (await _confirm(
                          'Restart this sample?',
                          'Restart',
                          const Key('confirm-restart'),
                        )) {
                          selected = null;
                          await c.restart();
                        }
                      },
                child: Text(l.restart),
              ),
              OutlinedButton(
                key: const Key('pause'),
                onPressed: c.busy
                    ? null
                    : () async {
                        selected = null;
                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Paused'),
                            content: Text(
                              c.phase == SavePhase.failed
                                  ? 'Some changes are only in memory. Resume and Retry before leaving.'
                                  : 'Each completed action is saved locally. Resume this board or return to the sample menu.',
                            ),
                            actions: [
                              TextButton(
                                key: const Key('resume-pause'),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Resume'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  c.goHome();
                                },
                                child: Text(l.home),
                              ),
                            ],
                          ),
                        );
                      },
                child: Text(l.pause),
              ),
            ],
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          key: const Key('fail-next'),
          onPressed: c.busy || s.completed ? null : c.failNextWrite,
          child: Text(
            c.store.fault == null
                ? 'Development: fail next disk write'
                : 'Development: failure armed',
          ),
        ),
      ],
    );
  }
}

class ProgressPanel extends StatefulWidget {
  const ProgressPanel({super.key, required this.store});
  final GameStore store;
  @override
  State<ProgressPanel> createState() => _ProgressPanelState();
}

class _ProgressPanelState extends State<ProgressPanel> {
  late final Future<LocalProgress> data = widget.store.progress();
  @override
  Widget build(BuildContext context) => FutureBuilder<LocalProgress>(
    future: data,
    builder: (context, s) {
      if (s.hasError) return Text('Couldn’t read local progress: ${s.error}');
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final p = s.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local development progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('First clears: ${p.firstClears}'),
          Text('Unlocked levels: ${p.unlockedLevels.join(', ')}'),
          Text(
            'Owned pieces: ${p.pieces.isEmpty ? 'none' : p.pieces.join(', ')}',
          ),
          Text('Qualifying first clears: ${p.qualifyingClears}'),
          Text('Settlement receipts: ${p.receipts}'),
          const Text(
            'Only engineering samples are playable here. No advertising SDK is connected.',
          ),
        ],
      );
    },
  );
}
