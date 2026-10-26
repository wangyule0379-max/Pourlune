import 'package:flutter/material.dart';
import 'package:pourlune_core/pourlune_core.dart';

import '../application/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'board_page.dart';
import 'bottle.dart';
import 'reference_extra_art.dart';
import 'parallel_navigation/knitted_switch.dart';
import 'parallel_navigation/navigation_materials.dart';
import 'parallel_navigation/settings_reference_art.dart';

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
          ('haptics', l.haptics, Icons.waving_hand_rounded),
          ('reduced_motion', l.reducedMotion, Icons.directions_run_rounded),
          ('color_symbols', l.colorSymbols, Icons.palette_rounded),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          foregroundColor: destructive ? const Color(0xffa42d3a) : ink,
        ),
        onPressed: action,
        child: Row(
          children: [
            _SettingsIcon(icon, destructive: destructive),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            SettingsChevronArt(destructive: destructive),
          ],
        ),
      ),
    );
    return NavigationMaterials(
      secondarySurfaceKind: ExtraSurfaceKind.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationPanel(
            kind: ExtraSurfaceKind.settings,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    _SettingRow(
                      key: Key('setting-${settings[i].$1}'),
                      label: settings[i].$2,
                      icon: settings[i].$3,
                      reducedMotion: c.settings.reducedMotion,
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
          const SizedBox(height: 12),
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
            'reset-progress',
            l.resetProgress,
            Icons.restart_alt_rounded,
            c.busy || c.phase == SavePhase.failed ? null : onReset,
            destructive: true,
          ),
          link(
            'feedback',
            l.feedback,
            Icons.mail_outline_rounded,
            c.busy ? null : onFeedback,
          ),
          link(
            'licenses',
            l.licenses,
            Icons.description_outlined,
            () =>
                showLicensePage(context: context, applicationName: 'Pourlune'),
          ),
          NavigationPanel(
            kind: ExtraSurfaceKind.settings,
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
                const SizedBox(height: 8),
                Text(l.audioInfo),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            const String.fromEnvironment('POURLUNE_VERSION_NAME').isEmpty ||
                    const String.fromEnvironment('POURLUNE_VERSION_CODE')
                        .isEmpty
                ? 'Pourlune'
                : l.versionInfo(
                    const String.fromEnvironment('POURLUNE_VERSION_NAME'),
                    const String.fromEnvironment('POURLUNE_VERSION_CODE'),
                  ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.reducedMotion,
  });
  final String label;
  final IconData icon;
  final bool value, reducedMotion;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 62),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _SettingsIcon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              KnittedSwitch(
                value: value,
                onChanged: onChanged,
                semanticLabel: label,
                reducedMotion: reducedMotion,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon, {this.destructive = false});
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final source = switch (icon) {
      Icons.volume_up_rounded => const Rect.fromLTWH(62, 186, 55, 54),
      Icons.music_note_rounded => const Rect.fromLTWH(62, 267, 55, 54),
      Icons.waving_hand_rounded => const Rect.fromLTWH(59, 345, 59, 56),
      Icons.directions_run_rounded => const Rect.fromLTWH(59, 426, 59, 58),
      Icons.palette_rounded => const Rect.fromLTWH(59, 510, 59, 58),
      Icons.contrast_rounded => const Rect.fromLTWH(59, 590, 59, 57),
      Icons.school_rounded => const Rect.fromLTWH(60, 711, 60, 53),
      Icons.shield_outlined => const Rect.fromLTWH(64, 799, 52, 56),
      Icons.restart_alt_rounded => const Rect.fromLTWH(63, 890, 53, 57),
      Icons.description_outlined => const Rect.fromLTWH(557, 741, 51, 56),
      _ => null,
    };
    return ExcludeSemantics(
      child: source != null
          ? SettingsReferenceIcon(source: source, destructive: destructive)
          : SizedBox(
              width: 36,
              height: 38,
              child: Icon(icon, size: 32, color: const Color(0xff0a78ce)),
            ),
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
    return NavigationMaterials(
      secondarySurfaceKind: ExtraSurfaceKind.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationPanel(
            kind: ExtraSurfaceKind.settings,
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
                  } else if (state.tutorial?.active != true &&
                      state.board[index].isNotEmpty) {
                    setState(() => selected = index);
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
                    onPressed: () =>
                        setState(() => demo = state.skipTutorial()),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ExcludeSemantics(child: Icon(Icons.arrow_back_rounded)),
                const SizedBox(width: 8),
                Flexible(child: Text(l.rulesBack, textAlign: TextAlign.center)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
