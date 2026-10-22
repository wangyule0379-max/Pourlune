# Pourlune client — B04 optional services

Actual Flutter iOS/Android app, local pure Dart core and sqflite SQLite. B01 and B02 are independently accepted within their documented engineering scope; see `docs/development/review/B02-acceptance.md` for checks and limits. Default content is **60 main +30 independent daily candidates** from `assets/puzzles/` and `assets/catalog/daily.json`; original main012 stays v1 and newly authored main021 is v2. B03 replaces development visual probes with layered candidate art, original synthesized local WAVs, Nunito/OFL and platform icon exports. Candidate content/visuals remain subject to independent acceptance and the reference artwork commercial rights remain unconfirmed. B04 adds optional service adapters, official test advertising and configured support entries; real Firebase/project/support handoff remains external.

Use Flutter **3.47.2** (`d3b14c876900e553bc736ca19295fc09e3853e8e`), Dart **3.13.2**. `.flutter-version` and both lockfiles fix the toolchain/dependencies. Runtime dependencies are Flutter localization, intl 0.20.3, sqflite 2.4.5, audioplayers 6.8.1 and local core; host tests also use sqflite_common_ffi 2.4.4 against actual SQLite files. Audioplayers provides local asset playback; the lockfile pins its platform dependencies.

Development IDs: iOS `dev.pourlune.pourluneDev`, Android `dev.pourlune.pourlune_dev`; Android minimum24, iOS minimum15.0. These settings do not establish minimum-device coverage or production signing.

