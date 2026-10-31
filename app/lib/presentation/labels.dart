export '../data/scenes.dart';

import 'package:pourlune_core/pourlune_core.dart';

import '../l10n/app_localizations.dart';
import '../application/game_controller.dart';

String colorLabel(AppLocalizations l, String color) => switch (color) {
  'O' => l.orangeCircle,
  'G' => l.greenTriangle,
  'P' => l.purpleDiamond,
  'B' => l.blueSquare,
  'R' => l.roseStar,
  _ => color,
};
Set<int> ownedRegions(List<String> pieces, String scene) => pieces
    .where((p) => p.startsWith('$scene:'))
    .map((p) => int.parse(p.split(':').last))
    .toSet();
String regionLabel(AppLocalizations l, String scene, int number) =>
    (switch (scene) {
      'color_studio' => [l.window, l.deskPaint, l.stool, l.plant, l.table],
      'garden_nook' => [
        l.gardenArch,
        l.gardenTable,
        l.gardenChair,
        l.gardenPlants,
        l.gardenTea,
      ],
      'seaside_corner' => [
        l.seasideDock,
        l.seasideCabana,
        l.seasideRing,
        l.seasidePlant,
        l.seasideGull,
      ],
      _ => [for (var i = 1; i <= 5; i++) l.patchNumber(i)],
    })[number - 1];
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
