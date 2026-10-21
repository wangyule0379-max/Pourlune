export '../data/scenes.dart';

import 'package:pourlune_core/pourlune_core.dart';

import '../l10n/app_localizations.dart';
import '../application/game_controller.dart';

String colorLabel(AppLocalizations l, String color) => switch (color) {
  'O' => l.orangeCircle,
  'G' => l.greenTriangle,
  'P' => l.purpleDiamond,
  'B' => l.blueSquare,
  _ => color,
};
Set<int> ownedRegions(List<String> pieces, String scene) => pieces
    .where((p) => p.startsWith('$scene:'))
    .map((p) => int.parse(p.split(':').last))
    .toSet();
String regionLabel(AppLocalizations l, String scene, int number) =>
    scene == 'color_studio'
    ? [l.window, l.deskPaint, l.stool, l.plant, l.table][number - 1]
    : l.patchNumber(number);
String rejectionLabel(AppLocalizations l, String message) => switch (message) {
  'Choose another bottle' => l.chooseAnother,
  'Choose a bottle with liquid' => l.chooseLiquid,
  'That bottle is full' => l.bottleFull,
  'Empty or matching top color only' => l.matchingTop,
  'Follow the guided pour or Skip' => l.followGuide,
  _ => l.puzzleComplete,
};
String noticeLabel(AppLocalizations l, FlowNotice notice) => switch (notice) {
  FlowNotice.locked => l.locked,
  FlowNotice.unavailable => l.contentUnavailable,
  FlowNotice.replaceRequired => l.replaceBody,
  FlowNotice.viewPatchFirst => l.viewPatchFirst,
  FlowNotice.settingsUnreadable => l.settingsUnreadable,
};
String hintLabel(AppLocalizations l, HintResult result) =>
    switch (result.status) {
      HintStatus.found => l.hintFound(
        result.move!.from + 1,
        result.move!.to + 1,
      ),
      HintStatus.provenUnsolvable => l.hintUnsolvable,
      HintStatus.noMoves => l.noMoves,
      HintStatus.alreadyComplete => l.puzzleComplete,
      _ => l.hintTimeout,
    };
