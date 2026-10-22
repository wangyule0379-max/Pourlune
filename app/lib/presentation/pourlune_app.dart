import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../application/game_audio.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'motion.dart';
import 'game_screen.dart';
import 'knit_components.dart';

class PourluneApp extends StatelessWidget {
  const PourluneApp({
    super.key,
    required this.controller,
    this.puzzles = const [],
    this.textScaler,
    this.advanceTestDay,
    this.audio,
  });
  final GameController controller;
  final List<Puzzle> puzzles;
  final TextScaler? textScaler;
  final VoidCallback? advanceTestDay;
  final GameAudio? audio;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      title: 'Pourlune Dev',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          primary: ink,
          surface: cream,
        ),
        scaffoldBackgroundColor: controller.settings.strongContrast
            ? Colors.white
            : const Color(0xff82dff1),
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const KnitRouteTransitions(),
          },
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Nunito',
          bodyColor: ink,
          displayColor: ink,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style:
              FilledButton.styleFrom(
                minimumSize: const Size(48, 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: ink,
                disabledBackgroundColor: Colors.transparent,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ).copyWith(
                backgroundBuilder: (context, states, child) =>
                    knitButtonBackground(context, states, child, primary: true),
              ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style:
              OutlinedButton.styleFrom(
                minimumSize: const Size(48, 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: ink,
                side: BorderSide.none,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ).copyWith(
                backgroundBuilder: (context, states, child) =>
                    knitButtonBackground(
                      context,
                      states,
                      child,
                      primary: false,
                    ),
              ),
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(backgroundBuilder: knitPressFeedback),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48))
              .copyWith(backgroundBuilder: knitPressFeedback),
        ),
      ),
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: textScaler ?? data.textScaler,
            disableAnimations:
                data.disableAnimations || controller.settings.reducedMotion,
          ),
          child: child!,
        );
      },
      home: GameScreen(
        controller: controller,
        puzzles: puzzles,
        advanceTestDay: advanceTestDay,
        audio: audio,
      ),
    ),
  );
}
