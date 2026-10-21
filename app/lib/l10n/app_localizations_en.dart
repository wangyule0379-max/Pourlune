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
      'Offline development slice · 3 engineering fixtures, not the full game';

  @override
  String get drawingNotice =>
      'Development drawing probe · final artwork pending';

  @override
  String get chooseSample => 'Choose a sample';

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
  String get home => 'Sample menu';
}
