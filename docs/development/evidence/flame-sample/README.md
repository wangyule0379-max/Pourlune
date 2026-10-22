# Flame sample authoritative evidence index

Final native source: `final-source-manifest.json`; frozen code/tests/pubspec snapshot and base in `source-freeze.json`. Native candidates and raw movies live in root **build/** (ignored), outside app/build so a later App UI Flutter clean does not erase them. Review movies are normal speed; only trailing idle was trimmed. Exports decoded to PNG at9.12s and26.91s and inspected; metadata is in review-video-metadata.log. Original art is unchanged.

## Use these final results

- Each platform: `final-ready-route.json` (13 actual-pointer cases), `screens/` (26 PNGs with paint-time JSON sidecars), `route-review.mp4`, `video-index.json`.
- Each platform: `startup-samples.json` (3 fresh PIDs, same install, OS caches retained), `final-before-kill.json`, `final-after-kill.json`, `process-restore-comparison.json`.
- Idle: iOS `idle-{start,end}-final.json`; Android `idle-{start,end}-reviewed.json`.
- Cross-platform: `diagnostics-summary.json`, `artifact-manifest.json`, `protected-database.json`, `final-review-dispositions.md`, Flutter/core/content/analyze/format final logs.
- Final build logs: `final-builds/ios-input-ready.log`, `final-builds/android-input-ready.log`. All Flutter CLI/SPM/build commands were serialized and iOS used FIREBASE_ANALYTICS_WITHOUT_ADID=1. Android retains its existing FlutterFire future Kotlin migration warning; this build succeeded.

The standalone QA app is real Flutter + Flame + native sqflite, controlled by public LiveWidgetController actual pointer events. It is **not** a successful DDS integration-test runner invocation. Its50ms protocol polling, phase captures, SQLite queries, debug/JIT, emulator recording and host load affect timing. Framework FrameTiming totalSpan is not game FPS. Video nominal FPS is encoder/capture metadata, not game FPS. No physical FPS/audio/haptics or improvement pass.

## Reproduction

From app/: build/run `integration_test/flame_sample_app.dart` with debug, exact POURLUNE_DATABASE=flame_sample.sqlite and POURLUNE_AD_MODE=disabled, iOS FIREBASE_ANALYTICS_WITHOUT_ADID=1. Devices are restricted in tools/validation/flame_sample.py to iOS9B172C50-E5CB-4F3F-8F16-0A3DB04F495D / Android emulator-5584. Keep separate from ordinary/Firebase installs. Normal usable sample entry is lib/development/flame_sample_main.dart; it has no file-polling instrumentation.

From root: `.venv/bin/python tools/validation/flame_sample.py <ios|android> route --id <fresh-id>`, `startups`, `state`, `capture`, `prepare-restore`, `sample-start`, `sample-end`. Reused explicit IDs discard only the exact old response inside the QA sandbox before sending, so they cannot report a stale success. Commands are serial; do not issue a second command while a route is running.

`restore-check-executed.py.txt` is the exact executed host script: prepare a clean saved active pour, immediately SIGKILL on iOS or Android force-stop plus absence check, same-install relaunch, await real session/images, compare full instance/saved/settings/receipts/pieces/reveals for both stores; require newPID, idle unlocked full state. No reinstall or DB reset between kill/relaunch. Script contains this workspace absolute path and only fixed QA identities. It did not touch the protected ordinary DB.

## Historical and failed attempts

Keep initial/native-route-* / reviewed-native-route* logs as history; final pass is **final-ready-route** only. Initial Android snapshot encoding missed a following short phase; toImageSync freezes pixels, encoding occurs after the action and images are disposed. Later a repeated explicit host ID returned an old receipt (RED→GREEN host-protocol logs); fixed by clearing exact own response. A post-gesture enabled check incorrectly rejected buttons that became disabled after action; validation moved before gesture. Finally native QA reset could become controller-clean before its native button recognizer/layout was ready: two Android route attempts timed out at the prepared reward, with no duplicate move/award. The driver now waits for actual onPressed/onChanged availability and50ms painted layout before one gesture; final route passes without repeated taps. Added last_action/stack/state on any subsequent QA failure. Product code was unchanged for these driver corrections.

The four final review fixes have RED→GREEN evidence and Flutter192-test suite. `final-review-green.log` first pass had the new blank-tap test pointed above the scrolled viewport; corrected whole-canvas visibility passes in blank-canvas-green.log and the full suite. No failing attempt is relabeled as final success. Pilot before-process-kill screenshots are historical, not proof of an actual kill. No second review was requested.

## Boundaries

Same-device/debug original Flutter baselines are in ../motion-polish/before/, with original complete-board routes/recordings and startup samples. The original board has more bottles and the readiness endpoint differs; these are visual/device/mode baselines, **not equal-load performance benchmarks**. M01–M08 remains unfinished. No full-board Flame migration, SDK changes, service uploads, production signing, store release or visual/artwork-rights acceptance. Independent architecture acceptance and later human satisfaction are separate gates.