Run from `app/` (tests load relative fixtures):

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter run -d <device-id>
```

Run core checks separately from `../packages/pourlune_core/`. GitHub Actions discovers the added tests; remote CI is unverified until the acceptance owner pushes. Build artifacts remain ignored under `build/`.

Home/chapters use actual saved progress, locks, missing content and Replay identity. Ordinary and daily slots are independent. First-level guidance restricts its three introductory actions; Skip preserves the board. Settings contains a separate practice board. Hints search the **current board** in a cancellable isolate (2-second wall budget including startup, 50,000-state search budget); only exhausted search means proven unsolvable. A suggestion selects the source and never pours automatically. Token, instance and revision checks discard stale replies, and board/navigation/background changes cancel the worker.

SQLite schema **v5** explicitly migrates B01 v1/v2 records without clearing them. It retains both slots, original definitions, undo history/extra entitlement, receipts, unlocks, pieces and qualification count; v3 adds tutorial completion, six preferences, separately acknowledged piece reveals, and consumed Next targets. Snapshot schema2 accepts old schema1; unfinished guidance verifies the bounded guided prefix. R01 history checks remain. Unknown newer DB schemas fail without deletion. A corrupt slot uses its valid same-instance backup; a completed backup can continue settlement navigation. Whole-file database repair is not implemented.

Every accepted action saves a full snapshot. Win + progress + piece/stamp + receipt are one transaction. Failed saves show the actual failure; Retry saves before queued navigation, Stay cancels navigation. Replay again and the shared Play/Today actions join that same first-intent queue; their resume, replacement confirmation and content/unlock checks run after persistence succeeds. Repeated clicks or Home cannot replace the first queued intent; after Stay a new first intent is accepted. A failed new-instance write retains its candidate for Retry. A failed replacement leaves the old persisted slot intact and freezes its actions until the pending candidate is saved. Debug disk-failure injection throws after SQL writes, before COMMIT; it is a real rollback. Reset requires explicit secondary confirmation, clears progress atomically and keeps preferences. Reveal acknowledgement is separate from piece ownership and survives revisits.

The qualification counter is preserved. `canCheckInterstitialOnNext` only identifies a fresh ordinary settlement with a valid next target; it excludes chapter/final/replay/daily and opportunities already left/restored. B04 checks it only on the first Next from a fresh settlement after any patch acknowledgement. Actual full-screen show records start the shared180s interval; only actual interstitial show resets qualification. Inventory alone never shows. Reward entitlement requires a valid SDK confirmation and SQLite transaction.

Production daily catalog: `assets/catalog/daily.json`, strict schema1, version, calendar epoch and ordered unique daily IDs, at least30 definitions. Puzzle assets go under `assets/puzzles/`. Missing/malformed catalog leaves saved daily and ordinary games available. Date mapping uses UTC-normalized calendar components; each daily instance embeds its date, platform timezone name + offset, catalog version and full definition. No IANA identifier is claimed. Only today starts a new game; historical dates are read-only. Default candidate catalog version1, epoch2026-01-01, ordered daily001–030 is bundled. Release mode excludes fixture fallback and debug controls.

For native integration with real sqflite and isolate:

```sh
flutter test integration_test/offline_test.dart -d <device-id> --dart-define=POURLUNE_DATABASE=b01_integration.sqlite
flutter test integration_test/history_recovery_test.dart -d <device-id> --dart-define=POURLUNE_DATABASE=b01_recovery.sqlite
flutter test integration_test/offline_flows_test.dart -d <device-id> --dart-define=POURLUNE_SCENARIO=flow --dart-define=POURLUNE_DATABASE=b02_native_flow.sqlite
flutter test integration_test/replay_navigation_test.dart -d <device-id> --dart-define=POURLUNE_SCENARIO=flow --dart-define=POURLUNE_DATABASE=b02_native_r01_replay.sqlite
```

`offline_flows_test` also accepts `milestone` and `final` with matching `b02_native_*` database names. It deletes **only its named integration database at test start**. Framework lifecycle injection there proves observer/controller handling, not OS background/termination. Test-runner reinstall behavior is not process-restart evidence.

Normal app scenarios (debug only): `flow` (tutorial start), `milestone` (19 actual seeded settlements + active20), `final` (59 + active60), `old-daily` (yesterday after one move). **All60 aliases reuse the two-color sample, and the two daily aliases reuse that sample: these are flow fixtures, never60+30 production puzzles.** The UI labels engineering content; a debug Home button advances an injected day. Seeds go through store settlement transactions once, marked in metadata, never reset on launch. Default scenario databases are `b02_<scenario>.sqlite`; use an isolated `POURLUNE_DATABASE` filename for manual work.

```sh
flutter build ios --simulator --debug --dart-define=POURLUNE_SCENARIO=flow --dart-define=POURLUNE_DATABASE=b02_manual_flow.sqlite
```

For genuine cold restoration install this normal build, play and wait for Saved, terminate/launch the same installed app, then Continue. **Do not reinstall or clear data between compared launches.** Exact device, commands, results and limits are in [B02 delivery](../docs/development/deliveries/B02.md); B01 evidence remains in [B01 delivery](../docs/development/deliveries/B01.md).

English ARB drives product copy and bottle semantics. The six preferences persist; music and sound use local assets and stop on Pause/background; reduced motion shortens the pour to180ms and reveals fade without scale. Normal pour presentation is900ms, independent of the already updated full board and atomic persistence. Board actions wait for presentation/storage; lifecycle/navigation cancels the presentation to the full state. Privacy/support actions accurately explain the missing approved destinations and never send to placeholders. Native B03 evidence, content replay, 18 scene states,15 milestones,320px/2x checks and limitations are indexed in `../docs/development/deliveries/B03.md`; they do not establish physical-device, screen-reader speech, human difficulty or independent visual acceptance. No SDK, release signing, store submission or production performance certification is implied.


B03 commands from app (use a disposable named integration database):
```sh
flutter test integration_test/b03_runtime_test.dart -d <device-id> --dart-define=POURLUNE_DATABASE=b03_runtime.sqlite
flutter test integration_test/b03_audio_native_test.dart -d <device-id>
```
The B03 runtime harness clears only `b03_runtime.sqlite`, uses default Bootstrap with no scenario/injected clock, and records actual rendered UI to the app data sandbox `Documents/b03-evidence/`. Automated settlement setup is distinguished from UI-driven reference actions. The audio probe proves actual backend decode/transport, not subjective listening. Normal App cold-restart evidence is separate from integration-runner installation.

Candidate images and byte-identical runtime copies are checked from repository root with the bundled Python/Pillow runtime:
```sh
python3 tools/assets/visual_manifest.py --check
python3 -m unittest discover -s tools/assets -v
```
The image verifier does not change pixels. After an intentional geometry/resource change explicitly refresh with `--write`, then review the diff and run `--check`. Platform icon exports use `tools/assets/export_icons.py` (RGB conversion +LANCZOS resize only). Audio source/metrics, font OFL and per-file provenance are under `docs/design/production-candidates/`, with run evidence under `docs/development/evidence/B03/`. Content commands are in `../tools/content/README.md`.

B03 final quality fixes: the rounded bottle window uses horizontal area quantiles in upright/tilted poses so visible fluid volume is conserved; both system and app Reduce Motion suppress pour/selection/rejection displacement. Completion headings animate only after a saved receipt (700ms, reduced150ms); presentation never grants rewards. Final host suite82, native component calibration29 screenshots, plus ordinary App cold-restart and main1 completion proof. One deferred visual minor remains: same-color runs still display per-unit shape markers. See `../docs/development/evidence/B03/final-quality-review.md` for the sole fresh review and one RED→GREEN fix pass. This is not architecture acceptance.

B03 independent-acceptance repairs R01/R02 restore the approved welcome/Home/board/Pause composition with shared native knitted controls. Completion audio requires the same-instance saved receipt, clean phase, foreground, completion page and finished motion; Retry and stale-callback regressions use real SQLite. Latest checks and limits are in `../docs/development/evidence/B03-R01/repair-report.md`; the earlier82-test line above is historical, not the repair count.

```sh
flutter test integration_test/b03_r01_design_test.dart -d <device-id> --dart-define=POURLUNE_DATABASE=b03_r01_runtime.sqlite
```
This clears only its named integration DB. The25 actual Flutter captures distinguish ordinary UI-driven main1–4 progression from explicit6/7-bottle QA setup. Normal App cold restoration is separately documented. UI asset inventory is independently checked from repository root with `python3 tools/assets/ui_manifest.py --check` alongside the existing visual checker (Pillow required). All reference-derived graphics remain candidates with rights UNCONFIRMED.


## B04 configuration and evidence boundaries

Version0.4.0+4. Exact SDK pins: google_mobile_ads9.2.0; firebase_core5.0.0, firebase_analytics13.0.0, firebase_crashlytics6.0.0, firebase_remote_config7.0.0; url_launcher6.3.3. Plugin native defaults remain Android24/iOS15. SPM resolves Firebase13.0.0/GMA13.11.0/UMP3.1.0; keep both native Package.resolved files. Use `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --simulator --debug` (SPM variable presence selects AnalyticsCore). Android FlutterFire plugins currently emit a built-in Kotlin migration warning; current build result is recorded in B04 evidence.

Debug uses Google's official sample App IDs and test interstitial/rewarded units. `--dart-define=POURLUNE_AD_MODE=disabled` disables ad capability. Release defaults to disabled. `POURLUNE_AD_MODE=production` requires both `POURLUNE_INTERSTITIAL_ID` / `POURLUNE_REWARDED_ID` and native owned App IDs; it rejects Google's test publisher. Set iOS App ID with ignored `ios/Flutter/Services.local.xcconfig` (`POURLUNE_ADMOB_APP_ID = ...`); Android Gradle property `POURLUNE_ADMOB_APP_ID` overrides the test default. Both layers must be configured and ownership verified before production. Never exercise a production ad unit during development.

`POURLUNE_FIREBASE_OPTIONS` is a JSON Dart define containing the real platform apiKey/appId/messagingSenderId/projectId and optional storageBucket/iosBundleId. `POURLUNE_FIREBASE_NATIVE_READY=true` is additionally required after native project/configuration and symbols are verified. Options alone remain disabled. Values are public client configuration, not service-account credentials. Missing, malformed or platform-mismatched values disable Firebase without constructing product singletons. They do not prove project ownership. Native Google services/Crashlytics build IDs, plist target registration, symbol uploads and console validation remain required handoff steps; do not enable a production Options file alone and call integration complete. No fake native config or placeholder project is checked in.

Optional HTTPS support/policy and email are `POURLUNE_SUPPORT_URL`, `POURLUNE_PRIVACY_URL`, `POURLUNE_FEEDBACK_EMAIL`. Invalid/missing/example destinations remain unavailable. These entries open an external app after a player chooses them and never send feedback automatically. Draft pages are `../docs/support/`; they are not published or legally approved.

Analytics and Crashlytics are independent default-off local choices. Crash sharing explicitly includes cached earlier reports; automatic Crashlytics upload always remains off. Native SDK local caching and already queued transmissions cannot be revoked by Dart. UMP is the sole ad eligibility source, runs on a stable page, and exposes official privacy options when required. Non-personalized requests do not infer ATT or analytics permission; this build does not request tracking. Debug EEA probe: `--dart-define=POURLUNE_UMP_TEST_REGION=eea` (simulators are automatic test devices; physical test devices require `POURLUNE_UMP_TEST_DEVICE`). Do not reset consent in normal product flows.

Local schema4 adds attempts/origin snapshots, unique per-instance entitlements, full-screen timestamps, service choices and event dedup. Confirmation/grant is one transaction; closed alone never grants. Saved replaced-origin rewards require explicit exact-slot replacement. Startup open attempts become explained unconfirmed requests, without querying an imaginary SDK reward history. A received-but-unsaved confirmation only remains in memory; Retry while open, no recovery promise after process death. Optional product metrics persist best-effort alongside gameplay; a crash before their save can lose recent diagnostic duration/counts and does not affect progress/rewards.

B04 host boundary tests: `flutter test test/b04_*.dart`. Real-plugin probe (clears only its named disposable database):

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test integration_test/b04_services_native_test.dart -d <id> --dart-define=POURLUNE_DATABASE=b04_native.sqlite
```

