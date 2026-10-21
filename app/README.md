# Pourlune offline client — B01 + B02

Actual Flutter iOS/Android app, local pure Dart core and sqflite SQLite. B01 and B02 are independently accepted within their documented engineering scope; see `docs/development/review/B02-acceptance.md` for checks and limits. Default debug content is **three engineering fixtures**, with missing levels visibly unavailable. Production content, art/audio and SDKs remain B03/B04 work. Development drawings and launcher icons are probes.

Use Flutter **3.47.2** (`d3b14c876900e553bc736ca19295fc09e3853e8e`), Dart **3.13.2**. `.flutter-version` and both lockfiles fix the toolchain/dependencies. Runtime dependencies remain Flutter localization, intl 0.20.3, sqflite 2.4.5 and local core; host tests also use sqflite_common_ffi 2.4.4 against actual SQLite files. No new B02 dependency.

Development IDs: iOS `dev.pourlune.pourluneDev`, Android `dev.pourlune.pourlune_dev`; Android minimum24, iOS minimum15.0. These settings do not establish minimum-device coverage or production signing.

Run from `app/` (tests load relative fixtures):

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter run -d <device-id>
```

Run core checks separately from `../packages/pourlune_core/`. GitHub Actions discovers the added tests; remote CI is unverified until the acceptance owner pushes. Build artifacts remain ignored under `build/`.

Home/chapters use actual saved progress, locks, missing content and Replay identity. Ordinary and daily slots are independent. First-level guidance restricts its three introductory actions; Skip preserves the board. Settings contains a separate practice board. Hints search the **current board** in a cancellable isolate (2-second wall budget including startup, 50,000-state search budget); only exhausted search means proven unsolvable. A suggestion selects the source and never pours automatically. Token, instance and revision checks discard stale replies, and board/navigation/background changes cancel the worker.

SQLite schema **v3** explicitly migrates B01 v1/v2 records without clearing them. It retains both slots, original definitions, undo history/extra entitlement, receipts, unlocks, pieces and qualification count; v3 adds tutorial completion, six preferences, separately acknowledged piece reveals, and consumed Next targets. Snapshot schema2 accepts old schema1; unfinished guidance verifies the bounded guided prefix. R01 history checks remain. Unknown newer DB schemas fail without deletion. A corrupt slot uses its valid same-instance backup; a completed backup can continue settlement navigation. Whole-file database repair is not implemented.

Every accepted action saves a full snapshot. Win + progress + piece/stamp + receipt are one transaction. Failed saves show the actual failure; Retry saves before queued navigation, Stay cancels navigation. Replay again and the shared Play/Today actions join that same first-intent queue; their resume, replacement confirmation and content/unlock checks run after persistence succeeds. Repeated clicks or Home cannot replace the first queued intent; after Stay a new first intent is accepted. A failed new-instance write retains its candidate for Retry. A failed replacement leaves the old persisted slot intact and freezes its actions until the pending candidate is saved. Debug disk-failure injection throws after SQL writes, before COMMIT; it is a real rollback. Reset requires explicit secondary confirmation, clears progress atomically and keeps preferences. Reveal acknowledgement is separate from piece ownership and survives revisits.

The qualification counter is preserved. `canCheckInterstitialOnNext` only identifies a fresh ordinary settlement with a valid next target; it excludes chapter/final/replay/daily and opportunities already left/restored. It neither displays an ad nor resets the counter. No ad entitlement is simulated.

Production daily catalog: `assets/catalog/daily.json`, strict schema1, version, calendar epoch and ordered unique daily IDs, at least30 definitions. Puzzle assets go under `assets/puzzles/`. Missing/malformed catalog leaves saved daily and ordinary games available. Date mapping uses UTC-normalized calendar components; each daily instance embeds its date, platform timezone name + offset, catalog version and full definition. No IANA identifier is claimed. Only today starts a new game; historical dates are read-only. Default bundle currently has no production daily catalog. Release mode excludes fixture fallback and debug controls.

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

English ARB drives product copy and bottle semantics. The six preferences persist; audio tracks are unavailable pending production assets. Privacy/support actions accurately explain the missing approved destinations and never send to placeholders. Host narrow/2x checks are foundational, not full device, screen-reader speech or production visual acceptance. No SDK, release signing, store submission or production performance certification is implied.
