// Isolated, unapproved large-text presentation. Never imported by normal main.
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:pourlune_dev/l10n/app_localizations.dart';
import 'package:pourlune_dev/presentation/board_page.dart';
import 'package:pourlune_dev/presentation/bottle.dart' show ink;
import 'package:pourlune_dev/presentation/bottle_foot_label.dart';
import 'package:pourlune_dev/presentation/flame_board/game.dart';
import 'package:pourlune_dev/presentation/flame_board/geometry.dart';
import 'package:pourlune_dev/presentation/labels.dart';
import 'package:pourlune_dev/presentation/pourlune_app.dart';
import 'package:pourlune_dev/presentation/reference_extra_art.dart';
import 'package:sqflite/sqflite.dart';

String? _runtimeEvidenceDirectory, _reportedMedia;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const database = String.fromEnvironment('POURLUNE_DATABASE');
  const armSaveFailure = bool.fromEnvironment('POURLUNE_QA_ARM_SAVE_FAILURE');
  if (!kDebugMode ||
      database !=
          (armSaveFailure
              ? 'p09_failure_review.sqlite'
              : 'p05_max_text_c17_review.sqlite') ||
      const String.fromEnvironment('POURLUNE_AD_MODE') != 'disabled') {
    throw StateError('Dedicated maximum-text candidate QA only');
  }
  _runtimeEvidenceDirectory = await getDatabasesPath();
  final path = '$_runtimeEvidenceDirectory/$database';
  final existed = File(path).existsSync();
  final store = await GameStore.open(path);
  if (!existed) {
    final puzzle = Puzzle.parse(
      await rootBundle.loadString('assets/puzzles/main/main-012.json'),
    );
    var state = GameInstance.create(
      id: 'max-unapproved-main12',
      puzzle: puzzle,
    );
    for (final move in puzzle.referenceMoves.take(11)) {
      state = state.pour(move.from, move.to).state;
    }
    // Explicit QA entitlement and legal setup move, never an SDK reward.
    state = state.grantExtraBottle().pour(0, 5).state;
    await store.save(state, replace: true);
  }
  final c = GameController(store);
  await c.initialize();
  await c.resumeSlot('ordinary');
  if (armSaveFailure) c.failNextWrite();
  runApp(MaxTextReviewApp(controller: c));
}

class MaxTextReviewApp extends StatelessWidget {
  const MaxTextReviewApp({
    super.key,
    required this.controller,
    this.textScaler,
  });
  final GameController controller;
  final TextScaler? textScaler;
  @override
  Widget build(BuildContext context) => PourluneApp(
    controller: controller,
    textScaler: textScaler,
    debugBoardPagePresentation: (page) => LayoutBuilder(
      builder: (context, box) {
        final media = MediaQuery.of(context);
        final mediaKey = '${media.size}/${media.textScaler}';
        if (_runtimeEvidenceDirectory != null && mediaKey != _reportedMedia) {
          _reportedMedia = mediaKey;
          File('$_runtimeEvidenceDirectory/qa-media-current.json')
              .writeAsStringSync(
                jsonEncode({
                  'scope': 'Dedicated QA metrics, not release/SDK proof',
                  'screen': [media.size.width, media.size.height],
                  'scaled_font_sizes': {
                    for (final n in [12, 14, 17, 18, 22, 26])
                      '$n': media.textScaler.scale(n.toDouble()),
                  },
                }),
              );
        }
        // Review condition, not a production decision or device-model switch.
        if (MediaQuery.textScalerOf(context).scale(14) <= 28 ||
            page.controller.phase == SavePhase.failed ||
            page.controller.rewardSaveFailed ||
            page.controller.rewardIssue != null ||
            page.controller.pendingRewards.isNotEmpty) {
          return page;
        }
        return _MaxPage(page: page);
      },
    ),
  );
}

class _MaxPage extends StatefulWidget {
  const _MaxPage({required this.page});
  final BoardPage page;
  @override
  State<_MaxPage> createState() => _MaxPageState();
}

