# Validation utilities

## Firebase environment selection

Run from the repository root with Python3.11+ (`.venv/bin/python`); no extra
Python dependency, Firebase CLI login, or service-account file is needed.
Public authority is `docs/development/evidence/firebase-integration/registration.json`.
Real client files are ignored, local, and permission600:

```text
app/config/firebase/{dev,prod}/ios/GoogleService-Info.plist
app/config/firebase/{dev,prod}/ios/options.json
app/config/firebase/{dev,prod}/android/google-services.json
app/config/firebase/{dev,prod}/android/options.json
```

Each `options.json` contains the exact values from that native client file.
Shape example (placeholders deliberately fail validation):

```json
{"apiKey":"COPY_NATIVE_CLIENT_KEY","appId":"COPY_GOOGLE_APP_ID","projectId":"COPY_PROJECT_ID","messagingSenderId":"COPY_PROJECT_NUMBER","storageBucket":"COPY_STORAGE_BUCKET","iosBundleId":"COPY_IOS_BUNDLE_ID"}
```

Android omits `iosBundleId`; omit `storageBucket` if absent in the native file.
Never use service-account JSON. The CLI cross-checks registration, native
identity, platform, sender, Options and key; only identity/hash summaries print.

```sh
.venv/bin/python -m unittest discover -s tools/validation -p 'test_firebase_config.py' -v
.venv/bin/python tools/validation/firebase_config.py --environment dev --platform ios --config-dir app/config/firebase
.venv/bin/python tools/validation/firebase_config.py --environment dev --platform android --config-dir app/config/firebase
.venv/bin/python tools/validation/firebase_config.py --environment prod --platform ios --config-dir app/config/firebase
.venv/bin/python tools/validation/firebase_config.py --environment prod --platform android --config-dir app/config/firebase
```

Use the invocation wrapper, which validates before Flutter, generates temporary
private Dart definitions/Xcode inputs, and passes Gradle selection per process:

```sh
.venv/bin/python tools/validation/firebase_build.py --environment dev --platform ios --flutter /Users/wangyule/development/flutter/bin/flutter -- build ios --simulator --debug
.venv/bin/python tools/validation/firebase_build.py --environment dev --platform android --flutter /Users/wangyule/development/flutter/bin/flutter -- build apk --debug
.venv/bin/python tools/validation/firebase_build.py --environment prod --platform ios --flutter /Users/wangyule/development/flutter/bin/flutter -- build ios --simulator --debug
.venv/bin/python tools/validation/firebase_build.py --environment prod --platform android --flutter /Users/wangyule/development/flutter/bin/flutter -- build apk --debug
.venv/bin/python tools/validation/firebase_build.py --environment none --platform ios --flutter /Users/wangyule/development/flutter/bin/flutter -- build ios --simulator --debug
```

`none` needs no files and removes a previous iOS plist; Android does not apply
Google Services/Crashlytics plugins or package their old generated resources.
Default direct Flutter invocations also select `none`. Selected builds reject
native-ready alone, mismatched Dart definitions/native ID and duplicate Firebase
overrides. A rejected selection does not replace the existing product resource.
No root JSON/plist swapping occurs. iOS uses a temporary `XCODE_XCCONFIG_FILE`;
do not combine this wrapper with another override. Native identity is unchanged
for default/QA, dev uses the registered development IDs, and explicit prod uses
`com.pourlune.app` on both platforms. Prod accepts builds of the default entrypoint
only. Do not install/run production artifacts for these tests.
Production accepts positional `lib/main.dart` and the usual explicit target
forms only for that exact entrypoint, then pins the final Flutter target.
Supply other production option values inline (`--build-name=...`), not as
standalone values; dev retains diagnostic entrypoints. Use fresh diagnostic IDs
for every command and check response PID/UTC before treating it as new evidence.

Add `--upload-symbols` before `--` for **dev iOS only**. The last build phase calls
the active SPM checkout's official `Crashlytics/upload-symbols`, checks matching
Mach-O/dSYM UUIDs, and saves a public receipt at ignored
`app/config/firebase/dev/ios/symbol-upload.json`. Selected iOS builds produce
dSYMs and disable the debug dylib so the executable and dSYM inputs agree;
default builds keep existing settings. Config and symbol xcfilelists declare
the actual inputs. Default/prod do not upload; the wrapper rejects prod uploads.
Android debug has no R8 or Dart obfuscation, so mapping/Dart-symbol upload is
inapplicable. Production mapping upload is explicitly disabled. A successful
uploader exit is separate from console receipt/readable-stack acceptance.

