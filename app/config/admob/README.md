# Pourlune AdMob public registration

`registration.json` contains the real iOS/Android App IDs read back from the new
owner's AdMob console on 2026-10-26. These are public client identifiers, not
credentials. Both apps use `com.pourlune.app` and currently remain unlinked to a
public store listing. Account/application approval is still pending.

Pass this file explicitly as `--admob-registration app/config/admob/registration.json`
to the existing beta/Firebase wrapper with `--ad-mode test`. The wrapper consumes
registered App IDs only for the formal identity, and still fixes both ad units to
Google's exact official test units. Default builds remain disabled; this file does
not enable production ads or modify frozen TestFlight15. Independent QA aliases
continue to use sample App IDs, without weakening identity guards.

The separately recorded owner rewarded/interstitial IDs are console inventory in
`docs/development/evidence/admob-resume-20261026/console-registration.json`.
They must not replace test units in QA. Console registration does not prove
commercial readiness, consent-message publication, app-ads.txt verification,
Android device behavior, or physical-device acceptance.

2026-10-28: the user explicitly authorized the first release with commercial ads.
The existing iOS units were read again from the correct console account and are
now included in `registration.json`. `--ad-mode production` consumes those units
only with matching registered identity and native/Dart guards. `test` continues
to use sample units even with the same owned App ID. Account/app serving remains
limited pending public-store linkage; configuration does not guarantee fill.
