# Flame full-board author evidence

2026-10-22. Execution/self-verification evidence; architecture acceptance remains separate. The one fresh author-dispatched final review and one fix pass are recorded in [review/fix report](author-final-review-and-fix.md). Three Important findings are repaired; overall independent acceptance remains architecture-owned.

## Sources and reproducibility

- Plan: `../../../pmpowers/plans/2026-10-22-flame-full-board.md` (FB01–FB08).
- `comparison-source-provenance.json`: actual accepted UI HEAD `24bb1637f046e500946d770ca4808cef39687c74`, old Flutter-board baseline and protected UI/native/dependency hashes. Before uses its preserved pre-review QA; after adds elapsed diagnostic JSON, initial lifecycle log and early recovery guard. Route/timed/startup endpoint policy is unchanged and the source delta is explicit. The QA entry is untracked at that HEAD, so its `before_matches_ui_head=false` is expected. The original identical QA snapshot and final small diagnostic/recovery-only delta are both preserved; final `qa_identical=false` is intentional.
- `runtime-source.zip` / `runtime-source-sha256.json`: text snapshot of runtime/tests/helper; existing assets/native files are supplied by the recorded Git baseline. No Firebase, signing or private configuration is packaged.
- `candidate-sha256.json`: exact before/after candidates under ignored `build/flame-full-board-candidates/`; both phases use the same normal `main`/Bootstrap route policy; the final instrumentation source variant is declared. These are debug candidates, not distribution binaries.
- Commands and dedicated-device checks: `app/README.md` and `tools/validation/flame_full_board.py`. Serial Flutter/Dart/native builds with `FIREBASE_ANALYTICS_WITHOUT_ADID=1`; Firebase none, ads disabled, no scenario define. Dedicated identities/database in `device-identities.json`. No install or data clearing on ordinary, Firebase, sample or transition devices.

## Canonical passing native records

For each `ios/` and `android/`:

- `before/route-final.json` and `after/route-fixed.json`: 43 steps each, actual native pointers, formal bundled content, actual sqflite. Replay prefixes and seventh-bottle entitlement are prepared QA state. Main001/005/009 cover4/5/6 and7 bottles, actual reference solutions, partial one-unit capacity, four-unit edge/cross-row pours, deselect/illegal/blank/hint cancel, pause/Home/Continue, save-failure navigation block/Retry, daily/ordinary slots, first-clear4 receipt/patch/Next, settings and reduced/high-contrast rendering.
- `screens-route-final/` / `screens-route-fixed/`: selected → approach → flow → landed board captures with matching frame JSON. After `b7-m0-approach` retains4/0 despite already committed3/1. `seven-right-edge-four-units-flow` shows the shared integer midpoint progressing to2/2 while bands/stream remain continuous.
- `route-clip.mp4` / `route-clip.json`: normal-speed contiguous excerpts showing partial-capacity, seven-bottle four-unit edge and cross-row pours. Original full-route movies, UTC intervals and SHA256 are recorded in `route-*-recording.json`; full raw movies remain at their explicit local paths under ignored `build/flame-full-board-raw/`. Clipping/export does not retime the animation.
- `after/same-install-restore.json`: early active four-unit(out<1, stream>.02), same-domain dispatch/completion ages nonnegative and<250ms (Android device dates around force-stop; no host-device subtraction), save-clean snapshot → abrupt SIGKILL(iOS)/force-stop(Android) → launch the **same installed binary/container** → complete stored board, both slots, receipts/settings/entitlement/history checked → actual native Undo7→6 with extra bottle retained. No runner/reinstall occurs inside this test.
- `after/same-process-background.json`: actual OS Settings/Launcher app switch, fresh ordered native inactive/paused/resumed events (sequence counts, not cross-clock timestamp comparisons) and active pre-cancel token; same PID on return, complete state and native Undo verified. These are OS events, not synthetic lifecycle calls.
- `after/screens-large-text-seven/`: iOS accessibility-large and Android320×568 logical viewport/font_scale2. Android override/original values in `large-text-device.json`; settings restored. Scope is the board capture, not an assertion that every offscreen page control is simultaneously visible.
- `after/final-fullscreen.png` and `screens-final-installed-seven/`: final repaired after candidate retained for inspection after its complete route/recovery/measurement run. This later installation is explicitly **not** the same-install recovery evidence.
- `timed-moves.json`, `startup-samples.json`, `idle-start/end.json`: raw measurements. [Performance methods/results](performance.md), including Android hot-entry diagnostic increases and limitations. Engine paused in after idle snapshots; normal Flutter/instrumentation still produces frames.