The probe records real UMP eligibility, load outcomes, free action/save and separate privacy UI. Three explicit SQLite setup settlements unlock main4; they are not ad rewards. Real SDK display/grant is asserted only if inventory is actually available and actual callbacks arrive. Copy `Documents/b04-evidence/` before the integration runner uninstalls. B04 delivery separates host fakes, SQLite, linked plugins, Simulator, physical device and console scope. No production publish, signing, account creation or B05 work is included.

After an iOS build, generated `build/ios/SourcePackages/` contains upstream Dart examples/tests. Source formatting deliberately checks lib/test/integration_test only; do not format generated dependency copies or the pub cache. CI uses the same source scope. Local build evidence does not establish remote CI status.

B04 review adds session-only `pl_ad_continue`: after a known-shown ad closes, the first legal pour within120 accumulated foreground seconds is attributed once per display. Invalid actions do not count; background time is excluded, while exiting with no legal pour leaves only dismissal. Analytics withdrawal clears pending attribution. Hint requests use independent random identities and record cancellation once; tutorial complete/skip are emitted after their corresponding state transition is saved, including Retry.


### B04-R01/R02 repair boundary

`preShowTimeout` bounds only the wait for a show confirmation. After `onAdShowedFullScreenContent`, the timer is cancelled; background time and a late show-method Future cannot dispose the displayed handle or advance Next. Actual SDK dismissal/failure closes the session, and normal dismissal disposes the ad as Google recommends. The app-wide ServiceHub outlives page navigation; owner/engine shutdown is not a recovery promise for callbacks that were never saved.

