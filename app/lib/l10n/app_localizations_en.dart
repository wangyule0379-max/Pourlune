// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pourlune Dev';

  @override
  String get developmentNotice =>
      'Engineering content · not the complete release catalog';

  @override
  String get drawingNotice =>
      'Development drawing probe · final artwork pending';

  @override
  String get chooseSample => 'Engineering samples';

  @override
  String get resume => 'Resume saved sample';

  @override
  String get undo => 'Undo';

  @override
  String get restart => 'Restart';

  @override
  String get pause => 'Pause';

  @override
  String get retry => 'Retry';

  @override
  String get stayHere => 'Stay here';

  @override
  String get saved => 'Saved on this device';

  @override
  String get saving => 'Saving…';

  @override
  String get saveFailed => 'Couldn’t save. Retry before leaving.';

  @override
  String get goal =>
      'Match every color to its target. Leave all buffers empty.';

  @override
  String get progress => 'Local development progress';

  @override
  String get home => 'Home';

  @override
  String get start => 'Start';

  @override
  String continueLevel(int level) {
    return 'Continue · Level $level';
  }

  @override
  String continueReplay(int level) {
    return 'Continue replay · Level $level';
  }

  @override
  String playLevel(int level) {
    return 'Play Level $level';
  }

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String levelMoves(int level, int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves moves',
      one: '1 move',
    );
    return 'Level $level · $_temp0';
  }

  @override
  String replayLevel(int level) {
    return 'Replay · Level $level';
  }

  @override
  String get chapters => 'Chapters';

  @override
  String get collection => 'Collection';

  @override
  String get settings => 'Settings';

  @override
  String get dailyPuzzle => 'Daily puzzle';

  @override
  String get storyComplete => 'Story complete';

  @override
  String get storyCompleteBody =>
      'Your story is complete. Return for a daily puzzle, revisit levels or enjoy your collection.';

  @override
  String get contentUnavailable =>
      'This level is not available in this development catalog. Your saves and progress are kept.';

  @override
  String get locked => 'Locked';

  @override
  String get completed => 'Completed';

  @override
  String get ready => 'Ready to play';

  @override
  String get missing => 'Content unavailable';

  @override
  String get viewResult => 'View saved result';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get replaceTitle => 'Replace your unfinished puzzle?';

  @override
  String get replaceBody =>
      'Starting this level will replace your unfinished puzzle.';

  @override
  String get replace => 'Replace';

  @override
  String get pauseTitle => 'Take your time.';

  @override
  String get pauseSaved => 'Your puzzle is saved.';

  @override
  String get pauseMemory =>
      'Some changes are only in memory. Resume and Retry before leaving.';

  @override
  String get resumeGame => 'Resume';

  @override
  String get restartTitle => 'Start this level again?';

  @override
  String get restartBody => 'Your board will reset.';

  @override
  String get extraBottleStays => 'Your extra bottle stays.';

  @override
  String get lessonTitle => 'One pour at a time';

  @override
  String lessonAction(int step, int total, int from, int to) {
    return 'Step $step of $total: tap bottle $from, then bottle $to.';
  }

  @override
  String get skip => 'Skip';

  @override
  String get followGuide => 'Follow the guided pour or Skip.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get rulesTitle => 'Match the color tags';

  @override
  String get rulesBody =>
      'Each bottle holds four units. Choose a bottle with liquid, then an empty bottle or a matching top color with room. The whole top group pours as far as it can. Fill every target with its own color and leave all buffers empty. Undo and restart are always free.';

  @override
  String get demoNote =>
      'This demonstration uses a separate board. Your saved puzzle stays unchanged.';

  @override
  String get demoReset => 'Restart demonstration';

  @override
  String get rulesBack => 'Back to settings';

  @override
  String get hint => 'Hint';

  @override
  String get cancelHint => 'Cancel hint';

  @override
  String get searchingHint => 'Looking for a hint…';

  @override
  String hintFound(int from, int to) {
    return 'Try bottle $from → $to. Tap the suggested destination to pour.';
  }

  @override
  String hintReason(String color) {
    return 'This moves the top $color group along a solution for your current board.';
  }

  @override
  String get hintTimeout => 'No hint found yet. You can keep playing.';

  @override
  String get hintUnsolvable => 'Try undoing a move or restarting.';

  @override
  String get noMoves => 'No moves available';

  @override
  String get noMovesBody => 'Try an earlier move. You can undo or restart.';

  @override
  String get matchLabels => 'Match each color to its label.';

  @override
  String get chooseAnother => 'Choose another bottle.';

  @override
  String get chooseLiquid => 'Choose a bottle with liquid.';

  @override
  String get bottleFull => 'That bottle is full.';

  @override
  String get matchingTop => 'Empty or matching top color only.';

  @override
  String get puzzleComplete => 'Puzzle complete';

  @override
  String get beautifullySorted => 'Beautifully sorted.';

  @override
  String get pendingCompletion =>
      'Your board is complete. Retry saving before leaving.';

  @override
  String get firstClearSaved => 'Your progress is saved on this device.';

  @override
  String get replayComplete =>
      'Your collection and story progress are unchanged.';

  @override
  String get viewPatch => 'View patch';

  @override
  String get newPatch => 'New patch unlocked';

  @override
  String get addedCollection => 'Added to your collection';

  @override
  String get nextLevel => 'Next level';

  @override
  String get replayAgain => 'Replay again';

  @override
  String get chooseLevel => 'Choose level';

  @override
  String get viewCollection => 'View collection';

  @override
  String get replayLevels => 'Replay levels';

  @override
  String get chapterComplete => 'Scene complete';

  @override
  String sceneCount(int earned) {
    return '$earned / 5 patches';
  }

  @override
  String get scenePendingArt => 'Development scene map · final artwork pending';

  @override
  String get sceneLocked => 'Locked patch';

  @override
  String get sceneOwned => 'Unlocked patch';

  @override
  String patchNumber(int number) {
    return 'Patch $number';
  }

  @override
  String get dailyTitle => 'Today\'s puzzle';

  @override
  String get dailyUnavailable =>
      'Today\'s puzzle is unavailable. You can continue a saved daily puzzle or play the story.';

  @override
  String dailyDate(String date) {
    return 'Today · $date';
  }

  @override
  String resumeDaily(String date) {
    return 'Resume daily · $date';
  }

  @override
  String continuePrevious(String date) {
    return 'Continue puzzle from $date';
  }

  @override
  String get startToday => 'Start today\'s puzzle';

  @override
  String get dailyDone => 'Today\'s puzzle is complete.';

  @override
  String get replayToday => 'Replay today\'s puzzle';

  @override
  String get dailyComplete => 'Daily puzzle complete';

  @override
  String stampSaved(String date) {
    return 'Stamp saved for $date.';
  }

  @override
  String get dailyReplayComplete => 'This replay adds no new stamp.';

  @override
  String replaceDailyBody(String date) {
    return 'Starting today\'s puzzle will replace your unfinished puzzle from $date.';
  }

  @override
  String get calendar => 'Daily calendar';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get weekdays => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get historyReadOnly =>
      'History is read-only. Past puzzles cannot be started.';

  @override
  String get futureReadOnly => 'Future dates cannot be played.';

  @override
  String get stampOwned => 'Stamp collected';

  @override
  String get noStamp => 'No stamp for this date';

  @override
  String dateState(String date, String state) {
    return '$date · $state';
  }

  @override
  String get music => 'Music';

  @override
  String get sound => 'Sound';

  @override
  String get haptics => 'Haptics';

  @override
  String get reducedMotion => 'Reduced motion';

  @override
  String get colorSymbols => 'Color symbols';

  @override
  String get strongContrast => 'Stronger contrast';

  @override
  String get audioPending =>
      'Music and sound preferences are saved. Audio tracks are not included in this development build.';

  @override
  String get privacyChoices => 'Privacy choices';

  @override
  String get privacyUnavailable =>
      'Privacy policy and advertising privacy controls are not connected in this development build. No placeholder form is used.';

  @override
  String get yourProgress => 'Your game progress';

  @override
  String get localOnly =>
      'Progress is saved on this device. There is no account or cloud sync. Removing app data or changing devices can lose progress.';

  @override
  String get feedback => 'Send feedback';

  @override
  String get supportUnavailable =>
      'The support address has not been configured. No message will be sent.';

  @override
  String versionInfo(String version, String build) {
    return 'Pourlune · $version ($build)';
  }

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetTitle => 'Reset all progress?';

  @override
  String get resetBody =>
      'This removes your levels, collection and daily stamps from this device. Saved puzzles will also be removed. Sound and accessibility choices stay.';

  @override
  String get keepProgress => 'Keep progress';

  @override
  String get recoveredSave => 'Recovered the last valid local snapshot.';

  @override
  String get unavailableSave =>
      'This saved puzzle cannot be restored. Other saves and local progress are kept.';

  @override
  String get settingsUnreadable =>
      'Preferences could not be read. Defaults are being used; your game progress is kept.';

  @override
  String get viewPatchFirst => 'View your new patch before continuing.';

  @override
  String get openFailed => 'Couldn\'t open local data. Your files were kept.';

  @override
  String get close => 'Close';

  @override
  String get window => 'Window';

  @override
  String get deskPaint => 'Desk & paint';

  @override
  String get stool => 'Stool';

  @override
  String get plant => 'Plant';

  @override
  String get table => 'Table';

  @override
  String bottleSemantics(
    int number,
    String target,
    String contents,
    int units,
  ) {
    return 'Bottle $number. $target. $contents. $units of 4.';
  }

  @override
  String targetLabel(String color) {
    return 'Target $color';
  }

  @override
  String get bufferLabel => 'Buffer';

  @override
  String get emptyLabel => 'Empty';

  @override
  String contentsLabel(String colors) {
    return 'Bottom to top: $colors';
  }

  @override
  String get orangeCircle => 'Orange circle';

  @override
  String get greenTriangle => 'Green triangle';

  @override
  String get purpleDiamond => 'Purple diamond';

  @override
  String get blueSquare => 'Blue square';

  @override
  String get suggestedTarget => 'Suggested destination';

  @override
  String get continueChapter => 'Continue';

  @override
  String moveCount(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves moves',
      one: '1 move',
    );
    return '$_temp0';
  }
}