class _MaxPageState extends State<_MaxPage> {
  GameController get c => widget.page.controller;
  static const labelStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    height: 1.1,
    fontWeight: FontWeight.w900,
    color: ink,
  );
  @override
  void initState() {
    super.initState();
    c.attachMotionPresenter();
  }

  @override
  void dispose() {
    c.detachMotionPresenter();
    super.dispose();
  }

  bool get noMoves {
    final board = c.current!.board;
    for (var a = 0; a < board.length; a++) {
      for (var b = 0; b < board.length; b++) {
        if (pourBoard(board, a, b).units > 0) return false;
      }
    }
    return true;
  }

  String get shortStatus {
    if (c.hintSearching) return 'Search';
    if (c.hint?.move case final move?) {
      return '${move.from + 1} → ${move.to + 1}';
    }
    if (c.hint != null) {
      return switch (c.hint!.status) {
        HintStatus.provenUnsolvable => 'Undo',
        HintStatus.noMoves => 'No moves',
        HintStatus.alreadyComplete => 'Sorted',
        _ => 'Try again',
      };
    }
    if (noMoves) return 'No moves';
    return switch (c.rejection) {
      'That bottle is full' => 'Full',
      'Choose a bottle with liquid' => 'Empty',
      'Empty or matching top color only' => 'Mismatch',
      null => 'Rules',
      _ => 'Check',
    };
  }

  Future<void> showInformation() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final l = AppLocalizations.of(context), state = c.current!;
          final hint = c.hint;
          final title = c.hintSearching
              ? l.searchingHint
              : hint != null
              ? hintLabel(l, hint)
              : noMoves
              ? l.noMoves
              : c.rejection == 'Empty or matching top color only'
              ? l.cantPourHere
              : c.rejection == 'Choose a bottle with liquid'
              ? l.emptyLabel
              : c.rejection != null
              ? rejectionLabel(l, c.rejection!)
              : l.rulesTitle;
          final reason = c.hintSearching
              ? l.hintKeepPlaying
              : hint != null
              ? switch (hint.status) {
                  HintStatus.found => l.hintReason(
                    hint.move!.to + 1,
                    colorLabel(l, state.board[hint.move!.from].last),
                  ),
                  HintStatus.provenUnsolvable => l.hintUnsolvableBody,
                  HintStatus.noMoves => l.noMovesBody,
                  HintStatus.alreadyComplete => '',
                  _ => l.hintKeepPlaying,
                }
              : noMoves
              ? l.noMovesBody
              : c.rejection == 'Empty or matching top color only'
              ? l.matchingTopBody
              : c.rejection == 'Choose a bottle with liquid'
              ? l.chooseLiquid
              : '';
          final feedback =
              c.hintSearching || hint != null || noMoves || c.rejection != null;
          return Dialog(
            key: const Key('max-information'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 360,
                maxHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    32,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ReferenceExtraSurface(kind: ExtraSurfaceKind.pause),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                feedback ? title : l.howToPlay,
                                style: feedback
                                    ? labelStyle.copyWith(fontSize: 18)
                                    : labelStyle,
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                key: const Key('max-info-close'),
                                tooltip: l.close,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: SingleChildScrollView(
                            key: const Key('max-info-scroll'),
                            child: Column(
                              children: [
                                if (!feedback)
                                  Text(
                                    title,
                                    style: labelStyle.copyWith(fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                if (reason.isNotEmpty)
                                  Text(reason, textAlign: TextAlign.center),
                                if (!feedback) ...[
                                  const SizedBox(height: 8),
                                  Text(l.goal, textAlign: TextAlign.center),
                                ],
                              ],
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
        },
      ),
    );
  }

  Widget action(String key, String text, VoidCallback? onPressed) =>
      OutlinedButton(
        key: Key(key),
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              textStyle: labelStyle,
              side: BorderSide.none,
              foregroundColor: ink,
            ).copyWith(
              backgroundBuilder: (_, _, child) => Stack(
                fit: StackFit.passthrough,
                children: [
                  const Positioned.fill(
                    child: ReferenceExtraSurface(
                      tileEdges: true,
                      kind: ExtraSurfaceKind.secondary,
                    ),
                  ),
                  ?child,
                ],
              ),
            ),
        child: Text(text, textAlign: TextAlign.center),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), s = c.current!;
    final hint = c.hint?.move;
    final hintActive = c.hintSearching || c.hint != null;
    return Column(
      key: const Key('max-page'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Semantics(
              label: l.levelMoves(s.puzzle.mainLevel!, s.moveCount),
              excludeSemantics: true,
              child: Text(
                '${s.puzzle.mainLevel!}',
                key: const Key('max-level'),
                style: labelStyle.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  shortStatus,
                  key: const Key('max-status'),
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                key: const Key('max-info'),
                tooltip: l.howToPlay,
                onPressed: showInformation,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ),
          ],
        ),
        Expanded(
          child: _MaxCanvas(
            board: BoardView(
              state: s,
              selected: c.selectedSource,
              onTap: c.busy ? null : c.tapBottle,
              suggested: hint?.to,
              hintSource: hint?.from,
              settings: c.settings,
              motion: c.motion,
              onMotionComplete: c.completeMotion,
              rejectedBottle: c.rejectedBottle,
              rejectionRevision: c.rejectionRevision,
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  key: const Key('max-home'),
                  tooltip: l.home,
                  onPressed: c.busy ? null : c.goHome,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: action(
                  'max-undo',
                  l.undo,
                  c.busy || s.history.isEmpty ? null : c.undo,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: hintActive
                    ? IconButton(
                        key: const Key('max-cancel-hint'),
                        tooltip: l.cancelHint,
                        onPressed: c.cancelHint,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : action('max-hint', l.hint, c.busy ? null : c.requestHint),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: IconButton(
                  key: const Key('max-pause'),
                  tooltip: l.pause,
                  onPressed: c.busy ? null : widget.page.onPause,
                  icon: const Icon(Icons.pause_rounded),
                ),
              ),
            ],
          ),
        ),
        if (c.offersExtraBottle) ...[
          const SizedBox(height: 4),
          action(
            'max-extra',
            s.extraBottleGranted ? l.bottleAdded : l.extraBottle,
            c.busy || s.extraBottleGranted ? null : widget.page.onExtra,
          ),
        ],
      ],
    );
  }
}

