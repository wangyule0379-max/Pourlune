# Pourlune core

Pure Dart: immutable puzzle definitions, strict JSON parsing, pour rules and instance snapshots. No Flutter, SQLite, SDK or network dependency.

Run with Dart 3.13.2 (Flutter 3.47.2), from this directory:

```sh
dart pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

Boards are bottom-to-top; move indices are zero-based. Fixed target labels participate in victory, not receiving legality. Each valid pour stores one full undo frame. Invalid actions return the same instance. Every accepted mutation increments `revision`; undo can reduce steps but never revision. The extra-bottle flag is persistent, is at most once per instance, and survives undo/restart. Completed instances lock all actions.

`GameInstance` embeds its full puzzle definition and daily identity. Restart uses that definition. JSON rejects unknown fields/versions, duplicate keys (including escaped duplicates), non-integer number tokens, invalid quantities/labels and inconsistent snapshot dimensions. Undo history rejects completed frames: victory immediately locks an instance, so a won board cannot precede another move. The first frame must equal the embedded original initial board, optionally with the earned empty extra bottle. This also applies after restart and uses the original embedded content version. Instances are immutable; persistence must reject stale/conflicting revisions. `grantExtraBottle` is the domain operation for an externally confirmed entitlement; this package does not assert an ad reward was received. B04 must add durable SDK reward-confirmation ownership before connecting real callbacks.

The tests replay the three engineering fixtures from `docs/content/fixtures/`, plus every independently recorded original L12 move, quantity, color and resulting board. They are not a release catalog or a solver. Fixture tests assume this package working directory.
