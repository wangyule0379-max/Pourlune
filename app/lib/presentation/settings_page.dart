import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'board_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.onReset,
    required this.onPrivacy,
    required this.onFeedback,
  });
  final GameController controller;
  final VoidCallback onReset, onPrivacy, onFeedback;
  @override
  Widget build(BuildContext context) {
    final c = controller,
        l = AppLocalizations.of(context),
        names = {
          'music': l.music,
          'sound': l.sound,
          'haptics': l.haptics,
          'reduced_motion': l.reducedMotion,
          'color_symbols': l.colorSymbols,
          'strong_contrast': l.strongContrast,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in c.settings.toJson().entries)
          SwitchListTile(
            key: Key('setting-${entry.key}'),
            title: Text(names[entry.key]!),
            value: entry.value,
            onChanged: c.busy || c.phase == SavePhase.failed
                ? null
                : (value) => c.updateSetting(entry.key, value),
          ),
        Text(l.audioInfo),
        OutlinedButton(
          key: const Key('rules'),
          onPressed: c.busy ? null : () => c.navigate(GamePage.rules),
          child: Text(l.howToPlay),
        ),
        OutlinedButton(
          key: const Key('privacy'),
          onPressed: c.busy ? null : onPrivacy,
          child: Text(l.privacyChoices),
        ),
        OutlinedButton(
          key: const Key('feedback'),
          onPressed: c.busy ? null : onFeedback,
          child: Text(l.feedback),
        ),
        OutlinedButton(
          key: const Key('reset-progress'),
          onPressed: c.busy || c.phase == SavePhase.failed ? null : onReset,
          child: Text(l.resetProgress),
        ),
        OutlinedButton(
          key: const Key('licenses'),
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'Pourlune'),
          child: Text(l.licenses),
        ),
        Text(l.yourProgress, style: Theme.of(context).textTheme.titleLarge),
        Text(l.localOnly),
        Text(
          l.versionInfo(
            const String.fromEnvironment(
              'FLUTTER_BUILD_NAME',
              defaultValue: '0.3.0',
            ),
            const String.fromEnvironment(
              'FLUTTER_BUILD_NUMBER',
              defaultValue: '3',
            ),
          ),
        ),
      ],
    );
  }
}

class RulesPage extends StatefulWidget {
  const RulesPage({super.key, required this.controller});
  final GameController controller;
  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  GameInstance? demo;
  int? selected;
  @override
  void initState() {
    super.initState();
    final p = widget.controller.library.main[1];
    if (p != null) {
      demo = GameInstance.create(id: 'rules-demo', puzzle: p, tutorial: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), c = widget.controller, state = demo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.rulesTitle, style: Theme.of(context).textTheme.headlineSmall),
        Text(l.rulesBody),
        Text(l.demoNote),
        if (state != null) ...[
          if (state.tutorial?.active ?? false)
            Text(
              l.lessonAction(
                state.tutorial!.step + 1,
                state.tutorialLength,
                state.puzzle.referenceMoves[state.tutorial!.step].from + 1,
                state.puzzle.referenceMoves[state.tutorial!.step].to + 1,
              ),
            ),
          BoardView(
            state: state,
            selected: selected,
            keyPrefix: 'demo-bottle',
            settings: c.settings,
            onTap: (index) {
              if (selected == null) {
                if (state.board[index].isNotEmpty) {
                  setState(() => selected = index);
                }
              } else if (selected == index) {
                setState(() => selected = null);
              } else {
                final result = state.pour(selected!, index);
                if (result.changed) {
                  setState(() {
                    demo = result.state;
                    selected = null;
                  });
                }
              }
            },
          ),
          Wrap(
            spacing: 8,
            children: [
              if (state.tutorial?.active ?? false)
                TextButton(
                  key: const Key('demo-skip'),
                  onPressed: () => setState(() => demo = state.skipTutorial()),
                  child: Text(l.skip),
                ),
              TextButton(
                key: const Key('demo-restart'),
                onPressed: () => setState(() {
                  demo = GameInstance.create(
                    id: 'rules-demo',
                    puzzle: state.puzzle,
                    tutorial: true,
                  );
                  selected = null;
                }),
                child: Text(l.demoReset),
              ),
            ],
          ),
        ] else
          Text(l.contentUnavailable),
        OutlinedButton(
          key: const Key('rules-back'),
          onPressed: () => c.navigate(GamePage.settings),
          child: Text(l.rulesBack),
        ),
      ],
    );
  }
}
