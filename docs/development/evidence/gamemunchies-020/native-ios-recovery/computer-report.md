# SDK 0.2 iOS recovery R2 — 2026-10-28

On dedicated simulator Pourlune GM QA 20261028 (2894A85E-04FC-4857-A856-3BEFF2CCB565), upgraded the existing `dev.pourlune.gamemunchiesValidation` installation to the R2 QA binary using the isolated `gm_020_recovery_20261028.sqlite` database. The prior application data container was backed up under ignored `build/gamemunchies-020/ios-device-private-before-recovery/`. Runner SHA-256 was `c99c27fa727f16ae4305dd029c8f71ecbbcacfd2fe50d1f5d99b2b943c9e453b`; kernel SHA-256 was `506e5682cf238dbb6fba687680c05a4817866ceeafa24255a3581d1ca89bbf72`.

First process showed two queued events with offline POST transport. After stopping it and launching the installed app from its home icon without reinstalling, the second process reported a new process, the same game instance, and restoration of original events. A retry drained the queue to zero. Its preserved receipts record acceptance of 3/3 events, followed by 0/3 on retry after the deliberately lost acknowledgement; original IDs and first timestamps were retained, and originals deduplicated. Per-process sanitized status, HTTP and acknowledgement records accompany this report. Full private evidence is in ignored `build/gamemunchies-020/ios-device-private/recovery-r2/`.

This run did not re-test advertising or production, and does not constitute physical-device validation. Android recovery and normal app entry remain unverified.

## Device selection incident

Before correctly selecting the dedicated simulator, Xcode retained its default iPhone 17 Pro (26.2, 0A4E8F1C-7177-4F0E-A309-5160EE5695EA) despite a list click. A run began installing Runner there and was stopped immediately. Read-only inspection subsequently found a `dev.pourlune.gamemunchiesValidation` container on that simulator. No data was intentionally cleared and no cleanup was attempted. F9 was not targeted. The coordinator was informed.
