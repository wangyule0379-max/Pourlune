// Unapproved motion/readout adaptation; no normal entry imports this file.
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/labels.dart' show colorLabel;
import 'package:pourlune_dev/presentation/bottle.dart' show ink;
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/reference_extra_art.dart';
import 'package:pourlune_dev/presentation/bottle_foot_label.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  if (!kDebugMode ||
      database != 'p05_readout_dock_r3_review.sqlite' ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled') {
    throw StateError('Dedicated dock-candidate QA only');
  }
  final path = '${await getDatabasesPath()}/$database';
  await deleteDatabase(path);
  final store = await GameStore.open(path);
  final puzzle = Puzzle.parse(
    await rootBundle.loadString('assets/puzzles/main/main-012.json'),
  );
  var state = GameInstance.create(id: 'dock-unapproved-main12', puzzle: puzzle);
  for (final move in puzzle.referenceMoves.take(11)) {
    state = state.pour(move.from, move.to).state;
  }
  // Explicit isolated entitlement seed, never an SDK/reward confirmation.
  state = state.grantExtraBottle();
  await store.save(state, replace: true);
  final c = GameController(store);
  await c.initialize();
  await c.resumeSlot('ordinary');
  runApp(DockReviewApp(controller: c));
}

class DockReviewApp extends StatelessWidget {
  const DockReviewApp({super.key, required this.controller, this.textScaler});
  final GameController controller;
  final TextScaler? textScaler;
  @override
  Widget build(BuildContext context) => PourluneApp(
    controller: controller,
    textScaler: textScaler,
    debugBoardPresentation: (board) => _DockBoardSurface(board: board),
  );
}

/// QA-only alternative canvas, mounted inside the real GameScreen/BoardPage.
/// All navigation, pause, Hint, Undo, feedback and knitted actions remain real.
class _DockBoardSurface extends StatefulWidget {
  const _DockBoardSurface({required this.board});
  final BoardView board;
  @override
  State<_DockBoardSurface> createState() => _DockBoardSurfaceState();
}

class _DockBoardSurfaceState extends State<_DockBoardSurface> {
  late final game = FlameBoardGame(
    onMotionComplete: (token) {
      if (mounted) widget.board.onMotionComplete?.call(token);
    },
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = widget.board, state = w.state;
      final l = AppLocalizations.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final dockHeight = math.max(
        114.0,
        46 + scaler.scale(12) * 1.2 + scaler.scale(14) * 1.2,
      );
      final canvasHeight = math.max(160.0, box.maxHeight - dockHeight);
      final layout = BoardLayout(
        width: box.maxWidth,
        maxHeight: canvasHeight,
        count: state.board.length,
        textScale: scaler.scale(14) / 14,
      );
      final reduced = MediaQuery.disableAnimationsOf(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        game.show(
          state: state,
          layout: layout,
          settings: w.settings,
          systemReduced: reduced,
          motion: w.motion,
          selected: w.selected,
          suggested: w.suggested,
          hintSource: w.hintSource,
          addedBottle: w.addedBottle,
          rejectedBottle: w.rejectedBottle,
          rejectionRevision: w.rejectionRevision,
        );
      });
      return Column(
        children: [
          SizedBox(
            key: const Key('dock-canvas'),
            height: canvasHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([game.visual, game.artStatus]),
              child: GameWidget<FlameBoardGame>(game: game, autofocus: false),
              builder: (context, canvas) {
                final frame = game.visual.value, active = frame?.active;
                final canTap =
                    w.onTap != null &&
                    active == null &&
                    game.artStatus.value == BoardArtStatus.ready;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: IgnorePointer(child: canvas),
                      ),
                    ),
                    if (frame != null)
                      for (var i = 0; i < state.board.length; i++)
                        Positioned.fromRect(
                          rect: layout.hitRect(i),
                          child: Semantics(
                            label:
                                '${l.bottleSemantics(i + 1, i < state.puzzle.targets.length && state.puzzle.targets[i] != null ? l.targetLabel(colorLabel(l, state.puzzle.targets[i]!)) : l.bufferLabel, frame.contents[i].isEmpty ? l.emptyLabel : l.contentsLabel(frame.contents[i].map((c) => colorLabel(l, c)).join(', ')), frame.counts[i])}${w.hintSource == i ? ' ${l.suggestedSource}' : ''}${w.suggested == i ? ' ${l.suggestedTarget}' : ''}',
                            excludeSemantics: true,
                            enabled: canTap,
                            onTap: canTap ? () => w.onTap!(i) : null,
                            selected: w.selected == i,
                            button: true,
                            child: TextButton(
                              key: Key('dock-bottle-$i'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                overlayColor: Colors.transparent,
                              ),
                              onPressed: canTap ? () => w.onTap!(i) : null,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                    if (frame != null && active == null)
                      for (var i = 0; i < state.board.length; i++)
                        Positioned.fromRect(
                          rect: layout.labelRect(i),
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: BottleFootLabel(
                                index: i,
                                target: i < state.puzzle.targets.length
                                    ? state.puzzle.targets[i]
                                    : null,
                                count: frame.counts[i],
                                prefix: 'dock-original',
                                symbolsEnabled: w.settings.colorSymbols,
                                strongContrast: w.settings.strongContrast,
                              ),
                            ),
                          ),
                        ),
                    if (frame != null && active != null)
                      // The source's index follows its actual animated pose, and uses
                      // the same dark-blue outline as its individual dock card.
                      AnimatedBuilder(
                        animation: game.poseTick,
                        builder: (context, _) => Positioned(
                          left: (game.frame.poses[active.from].mouth.dx - 22)
                              .clamp(0.0, box.maxWidth - 44),
                          top: (game.frame.poses[active.from].mouth.dy - 48)
                              .clamp(0.0, canvasHeight - 44),
                          child: ExcludeSemantics(
                            child: DecoratedBox(
                              key: const Key('dock-moving-index'),
                              decoration: BoxDecoration(
                                color: const Color(0xfffff9ed),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ink, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                child: Text(
                                  '${active.from + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    height: 1.2,
                                    fontWeight: FontWeight.w900,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            height: dockHeight,
            child: ValueListenableBuilder(
              valueListenable: game.visual,
              builder: (context, frame, _) {
                if (frame?.active == null) return const SizedBox.expand();
                final active = frame!.active!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < state.board.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: ExcludeSemantics(
                          key: Key('dock-readout-$i'),
                          child: Stack(
                            fit: StackFit.passthrough,
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
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: i == active.from || i == active.to
                                        ? ink
                                        : const Color(0xffcabda8),
                                    width: i == active.from || i == active.to
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 34,
                                        child:
                                            i < state.puzzle.targets.length &&
                                                state.puzzle.targets[i] != null
                                            ? TargetCushion(
                                                size: 28,
                                                target:
                                                    state.puzzle.targets[i]!,
                                                symbolsEnabled:
                                                    w.settings.colorSymbols,
                                                strongContrast:
                                                    w.settings.strongContrast,
                                              )
                                            : const SizedBox(),
                                      ),
                                      Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          height: 1.2,
                                          fontWeight: FontWeight.w900,
                                          color: ink,
                                        ),
                                      ),
                                      Text(
                                        '${frame.counts[i]}/4',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          height: 1.2,
                                          fontWeight: FontWeight.w900,
                                          color: ink,
                                        ),
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
                  ],
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
