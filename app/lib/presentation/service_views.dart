import 'package:flutter/material.dart';

import '../application/game_controller.dart';

import 'package:pourlune_core/pourlune_core.dart';

import '../l10n/app_localizations.dart';
import '../services/ad_coordinator.dart';
import '../services/service_hub.dart';
import 'knit_components.dart';
import 'motion.dart';

class SaveFailureNotice extends StatelessWidget {
  const SaveFailureNotice({
    super.key,
    required this.controller,
    this.compact = false,
  });
  final GameController controller;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (compact) {
      return ColoredBox(
        color: const Color(0xfffff3d7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.saveFailed,
                  style: const TextStyle(fontSize: 14, height: 1.1),
                ),
              ),
            ),
            KnitIconButton(
              key: const Key('retry'),
              icon: Icons.refresh,
              label: l.retry,
              onPressed: controller.retry,
            ),
            KnitIconButton(
              key: const Key('stay'),
              icon: Icons.close,
              label: l.stayHere,
              onPressed: controller.stayHere,
            ),
          ],
        ),
      );
    }
    return KnitPanel(
      child: Column(
        children: [
          Text(l.saveFailed),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                key: const Key('retry'),
                onPressed: controller.retry,
                child: Text(l.retry),
              ),
              TextButton(
                key: const Key('stay'),
                onPressed: controller.stayHere,
                child: Text(l.stayHere),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> openSupportEntry(
  BuildContext context,
  GameController c, {
  bool privacy = false,
  bool feedback = false,
}) async {
  final ok =
      await c.services?.openSupport(privacy: privacy, feedback: feedback) ??
      false;
  if (!context.mounted || ok) return;
  final l = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l.supportUnavailable)));
}

Future<void> showExtraBottle(BuildContext context, GameController c) async {
  final l = AppLocalizations.of(context), hub = c.services;
  // The first sheet explains the exchange; only its explicit Watch starts it.
  final watch = await showKnitDialog<bool>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final ads = hub?.ads;
        final state = ads?.state(AdKind.rewarded);
        final reason = ads?.loadReasons[AdKind.rewarded];
        final status = c.current?.extraBottleGranted == true
            ? l.extraUsed
            : ads != null && ads.cooldown > Duration.zero
            ? l.adCooldown(ads.cooldown.inSeconds + 1)
            : state == AdLoadState.loading
            ? l.adLoading
            : reason == 'network'
            ? l.adNetwork
            : reason == 'no_fill'
            ? l.adNoFill
            : l.adUnavailable;
        return AlertDialog(
          title: Text(l.extraBottle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.extraExplain),
                const SizedBox(height: 12),
                if (!c.canWatchExtraBottle)
                  Text(status, key: const Key('extra-status')),
                if (!c.current!.extraBottleGranted &&
                    state != AdLoadState.loading &&
                    !c.canWatchExtraBottle)
                  TextButton(
                    onPressed: () async {
                      await hub?.prepareAdsPrivacy(force: true);
                      await ads?.retryTiming();
                      await ads?.preload(AdKind.rewarded);
                    },
                    child: Text(l.adRetry),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.notNow),
            ),
            FilledButton(
              key: const Key('watch-ad'),
              onPressed: c.canWatchExtraBottle
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text(l.watchAd),
            ),
          ],
        );
      },
    ),
  );
  if (watch == true) await c.watchExtraBottle();
}

