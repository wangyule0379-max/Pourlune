import 'package:flutter/material.dart';

import '../application/game_controller.dart';

import 'package:pourlune_core/pourlune_core.dart';

import '../l10n/app_localizations.dart';
import '../services/ad_coordinator.dart';
import '../services/service_hub.dart';
import 'knit_components.dart';
import 'motion.dart';
import 'extra_bottle_modal.dart';
import 'reference_extra_art.dart';
import 'reference_play_art.dart';
import 'parallel_navigation/navigation_materials.dart';
import 'parallel_navigation/settings_reference_art.dart';

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
    const textStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      height: 1.1,
      fontWeight: FontWeight.w800,
    );
    final saving = controller.phase == SavePhase.saving;
    final dense = compact && MediaQuery.textScalerOf(context).scale(14) > 22.4;
    ButtonStyle actionStyle(bool primary) =>
        OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          foregroundColor: primary
              ? const Color(0xff133000)
              : const Color(0xff080a74),
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          textStyle: textStyle,
        ).copyWith(
          backgroundBuilder: (_, states, child) => Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: states.contains(WidgetState.disabled) ? .5 : 1,
                  child: ReferenceExtraSurface(
                    tileEdges: true,
                    kind: primary
                        ? ExtraSurfaceKind.primary
                        : ExtraSurfaceKind.secondary,
                  ),
                ),
              ),
              ?child,
            ],
          ),
        );
    final warning = Semantics(
      liveRegion: true,
      label: l.saveFailed,
      excludeSemantics: compact,
      child: Text(
        compact ? l.progressNotSaved : l.saveFailed,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
    final actions = [
      FilledButton(
        key: const Key('retry'),
        style: actionStyle(true),
        onPressed: saving ? null : controller.retry,
        child: Text(l.retry, textAlign: TextAlign.center),
      ),
      OutlinedButton(
        key: const Key('stay'),
        style: actionStyle(false),
        onPressed: saving ? null : controller.stayHere,
        child: Text(l.stayHere, textAlign: TextAlign.center),
      ),
    ];
    return Stack(
      children: [
        const Positioned.fill(child: ReferenceHintMaterial()),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: dense ? 2 : 12,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              double width(String value) {
                final p = TextPainter(
                  text: TextSpan(
                    text: value,
                    style: DefaultTextStyle.of(context).style.merge(textStyle),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final w = p.width;
                p.dispose();
                return w;
              }

              final inline =
                  compact &&
                  box.maxWidth >=
                      width(l.retry) +
                          width(l.stayHere) +
                          l.progressNotSaved
                              .split(' ')
                              .map(width)
                              .reduce((a, b) => a > b ? a : b) +
                          64;
              return inline
                  ? Row(
                      children: [
                        Expanded(child: warning),
                        const SizedBox(width: 8),
                        actions[0],
                        const SizedBox(width: 8),
                        actions[1],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        warning,
                        SizedBox(height: dense ? 0 : 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: actions,
                        ),
                      ],
                    );
            },
          ),
        ),
      ],
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
  final config = c.services?.config;
  final uri = feedback
      ? config?.feedback
      : privacy
      ? config?.privacy
      : config?.support;
  final message = uri == null
      ? l.supportUnavailable
      : feedback
      ? l.feedbackOpenFailed(uri.path)
      : l.supportOpenFailed;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showExtraBottle(BuildContext context, GameController c) async {
  if (c.directExtraBottleEnabled) {
    await c.watchExtraBottle();
    return;
  }
  final l = AppLocalizations.of(context), hub = c.services;
  if (!c.canWatchExtraBottle) {
    hub?.ads.blockedOpportunity(
      AdKind.rewarded,
      c.current?.extraBottleGranted == true
          ? 'entitlement'
          : hub.ads.blockedReason(AdKind.rewarded) ?? 'unknown',
    );
  }
  // The first sheet explains the exchange; only its explicit Watch starts it.
  final watch = await showKnitDialog<bool>(
    context: context,
    barrierColor: const Color(0x732069a4),
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
            ? l.noAdPrompt
            : l.noAdPrompt;
        final available = c.canWatchExtraBottle;
        final retry =
            hub?.config.adsConfigured == true &&
            c.current?.extraBottleGranted != true &&
            state != AdLoadState.loading;
        return ExtraBottleModal(
          unavailable: !available,
          title: available ? l.moreRoomTitle : l.adUnavailableTitle,
          body: available ? l.extraOfferBody : status,
          footnote: available ? l.extraOfferLimit : l.puzzleUnchanged,
          closeLabel: l.close,
          primaryLabel: available ? l.watchAdPlusBottle : l.tryAgain,
          primaryIcon: available
              ? const ReferenceExtraArt(
                  source: Rect.fromLTWH(100, 712, 54, 44),
                  radius: 6,
                )
              : null,
          secondaryLabel: available ? l.notNow : l.backToPuzzle,
          onPrimary: available
              ? () => Navigator.pop(context, true)
              : retry
              ? () async {
                  await hub?.prepareAdsPrivacy(force: true);
                  await ads?.retryTiming();
                  await ads?.preload(AdKind.rewarded);
                }
              : null,
          onSecondary: () => Navigator.pop(context, false),
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
      builder: (context, _) {
        final largeText = MediaQuery.textScalerOf(context).scale(22) > 44;
        return NavigationMaterials(
          child: Dialog(
            key: const Key('privacy-card'),
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(),
            elevation: 0,
            insetPadding: EdgeInsets.all(largeText ? 8 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: NavigationPanel(
                kind: ExtraSurfaceKind.pause,
                padding: EdgeInsets.all(largeText ? 16 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        key: const Key('privacy-details'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: SettingsReferenceIcon(
                                source: Rect.fromLTWH(64, 799, 52, 56),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l.privacyChoices,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l.yourProgress,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(l.localOnly),
                            const SizedBox(height: 16),
                            if (hub == null || !hub.firebaseReady)
                              Text(
                                hub?.reporting.configured == true
                                    ? l.crashUnavailableAnalyticsAvailable
                                    : l.servicesDisabled,
                              ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 12),
                            if (hub != null &&
                                (hub.privacySaveFailed ||
                                    hub.privacySyncFailed)) ...[
                              Text(
                                hub.reporting.configured &&
                                        !hub.privacySaveFailed
                                    ? l.privacyProviderSyncProblem
                                    : l.privacySaveProblem,
                              ),
                              OutlinedButton(
                                onPressed: hub.retryPrivacy,
                                child: Text(l.retry),
                              ),
                            ],
                            if (hub?.privacyBusy == true)
                              Text(l.adPrivacyChecking),
                            if (hub?.adPrivacyFailed == true)
                              Text(l.adPrivacyProblem),
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
                                        await hub.prepareAdsPrivacy(
                                          force: true,
                                        );
                                      },
                                child: Text(l.adPrivacyRetry),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  openSupportEntry(context, c, privacy: true),
                              child: Text(l.privacyPolicy),
                            ),
                            OutlinedButton(
                              onPressed: () => openSupportEntry(context, c),
                              child: Text(l.supportWebsite),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  openSupportEntry(context, c, feedback: true),
                              child: Text(l.feedback),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.close, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
