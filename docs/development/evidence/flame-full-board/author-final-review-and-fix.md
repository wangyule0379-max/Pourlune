# One final whole-task review and one fix pass

The executing-plans skill dispatched one fresh read-only `gpt-6-astra` reviewer, `/root/flame_full_board_final_review`, over the full FB01–FB08 scope. No follow-up reviewer or author re-review was dispatched. This is an author-requested code review, not architecture-independent acceptance. The reviewer verified114 source hashes, examined code/tests/native evidence, and returned no Critical, three Important(P2), two Minor findings. Pre-review snapshot is preserved separately. 原审查结论为“修复后可送架构验收，修复前不应标整体完成”；下述修复闭环由执行者用测试和原生证据确认，并非二次审查结果。

## Important findings and directed repair

1. Moving seven-bottle1→6 art intersected another bottle's capacity caption. RED reproduced an overlap already at4 bottles/288px/0→2/90ms. Top-row captions now sit above a reserved flight area, lower-row captions below. Production geometry uses `flightBounds`; raw source rectangle and stream cannot cross either caption band. New regression covers4–7, every directed pair,1/2/4 units,288/370/768 widths, normal/2x text and15ms intervals, including approach/return, not only steady flow. All14 focused geometry/widget tests passed. Refreshed native flow captures on both platforms show2/4 at both ends with all captions outside the flight area.
2. Art-load failure left invisible actionable bottles and hid error semantics. Actual asset-channel failure RED observed enabled callbacks. Game exposes loading/ready/failed state; only ready enables pointer/semantic actions. Accessible live failure text and native Retry sit outside the canvas's excluded semantics. Retry replaces only the visual game. Tests verify failed action lock, semantic state, actual asset recovery, and delayed real bytes completing after unmount with disposed art. Existing UI tests now await bounded real decode completion; arrival test still proves first ready input before the finite arrival effect ends.
3. Android used host time minus device UTC and accepted negative freshness(-.403s). Unit RED reproduced that acceptance; nonnegative same-domain validation passes2 tests. Android now obtains native device dates immediately before and after `am force-stop` in one shell call, validates both dispatch and completion within250ms of the device snapshot, and records both ages. Recovery setup also requires early four-unit flow(`out<1`, stream>.02). Native lifecycle freshness uses ordered event indices rather than comparing different clocks. Fresh Android proof uses its own device clock: dispatch93.740ms, force-stop completion132.314ms; early out0.219 and stream0.131. iOS completion16.818ms. Both satisfy the nonnegative250ms guard.

Full app suite after fixes and lint cleanup:219/219,1:09. Format119 files0changes. AnalyzeNo issues,3.9s. New iOS Simulator build31.3s and Android debug10.6s completed strictly serially. Core rules/store unchanged since30/30 core pass.

## Minor findings deferred

- `BottleArt.load` decodes the two layers sequentially. Parallelization with partial-failure disposal is deferred; no new cache/framework or performance pass is introduced.
- Unit-area and fixed tick waterlines are recomputed during rendering. Caching static geometry is deferred; debug frame costs are retained honestly.

## Scope rulings for the reviewer's Declined to judge list

- Physical/profile/release runtime, stable startup, heat/power: remain unverified; cost is that emulator timings do not establish shipping-device performance.
- Real VoiceOver/TalkBack speech: semantics automated only; cost is possible system-reader issues still requiring device validation.
- Real ad awards, Firebase delivery, commercial rights and formal signing: retain external dependency status; cost is that release readiness is not established here.
- Unchanged fullscreen policy/final-level/all winning-transaction kill points: retain existing automatic coverage without a new native matrix; cost is that this batch's native43-step route does not recertify those boundaries.
- Architecture-independent visual acceptance: remains architecture-owned; cost is that this report cannot mark the overall product visually accepted.

Final repair evidence: dual after `route-fixed.json`43steps each, both `same-install-restore.json` and `same-process-background.json`passed; refreshed27-pour/3-cold samples and large-font captures. New source snapshot115 files, updated candidate hashes. All three Important findings addressed in this one test-backed fix pass; no re-review. Ready for architecture-independent acceptance within the stated runtime/visual limits.