Future<void> showPrivacyChoices(BuildContext context, GameController c) async {
  final l = AppLocalizations.of(context), hub = c.services;
  await showKnitDialog<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: c,
      builder: (context, _) => AlertDialog(
        title: Text(l.privacyChoices),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hub == null || !hub.firebaseReady) Text(l.servicesDisabled),
                SwitchListTile(
                  key: const Key('analytics-choice'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.analyticsChoice),
                  subtitle: Text(l.analyticsDetails),
                  value: hub?.choices.analytics ?? false,
                  onChanged: hub == null
                      ? null
                      : (v) => hub.updatePrivacy(
                          PrivacyChoices(
                            analytics: v,
                            crash: hub.choices.crash,
                          ),
                        ),
                ),
                SwitchListTile(
                  key: const Key('crash-choice'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.crashChoice),
                  subtitle: Text(l.crashDetails),
                  value: hub?.choices.crash ?? false,
                  onChanged: hub == null
                      ? null
                      : (v) => hub.updatePrivacy(
                          PrivacyChoices(
                            analytics: hub.choices.analytics,
                            crash: v,
                          ),
                        ),
                ),
                if (hub != null &&
                    (hub.privacySaveFailed || hub.privacySyncFailed)) ...[
                  Text(l.privacySaveProblem),
                  TextButton(onPressed: hub.retryPrivacy, child: Text(l.retry)),
                ],
                if (hub?.privacyBusy == true) Text(l.adPrivacyChecking),
                if (hub?.adPrivacyFailed == true) Text(l.adPrivacyProblem),
                if (hub?.adPrivacyRequired == true)
                  OutlinedButton(
                    onPressed: hub!.privacyBusy
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await hub.showAdPrivacy();
                          },
                    child: Text(l.adPrivacyOptions),
                  ),
                if (hub != null)
                  OutlinedButton(
                    onPressed: hub.privacyBusy
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await hub.prepareAdsPrivacy(force: true);
                          },
                    child: Text(l.adPrivacyRetry),
                  ),
                TextButton(
                  onPressed: () => openSupportEntry(context, c, privacy: true),
                  child: Text(l.privacyPolicy),
                ),
                TextButton(
                  onPressed: () => openSupportEntry(context, c),
                  child: Text(l.supportWebsite),
                ),
                TextButton(
                  onPressed: () => openSupportEntry(context, c, feedback: true),
                  child: Text(l.feedback),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    ),
  );
}

class RewardStatus extends StatelessWidget {
  const RewardStatus({
    super.key,
    required this.controller,
    this.compact = false,
  });
  final GameController controller;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = controller, l = AppLocalizations.of(context);
    String title(GameInstance state) => state.slot == 'daily'
        ? '${l.dailyPuzzle} · ${state.puzzleDate}'
        : l.level(state.puzzle.mainLevel!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.rewardSaveFailed || c.rewardIssue != null)
          KnitPanel(
            padding: EdgeInsets.all(compact ? 4 : 20),
            child: Column(
              children: [
                Text(
                  c.rewardSaveFailed &&
                          c.rewardIssue == 'confirmation_save_failed'
                      ? l.rewardSavingFailed
                      : l.rewardOperationFailed,
                ),
                TextButton(
                  key: const Key('retry-reward'),
                  onPressed: c.busy ? null : c.retryReward,
                  child: Text(l.retry),
                ),
              ],
            ),
          ),
        for (final attempt in c.pendingRewards)
          KnitPanel(
            key: Key('pending-${attempt.id}'),
            padding: EdgeInsets.all(compact ? 4 : 20),
            child: Column(
              children: [
                if (compact)
                  Text(
                    attempt.unconfirmed ? l.rewardUnconfirmed : l.rewardRestore,
                  ),
                Text(
                  title(attempt.origin),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!compact)
                  Text(
                    attempt.unconfirmed ? l.rewardUnconfirmed : l.rewardRestore,
                  ),
                TextButton(
                  onPressed: c.busy
                      ? null
                      : () async {
                          if (attempt.unconfirmed) {
                            await c.dismissUnconfirmedReward(attempt.id);
                            return;
                          }
                          final replacement = attempt.origin.slot == 'ordinary'
                              ? c.ordinary?.id
                              : c.daily?.id;
                          final yes = await showKnitDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              scrollable: true,
                              title: Text(l.restoreRewardTitle),
                              content: Text(
                                '${l.restoreRewardBody}\n\n${title(attempt.origin)}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(l.notNow),
                                ),
                                FilledButton(
                                  key: const Key('confirm-reward-restore'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l.resumeGame),
                                ),
                              ],
                            ),
                          );
                          if (yes == true) {
                            await c.resumeRewardedPuzzle(
                              attempt.id,
                              replacingInstance: replacement,
                            );
                          }
                        },
                  child: Text(
                    attempt.unconfirmed ? l.endRequest : l.resumeReward,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
