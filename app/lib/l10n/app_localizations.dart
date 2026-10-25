import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pourlune Dev'**
  String get appTitle;

  /// No description provided for @developmentNotice.
  ///
  /// In en, this message translates to:
  /// **'Engineering content · not the complete release catalog'**
  String get developmentNotice;

  /// No description provided for @drawingNotice.
  ///
  /// In en, this message translates to:
  /// **'Development drawing probe · final artwork pending'**
  String get drawingNotice;

  /// No description provided for @chooseSample.
  ///
  /// In en, this message translates to:
  /// **'Engineering samples'**
  String get chooseSample;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume saved sample'**
  String get resume;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @stayHere.
  ///
  /// In en, this message translates to:
  /// **'Stay here'**
  String get stayHere;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get saved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save. Retry before leaving.'**
  String get saveFailed;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Match every color to its target. Leave all buffers empty.'**
  String get goal;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Local development progress'**
  String get progress;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @continueLevel.
  ///
  /// In en, this message translates to:
  /// **'Continue · Level {level}'**
  String continueLevel(int level);

  /// No description provided for @continueReplay.
  ///
  /// In en, this message translates to:
  /// **'Continue replay · Level {level}'**
  String continueReplay(int level);

  /// No description provided for @playLevel.
  ///
  /// In en, this message translates to:
  /// **'Play Level {level}'**
  String playLevel(int level);

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @levelMoves.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {moves, plural, =1{1 move} other{{moves} moves}}'**
  String levelMoves(int level, int moves);

  /// No description provided for @replayLevel.
  ///
  /// In en, this message translates to:
  /// **'Replay · Level {level}'**
  String replayLevel(int level);

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dailyPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Daily puzzle'**
  String get dailyPuzzle;

  /// No description provided for @storyComplete.
  ///
  /// In en, this message translates to:
  /// **'Story complete'**
  String get storyComplete;

  /// No description provided for @storyCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your story is complete. Return for a daily puzzle, revisit levels or enjoy your collection.'**
  String get storyCompleteBody;

  /// No description provided for @contentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This level is not available in this development catalog. Your saves and progress are kept.'**
  String get contentUnavailable;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get ready;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Content unavailable'**
  String get missing;

  /// No description provided for @viewResult.
  ///
  /// In en, this message translates to:
  /// **'View saved result'**
  String get viewResult;

  /// No description provided for @keepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get keepPlaying;

  /// No description provided for @replaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace your unfinished puzzle?'**
  String get replaceTitle;

  /// No description provided for @replaceBody.
  ///
  /// In en, this message translates to:
  /// **'Starting this level will replace your unfinished puzzle.'**
  String get replaceBody;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @pauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Take your time.'**
  String get pauseTitle;

  /// No description provided for @pauseSaved.
  ///
  /// In en, this message translates to:
  /// **'Your puzzle is saved.'**
  String get pauseSaved;

  /// No description provided for @progressNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress not saved'**
  String get progressNotSaved;

  /// No description provided for @pauseMemory.
  ///
  /// In en, this message translates to:
  /// **'Some changes are only in memory. Retry before leaving.'**
  String get pauseMemory;

  /// No description provided for @resumeGame.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeGame;

  /// No description provided for @restartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start this level again?'**
  String get restartTitle;

  /// No description provided for @restartBody.
  ///
  /// In en, this message translates to:
  /// **'Your board will reset.'**
  String get restartBody;

  /// No description provided for @extraBottleStays.
  ///
  /// In en, this message translates to:
  /// **'Your extra bottle stays.'**
  String get extraBottleStays;

  /// No description provided for @lessonTitle.
  ///
  /// In en, this message translates to:
  /// **'One pour at a time'**
  String get lessonTitle;

  /// No description provided for @lessonAction.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: tap bottle {from}, then bottle {to}.'**
  String lessonAction(int step, int total, int from, int to);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @followGuide.
  ///
  /// In en, this message translates to:
  /// **'Follow the guided pour or Skip.'**
  String get followGuide;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @rulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Match the color tags'**
  String get rulesTitle;

  /// No description provided for @rulesBody.
  ///
  /// In en, this message translates to:
  /// **'Each bottle holds four units. Choose a bottle with liquid, then an empty bottle or a matching top color with room. The whole top group pours as far as it can. Fill every target with its own color and leave all buffers empty. Undo and restart are always free.'**
  String get rulesBody;

  /// No description provided for @demoNote.
  ///
  /// In en, this message translates to:
  /// **'This demonstration uses a separate board. Your saved puzzle stays unchanged.'**
  String get demoNote;

  /// No description provided for @demoReset.
  ///
  /// In en, this message translates to:
  /// **'Restart demonstration'**
  String get demoReset;

  /// No description provided for @rulesBack.
  ///
  /// In en, this message translates to:
  /// **'Back to settings'**
  String get rulesBack;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @cancelHint.
  ///
  /// In en, this message translates to:
  /// **'Cancel hint'**
  String get cancelHint;

  /// No description provided for @searchingHint.
  ///
  /// In en, this message translates to:
  /// **'Finding a move…'**
  String get searchingHint;

  /// No description provided for @hintFound.
  ///
  /// In en, this message translates to:
  /// **'Bottle {from} → {to}'**
  String hintFound(int from, int to);

  /// No description provided for @hintReason.
  ///
  /// In en, this message translates to:
  /// **'Tap {to} to move the top {color} group along a solution.'**
  String hintReason(int to, String color);

  /// No description provided for @hintTimeout.
  ///
  /// In en, this message translates to:
  /// **'No hint found yet'**
  String get hintTimeout;

  /// No description provided for @hintUnsolvable.
  ///
  /// In en, this message translates to:
  /// **'Try Undo'**
  String get hintUnsolvable;

  /// No description provided for @noMoves.
  ///
  /// In en, this message translates to:
  /// **'No moves available'**
  String get noMoves;

  /// No description provided for @noMovesBody.
  ///
  /// In en, this message translates to:
  /// **'Undo or restart to keep playing.'**
  String get noMovesBody;

  /// No description provided for @matchLabels.
  ///
  /// In en, this message translates to:
  /// **'Match each color to its label.'**
  String get matchLabels;

  /// No description provided for @chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get chooseAnother;

  /// No description provided for @chooseLiquid.
  ///
  /// In en, this message translates to:
  /// **'Choose a filled bottle.'**
  String get chooseLiquid;

  /// No description provided for @bottleFull.
  ///
  /// In en, this message translates to:
  /// **'Bottle full'**
  String get bottleFull;

  /// No description provided for @matchingTop.
  ///
  /// In en, this message translates to:
  /// **'Empty or matching top color only.'**
  String get matchingTop;

  /// No description provided for @puzzleComplete.
  ///
  /// In en, this message translates to:
  /// **'Puzzle complete'**
  String get puzzleComplete;

  /// No description provided for @beautifullySorted.
  ///
  /// In en, this message translates to:
  /// **'Beautifully sorted.'**
  String get beautifullySorted;

  /// No description provided for @pendingCompletion.
  ///
  /// In en, this message translates to:
  /// **'Your board is complete. Retry saving before leaving.'**
  String get pendingCompletion;

  /// No description provided for @firstClearSaved.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved on this device.'**
  String get firstClearSaved;

  /// No description provided for @replayComplete.
  ///
  /// In en, this message translates to:
  /// **'Your collection and story progress are unchanged.'**
  String get replayComplete;

  /// No description provided for @viewPatch.
  ///
  /// In en, this message translates to:
  /// **'View patch'**
  String get viewPatch;

  /// No description provided for @newPatchCompact.
  ///
  /// In en, this message translates to:
  /// **'New patch'**
  String get newPatchCompact;

  /// No description provided for @newPatch.
  ///
  /// In en, this message translates to:
  /// **'New patch unlocked'**
  String get newPatch;

  /// No description provided for @addedCollection.
  ///
  /// In en, this message translates to:
  /// **'Added to your collection'**
  String get addedCollection;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @replayAgain.
  ///
  /// In en, this message translates to:
  /// **'Replay again'**
  String get replayAgain;

  /// No description provided for @chooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose level'**
  String get chooseLevel;

  /// No description provided for @viewCollection.
  ///
  /// In en, this message translates to:
  /// **'View collection'**
  String get viewCollection;

  /// No description provided for @replayLevels.
  ///
  /// In en, this message translates to:
  /// **'Replay levels'**
  String get replayLevels;

  /// No description provided for @chapterComplete.
  ///
  /// In en, this message translates to:
  /// **'Scene complete'**
  String get chapterComplete;

  /// No description provided for @sceneCount.
  ///
  /// In en, this message translates to:
  /// **'{earned} / 5 patches'**
  String sceneCount(int earned);

  /// No description provided for @scenePendingArt.
  ///
  /// In en, this message translates to:
  /// **'Development scene map · final artwork pending'**
  String get scenePendingArt;

  /// No description provided for @sceneLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked patch'**
  String get sceneLocked;

  /// No description provided for @sceneOwned.
  ///
  /// In en, this message translates to:
  /// **'Unlocked patch'**
  String get sceneOwned;

  /// No description provided for @patchNumber.
  ///
  /// In en, this message translates to:
  /// **'Patch {number}'**
  String patchNumber(int number);

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle'**
  String get dailyTitle;

  /// No description provided for @dailyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle is unavailable. You can continue a saved daily puzzle or play the story.'**
  String get dailyUnavailable;

  /// No description provided for @dailyDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String dailyDate(String date);

  /// No description provided for @resumeDaily.
  ///
  /// In en, this message translates to:
  /// **'Resume daily · {date}'**
  String resumeDaily(String date);

  /// No description provided for @continuePrevious.
  ///
  /// In en, this message translates to:
  /// **'Continue puzzle from {date}'**
  String continuePrevious(String date);

  /// No description provided for @startToday.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s puzzle'**
  String get startToday;

  /// No description provided for @dailyDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle is complete.'**
  String get dailyDone;

  /// No description provided for @replayToday.
  ///
  /// In en, this message translates to:
  /// **'Replay today\'s puzzle'**
  String get replayToday;

  /// No description provided for @dailyComplete.
  ///
  /// In en, this message translates to:
  /// **'Daily puzzle complete'**
  String get dailyComplete;

  /// No description provided for @stampSaved.
  ///
  /// In en, this message translates to:
  /// **'Stamp saved for {date}.'**
  String stampSaved(String date);

  /// No description provided for @dailyReplayComplete.
  ///
  /// In en, this message translates to:
  /// **'This replay adds no new stamp.'**
  String get dailyReplayComplete;

  /// No description provided for @replaceDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Starting today\'s puzzle will replace your unfinished puzzle from {date}.'**
  String replaceDailyBody(String date);

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Daily calendar'**
  String get calendar;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get weekdays;

  /// No description provided for @historyReadOnly.
  ///
  /// In en, this message translates to:
  /// **'History is read-only. Past puzzles cannot be started.'**
  String get historyReadOnly;

  /// No description provided for @futureReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Future dates cannot be played.'**
  String get futureReadOnly;

  /// No description provided for @stampOwned.
  ///
  /// In en, this message translates to:
  /// **'Stamp collected'**
  String get stampOwned;

  /// No description provided for @noStamp.
  ///
  /// In en, this message translates to:
  /// **'No stamp for this date'**
  String get noStamp;

  /// No description provided for @dateState.
  ///
  /// In en, this message translates to:
  /// **'{date} · {state}'**
  String dateState(String date, String state);

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get reducedMotion;

  /// No description provided for @colorSymbols.
  ///
  /// In en, this message translates to:
  /// **'Color symbols'**
  String get colorSymbols;

  /// No description provided for @strongContrast.
  ///
  /// In en, this message translates to:
  /// **'Stronger contrast'**
  String get strongContrast;

  /// No description provided for @privacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices'**
  String get privacyChoices;

  /// No description provided for @privacyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy and advertising privacy controls are not connected in this development build. No placeholder form is used.'**
  String get privacyUnavailable;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your game progress'**
  String get yourProgress;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Progress is saved on this device. There is no account or cloud sync. Removing app data or changing devices can lose progress.'**
  String get localOnly;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedback;

  /// No description provided for @supportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The support address has not been configured. No message will be sent.'**
  String get supportUnavailable;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Pourlune · {version} ({build})'**
  String versionInfo(String version, String build);

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress?'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'This removes your levels, collection and daily stamps from this device. Saved puzzles will also be removed. Sound and accessibility choices stay.'**
  String get resetBody;

  /// No description provided for @keepProgress.
  ///
  /// In en, this message translates to:
  /// **'Keep progress'**
  String get keepProgress;

  /// No description provided for @recoveredSave.
  ///
  /// In en, this message translates to:
  /// **'Recovered the last valid local snapshot.'**
  String get recoveredSave;

  /// No description provided for @unavailableSave.
  ///
  /// In en, this message translates to:
  /// **'This saved puzzle cannot be restored. Other saves and local progress are kept.'**
  String get unavailableSave;

  /// No description provided for @settingsUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Preferences could not be read. Defaults are being used; your game progress is kept.'**
  String get settingsUnreadable;

  /// No description provided for @viewPatchFirst.
  ///
  /// In en, this message translates to:
  /// **'View your new patch before continuing.'**
  String get viewPatchFirst;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open local data. Your files were kept.'**
  String get openFailed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @window.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get window;

  /// No description provided for @deskPaint.
  ///
  /// In en, this message translates to:
  /// **'Desk & paint'**
  String get deskPaint;

  /// No description provided for @stool.
  ///
  /// In en, this message translates to:
  /// **'Stool'**
  String get stool;

  /// No description provided for @plant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get plant;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @bottleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Bottle {number}. {target}. {contents}. {units} of 4.'**
  String bottleSemantics(int number, String target, String contents, int units);

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target {color}'**
  String targetLabel(String color);

  /// No description provided for @bufferLabel.
  ///
  /// In en, this message translates to:
  /// **'Buffer'**
  String get bufferLabel;

  /// No description provided for @emptyLabel.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptyLabel;

  /// No description provided for @contentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bottom to top: {colors}'**
  String contentsLabel(String colors);

  /// No description provided for @orangeCircle.
  ///
  /// In en, this message translates to:
  /// **'Orange circle'**
  String get orangeCircle;

  /// No description provided for @greenTriangle.
  ///
  /// In en, this message translates to:
  /// **'Green triangle'**
  String get greenTriangle;

  /// No description provided for @purpleDiamond.
  ///
  /// In en, this message translates to:
  /// **'Purple diamond'**
  String get purpleDiamond;

  /// No description provided for @blueSquare.
  ///
  /// In en, this message translates to:
  /// **'Blue square'**
  String get blueSquare;

  /// No description provided for @roseStar.
  ///
  /// In en, this message translates to:
  /// **'Rose star'**
  String get roseStar;

  /// No description provided for @suggestedTarget.
  ///
  /// In en, this message translates to:
  /// **'Suggested destination'**
  String get suggestedTarget;

  /// No description provided for @continueChapter.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueChapter;

  /// No description provided for @moveCount.
  ///
  /// In en, this message translates to:
  /// **'{moves, plural, =1{1 move} other{{moves} moves}}'**
  String moveCount(int moves);

  /// No description provided for @audioInfo.
  ///
  /// In en, this message translates to:
  /// **'Music and sound play offline. Pause or leave the app to stop audio.'**
  String get audioInfo;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @gardenArch.
  ///
  /// In en, this message translates to:
  /// **'Flower arch'**
  String get gardenArch;

  /// No description provided for @gardenTable.
  ///
  /// In en, this message translates to:
  /// **'Garden table'**
  String get gardenTable;

  /// No description provided for @gardenChair.
  ///
  /// In en, this message translates to:
  /// **'Chair'**
  String get gardenChair;

  /// No description provided for @gardenPlants.
  ///
  /// In en, this message translates to:
  /// **'Potted plants'**
  String get gardenPlants;

  /// No description provided for @gardenTea.
  ///
  /// In en, this message translates to:
  /// **'Tea and flowers'**
  String get gardenTea;

  /// No description provided for @seasideDock.
  ///
  /// In en, this message translates to:
  /// **'Dock'**
  String get seasideDock;

  /// No description provided for @seasideCabana.
  ///
  /// In en, this message translates to:
  /// **'Cabana'**
  String get seasideCabana;

  /// No description provided for @seasideRing.
  ///
  /// In en, this message translates to:
  /// **'Life ring'**
  String get seasideRing;

  /// No description provided for @seasidePlant.
  ///
  /// In en, this message translates to:
  /// **'Coastal plant'**
  String get seasidePlant;

  /// No description provided for @seasideGull.
  ///
  /// In en, this message translates to:
  /// **'Seagull'**
  String get seasideGull;

  /// No description provided for @extraBottle.
  ///
  /// In en, this message translates to:
  /// **'Extra bottle'**
  String get extraBottle;

  /// No description provided for @bottleAdded.
  ///
  /// In en, this message translates to:
  /// **'Bottle added'**
  String get bottleAdded;

  /// No description provided for @extraExplain.
  ///
  /// In en, this message translates to:
  /// **'Watch an optional ad to add one empty bottle to this puzzle. It stays through Undo and Restart. You can add one per puzzle. Hint, Undo and Restart remain free.'**
  String get extraExplain;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get watchAd;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @extraUsed.
  ///
  /// In en, this message translates to:
  /// **'This puzzle already has its extra bottle.'**
  String get extraUsed;

  /// No description provided for @adLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing an optional ad… You can keep playing.'**
  String get adLoading;

  /// No description provided for @adUnavailable.
  ///
  /// In en, this message translates to:
  /// **'An ad is not available. Keep playing with free Hint, Undo or Restart, or try again later.'**
  String get adUnavailable;

  /// No description provided for @adCooldown.
  ///
  /// In en, this message translates to:
  /// **'Another ad was shown recently. Please wait {seconds} seconds.'**
  String adCooldown(int seconds);

  /// No description provided for @adRetry.
  ///
  /// In en, this message translates to:
  /// **'Try loading an ad'**
  String get adRetry;

  /// No description provided for @rewardSavingFailed.
  ///
  /// In en, this message translates to:
  /// **'A reward confirmation was received, but could not be saved. Retry while this app remains open. Closing the app may lose an unsaved confirmation. Free tools still work.'**
  String get rewardSavingFailed;

  /// No description provided for @rewardUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'An earlier ad request was interrupted. This device has no saved reward confirmation; the SDK cannot verify it now. End this request to try again. No bottle will be added.'**
  String get rewardUnconfirmed;

  /// No description provided for @endRequest.
  ///
  /// In en, this message translates to:
  /// **'End interrupted request'**
  String get endRequest;

  /// No description provided for @rewardRestore.
  ///
  /// In en, this message translates to:
  /// **'An extra bottle belongs to an earlier puzzle. Resume that puzzle to use it.'**
  String get rewardRestore;

  /// No description provided for @resumeReward.
  ///
  /// In en, this message translates to:
  /// **'Resume rewarded puzzle'**
  String get resumeReward;

  /// No description provided for @restoreRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume the earlier puzzle?'**
  String get restoreRewardTitle;

  /// No description provided for @restoreRewardBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces the current puzzle in the same slot with the saved earlier puzzle and its extra bottle. Progress in the other slot is kept.'**
  String get restoreRewardBody;

  /// No description provided for @rewardOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The reward request could not be saved or restored. No new bottle was added. Please retry.'**
  String get rewardOperationFailed;

  /// No description provided for @analyticsChoice.
  ///
  /// In en, this message translates to:
  /// **'Share gameplay analytics'**
  String get analyticsChoice;

  /// No description provided for @analyticsDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional gameplay events. Turning this off stops new app events; it cannot recall data already sent.'**
  String get analyticsDetails;

  /// No description provided for @crashChoice.
  ///
  /// In en, this message translates to:
  /// **'Share crash reports'**
  String get crashChoice;

  /// No description provided for @crashDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional technical diagnostics, including crash reports stored on this device before you enabled sharing. The SDK may store crashes locally while sharing is off. Turning this off stops new app upload requests; queued reports cannot be recalled.'**
  String get crashDetails;

  /// No description provided for @privacySaveProblem.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices could not be saved or synchronized. Sharing is blocked by the app until Retry succeeds.'**
  String get privacySaveProblem;

  /// No description provided for @adPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Advertising privacy options'**
  String get adPrivacyOptions;

  /// No description provided for @adPrivacyRetry.
  ///
  /// In en, this message translates to:
  /// **'Check advertising privacy'**
  String get adPrivacyRetry;

  /// No description provided for @adPrivacyChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the advertising privacy service… Core play remains available.'**
  String get adPrivacyChecking;

  /// No description provided for @adPrivacyProblem.
  ///
  /// In en, this message translates to:
  /// **'Advertising privacy is unavailable. Ads stay unavailable until the SDK permits requests.'**
  String get adPrivacyProblem;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @supportWebsite.
  ///
  /// In en, this message translates to:
  /// **'Help website'**
  String get supportWebsite;

  /// No description provided for @servicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Optional diagnostics are unavailable in this build. Choices are saved locally.'**
  String get servicesDisabled;

  /// No description provided for @adNetwork.
  ///
  /// In en, this message translates to:
  /// **'The ad network could not be reached. Free tools still work. Try again when connected.'**
  String get adNetwork;

  /// No description provided for @adNoFill.
  ///
  /// In en, this message translates to:
  /// **'No ad is available from the service right now. Free tools still work. Please try later.'**
  String get adNoFill;

  /// No description provided for @cantPourHere.
  ///
  /// In en, this message translates to:
  /// **'Can\'t pour here'**
  String get cantPourHere;

  /// No description provided for @matchingTopBody.
  ///
  /// In en, this message translates to:
  /// **'Use an empty bottle or match its top color.'**
  String get matchingTopBody;

  /// No description provided for @hintKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'You can keep playing.'**
  String get hintKeepPlaying;

  /// No description provided for @hintUnsolvableBody.
  ///
  /// In en, this message translates to:
  /// **'Undo or restart to try another path.'**
  String get hintUnsolvableBody;

  /// No description provided for @matchLabelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the color tags'**
  String get matchLabelsTitle;

  /// No description provided for @suggestedSource.
  ///
  /// In en, this message translates to:
  /// **'Suggested source'**
  String get suggestedSource;

  /// No description provided for @hintDirectionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Bottle {from} to bottle {to}; tap bottle {to} to pour.'**
  String hintDirectionSemantics(int from, int to);

  /// No description provided for @moreRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'A little more room'**
  String get moreRoomTitle;

  /// No description provided for @adUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'No ad available'**
  String get adUnavailableTitle;

  /// No description provided for @backToPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Back to puzzle'**
  String get backToPuzzle;

  /// No description provided for @extraBottleAdded.
  ///
  /// In en, this message translates to:
  /// **'Extra bottle added'**
  String get extraBottleAdded;

  /// No description provided for @extraOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Watch an optional ad to add one empty bottle to this puzzle.'**
  String get extraOfferBody;

  /// No description provided for @extraOfferLimit.
  ///
  /// In en, this message translates to:
  /// **'One per puzzle, kept through Undo and Restart.\nHint, Undo and Restart remain free.'**
  String get extraOfferLimit;

  /// No description provided for @noAdPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get noAdPrompt;

  /// No description provided for @puzzleUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Your puzzle is unchanged. Free tools still work.'**
  String get puzzleUnchanged;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @completionLevels.
  ///
  /// In en, this message translates to:
  /// **'{count} / {total} levels'**
  String completionLevels(int count, int total);

  /// No description provided for @watchAdPlusBottle.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for +1 bottle'**
  String get watchAdPlusBottle;

  /// No description provided for @compactSearching.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get compactSearching;

  /// No description provided for @compactNoMoves.
  ///
  /// In en, this message translates to:
  /// **'No moves'**
  String get compactNoMoves;

  /// No description provided for @compactSorted.
  ///
  /// In en, this message translates to:
  /// **'Sorted'**
  String get compactSorted;

  /// No description provided for @compactFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get compactFull;

  /// No description provided for @compactMismatch.
  ///
  /// In en, this message translates to:
  /// **'Mismatch'**
  String get compactMismatch;

  /// No description provided for @compactRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get compactRules;

  /// No description provided for @compactCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get compactCheck;

  /// No description provided for @compactDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get compactDaily;

  /// No description provided for @compactNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get compactNotSaved;

  /// No description provided for @compactReward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get compactReward;

  /// No description provided for @yourCollection.
  ///
  /// In en, this message translates to:
  /// **'Your collection'**
  String get yourCollection;

  /// No description provided for @sceneLevelsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 level to complete this scene} other{{count} levels to complete this scene}}'**
  String sceneLevelsRemaining(int count);

  /// No description provided for @completeSceneToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Complete\n{scene}'**
  String completeSceneToUnlock(String scene);

  /// No description provided for @collectionTagline.
  ///
  /// In en, this message translates to:
  /// **'A little more with every puzzle.'**
  String get collectionTagline;

  /// No description provided for @backToCollection.
  ///
  /// In en, this message translates to:
  /// **'Back to collection'**
  String get backToCollection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
