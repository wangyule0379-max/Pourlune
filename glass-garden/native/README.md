# Local QA mobile shells

Both use **dev.pourlune.glassgarden.localqa**, version0.1.0(1), an unregistered independent development identity. They do not replace `com.pourlune.app`, register a store app or use production signing. The first builds contain the accepted S3 web candidate and **no ad/statistics SDK**.

```sh
# glass-garden/ — verify and stage one frozen candidate to generated ignored assets
node scripts/stage-native.mjs s3-r2

# native/android/ — Java21, Gradle9.3.1, AGP9.1.0, compile/target36, min26
./gradlew :app:assembleDebug --offline --no-daemon --max-workers=2

# glass-garden/ — Xcode26.6/SDK26.5, min iOS16; no boot or signing
xcodebuild -project native/ios/GlassGarden.xcodeproj -scheme GlassGarden -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build/native/ios-derived -jobs 2 CODE_SIGNING_ALLOWED=NO build

# Same iOS asset-server implementation, exercised on macOS without a simulator
swiftc -swift-version 5 native/ios/GlassGarden/AssetServer.swift qa/AssetServerCheck.swift -o build/native/asset-server-check
build/native/asset-server-check
```

First Android offline attempt identified uncached AGP transitive dependencies; a normal authenticated-free HTTPS dependency fetch completed, then offline rebuild passed. The application dependency lock is committed. No TLS/proxy/DNS or SDK version workarounds were made. SDK XML/deprecation warnings remain separate from the successful build.

Android serves bundled resources from the fixed virtual HTTPS `appassets.androidplatform.net/assets/web/` origin, with AndroidX WebKit1.15.0. Only that prefix can navigate or return content; file/content access and mixed content are disabled. ESM MIME is explicit. This baseline has no INTERNET permission. Platform packaging omits only the vendor `.gitignore`; all414 shipped web files match S3. Native lifecycle forwards to the existing controller; system Back preserves modal/navigation semantics. Insets are handled by the native root without changing game geometry.

iOS uses WKWebView's persistent data store and a bundled read-only server bound specifically to127.0.0.1:43177. The origin is fixed across restarts; occupied-port failure offers Retry instead of silently creating a new origin/save. Only GET/HEAD are served; decoded traversal, symlink escape, directory listing and writes are refused. Both `.mjs` and Worker scripts have JavaScript MIME. No cloud/gameplay server or broad ATS exception exists. Safe-area layout keeps system controls outside the game; foreground/background callbacks reach the same controller. The simulator bundle contains all415 S3 web files unchanged.

Host tests actually request GET/module/HEAD/404/symlink/traversal/POST and close only their ephemeral listener/temp files in cleanup. They do not establish iOS runtime, disk eviction, lifecycle, native audio or physical performance. Debug web inspection is enabled only in debug builds.

All actual simulator/emulator operations belong to the existing Use Computer chat. Before a batch, confirm Fruplop/other-task release; reuse the recorded matching Pourlune device and keep at most one device running. Record UDID/serial, never clear old apps/data, and use finally/trap cleanup for the device this batch starts. F9 is protected. Compilation does not authorize booting another device while one is occupied.

The private JavaScript GameMunchies0.3.0 package was subsequently found and hash-verified (see `../sdk-manifest.json`). It is ignored outside source control. The separate `s4b-consent-final` candidate includes the unchanged eight-file SDK and uses QA version0.1.0(2). Stage it with `node scripts/stage-native.mjs s4b-consent-final`; Android requires `-PgardenQaServices=true`, and iOS requires `SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG GARDEN_QA_SERVICES'`. Without those explicit flags services stay disabled. This variant permits only the actual GameMunchies API in addition to local assets; it adds Android INTERNET permission. No native advertising SDK is included yet.

The SDK has one owner, strict persistent storage without a memory fallback, and statistics default off. New rounds are reported only after the game transaction commits. Declining immediately stops sharing while its preference save is pending; a persisted reset token and scoped durable SDK-clear acknowledgement prevent an old queue from reviving after allow→decline→allow or a restart. Configuration and cooldown are independent of optional statistics. The connected notice requires a new informed choice for the earlier offline-only allowed state; an existing decline stays declined. The 13 real-SDK directional tests use controlled HTTP and IndexedDB; the read-only iOS/Android live configuration probe performs GET only. Neither proves native events, ad delivery or physical-device behavior.

## Rewarded-ad developer candidate

Current native self-test target: build/native-candidates/s4c-reward-selftest-2-guard/, QA0.1.0(3). Its web source is frozen s4c-reward-selftest-2 (package with --sdk --ads). Both compile flags above now require a staged official-test-ad notice; mismatches fail the build. Use scripts/freeze-native.py with web tag, built app path and optional new native tag after serial builds. It verifies both payloads, QA identity/version and absence of Android AD_ID permissions before creating an immutable directory. It never installs or signs. Intermediate candidates remain intact.

Native dependencies retain GoogleMobileAds13.11.0/UMP3.1.0 on iOS, Android Google Mobile Ads25.5.0/UMP4.0.0. Their exact SPM/Gradle locks are committed. IDs are Google's platform-specific sample AppID and rewarded unit; PG, non-personalized requests, delayed measurement initialization, no ATT request and both Android advertising-ID permission removals remain. UMP update runs each launch; eligibility is checked before load/show and required privacy options are exposed. No forced geography or consent reset is used. Native callbacks include raw error domain/code diagnostics and adapter initialization status. Those logs still need a real device batch and contemporaneous routing evidence; a compile is not an ad-timeout fix.

