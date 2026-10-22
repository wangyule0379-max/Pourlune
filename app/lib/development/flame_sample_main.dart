import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/game_audio.dart';
import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import '../presentation/bottle.dart';
import '../presentation/knit_components.dart';
import 'flame_sample/games.dart';
import 'flame_sample/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode ||
      const String.fromEnvironment('POURLUNE_DATABASE') !=
          'flame_sample.sqlite') {
    throw StateError('Debug sample only');
  }
  runApp(const _SampleBootstrap());
}

class _SampleBootstrap extends StatefulWidget {
  const _SampleBootstrap();
  @override
  State<_SampleBootstrap> createState() => _SampleBootstrapState();
}

class _SampleBootstrapState extends State<_SampleBootstrap> {
  FlameSampleSession? session;
  bool failed = false, opening = false;
  @override
  void initState() {
    super.initState();
    unawaited(open());
  }

  Future<void> open() async {
    if (opening) return;
    opening = true;
    setState(() => failed = false);
    try {
      final s = await FlameSampleSession.open();
      if (!mounted) {
        await s.close();
        return;
      }
      s.bottles.resume();
      setState(() => session = s);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      opening = false;
    }
  }

  @override
  void dispose() {
    final s = session;
    if (s != null) unawaited(s.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => session == null
      ? MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xff82dff1),
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const KnitArt(name: 'logo', width: 260, height: 100),
                    if (failed) ...[
                      const Text('Could not open this sample.'),
                      FilledButton(onPressed: open, child: const Text('Retry')),
                    ],
                  ],
                ),
              ),
            ),
          ),
        )
      : FlameSampleApp(session: session!);
}

class FlameSampleApp extends StatefulWidget {
  const FlameSampleApp({super.key, required this.session});
  final FlameSampleSession session;
  @override
  State<FlameSampleApp> createState() => _FlameSampleAppState();
}