The isolated standalone diagnostic delegates to the **normal main/Bootstrap**,
uses formal content and `firebase_dev_native.sqlite`, and has no shipping buttons:

```sh
.venv/bin/python tools/validation/firebase_build.py --environment dev --platform ios --upload-symbols --flutter /Users/wangyule/development/flutter/bin/flutter -- build ios --simulator --debug -t integration_test/firebase_services_app.dart --dart-define=POURLUNE_DATABASE=firebase_dev_native.sqlite
```

Install only on a Pourlune-specific simulator/AVD. For Android substitute
`--platform android`, omit `--upload-symbols`, and use `build apk --debug`.
Detached native launch followed by same-install restart supplies crash evidence;
rebuilding/reinstalling is not that restart comparison. In the app's
`getDatabasesPath()/firebase-evidence/`, write `command.json` with e.g.
`{"id":"inspect-1","action":"state"}`; the app deletes the command and writes
`inspect-1.json`. Actions: state, privacy (analytics/crash booleans), start, move,
undo, resume, event, nonfatal, crash, pending, remote. `remote` forces a debug-only
zero-interval fetch, then uses the unchanged production policy parser. `event`
logs the same identity twice. `crash` writes its receipt before native termination.
`checkForUnsentReports` can cache a result within a process; check deletion on a
fresh launch, and do not treat the bool as transport/console proof. Copy evidence
before reinstall; simctl can relocate the container, so resolve its current path.

DebugView uses iOS launch argument `-FIRDebugEnabled` / ending
`-FIRDebugDisabled`, Android `setprop debug.firebase.analytics.app
dev.pourlune.pourlune_dev` / ending `.none.`. Restore both privacy choices to
false, debug properties and any test-only emulator network changes afterward.
No production events, RC template, ads, terms, IAM or billing changes are part
of these commands. Results and remaining external limits:
`docs/development/deliveries/firebase-integration.md`.

## B05 lifecycle

`b05_lifecycle.py` uses Python's standard library and macOS `xcrun simctl`. Run from the project root with `.venv/bin/python` (Python3.11+). It requires the standalone **QA entrypoint already installed**; it never installs an app or operates on the ordinary development identity. It is not a production app interface or a Firebase/AdMob transport.

1. Create an external Xcode override containing `PRODUCT_BUNDLE_IDENTIFIER = dev.pourlune.b05Validation`, for example `/tmp/pourlune-b05.xcconfig`. Do not modify production project identity.
2. From `app/`:

   ```sh
   XCODE_XCCONFIG_FILE=/tmp/pourlune-b05.xcconfig FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --simulator --debug -t integration_test/b05_lifecycle_app.dart
   xcrun simctl install <simulator-id> build/ios/iphonesimulator/Runner.app
   ```

3. From the project root:

   ```sh
   .venv/bin/python tools/validation/b05_lifecycle.py --device <simulator-id> --out docs/development/evidence/B05/lifecycle-repeat
   ```

The QA entrypoint deletes only `b05_lifecycle.sqlite` when an explicit prepare command resets its QA state. The runner pins the QA bundle, checks the PID's executable path, and uses SIGKILL at seven save/reveal boundaries plus an active900ms animation. Every launch asserts the same container and executable. It checks exact snapshots, both-slot preservation, SQL integrity/schema5, one receipt/award, an observed active SceneArt reveal followed by interruption/re-entry/acknowledgment/another cold launch without repeat, controlled saved/unconfirmed/uncommitted reward outcomes, and10 move/undo/immediate hint-cancel cycles. Receipt barriers block only this test binary for30s so the host can kill an actually open transaction; they are not production delays. No mocked database is used. The ordinary `dev.pourlune.pourluneDev` app and `b04_review_r2.sqlite` are outside its scope.

The Python runner copies JSON/PNG evidence and command results. Choose a fresh --out directory for every run; a previous successful JSON in a reused directory is historical and cannot certify a new failed run. Final success requires the current command exit0 and current B05_LIFECYCLE_PASS marker. Do not run with `python -O`: assertions are acceptance checks. Screenshots produced immediately after a kill may depict the last completed capture; authoritative restore assertions are JSON/SQL, and later `inspect` creates a new render capture. The native integration runner can uninstall its own QA app at teardown; copy its evidence before the end. This is why the bundle override matters.

`app/integration_test/b05_candidate_test.dart` is the separate actual Flutter/sqflite five-flow/short-screen suite. It uses formal bundled60+30 puzzles, explicitly seeded prior progress and controlled ad callbacks. Run with the same QA identity override, then copy `Documents/b05-candidate-evidence/` before teardown. Its12 branch is transaction-failure/Retry; the standalone lifecycle runner supplies actual process-death coverage. Never label either controlled callback test as a real SDK ad reward.