## Automated verification

- `fix-full-tests.log`: app full suite219/219,1:09; `fix-final-format-check.log`:119 files,0 changed; `fix-final-analyze.log`: no issues,3.9s. Core30 remains unchanged. `clock-final.log`:2 host freshness tests. The earlier216-suite snapshot is historical.
- `core-check.log`: core lock enforcement, format/analyze and30/30 tests. App lock enforcement in `pub-get.log`; dependencies unchanged.
- Dedicated RED→GREEN evidence: sample capacity jumping ahead (`sample-counts-red.log`), renderer retention through tutorial completion (`renderer-retention-red.log` / `renderer-host-retention-red.log`), presenter attach/new-mount/old-dispose race (`presenter-owner-red.log` → `presenter-owner-green.log`,26 passed). Necessary controller fix is balanced presenter reference counting only; no schema, commit timing, reward or business-rule changes.
- Geometry regression covers all42 directed pairs for7 bottles,1/2/4 units,15ms samples,288/338/370/379.428571/768 widths at2x text, raw art bounds and volume including stream. All4–7 directed flights and streams also avoid every native label at normal/2x text, including approach/return; upper captions frame the flight area from above and lower captions from below. Actual painter super-call order is probed in both directions. Real native text/semantic tap, readonly state, stale saved effect callback, lifecycle and OS reduce-motion toggle are covered.
- Earlier failing logs/QA attempts are retained as diagnostics, not counted as passing evidence. iOS screenshot direct-to-external-volume failed due simulator-service permission; `/tmp` capture followed by ordinary copy succeeded, without permission changes. An earlier overlapping build pair was discarded and both final after candidates were rebuilt strictly serially (`after-*-build-serial.log`).

## Applicable acceptance scope

|FB / AC|Evidence / scope|
|---|---|
|FB01–03; AC01/03|Formal4–7 reference solutions, partial capacity, actual frame/count/stream captures, all-pair geometry; core still sole rule authority. FS-M01 sample uses same quantization policy and has dedicated persisted-before-display regression.|
|FB04; AC02/04/05/07/08|Native cancel/illegal/hint/undo/restart; real-App tutorial retention; full-suite asynchronous stale-result and entitlement/history regressions. AC06 search outcome rules are unchanged and rely on existing automated coverage, not four new native solver outcomes.|
|FB05; AC09–12/24/33|Native first-clear4 one receipt/patch, saved navigation rollback/Retry, separate daily/ordinary and actual same-install active-pour recovery/native Undo; existing transaction/reward idempotence tests. The new kill route is nonwinning; no claim of a new native kill-at-every-winning-transaction-phase matrix.|
|FB06; AC15/16/22/28/32|Combined current UI host tests and native reward/Next/Home/replay paths. Existing fullscreen eligibility/final-level tests remain in219; no real ad SDK success, main060 native run or new fullscreen-boundary runtime audit in this batch.|
|FB07–08; AC31/34|Dual native normal-main builds/routes, real system/font board evidence, free actions with Firebase none/ads disabled. This batch did not toggle airplane mode; existing offline behavior is retained, not newly certified against all connectivity states.|

No physical-device/profile/release-runtime performance, VoiceOver/TalkBack spoken reading, real ad award, new Firebase delivery, commercial asset rights or architecture-independent visual pass is claimed. Fixed-target rules, store schema5/snapshot2 and SDK versions are unchanged. [Protected ordinary review DB](protected-review-db.json) retains the pre-task SHA256.