Schema5 adds `fullscreen_attempts(show_id, kind, qualifying_boundary)` and monotonic qualifying total/consumed ordinals. Preparing is transactional before SDK show and does not consume anything. A confirmed fullscreen record consumes at most the interstitial's durable boundary, once. Later first clears stay qualified; rewarded shows never consume them. Next locks its first intent and refreshes the persisted count before deciding, avoiding a stale settlement count after Retry. Reset advances the consumed floor to the current total without rewinding ordinals, so an old pending write cannot consume new progress. Old retries retain the newest timestamp and cannot clear a different current intent.

Upgrade1/2/3/4→5 preserves saved slots, history, rewards, receipts and preferences. Its initial ordinal equals the exact legacy outstanding count; old consumed history is not fabricated. A schema4 uncertain intent has no known boundary or saved show fact: preserve its qualification, use the existing conservative180-second restart window, and do not infer a reward or actual display. Likewise a prepared schema5 attempt is not proof of show; a process lost before confirmation persisted cannot be silently backfilled from an imaginary SDK history. Retry while this process still owns the delivered callback uses the durable boundary.

Tests: `b04_architecture_regression_test.dart`, `b04_sdk_lifecycle_test.dart`, `b04_v4_migration_test.dart`, plus existing suites. The SDK contract uses actual google_mobile_ads9.2 Dart dispatch and production adapter with mocked native messages, including real dispose-removes-adId semantics; it is not a native ad success. Native `flutter test integration_test/b04_repairs_native_test.dart -d <id>` exercises actual sqflite and Flutter, but ads/lifecycle events are controlled test inputs and aliases reuse the reference fixture. It clears only b04_repairs_migration.sqlite and b04_repairs_flow.sqlite and writes Documents/b04-repairs-evidence. Actual inventory/earn/native-background validation and Firebase console work remain external pending scope. See `../docs/development/evidence/B04-R01-R02/repair-report.md`.
