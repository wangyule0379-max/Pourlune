# Build13 nonempty compatibility fixture

This is synthetic, local data, not an exported user save and not evidence that
the original released13 binary completed a nonempty in-place upgrade. That
binary fails in WorkManager initialization before Flutter on the current QA AVD.

The generator must run against **236cea0479837d415094a784f47b6d3928c3366c**.
Extract that commit's `app/`, `packages/`, and `.flutter-version` into a fresh
ignored directory, verify these files against the original frozen13
`sources.json`, then copy `generate_legacy13_fixture_test.dart` into its
`app/test/`. Use Flutter3.47.2, `flutter pub get --enforce-lockfile`, then:

```sh
POURLUNE_LEGACY13_OUTPUT=/absolute/new/path/legacy13.sqlite \
  FIREBASE_ANALYTICS_WITHOUT_ADID=1 \
  flutter test test/generate_legacy13_fixture_test.dart
```

The output must not exist. The generator uses the original13 GameStore,
GameInstance and puzzle files, completes1–3, saves main004 after two moves,
grants its old ads-disabled direct extra bottle, disables music/statistics,
and closes real SQLite. It does not invoke any SDK, device, or network.
SQLite file bytes can differ by generation time/header; verify the documented
logical contents rather than assuming all regenerated file hashes are equal.

The frozen131072-byte output SHA256 is
`a5cbb36efe5b6eee47cfc59785a550006df563fb8f76d52b7b62af3dd7364c9f`.
Its gzip/base64 is in `app/integration_test/fixtures/legacy13_fixture.dart`,
outside production assets. `app/test/legacy13_upgrade_test.dart` checks current
SQLite restore, undo/restart/actions, settings, progress and unique entitlement.
The standalone `legacy13_migration_app.dart` seeds only an absent, explicitly
named debug QA database, then runs normal main. It never resets existing QA data.