Only the trusted main local document can send native commands. Load can cancel, including while remote configuration is pending; no callback timeout destroys a shown ad. Earned callbacks are locally retained until game receipt acknowledgement; repeat native observations keep the first event ID/time. Callback routing survives backgrounding, and an unreadable game save does not acknowledge/discard an earned receipt. A restored native-state response closes unconfirmed interrupted attempts without fabricating rewards. Optional statistics acknowledgement is separate from game/close processing.

The game binds a durable attempt to a stable puzzle identity before any load/show command. Reward receipt plus exactly one extra ordinary empty bottle commit in the same game transaction. Restart changes the statistical round but retains puzzle entitlement; Undo/history and process restore retain it too. A completed puzzle replay creates a fresh identity. Late rewards can affect the retained original puzzle, never another current puzzle. A strict generated scene integration adds only an active-definition parameter and its restore/layout references; original rules/render/game and the100 definitions remain byte-identical. Reward-only geometry keeps liquid units and bottle widths unchanged, including the14→15 board.

Developer checks: 52 core/UI/controller tests and14 official-SDK directional tests pass. Controlled browser receipts on390×844/320×568 exercise actual rendered1/16/39/61/100 boards; they are not native ad callbacks. Real native startup, ads/UMP callbacks, test-scope backend readback and hardware behavior remain pending. See the delivery report and browser-s4-reward evidence.

Official integration references: [iOS rewarded](https://developers.google.com/admob/ios/rewarded), [Android rewarded](https://developers.google.com/admob/android/rewarded), [iOS UMP](https://developers.google.com/admob/ios/privacy), [Android UMP](https://developers.google.com/admob/android/privacy), and the platform quick-start pages. These establish callback/consent contracts, not runtime success.

## Migration and effects developer checkpoint

Latest QA target is build/native-candidates/s4d-migration-effects-selftest-4-retry/, version0.1.0(4), frozen web s4d-migration-effects-selftest-4. It supersedes earlier self-test targets without modifying them. The native bridge version2 build guards require the unchanged licensed music asset and the matching privacy notice. Stage using the existing script, compile serially with explicit QA services flags, then freeze to a new name.

Legacy readers copy only this app's fixed old SQLite/main/WAL/SHM into an owned temporary directory and open the copy read-only. Invalid or unreadable originals are preserved and cannot silently start a fresh game. New-campaign saves are authoritative after the first successful import. Old60 progress and private Dart SDK state remain intact and are not remapped into the100-level campaign or JS SDK. Host fixture tests do not establish a device upgrade.

Music uses native ambient/background gates and the unchanged approved Dream Culture file with visible attribution. Haptics use system selection feedback without a new Android permission. Foreground recovery also works after a failed local page load and Retry. WebAudio transient voices are stopped on interruption. Late rewards refresh only the same retained scene and preserve a Settings/Pause page. Core69 and actual-SDK14 controlled tests pass; browser reports use simulated native ports. Native ads, real audio/haptics, routing/backend and process recovery remain pending; complete interstitial strategy is the next integration stage.

## Fullscreen-policy developer checkpoint

Current frozen target: build/native-candidates/s5-fullscreen-selftest-2-privacy/, QA0.1.0(5), web s5-fullscreen-selftest-2, bridge protocol3. The strict stage guards reject older web bridges. Both official test formats are present, with one fullscreen route; unsolicited interstitial preloads never present consent forms. Actual load_requested occurs only at the Google SDK load call. UserDefaults/file receipts keep original callback IDs and times until acknowledgement.

The existing first-clear/Next qualification,20/40 protection and180s shared rewarded/interstitial clock are ported. Prepare captures a durable ordinal boundary, actual show consumes only that boundary, optional statistics never controls valid reward persistence, and actual shown routes survive background/elapsed time. Read-only old public clock import prevents migration from resetting the shared floor. A ready ad may show only on the eligible first Next; missing/late cache never delays or hijacks play. Native and hardware runtime checks remain pending. See the delivery and fullscreen-policy evidence for exact hashes and limitations.

The new CI workflow tests80 core/UI checks and compiles services-disabled shells from tracked copied assets. It does not upload the private SDK or claim its15 locally executed controlled tests ran remotely. --copied-inputs-only packaging is restricted to ci- names without --sdk/--ads; the local frozen release path still checks original source/prototype inputs. Native app privacy manifests are bundled and vendor manifests remain untouched; live store disclosures still need final runtime comparison.

Manifest-only refinement: use s5-fullscreen-selftest-2-privacy-final for future device self-test. It differs from the prior tag only in the root app manifest: the unused required-reason API key is omitted rather than left empty or populated with invented API reasons.445 iOS files, Android APK and the entire frozen web payload are unchanged; previous candidates stay immutable. See privacy-final-difference.json and preflight-triage.md. This has not been installed or accepted as a full native product.

Retry repair target: build/native-candidates/s4f-native-retry-selftest-1/, QA0.1.0(6), same frozen web s5-fullscreen-selftest-2. Healthy local asset listener is reused across page/renderer Retry; failed owned listener is canceled before retry. Real host socket tests cover20 same-origin retries, occupied-port rejection and recovery after only that test's owner releases it. No port sharing or fallback is introduced. Actual device/WK recovery still awaits the queued batch.

Final queued QA6 target is s4f-native-retry-selftest-2-version. Both native bridges derive the SDK version dimension from installed metadata rather than a stale literal; freezing rejects an APK whose DEX lacks the expected version. This supersedes selftest1 without overwriting it and leaves the same434 frozen web files unchanged.
