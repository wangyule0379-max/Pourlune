# Pre-review historical snapshot

These are the exact114-source-file snapshot, initial native records/timing and author evidence inspected by the one fresh gpt-6-astra final reviewer. They are **not** the final repaired pass. The reviewer found three P2 issues: label overlap, input after art-load failure, and Android freshness using different clocks. Final code/tests/native records supersede these.

The initial after candidates were moved, without modification, from `build/flame-full-board-candidates/after/` to `build/flame-full-board-candidates/pre-review-after/`; historical candidate SHA records retain their then-current paths. The old before candidate/source stays unchanged and its complete routes/timings remain the final old-renderer baseline. Root `ios/after/route-v2*` and Android equivalent are historical diagnostics; current repaired route is `route-fixed*`.