class _MaxCanvas extends StatefulWidget {
  const _MaxCanvas({required this.board});
  final BoardView board;
  @override
  State<_MaxCanvas> createState() => _MaxCanvasState();
}

class _MaxCanvasState extends State<_MaxCanvas> {
  String? _reportedLayout;
  late final game = FlameBoardGame(
    onMotionComplete: (token) {
      if (mounted) widget.board.onMotionComplete?.call(token);
    },
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = widget.board, s = w.state, l = AppLocalizations.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final layout = BoardLayout(
        width: box.maxWidth,
        maxHeight: box.maxHeight,
        count: s.board.length,
        textScale: scaler.scale(14) / 14,
      );
      final reduced = MediaQuery.disableAnimationsOf(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        game.show(
          state: s,
          layout: layout,
          settings: w.settings,
          systemReduced: reduced,
          motion: w.motion,
          selected: w.selected,
          suggested: w.suggested,
          hintSource: w.hintSource,
          rejectedBottle: w.rejectedBottle,
          rejectionRevision: w.rejectionRevision,
        );
        final reportKey = '${s.id}/${s.revision}/$box/${scaler.scale(14)}';
        if (_runtimeEvidenceDirectory != null && _reportedLayout != reportKey) {
          _reportedLayout = reportKey;
          final media = MediaQuery.of(context);
          final view = View.of(context);
          final origin = (context.findRenderObject()! as RenderBox)
              .localToGlobal(Offset.zero);
          File(
            '$_runtimeEvidenceDirectory/max-layout-current.json',
          ).writeAsStringSync(
            jsonEncode({
              'scope':
                  'Unapproved dedicated QA, not normal-main or release proof',
              'instance': s.id,
              'revision': s.revision,
              'moves': s.moveCount,
              'screen': [media.size.width, media.size.height],
              'dpr': media.devicePixelRatio,
              'padding_note':
                  'Inherited padding is consumed by GameScreen SafeArea.',
              'view_padding': [
                view.padding.left / view.devicePixelRatio,
                view.padding.top / view.devicePixelRatio,
                view.padding.right / view.devicePixelRatio,
                view.padding.bottom / view.devicePixelRatio,
              ],
              'board_origin': [origin.dx, origin.dy],
              'safe_area': [
                media.padding.left,
                media.padding.top,
                media.padding.right,
                media.padding.bottom,
              ],
              'scaler': scaler.toString(),
              'scaled_font_sizes': {
                for (final n in [12, 14, 18, 22])
                  '$n': scaler.scale(n.toDouble()),
              },
              'board_box': [box.maxWidth, box.maxHeight],
              'bottle_visible': [
                layout.shape.visibleRect.width,
                layout.shape.visibleRect.height,
              ],
              'count': s.board.length,
            }),
          );
        }
      });
      return SizedBox(
        key: const Key('max-canvas'),
        child: AnimatedBuilder(
          animation: Listenable.merge([game.visual, game.artStatus]),
          child: GameWidget<FlameBoardGame>(game: game, autofocus: false),
          builder: (context, canvas) {
            final frame = game.visual.value;
            final enabled =
                frame?.active == null &&
                w.onTap != null &&
                game.artStatus.value == BoardArtStatus.ready;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(child: IgnorePointer(child: canvas)),
                ),
                if (frame != null)
                  for (var i = 0; i < s.board.length; i++) ...[
                    Positioned.fromRect(
                      rect: layout.hitRect(i),
                      child: Semantics(
                        label:
                            '${l.bottleSemantics(i + 1, i < s.puzzle.targets.length && s.puzzle.targets[i] != null ? l.targetLabel(colorLabel(l, s.puzzle.targets[i]!)) : l.bufferLabel, frame.contents[i].isEmpty ? l.emptyLabel : l.contentsLabel(frame.contents[i].map((v) => colorLabel(l, v)).join(', ')), frame.counts[i])}${w.hintSource == i ? ' ${l.suggestedSource}' : ''}${w.suggested == i ? ' ${l.suggestedTarget}' : ''}',
                        selected: w.selected == i,
                        enabled: enabled,
                        button: true,
                        excludeSemantics: true,
                        onTap: enabled ? () => w.onTap!(i) : null,
                        child: TextButton(
                          key: Key('max-bottle-$i'),
                          onPressed: enabled ? () => w.onTap!(i) : null,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            overlayColor: Colors.transparent,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: layout.labelRect(i),
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: Column(
                            key: Key('max-label-$i'),
                            children: [
                              SizedBox(
                                height: math
                                    .max(
                                      scaler.scale(14) * 1.2,
                                      scaler.scale(12) + 12,
                                    )
                                    .ceilToDouble(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${i + 1}',
                                      key: Key('max-index-$i'),
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        height: 1.2,
                                        color: ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (i < s.puzzle.targets.length &&
                                        s.puzzle.targets[i] != null) ...[
                                      const SizedBox(width: 4),
                                      TargetCushion(
                                        key: Key('max-target-$i'),
                                        size: scaler.scale(12) + 12,
                                        target: s.puzzle.targets[i]!,
                                        symbolsEnabled: w.settings.colorSymbols,
                                        strongContrast:
                                            w.settings.strongContrast,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '${frame.counts[i]}/4',
                                key: Key('max-count-$i'),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  height: 1.2,
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
              ],
            );
          },
        ),
      );
    },
  );
}
