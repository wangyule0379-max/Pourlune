# Pourlune B01 offline development slice

This is an actual Flutter iOS/Android application connected to `../packages/pourlune_core` and SQLite through sqflite. The menu exposes **three engineering fixtures**, not a complete main campaign. Bottles, labels and symbols are drawn from runtime state; drawings, launcher icons and development controls are probes, not accepted production art.

Use Flutter **3.47.2** (framework `d3b14c876900e553bc736ca19295fc09e3853e8e`), Dart **3.13.2**. `.flutter-version` records the SDK; app/core lockfiles record resolved dependencies. Direct runtime dependencies: Flutter localization, intl 0.20.3, sqflite 2.4.5, local core. Host tests additionally use sqflite_common_ffi 2.4.4 (real native SQLite files).

Temporary development identities: iOS `dev.pourlune.pourluneDev`, Android `dev.pourlune.pourlune_dev`. These are not production identifiers or signing setup. Android minimum API 24; iOS minimum 15.0. Official support and dependency references are recorded in the B01 delivery. Minimum versions are build settings, not a claim of device coverage at those minimums.

From this directory:

```sh
flutter pub get --enforce-lockfile
flutter run -d <device-id>
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Core checks run separately in `../packages/pourlune_core`. Host tests must run from `app/` because test fixtures use relative paths. Platform artifacts are in ignored `build/`; rebuild them locally.

For native plugin integration on the existing iOS simulator (or another available device), use an isolated development DB name:

```sh
flutter test integration_test/offline_test.dart -d 4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2 --dart-define=POURLUNE_DATABASE=b01_integration.sqlite
flutter build ios --simulator --debug --dart-define=POURLUNE_DATABASE=b01_integration.sqlite
```

The integration test uses the real UI/core/plugin. It pours, undoes, pauses, injects a real transaction failure, retries, completes a sample, and leaves L12 after two saved moves. Installation/test-runner lifecycle may clear test data: for a process-restart check use the normal built app, play two moves, wait for **Saved on this device**, terminate and launch the same installed app, then Resume. Do not reinstall/clear its data between these two launches. See evidence and exact observations in `../docs/development/deliveries/B01.md`. `POURLUNE_DATABASE` is a development-only filename override; default is `pourlune_dev.sqlite` in sqflite's database directory.

The **Development: fail next disk write** control throws after an actual SQL write and before COMMIT. SQLite rolls back. The failed banner keeps current state; free operations can update that state, Retry persists the latest full result, Stay here cancels pending navigation, and leaving waits for successful persistence. When replacing a sample fails, its old persisted slot stays intact and actions on that old board remain frozen until the candidate save is retried. There is no pretend ad reward button.

Data schema v2 contains ordinary/daily slots, the embedded definition/history/extra entitlement, same-instance backup snapshots, first-completion records, unlocks, pieces, qualification counter, date stamps and instance receipts. Schema v1 is an explicit test baseline with nonempty slots/progress; its migration retains those records and derives unlocks/pieces. No shipped user database is claimed. Unknown newer schema fails to open without deletion. Snapshots with a won undo-history frame or a non-original first history frame are invalid (B01-R01). The first frame may include an already earned empty extra bottle. A bad slot falls back to its valid backup; both bad exposes recovery notice for that slot only. Settlement backs up the completed board so recovery cannot reopen an already rewarded game.

Settlement atomically persists the won instance and all grants. Stable puzzle IDs deduplicate first clears across versions; instance receipts deduplicate repeated settlement across connections/restarts. The first ten main first clears do not increment advertising qualification; subsequent first clears accumulate. B01 never resets this counter or displays ads; SDK confirmation/reset belongs to B04. Replay/daily do not increment main progress. Local progress deliberately exposes sample-derived data, even if selecting a later fixture leaves gaps.

Deferred by the approved batch: hint isolate, teaching/full daily/navigation in B02; 60+30 verified content, production assets and animations in B03; Firebase/AdMob and their real callbacks in B04. No release signing/store submission, performance, Android device execution, screen-reader speech or production visual acceptance is implied. GitHub Actions configuration is present but its remote execution remains unverified until pushed by the acceptance owner.
