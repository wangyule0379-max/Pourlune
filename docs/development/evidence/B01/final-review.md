# B01 fresh review and fix pass

Fresh reviewer: b01_final_review, gpt-6-astra/high, clean context; read-only review against working tree at HEAD fbe4124. Reviewer inspected implementation/specs/evidence and independently reproduced two defects in a temporary project (original checkout unchanged). No Critical finding. Two Important findings, one initially Minor finding. Verdict: ready for B01 acceptance with fixes. No second reviewer or re-review; regressions and full suite verify fixes.

| Finding | Review grade | Executor grade / reason | Regression |
|---|---|---|---|
| Pre-grant backup revokes persisted extra entitlement if primary is corrupted immediately after grant | Important | Important; violates stored entitlement preservation | store: AC-07/24 persisted extra entitlement survives primary corruption immediately after grant; tests both initial-save-then-grant and first persisted snapshot already granted; reopen, retain flag/fifth bottle, second grant is identical, restart keeps bottle |
| Bottle label has no semantic tap action because child InkWell is excluded | Important | Important; blocks accessible operation | widget: bottle semantic activation invokes action once; disabled bottle has no action; invokes SemanticsOwner action and checks actual callback |
| Pause after failed write says every action is saved | Minor | Regraded Important: directly contradicts failure state, may cause user to terminate believing memory changes persisted | existing full UI journey now pauses after a real transaction failure, requires memory-only/Retry text and rejects false saved claim |

`final-review-red.log`: 15 tests, 12 pass/3 fail at exactly these assertions before fixes. Fix pass: entitlement-preserving backup in same write transaction, outer semantic onTap/enabled, phase-aware pause text. `app-test.log`: final full suite result recorded in progress.md / B01.md. No deferred minors.

## Behaviors declined by reviewer and executor rulings

These are limitations/authorized boundaries, not claims of passing implementations. Every reviewed omission is retained here and in progress.md.

1. Hint isolate/cancellation/stale results, full daily, tutorial, production navigation: accept B02 boundary; risk if mistaken: the slice is incomplete as a full first release.
2. 60+30 content, difficulty, final art/animation/visual fidelity: accept B03 boundary and development probe labeling; risk: no production content/visual readiness.
3. Real ad callbacks/durable SDK confirmation/delayed rewards/privacy/cooldown/display/reset and Firebase: accept B04 boundary; risk: no managed-service/ad readiness.
4. Eligibility gating of core grant: core represents an already supplied entitlement; actual eligibility/SDK confirmation must gate the application caller in B04. Risk: direct ungated production calls would issue unauthorized grants; no such UI/caller is present in B01.
5. Android runtime, physical iOS/minimum OS/release/profile/performance/lifecycle matrix/screen-reader speech: keep explicitly unverified. Semantic activation is now automated and fixed, not treated as a substitute for actual assistive-device checks. Risk: those environments may expose untested defects.
6. Remote CI: configuration only until acceptance owner commits/pushes; risk: runner-specific failures remain undiscovered.
7. Whole SQLite-file/global-table corruption: B01 handles per-slot payload/backup corruption, not general file repair; risk: full-file damage can prevent startup, which surfaces Retry without erasing data.
8. Shipped historical migration: schema1 is the explicit nonempty constructed baseline, no published legacy app claimed; risk: actual future migrations need fixtures from the shipped schema.
9. Cancel failed replacement and resume old board: retain documented candidate freeze until Retry; Stay only cancels navigation and stays on the page. Risk: user must resolve failed candidate persistence before resuming the old board; old slot remains intact on disk.
10. Cryptographic tamper detection/history reachability proof: retain strict structural/type/capacity/conservation validation without cryptography or replay proof. Risk: hand-edited but conserved snapshots may pass; local saves are not a secure anti-cheat boundary.