class _FlameSampleAppState extends State<FlameSampleApp>
    with WidgetsBindingObserver {
  final audio = GameAudio();
  bool patch = false, foreground = true, _closing = false;
  FlameSampleSession get s => widget.session;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    s.bottles.addListener(_audio);
    _audio();
  }

  void _audio() => unawaited(
    audio.update(
      settings: s.bottles.settings,
      foreground: foreground,
      paused: false,
    ),
  );
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    s.bottles.setForeground(foreground);
    s.patch.setForeground(foreground);
    _audio();
  }

  Future<void> _tab(bool value) async {
    final c = patch ? s.patch : s.bottles;
    if (value == patch) return;
    final token = c.motion?.token;
    if (token != null) c.completeMotion(token);
    if (c.deferNavigationUntilSaved(() => _tab(value))) return;
    await c.goHome();
    if (!mounted) return;
    setState(() => patch = value);
    (patch ? s.patch : s.bottles).resume();
  }

  Future<void> _back() async {
    if (_closing) return;
    if (patch) {
      await _tab(false);
      return;
    }
    final token = s.bottles.motion?.token;
    if (token != null) s.bottles.completeMotion(token);
    if (s.bottles.deferNavigationUntilSaved(_back)) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      _closing = true;
      await SystemNavigator.pop();
    } else {
      s.bottles.clearSelection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    s.bottles.removeListener(_audio);
    unawaited(audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const Key('flame-sample-capture'),
    child: ListenableBuilder(
      listenable: Listenable.merge([s.bottles, s.patch]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          fontFamily: 'Nunito',
          scaffoldBackgroundColor: const Color(0xff82dff1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: ink,
            primary: ink,
            surface: cream,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style:
                FilledButton.styleFrom(
                  minimumSize: const Size(48, 52),
                  foregroundColor: ink,
                  backgroundColor: Colors.transparent,
                ).copyWith(
                  backgroundBuilder: (c, s, w) =>
                      knitButtonBackground(c, s, w, primary: true),
                ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style:
                OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: ink,
                  side: BorderSide.none,
                ).copyWith(
                  backgroundBuilder: (c, s, w) =>
                      knitButtonBackground(c, s, w, primary: false),
                ),
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.disableAnimationsOf(context) ||
                s.bottles.settings.reducedMotion,
          ),
          child: child!,
        ),
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_back());
          },
          child: Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/art/backgrounds/game.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  key: PageStorageKey(
                    'sample-scroll-${patch ? 'patch' : 'bottles'}',
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: KnitArt(name: 'logo', width: 210, height: 64),
                      ),
                      const Text(
                        'Motion study · QA sample',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('sample-bottles'),
                              onPressed: () => _tab(false),
                              child: const Text('Two bottles'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('sample-patch'),
                              onPressed: () => _tab(true),
                              child: const Text('Patch placement'),
                            ),
                          ),
                        ],
                      ),
                      SampleSaveStatus(controller: patch ? s.patch : s.bottles),
                      if (patch)
                        FlamePatchPanel(session: s, audio: audio)
                      else
                        FlameBottlePanel(session: s, audio: audio),
                      KnitPanel(
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              for (final entry in [
                                ('sound', 'Sound', s.bottles.settings.sound),
                                ('music', 'Music', s.bottles.settings.music),
                                (
                                  'haptics',
                                  'Haptics',
                                  s.bottles.settings.haptics,
                                ),
                                (
                                  'reduced_motion',
                                  'Reduced motion',
                                  s.bottles.settings.reducedMotion,
                                ),
                              ])
                                SwitchListTile(
                                  key: Key('sample-setting-${entry.$1}'),
                                  title: Text(entry.$2),
                                  value: entry.$3,
                                  onChanged: s.bottles.busy
                                      ? null
                                      : (value) async {
                                          await s.bottles.updateSetting(
                                            entry.$1,
                                            value,
                                          );
                                        },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SampleSaveStatus extends StatelessWidget {
  const SampleSaveStatus({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) => controller.phase == SavePhase.failed
      ? KnitPanel(
          key: const Key('sample-save-failed'),
          child: Column(
            children: [
              Semantics(
                liveRegion: true,
                child: Text('Could not save. This result is still in memory.'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    key: const Key('sample-retry'),
                    onPressed: controller.retry,
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    key: const Key('sample-stay'),
                    onPressed: controller.stayHere,
                    child: const Text('Stay here'),
                  ),
                ],
              ),
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            controller.phase == SavePhase.clean ? 'Saved locally' : 'Saving…',
            key: const Key('sample-save-status'),
            textAlign: TextAlign.center,
          ),
        );
}

class FlameBottlePanel extends StatefulWidget {
  const FlameBottlePanel({
    super.key,
    required this.session,
    required this.audio,
  });
  final FlameSampleSession session;
  final GameAudio audio;
  @override
  State<FlameBottlePanel> createState() => _FlameBottlePanelState();
}

class _FlameBottlePanelState extends State<FlameBottlePanel> {
  late final PourSampleGame game;
  final states = [WidgetStatesController(), WidgetStatesController()];
  GameController get c => widget.session.bottles;
  @override
  void initState() {
    super.initState();
    c.attachMotionPresenter();
    game = PourSampleGame(
      c,
      onFlowStart: () => unawaited(widget.audio.play(GameSound.pour)),
      onFlowEnd: () => unawaited(widget.audio.finishEffect()),
    );
    for (var i = 0; i < 2; i++) {
      states[i].addListener(
        () => game.press(i, states[i].value.contains(WidgetState.pressed)),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game.setSystemReduced(MediaQuery.disableAnimationsOf(context));
  }

  @override
  void dispose() {
    for (final s in states) {
      s.dispose();
    }
    c.detachMotionPresenter();
    super.dispose();
  }

  Future<void> tap(int index) async {
    if (c.busy) return;
    if (c.settings.haptics) unawaited(HapticFeedback.selectionClick());
    final before = c.selectedSource;
    await c.tapBottle(index);
    if (before == null && c.selectedSource != null) {
      unawaited(widget.audio.play(GameSound.select));
    }
    if (c.rejection != null) unawaited(widget.audio.play(GameSound.error));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([game.status, game.capacityView]),
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose a bottle, then its destination.',
          textAlign: TextAlign.center,
        ),
        const Text(
          'Engineering fixture · no level rewards',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(16) > 22 ? 420 : 365,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('sample-blank-canvas'),
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: c.busy ? null : c.clearSelection,
                    child: _GameCanvas(
                      child: GameWidget<PourSampleGame>(
                        game: game,
                        autofocus: false,
                        loadingBuilder: (_) => const Center(
                          child: KnitArt(name: 'moon', width: 64, height: 64),
                        ),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < 2; i++)
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(
                      box.maxWidth * (i == 0 ? .26 : .74) -
                          mathWidth(box.maxWidth) / 2 -
                          5,
                      133 - mathWidth(box.maxWidth) * 1.5 * .148 - 5,
                      mathWidth(box.maxWidth) + 10,
                      mathWidth(box.maxWidth) * 1.5 + 10,
                    ),
                    child: Semantics(
                      label:
                          'Bottle ${game.indices[i] + 1}. ${game.indices[i] == 0 ? 'Target Green triangle.' : 'Buffer.'} ${game.capacityView.value[game.indices[i]].length} of 4. ${game.capacityView.value[game.indices[i]].map((v) => colorNames[v]).join(', ')}',
                      button: true,
                      enabled: !c.busy && game.assetsReady,
                      onTap: c.busy || !game.assetsReady
                          ? null
                          : () => tap(game.indices[i]),
                      selected: c.selectedSource == game.indices[i],
                      child: ExcludeSemantics(
                        child: OutlinedButton(
                          key: Key('flame-bottle-$i'),
                          statesController: states[i],
                          onPressed: c.busy || !game.assetsReady
                              ? null
                              : () => tap(game.indices[i]),
                          style:
                              OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                overlayColor: Colors.transparent,
                                splashFactory: NoSplash.splashFactory,
                              ).copyWith(
                                backgroundBuilder: (_, _, child) => child!,
                              ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < 2; i++)
                  Positioned(
                    left: box.maxWidth * (i == 0 ? .26 : .74) - 66,
                    top: 326,
                    width: 132,
                    child: ExcludeSemantics(
                      child: Text(
                        '${game.indices[i] + 1} · ${game.indices[i] == 0 ? '▲ G' : '— Buffer'} · ${game.capacityView.value[game.indices[i]].length}/4',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (c.rejection != null)
          Semantics(
            liveRegion: true,
            child: Text(
              'That pour is not legal. Choose again.',
              textAlign: TextAlign.center,
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            for (var u = 1; u <= 4; u++)
              ChoiceChip(
                key: Key('sample-units-$u'),
                label: Text('$u ${u == 1 ? 'unit' : 'units'}'),
                selected: widget.session.units == u,
                onSelected: c.phase != SavePhase.clean
                    ? null
                    : (_) => widget.session.resetPour(u),
              ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('sample-direction'),
              onPressed: c.busy || c.phase != SavePhase.clean
                  ? null
                  : () {
                      setState(() => game.reverse = !game.reverse);
                      game.wake();
                    },
              child: Text(game.reverse ? 'Right → Left' : 'Left → Right'),
            ),
            FilledButton(
              key: const Key('sample-reset'),
              onPressed: c.phase != SavePhase.clean
                  ? null
                  : () => widget.session.resetPour(widget.session.units),
              child: const Text('Reset sample'),
            ),
            OutlinedButton(
              key: const Key('sample-replay'),
              onPressed: c.busy || c.phase != SavePhase.clean
                  ? null
                  : () async {
                      await widget.session.resetPour(widget.session.units);
                      if (mounted && c.phase == SavePhase.clean) {
                        await c.pour(0, 2);
                      }
                    },
              child: const Text('Replay pour'),
            ),
            TextButton(
              key: const Key('sample-invalid'),
              onPressed: c.busy
                  ? null
                  : () async {
                      await c.pour(0, 0);
                      if (c.rejection != null) {
                        unawaited(widget.audio.play(GameSound.error));
                        if (c.settings.haptics) {
                          unawaited(HapticFeedback.lightImpact());
                        }
                      }
                    },
              child: const Text('Try invalid move'),
            ),
            TextButton(
              key: const Key('sample-fail-write'),
              onPressed: c.busy ? null : c.failNextWrite,
              child: const Text('QA: fail next save'),
            ),
          ],
        ),
      ],
    ),
  );
  double mathWidth(double width) => width * .43 < 158 ? width * .43 : 158;
}

class FlamePatchPanel extends StatefulWidget {
  const FlamePatchPanel({
    super.key,
    required this.session,
    required this.audio,
  });
  final FlameSampleSession session;
  final GameAudio audio;
  @override
  State<FlamePatchPanel> createState() => _FlamePatchPanelState();
}

class _FlamePatchPanelState extends State<FlamePatchPanel> {
  late final PatchSampleGame game;
  bool placing = false;
  GameController get c => widget.session.patch;
  @override
  void initState() {
    super.initState();
    game = PatchSampleGame(
      c,
      onFlightStart: () => unawaited(widget.audio.play(GameSound.reveal)),
      onFlightEnd: () => unawaited(widget.audio.finishEffect()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game.setSystemReduced(MediaQuery.disableAnimationsOf(context));
  }

  Future<void> place() async {
    if (placing ||
        game.active ||
        c.busy ||
        c.phase != SavePhase.clean ||
        c.receipt?.piece != 'color_studio:1') {
      return;
    }
    setState(() => placing = true);
    final reservation = game.reserve();
    if (!c.progress.revealedPieces.contains('color_studio:1')) {
      await c.acknowledgeReveal(destination: GamePage.reward);
    }
    if (!mounted) return;
    final foreground = WidgetsBinding.instance.lifecycleState;
    if (c.phase == SavePhase.clean &&
        (foreground == null || foreground == AppLifecycleState.resumed)) {
      game.fly(reservation);
    } else {
      game.cancel();
    }
    setState(() => placing = false);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: game.status,
    builder: (context, status, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Color Studio · Patch 1',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          c.progress.pieces.contains('color_studio:1')
              ? 'Reward saved. Place the patch in its scene.'
              : 'QA setup: three cleared levels; one legal move remains in Level 4.',
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const Key('sample-complete'),
              onPressed:
                  !game.assetsReady ||
                      game.active ||
                      c.busy ||
                      (c.current?.completed ?? true)
                  ? null
                  : widget.session.finishReward,
              child: const Text('Complete prepared level'),
            ),
            FilledButton(
              key: const Key('sample-place'),
              onPressed:
                  placing ||
                      game.active ||
                      !game.assetsReady ||
                      c.busy ||
                      c.phase != SavePhase.clean ||
                      !c.progress.pieces.contains('color_studio:1')
                  ? null
                  : place,
              child: Text(
                c.progress.revealedPieces.contains('color_studio:1')
                    ? 'Replay visual'
                    : 'Place patch',
              ),
            ),
          ],
        ),
        SizedBox(
          height: 420,
          child: _GameCanvas(
            child: GameWidget<PatchSampleGame>(
              game: game,
              autofocus: false,
              loadingBuilder: (_) => const Center(
                child: KnitArt(name: 'moon', width: 64, height: 64),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: game.status,
          builder: (context, status, _) => Text(
            status == 'flight' || status == 'reduced'
                ? 'Placing patch…'
                : status == 'saving'
                ? 'Saving placement…'
                : c.progress.revealedPieces.contains('color_studio:1')
                ? 'Placed in Color Studio'
                : c.progress.pieces.contains('color_studio:1')
                ? 'Patch saved; ready to place'
                : 'No patch awarded yet',
            key: const Key('sample-patch-status'),
            textAlign: TextAlign.center,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('sample-reward-reset'),
              onPressed:
                  placing || game.active || c.busy || c.phase != SavePhase.clean
                  ? null
                  : widget.session.resetReward,
              child: const Text('Reset QA reward'),
            ),
            TextButton(
              key: const Key('sample-patch-fail'),
              onPressed: c.busy ? null : c.failNextWrite,
              child: const Text('QA: fail next save'),
            ),
          ],
        ),
        const Text(
          'QA reward uses real Level 4 and a saved receipt. Two-bottle pours never award patches.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class _GameCanvas extends StatelessWidget {
  const _GameCanvas({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(child: ClipRect(child: child)),
  );
}
