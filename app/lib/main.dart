import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:sqflite/sqflite.dart';

import 'application/game_controller.dart';
import 'application/game_audio.dart';
import 'data/game_store.dart';
import 'data/content_library.dart';
import 'development/scenarios.dart';
import 'l10n/app_localizations.dart';
import 'presentation/pourlune_app.dart';
export 'presentation/pourlune_app.dart' show PourluneApp;
export 'presentation/game_screen.dart' show GameScreen;

bool _fontLicenseRegistered = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!_fontLicenseRegistered) {
    _fontLicenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'Nunito',
      ], await rootBundle.loadString('assets/fonts/nunito/OFL.txt'));
    });
  }
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  GameController? controller;
  DevelopmentScenario? development;
  GameAudio? audio;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => failed = false);
    GameStore? store;
    GameAudio? pendingAudio;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final formal = manifest
          .listAssets()
          .where((p) => p.startsWith('assets/puzzles/') && p.endsWith('.json'))
          .toList();
      final sources = formal.isNotEmpty
          ? formal
          : kDebugMode
          ? manifest
                .listAssets()
                .where(
                  (p) =>
                      p.startsWith('assets/fixtures/') && p.endsWith('.json'),
                )
                .toList()
          : <String>[];
      final definitions = parsePuzzleDefinitions([
        for (final path in sources) await rootBundle.loadString(path),
      ]);
      DailyCatalog? daily;
      String? dailyError;
      if (manifest.listAssets().contains('assets/catalog/daily.json')) {
        try {
          daily = DailyCatalog.parse(
            await rootBundle.loadString('assets/catalog/daily.json'),
            definitions,
          );
        } on FormatException {
          dailyError = 'invalid';
        }
      } else {
        dailyError = 'missing';
      }
      var library = ContentLibrary(
        main: {
          for (final p in definitions.values.where((p) => p.mode == 'main'))
            p.mainLevel!: p,
        },
        daily: daily,
        dailyError: dailyError,
        engineering: formal.isEmpty && kDebugMode,
      );
      const requestedScenario = String.fromEnvironment('POURLUNE_SCENARIO');
      final scenario = kDebugMode ? requestedScenario : '';
      const requestedDatabase = String.fromEnvironment('POURLUNE_DATABASE');
      final filename = requestedDatabase.isNotEmpty
          ? requestedDatabase
          : scenario.isNotEmpty
          ? 'b02_$scenario.sqlite'
          : 'pourlune_dev.sqlite';
      store = await GameStore.open('${await getDatabasesPath()}/$filename');
      if (scenario.isNotEmpty) {
        development = await DevelopmentScenario.prepare(
          scenario,
          definitions.values.toList(),
          store,
        );
        library = development!.library;
      }
      final sounds = pendingAudio = GameAudio();
      final c = GameController(
        store,
        library: library,
        clock: development?.now,
        onFeedback: (feedback) => unawaited(
          sounds.play(switch (feedback) {
            GameFeedback.select => GameSound.select,
            GameFeedback.pour => GameSound.pour,
            GameFeedback.error => GameSound.error,
            GameFeedback.complete => GameSound.win,
          }),
        ),
      );
      await c.initialize();
      if (!mounted) {
        c.dispose();
        await sounds.dispose();
        await store.close();
        return;
      }
      setState(() {
        controller = c;
        audio = sounds;
      });
    } catch (_) {
      await pendingAudio?.dispose();
      await store?.close();
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    if (audio != null) unawaited(audio!.dispose());
    controller?.store.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c != null) {
      return PourluneApp(
        controller: c,
        audio: audio,
        advanceTestDay: development == null
            ? null
            : () {
                development!.advanceDay();
                c.setForeground(true);
              },
      );
    }
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: failed
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.openFailed),
                            FilledButton(
                              onPressed: _open,
                              child: Text(l.retry),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
