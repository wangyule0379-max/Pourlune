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

Firebase now uses the explicit per-invocation environment wrapper in `../tools/validation/README.md`. Default `none` still builds offline without local config. Real files live only in ignored `config/firebase/{dev,prod}/{ios,android}/`; the native build guard cross-checks the public registration matrix, native file, actual bundle/package and Dart Options. `POURLUNE_FIREBASE_NATIVE_READY=true` alone is rejected. The wrapper creates the matching `POURLUNE_FIREBASE_ENV`, Options and native-ready values temporarily and disables ads for this validation batch. Explicit production is compile-only with `com.pourlune.app`; default/QA identities stay independent. Client files contain public API keys but are kept out of repository/logs; service-account credentials are never required. Actual SDK initialization, uploader exit, console receipt and independent acceptance are separate conclusions in `../docs/development/deliveries/firebase-integration.md`.

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

## B05 internal candidate validation

B05 does not assign a production identity, increment the store version, or enable real services. Current internal version remains0.4.0+4. Android `flutter build apk --profile` is signed with the development debug certificate; `flutter build appbundle --release` currently has no release signing config. iOS `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --profile --no-codesign` and `--release --no-codesign` compile device-targeted products without producing installable distribution artifacts. Profile/release runtime performance cannot be assessed on iOS Simulator. Keep build outputs ignored.

Native B05 runners use a separate `dev.pourlune.b05Validation` identity through an external `XCODE_XCCONFIG_FILE`, never overwrite the ordinary review app, and only clear `b05_*` QA databases. Setup, standalone same-install SIGKILL/launch command and evidence copying: `../tools/validation/README.md`. E2E command from app/: `XCODE_XCCONFIG_FILE=/tmp/pourlune-b05.xcconfig FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test integration_test/b05_candidate_test.dart -d <simulator-id>`. Formal bundled content, seeded progress and controlled advertising inputs are labeled in every report. The main.dart default target does not import either B05 test entrypoint.

B05 author evidence/AC matrix/release and device handoff live under `../docs/development/evidence/B05/` and `../docs/development/deliveries/B05.md`. An execution report is not independent acceptance, actual ad display/earned/Firebase verification, or permission to publish. CI remains the existing fixed-toolchain test/debug-build workflow; B05 candidate compilation and native evidence are local runs, with remote statuses reported separately.

## Flame two-bottle and patch sample (debug only)

The local sample uses exact `flame: 1.38.2` (Flutter >=3.41, Dart >=3.11; this project stays on Flutter3.47.2/Dart3.13.2). It is a partial rendering experiment, not a complete-board migration. `main.dart` does not import it. No Forge2D, physics service, new audio framework, SDK configuration, or new artwork is added.

