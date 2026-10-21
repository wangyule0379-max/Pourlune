import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'game_screen.dart';

class PourluneApp extends StatelessWidget {
  const PourluneApp({
    super.key,
    required this.controller,
    this.puzzles = const [],
    this.textScaler,
    this.advanceTestDay,
  });
  final GameController controller;
  final List<Puzzle> puzzles;
  final TextScaler? textScaler;
  final VoidCallback? advanceTestDay;
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          primary: ink,
          surface: cream,
        ),
        scaffoldBackgroundColor: controller.settings.strongContrast
            ? Colors.white
            : cream,
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
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
      ),
    ),
  );
}
