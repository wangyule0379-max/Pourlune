# Glass Garden implementation plan

> Use superpowers:executing-plans inline; independent final acceptance remains with the parent. The user's approved prototype and direct instruction to proceed replace another plan-approval round.

**Goal:** Implement the accepted N01–N15 outer product around the unchanged Cocos2d-JS3.17/HTML100 campaign.
**Architecture:** Independent `glass-garden/` product, local offline web assets and Cocos iframe; transactional IndexedDB stores complete product+game snapshots. Thin Android WebViewAssetLoader/iOS WKWebView containers preserve the existing HTML runtime, rather than porting DOM code to JSB or restoring Flutter.
**Spec:** canonical `docs/pmpowers/specs/2026-11-06-cocos-product-flow-and-ui-brief.md`; accepted prototype R1-5732d17bf059 / artifact acdc7a0e…8324, product-flow.md and handoff.md.

## Boundaries and rulings

- Existing checkout `/Users/wangyule/.codex/worktrees/testflight17-fixes/Pourlune`, branch `codex/pour-flight-size-fix`; initial dirty state only pre-existing `.scratch/`. All product code goes in new `glass-garden/`; no old Flutter, original Cocos source, frozen prototype or old save writes.
- Copy accepted game resources with source SHA manifest; rules/campaign/game/render/progress/main remain byte-identical. Only copied host HTML/project script wiring changes. Do not change bottles, colors, trajectories, levels or free tools.
- No remote analytics/ad SDK, real reward, extra bottle, new gameId/store identity or store upload. Native identifiers are unregistered local QA identifiers only. N15 contract is unavailable in the player build; samples live in tests, not player routes.
- Runtime remains Cocos2d-JS3.17. Android uses HTTPS virtual asset origin and pinned cached AndroidX WebKit1.15.0; iOS serves bundled read-only assets on fixed loopback43177 for standard-origin modules/Worker/IndexedDB. This is an in-process asset loader, not a gameplay/cloud business server. Native compile is separate from actual native runtime acceptance.
- Browser/default native storage has new product namespace and schema; no automatic adoption/deletion of prior prototype/site/Flutter data. Native JS persistence acknowledges transaction completion, not a request's early success. Corrupt data retained; replacement requires explicit confirmation and quarantine.
- Current build has no analytics collection/queue. Save first choice (including declined/closed) once, document local data honestly and provide bundled policy. Future SDK/purpose changes require new informed disclosure. Music has no approved track; native haptics unintegrated: disabled with truthful availability labels, not fake success.
- All actual browser/device work goes to existing Use Computer. No simulator boots from this development task; build only. Before any later native batch coordinate other tasks, exact serial/UDID, one device, cleanup only owned instance. F9 protected.

## Added 2026-11-06 constraints

Read the three canonical `2026-11-06-refactor-*` contracts from /Volumes/data/App Development/Pourlune/docs/pmpowers/specs; exact hashes in evidence/s2-input-contracts.json. S1/S2 is the first gate: do not build native shells or claim whole-product/SDK acceptance before parent representative acceptance. Preserve return-stage queue and animation durations; commit the full legal action independently of animation finish and reject old-round callbacks. Music/haptics capability placeholders are not production defaults or migrated preferences. Old60→new100 migration remains unimplemented. Measure before optimizing; no performance claims.

## Review focus

1. Disk abort after request success must keep prior save and pending retry; no false saved/navigation/win.
2. Replayed level1 Next must retain unfinished level2 board/history/round; only explicit restart replaces it.
3. Hidden page or parent modal must not wake child rendering/audio; hint cancellation invalidates Worker/timer/late callback.
4. Corrupt/current+backup mismatches must not silently become a new game; retain bytes until confirmed replacement.
5. First refusal/reload and change of round while asynchronous callbacks are pending must not emit queued statistics or invent rewards.

## Task1 — provenance and transactional persistence

Files: `glass-garden/web/game/**`, `web/product-model.mjs`, `web/storage.mjs`, `test/storage.test.mjs`, `source-manifest.json`, package lock.
- [x] Freeze accepted/source input hashes; copy resources without rewriting core files.
- [x] RED tests real IndexedDB API (fake-indexeddb dev-only) transaction abort/ack, nonempty restore, corruption quarantine, competing writer protection.
- [x] Implement `openStore({indexedDB,name}) -> {read,write,replace,close}`, `validateState(value,R,P)`, schema and round/completion contracts; GREEN.

## Task2 — real player controller and accepted views

Files: `web/product.mjs`, `web/views.mjs`, `web/game-bridge.js`, `web/index.html`, CSS/tokens, `test/product.test.mjs`.
- [x] RED full real-rule sequence new/play/save/restore/Undo/restart/first-clear/idempotent Next; privacy decline/reload; save failure navigation gate.
- [x] Implement serialized snapshot commits, real round IDs, sequential unlocked groups, per-level resume, completion after commit,100-end; reuse accepted visual templates. Remove dev query/samples/rail and fake player copy.
- [x] Implement accepted view templates and safe sheet/Escape cancellation; representative flow self-check passed. Peripheral promotion is NOT independently accepted. Preserve free tools and geometry.

## Task3 — lifecycle and inactive service boundary

Files: bridge/controller, `web/services.mjs`, lifecycle tests.
- [x] RED late hint/hidden child wake/same-instance completion/failure retry cases.
- [x] Implement lifecycle gates and late-callback tests. No SDK/service client or event queue exists; not a simulated SDK acceptance. Actual native lifecycle remains untested.

## Task4 — reproducible mobile shells

Files: `native/android/**`, `native/ios/**`, `scripts/package.mjs`, README/build commands.
- [ ] Package player files only, verify source hashes/absence of dev routes/SDK credentials.
- [ ] Android local asset origin denies nonlocal requests; iOS bounded loopback path serving and persistent origin, lifecycle/back callbacks. No new registered identities or signing assets.
- [ ] Compile Android debug and iOS generic simulator serially, at bounded worker count; never boot a device. Record actual result/limitations.

## Task5 — actual browser acceptance and handoff

Files: evidence and `docs/development/deliveries/new-cocos-product-implementation.md`.
- [x] Run focused tests then whole new-product suite, source/packaging checks.
- [ ] Use Computer actual normal390/320 flows, per-level resume/Next, save-failure harness only outside player, background/audio/rest and representative existing tall/cover/max layouts without new devices.
- [ ] Fix concrete issues, freeze artifact/hash; hand complete stage to parent for independent review. Native/SDK/physical/commercial/source-art rights stay explicitly unverified where not run.

## S2 checkpoint

Candidate `glass-garden/build/s2-r2-final/`, manifestca42924a5b2ac6403b2f439870d8d1212be9cd840110e04f120877bff8264978,415 player files/14240361 bytes.24 Node tests PASS; source407 entries verified,6 core files unchanged,100 levels retained. Computer representative ordinary play/resume/Next and isolated real transaction-abort PASS, with initial disabled-input defect retained and repaired. Parent independent acceptance pending; do not promote or upload yet. See delivery for precise measured boundaries.
