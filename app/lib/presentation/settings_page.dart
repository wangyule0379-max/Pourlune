import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'board_page.dart';
import 'bottle.dart';
import 'knit_components.dart';

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
        settings = [
          ('sound', l.sound, Icons.volume_up_rounded),
          ('music', l.music, Icons.music_note_rounded),
          ('haptics', l.haptics, Icons.vibration_rounded),
          ('reduced_motion', l.reducedMotion, Icons.animation_rounded),
          ('color_symbols', l.colorSymbols, Icons.category_rounded),
          ('strong_contrast', l.strongContrast, Icons.contrast_rounded),
        ];
    Widget link(
      String key,
      String label,
      IconData icon,
      VoidCallback? action, {
      bool destructive = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        key: Key(key),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          foregroundColor: destructive ? const Color(0xffa42d3a) : ink,
        ),
        onPressed: action,
        child: Row(
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KnitPanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (var i = 0; i < settings.length; i++) ...[
                  if (i != 0)
                    const Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                      color: Color(0xffe8d6b8),
                    ),
                  SwitchListTile(
                    key: Key('setting-${settings[i].$1}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    secondary: Icon(settings[i].$3, color: ink),
                    title: Text(
                      settings[i].$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    activeThumbColor: cream,
                    activeTrackColor: const Color(0xff91bd68),
                    inactiveThumbColor: cream,
                    inactiveTrackColor: const Color(0xffc8c0e0),
                    value: c.settings.toJson()[settings[i].$1]!,
                    onChanged: c.busy || c.phase == SavePhase.failed
                        ? null
                        : (value) => c.updateSetting(settings[i].$1, value),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Text(
            l.audioInfo,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        link(
          'rules',
          l.howToPlay,
          Icons.school_rounded,
          c.busy ? null : () => c.navigate(GamePage.rules),
        ),
        link(
          'privacy',
          l.privacyChoices,
          Icons.shield_outlined,
          c.busy ? null : onPrivacy,
        ),
        link(
          'feedback',
          l.feedback,
          Icons.mail_outline_rounded,
          c.busy ? null : onFeedback,
        ),
        link(
          'reset-progress',
          l.resetProgress,
          Icons.restart_alt_rounded,
          c.busy || c.phase == SavePhase.failed ? null : onReset,
          destructive: true,
        ),
        link(
          'licenses',
          l.licenses,
          Icons.description_outlined,
          () => showLicensePage(context: context, applicationName: 'Pourlune'),
        ),
        KnitPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.yourProgress,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(l.localOnly),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          const String.fromEnvironment('POURLUNE_VERSION_NAME').isEmpty ||
                  const String.fromEnvironment('POURLUNE_VERSION_CODE').isEmpty
              ? 'Pourlune'
              : l.versionInfo(
                  const String.fromEnvironment('POURLUNE_VERSION_NAME'),
                  const String.fromEnvironment('POURLUNE_VERSION_CODE'),
                ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
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
        KnitPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.rulesTitle,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(l.rulesBody, style: const TextStyle(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.demoNote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
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
            runSpacing: 8,
            alignment: WrapAlignment.center,
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
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('rules-back'),
          onPressed: () => c.navigate(GamePage.settings),
          child: Text(l.rulesBack),
        ),
      ],
    );
  }
}
