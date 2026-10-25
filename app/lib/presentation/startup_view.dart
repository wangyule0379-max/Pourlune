import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'bottle.dart';
import 'knit_components.dart';

// Also used by native Launch/Normal themes and the engine container storyboard.
const startupBackground = Color(0xff82dff1);
const startupMarkSize = Size(176, 176 * 776 / 1943);

/// Matches the native static launch frame. Local readiness alone opens Home.
class StartupView extends StatelessWidget {
  const StartupView({super.key, required this.failed, required this.onRetry});
  final bool failed;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final brand = Semantics(
      label: 'Pourlune',
      header: true,
      child: KnitArt(
        name: 'logo',
        width: startupMarkSize.width,
        height: startupMarkSize.height,
      ),
    );
    return Scaffold(
      backgroundColor: startupBackground,
      body: failed
          ? SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      brand,
                      const SizedBox(height: 24),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l.openFailed,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ink, fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('startup-retry'),
                        onPressed: onRetry,
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(child: brand),
    );
  }
}
