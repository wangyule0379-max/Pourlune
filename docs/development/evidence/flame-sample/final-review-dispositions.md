# Final code review and dispositions

Fresh read-only reviewer: `/root/flame_final_review`, gpt-6-astra high, fresh context; one review, no implementer delegates or re-review. Reviewed listed authored uncommitted files and shared checkpoint overlap, no Flutter commands. Initial verdict: no Critical; three Important, one Minor, not ready until fixes and final validation.

## Fix pass

1. Reduced idle / failed reveal rendered a saved-but-unrevealed piece at target. Reproduced via actual rendered RGBA pixel comparison, not snapshot-only assertion. Fixed reduced target fade so it requires active **committed** reveal; source remains visible while waiting/failed. Regression: `review: reduced idle and failed-reveal pixels retain the unplaced source piece`.
2. Background cancellation left reservation IDs valid; delayed reveal save could restart old flight/audio after foreground. Held actual SQLite transaction, background→foreground→release reproduced old animation. Added monotonically invalidated reservation and original-token check after await. Regression: `review: pending patch reveal cannot restart a flight after background cancellation`.
3. Reduced preference duplicated in stores could diverge while patch save was busy. Reproduced UI off / actual patch reduced on. Bottles settings are now the sole sample-wide preference, propagated with OS preference via MediaQuery; patch ignores legacy private-store reduced flag. Regression: `review: sample preference remains authoritative while patch storage is busy`.
4. Reviewer Minor blank-canvas cancellation regraded **Important**: PRD§2.2 requires it and retained source could change the next action. Added a native Flutter background tap handler below both bottle buttons, excluded from semantics; scrolling/native button arena remains Flutter. Regression: `review: blank canvas tap cancels selection without a move`. Initial test target was scrolled above viewport; corrected by ensuring whole canvas visible. Full-suite result remains authoritative.

All four regressions were observed failing before production changes (`final-review-red.log`). Three passed in first fix run; blank-canvas target correction passed (`blank-canvas-green.log`). Full-suite/logs recorded separately. No deferred minors remain. No code-review approval of main merge, publication, full-board expansion or user visual satisfaction is claimed.

## Rulings and costs

1. Shared authorized checkout retained with M01–M08 checkpoint, no author staging/commit/push. Protect owner tracking/plans/reviews; cost: integration/review must use explicit file scope.
2. Two visible bottles project indices0/2 of a valid four-bottle QA definition because the production core requires two colors plus buffers. Cost: no full-board layout or formal two-bottle puzzle proof; cannot grant first-clear rewards.
3. Standalone LiveWidgetController native gestures/file protocol after bounded DDS runner failures. Cost: custom debug instrumentation and its overhead; not an integration-runner pass or physical performance proof.
4. Uncommitted tracked patch plus complete untracked file/SHA inventory used for review because architecture owns commits. Cost: manual review/scope auditing, no author commit-range certificate.

## Every behavior the reviewer declined to judge

- Full/seven-bottle Flame migration: excluded by explicit sample authorization. Ruling: leave original renderer; cost is another implementation/acceptance step after user approval.
- M01–M08 overall completion: preserved unfinished checkpoint, no overall pass. Ruling: separate delivery; cost is M after-evidence still pending.
- Relative Flame performance improvement: baseline load differs and instrumentation affects sampling. Ruling: publish raw distributions only; cost is no speedup conclusion.
- Representative real-device FPS/audio/haptics: no physical-device evidence. Ruling: remain unverified; cost is physical acceptance still required.
- Final native routes/full suite: pending at review time. Ruling: author must finish and record fresh final evidence, never infer review-time pass; cost is build/test work after review.
- User visual satisfaction/independent visual acceptance/artwork rights: code review cannot decide them. Ruling: hand off sample for architecture acceptance and later user appearance approval; reuse existing art does not grant new rights; cost is no expansion/production art sign-off.
- Firebase/ads/signing/store release: unchanged and outside sample scope. Ruling: preserve their established status; cost is no new service/distribution assurance.