From app/, on the dedicated QA device:

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter run -t lib/development/flame_sample_main.dart -d <qa-device> --dart-define=POURLUNE_DATABASE=flame_sample.sqlite --dart-define=POURLUNE_AD_MODE=disabled
```

The guard requires debug and the exact named database. The two stores are `flame_sample.sqlite` (bottles) and `flame_patch.sqlite` (reward). Keep them separate from ordinary/Firebase/M/B05 databases. Existing sample data restores on startup; only explicit QA reset buttons replace or reset their own state.

The two visible bottles are core indices0/2 from a legal, versioned four-bottle engineering fixture. The other color and empty buffer remain in the authoritative board. Versions10001–10004 are QA definitions for 1–4 units, replay instances cannot grant first-clear rewards. Direction changes the projection only. Reset/Replay use the existing controller and SQLite; tapping the selected bottle cancels selection. The rejection probe makes an always-invalid same-index request; ordinary same-bottle taps still cancel selection.

Patch placement uses actual bundled main1–4: three labeled QA settlements, then one real legal final move of a prepared main4. Only a committed receipt can unlock placement. Reveal acknowledgement is also saved before the visual flight; animation callbacks do not write rewards or submit moves. Explicit Replay visual changes no progress; re-entry/cold restore shows the saved placement without replay. The sample-wide settings are owned only by the bottles store; both panels receive reduced motion through MediaQuery (including the OS preference), so a busy patch write cannot create a second conflicting preference. Pending placement reservations are invalidated on cancellation/background; a later save completion restores the committed piece without starting an old flight. Unrevealed or failed-save pieces stay on their source even in reduced mode. Tapping empty bottle-canvas space cancels selection. Source image, world-horizontal liquid clipping, the transformed spout, finite stream and curves are custom sample code; Flame supplies the loop/effect lifecycle, not a fluid simulation.

`integration_test/flame_sample_app.dart` is a separate standalone instrumentation entry with real Flutter pointer gestures, PNG/frame timing and file commands. It does not represent a passing DDS integration-test run. Root helper `tools/validation/flame_sample.py` is restricted to iOS `9B172C50-E5CB-4F3F-8F16-0A3DB04F495D` and Android `emulator-5584`; actions `state`, `route`, `capture`, `prepare-restore`, `startups`. Its command files stay inside the QA sandbox. Do not point it at an ordinary installation. Same-install termination/relaunch proves a different property from installing a new binary.

Independent acceptance and the user's approval of the sample's appearance are required before extending to the complete board. M01–M08 remains a separate, unfinished checkpoint. Evidence and actual run results belong in `../docs/development/deliveries/flame-sample.md`; source existence is not a performance, native-audio, physical-haptics or release conclusion.

## Page transitions (T01–T06)

The existing controller remains the navigation authority. `presentation/motion.dart` uses the exactly pinned official `animations 3.0.0`: FadeThrough for independent destinations, horizontal SharedAxis for play/next/rules, scaled SharedAxis for collection details and settlement, and FadeScale for all custom dialogs. Transparent fills preserve the knitted background. The bounded host retires older outgoing pages and immediately disposes departing boards; page identity includes instance ID, never move revision. Scroll storage is scoped to each instance and scene; returning to the same instance/destination restores its offset, while a new instance starts at the top. Framework license routes use the same SharedAxis through the existing Material theme. No Material widget library migration is required for these transition-only widgets.

Focused host checks: `flutter test test/page_transitions_test.dart test/motion_primitives_test.dart test/motion_polish_test.dart test/startup_motion_test.dart`. Run Flutter CLI and native builds serially with `FIREBASE_ANALYTICS_WITHOUT_ADID=1`.

`integration_test/page_transitions_app.dart` is an isolated standalone debug QA runner using actual Flutter pointer gestures, bundled formal content and sqflite. It requires `--dart-define=POURLUNE_DATABASE=page_transitions.sqlite --dart-define=POURLUNE_AD_MODE=disabled`; it clears only that database and writes `page-transitions/route.json` plus PNGs under `getDatabasesPath()`. Controlled progress prepares main002/004/020/060; it is not natural progression, real advertising evidence or a production entrypoint. Use the dedicated transition devices recorded in `docs/development/deliveries/ui-transition-handoff.md`; preserve the ordinary, Firebase and Flame installations. The iOS runner uses external `/tmp/pourlune-transitions.xcconfig` containing only `PRODUCT_BUNDLE_IDENTIFIER = dev.pourlune.transitionsValidation`. Commands from app/:

```sh
XCODE_XCCONFIG_FILE=/tmp/pourlune-transitions.xcconfig FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --simulator --debug -t integration_test/page_transitions_app.dart --dart-define=POURLUNE_DATABASE=page_transitions.sqlite --dart-define=POURLUNE_AD_MODE=disabled
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build apk --debug -t integration_test/page_transitions_app.dart --dart-define=POURLUNE_DATABASE=page_transitions.sqlite --dart-define=POURLUNE_AD_MODE=disabled
```

Copy screenshots/reports before any runner replacement. Execution evidence and limits live in `../docs/development/deliveries/page-transitions.md`; architecture owns independent acceptance.

### Native startup continuity (T-R01)

Native iOS LaunchScreen/Main, Android legacy and API31+ light/night launch themes, and the Flutter initialization shell share #82DFF1 and the existing centered wordmark. Native density exports are checked with the bundled Pillow Python using `tools/assets/startup_assets.py`; `--write` is only for an intentional regeneration. No timed hold or simulated progress is added. Startup failure retains a real Retry control.

`tools/validation/startup_capture.py ios|android light|dark` is restricted to the transition devices and `dev.pourlune.transitionsr01`; first install the isolated normal `lib/main.dart` candidate using `ui_transition_r01.sqlite`, Firebase none and ads disabled. The Android applicationId overlay exists only in the R01 source copy; iOS uses an external xcconfig. It force-stops/terminates only that identity, records actual native launch and checks the named database. Preserve all existing review installations. `startup_frames.swift <video> <frames-dir> [seconds-limit]` extracts actual recorded frames with timestamps; `startup_frame_check.py <frames-dir> <evidence-dir>` describes sampled colors, not startup or frame-rate performance. See `../docs/development/evidence/page-transitions/T-R01/repair-report.md` for results and limitations.