Focused regression: add `--reveal-only` to run just the reveal interruption/acknowledgment chain; it writes reveal-only.json and B05_REVEAL_ONLY_PASS, never the full lifecycle success marker. The final B05 run uses the complete matrix.


## BR01 compile-only beta candidates

`beta_build.py` freezes current main-entrypoint production-ID release outputs in a
new ignored `build/` subfolder; it refuses to replace candidates or write outside
that tree. It uses validated existing **prod** Firebase client config through
`firebase_build.py`, never runs production, uploads symbols, installs, uploads to
stores, registers keys, or enables ads. Analytics/crash choices remain separately
off by default; Remote Config and embedded SDK infrastructure can still process
data. This is the existing production compile selection, not a zero-data build.
No private client files belong in Git or logs.

From root, after obtaining the serial Flutter/SPM CLI window:

```sh
cd app
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter pub get --enforce-lockfile
cd ..
.venv/bin/python tools/validation/beta_build.py --platform ios --output build/beta-candidates/0.5.0-5/ios --flutter /Users/wangyule/development/flutter/bin/flutter
.venv/bin/python tools/validation/beta_build.py --platform android --output build/beta-candidates/0.5.0-5/android --flutter /Users/wangyule/development/flutter/bin/flutter
```

Use a fresh output path on retry; failed directories retain redacted build logs.
The version comes from `app/pubspec.yaml`; before future distribution compare the
number to actual uploaded builds and increment it, never overwrite a frozen pack.
`candidate.json` plus `sources.json` pin the artifact, build number and dirty source
bytes, including locks. By default the tool demands unsigned outputs. The explicit iOS profile option
reuses an existing verified identity for local export; neither mode submits. The iOS device app is not an IPA or a Simulator app. AAB needs a
real upload-key JAR signature, not APK `apksigner`; debug signing does not qualify.

For iOS signing, reuse the authorized Team T7U878Z8H6 distribution identity in
Keychain with a **Pourlune-only** App Store profile for com.pourlune.app. Do not use
FishPilot/GetDoneFrame profiles, create private keys, revoke certificates or ask
Xcode to create missing signing assets automatically. Once profile/account/legal
requirements are verified, prepare an archive with the same production selection,
identity, source version and no-AdID environment; archive/export is an explicit, separately
recorded local operation, using the optional existing-profile argument below. Preserve the
archive, dSYM, export options, actual codesign/entitlements and IPA SHA; inspect
before upload. A matching profile and an existing certificate are prerequisites,
not proof that an archive/export succeeds.

For Android signing, the owner selects an existing authorized upload key **locally**
and unlocks it without posting passwords, keystores or service-account JSON in
chat/Git. Keep signing outside the repo; use Java `jarsigner` password environment
or protected password-file options, never a literal secret argument or shell
trace. Copy the unsigned AAB to a new named signed path, verify its signer SHA256
against the intended upload key/Play record, validate with official bundletool,
and freeze a new manifest. Existing app-signing keys belonging to FishPilot are
not to be reset or repurposed silently. No key generation is part of BR01.

`bundletool-all-1.18.3.jar` was downloaded from Google's official GitHub release to
`/Users/wangyule/.cache/pourlune-tools/`; its SHA256 matches the release digest in
`docs/development/evidence/beta-readiness/BR01/bundletool-download.json`.
`java -jar <jar> validate --bundle=<aab>` and `dump manifest --bundle=<aab>` inspect
an unsigned bundle without making or installing a debug-signed APK. `asc 5.16.0`
was installed via Homebrew; its auth doctor found no API profile, so read-only
account verification used the existing browser login. Do not create an API key just
to satisfy the CLI; browser registration can reuse the existing owner session.

CI runs stdlib Python configuration/immutability guard tests without private
configs, then the existing fixed Flutter/core/test/debug-build matrix. Local
production compile and future signing remain separate; CI presence is not a
passing run or store processing evidence.


A downloaded/installed Pourlune-only App Store profile now exists and was matched
to the existing distribution identity. Explicit local IPA preparation:

```sh
.venv/bin/python tools/validation/beta_build.py --platform ios --output build/beta-candidates/0.5.0-5/ios-signed --ios-profile "/Users/wangyule/Library/Developer/Xcode/UserData/Provisioning Profiles/74a202b2-3b25-4e31-8fd4-0413bf15d486.mobileprovision" --flutter /Users/wangyule/development/flutter/bin/flutter
```

`ios_signing.py` checks current Pourlune/team/App Store/beta distribution metadata
and an exactly matching existing local certificate/private-key identity. It reads
public CMS/Keychain metadata in memory, never exports a key. `firebase_build.py`
prepares unsigned with Flutter, then invokes manual `xcodebuild archive` and
`-exportArchive` to an explicit new ignored output. It never passes
`-allowProvisioningUpdates` or `-allowProvisioningDeviceRegistration`, never
chooses an automatic signing style, and fixes export destination to `export` and
symbol upload to false. Caller export/provisioning options are rejected. Existing
account/legal/content gates remain even if local export succeeds. A Keychain
access prompt or missing asset is a concrete interruption, not permission to
create or revoke signing credentials. The final IPA is independently unpacked for
codesign deep/strict, identity/version, entitlements and embedded-profile checks;
archive/dSYM/IPA hashes are frozen together. Do not substitute an unsigned device
compile for that successful export evidence.

Release candidate builds intentionally allow Flutter's normal pub/tooling refresh
after an explicit enforce-lockfile check. `--no-pub` can retain a dev-mode native
GeneratedPluginRegistrant containing integration_test while Gradle excludes that
dev plugin in release. Normal refresh alone is insufficient on iOS: fixed Flutter
3.47.2 explicitly retains iOS dev plugins (upstream
[flutter/flutter#163874](https://github.com/flutter/flutter/issues/163874)).
For manual App Store archive/export, `ios_release_plugins.py` temporarily excludes
only the known integration_test import/registration and its two generated SPM
dependency entries after Flutter generation. It rejects unexpected generator
formats or additional native dev plugins before writing, and restores both
generated files on success or failure. SDK sources, pubspec and locks are untouched.
The actual archived Runner and copied IPA Runner must contain neither the native
test plugin class nor its channel name; otherwise the candidate is rejected.
The existing unsigned iOS path remains compile-only and may retain the upstream
native dev plugin; it never claims signing, distribution approval or upload readiness.
Ordinary QA builds retain integration_test. The candidate source/lock hashes must
still remain unchanged. Build10's first local candidate was blocked by this check
during independent review and was never uploaded; it remains frozen for evidence.
Manual profile variables are consumed only by Runner target build settings, not
global PROVISIONING_PROFILE_SPECIFIER on SPM framework/resource targets.

Firebase-selected bundle identity is also a Runner-only variable
`POURLUNE_BUNDLE_IDENTIFIER`; global PRODUCT_BUNDLE_IDENTIFIER would incorrectly
rename SPM resource bundles. The final IPA inspection rejects that leakage.
QA-only external raw identity overrides remain historical QA scope; the official
candidate uses the scoped selection and keeps SDK bundle identifiers distinct.

### BR04 public destinations and authorized Android upload signing

`firebase_build.py` also derives the Settings version label from the same
`app/pubspec.yaml` version or explicit native `--build-name`/`--build-number`
overrides. It supplies project-owned `POURLUNE_VERSION_NAME` and
`POURLUNE_VERSION_CODE`; callers cannot override these. Never inject reserved
`FLUTTER_BUILD_NAME`/`FLUTTER_BUILD_NUMBER` through Dart defines: Flutter rejects
them. A raw development invocation without version definitions displays only
the app name. This does not change the native version or bump a release.

`beta_build.py` and `firebase_build.py` accept explicit `--support-url`,
`--privacy-url`, and `--feedback-email` **before** the Flutter `--` separator.
Missing values remain empty; no guessed URL, mailbox or fixture is built in.
HTTPS only, public DNS format, no credentials/IP/local/reserved placeholder host,
no control characters, and a plain valid mailbox are required. Ports other than
443 are rejected. Validation checks syntax, not ownership, live availability or
legal approval. `candidate.json.public_destinations` records exact public inputs;
`ready` means all three syntactically valid values are present. It is not store
or owner approval. `external_store_gates_verified` remains false.

The wrapper owns the destination and ads definitions; direct Dart-definition
bypasses are rejected. Values enter the same private defines file used by the
existing Firebase selection. All identity/config/default-entrypoint/no-AdID,
lock/source, and production compile-only protections remain. In the manual iOS
archive path these values use the same Flutter preparation, without automatic
provisioning or symbol upload. Never run a production candidate without the
separate runtime authorization.

Android is still unsigned by default. To use a **previously created and explicitly
authorized** upload key, pass all four options to `beta_build.py`:

- `--android-keystore` existing file outside the repository
- `--android-key-alias` selected alias, normally `pourlune-upload`
- `--android-store-password-file` outside-repository password file
- `--android-certificate-sha256` expected public certificate fingerprint

An optional `--android-key-password-file` handles a distinct key password; absent
means the store password is used. Files must be owned by the current user, have
no group/other permissions (normally0600), and sit in a private directory
(normally0700). Final symlink files are refused. Password files contain one line,
6–1024 bytes. No password CLI value/env or secret manifest field is supported.
`keytool` only lists the specified alias; metadata must show PrivateKeyEntry,
current validity and exact certificate pin, with no Android Debug certificate.
Raw keytool/jarsigner output is not printed or saved because errors may echo
secrets or personal subject data. Missing/wrong assets fail before compiling.

After a successful unsigned build, the tool preserves
`app-release-unsigned.aab` and creates a separate
`Pourlune-<version>-<build>-upload-signed.aab` using JAR signing. It requires
strict verification with the selected keystore/alias, a public-certificate pin
check on the signed AAB itself, and identical non-META-INF payload. Failed signing/verification removes only the incomplete new signed
copy. It never overwrites an existing output or generates/resets a key.
`signing.json` holds alias, public SHA256, expiry and verification state;
`signature-check.log` contains that public summary, while the unsigned input
check has its own log. This is upload signing, not the final APK app-signing
certificate Google Play uses. Both signatures and real installation/update
continuity require later actual assets and platform evidence.

For future approved values only, the executor can add the public flags plus
these Android flags to the existing new-output build command. First update the
actual build number as appropriate; do not reuse a processed platform build or
overwrite BR01. The user is not asked to run engineering commands. Owner-only
interactive key creation steps (not executed) are in
`docs/development/evidence/beta-readiness/BR04/owner-key-steps.md`.

The user cannot connect a phone to this remote Mac: **USB is not a universal
pre-upload gate.** Package/engineering checks precede a later concrete
distribution/runtime authorization. Actual phone install, N→N+1 update, restore,
audio/haptics and reader feedback follow TestFlight/Play on that phone; missing
results remain unverified. See `BR04/remote-device-route.md` and
`BR04/device-feedback.md`. No developer mode, debug USB, unsigned sideloading or
unknown certificate installation is needed for that route.


## ADM01 explicit beta test ads

Default `firebase_build.py` and `beta_build.py` remain `--ad-mode disabled`.
Use `--ad-mode test` only for the authorized ad-testing candidate. Both platforms
use Google's exact official interstitial/rewarded test units, even on phones that
have not been registered as test devices; no live-unit flag is provided.
Existing Firebase selection, production compile-only/default-main guard, signing,
new-output folders and source/lock checks still apply. No candidate should be
built/uploaded until the new implementation's independent acceptance and exact CI.

An optional `--admob-registration /absolute/registration.json` chooses the real
Pourlune native App ID while retaining official test units. Public config shape:

```json
{"schema":1,"apps":{"ios":{"native_id":"com.pourlune.app","app_id":"COPY_CONSOLE_APP_ID"},"android":{"native_id":"com.pourlune.app","app_id":"COPY_CONSOLE_APP_ID"}}}
```

This illustrative placeholder fails validation. Use only actual console-verified
platform records; do not fabricate IDs or copy another app's resources. App IDs
are public client config. No signing secrets, payment/tax data or login credentials
belong here. When no registration is provided, Google's platform sample App ID
is explicit and candidate metadata has `owned_registration_verified=false`;
this is engineering preparation, not account registration/readiness approval.

The wrapper pins matching Dart definitions, iOS xcconfig and Android properties;
native guards reject stale platform/identity/App ID, duplicates and unit injection.
Direct debug builds with no ad definition retain the official-sample debug default.
An explicit test definition must include matching `POURLUNE_AD_APP_ID`,
`POURLUNE_AD_PLATFORM`, `POURLUNE_AD_NATIVE_ID`. QA external identity overrides
must match those definitions and use Firebase none; they are not production builds.

BR08 build7 remains frozen with ads disabled. Do not overwrite or relabel it as
ADM01. Actual UMP availability/message configuration, test ad delivery/show/close/
reward, app-ads.txt verification, store declarations and phone results are separate
checks; controlled B04 transport tests do not establish real SDK receipt.

For an owned registration the candidate tool freezes the exact public JSON bytes
as read-only `admob-registration.json` in the new output before delegation; the
wrapper and native checks consume that snapshot. Parsing and hashing use one byte
read. The snapshot hash is pinned in the candidate and checked after compilation;
changing the original file cannot relabel an in-flight build. iOS packaging also
checks the actual product's GADApplicationIdentifier. Independently inspect the
new AAB's actual bundletool manifest App ID before store upload, alongside its
certificate/payload/signature checks; native Gradle checks alone are not store
acceptance.
