# Initial regression run (before production edit)

Executed `flutter test test/game_audio_test.dart test/game_audio_transport_test.dart --reporter expanded` against the pre-edit audio implementation.
Result: 10 passed, 3 failed (terminal output observed by parent; this is a summary, not a saved raw log).

- Rapid pause/resume: expected one `stop effects`, observed zero.
- Failed flow-end stop followed by background: expected two stop attempts, observed one.
- Actual default transport with stubbed native decoder: expected two `pause` calls, observed zero; old implementation issued stop/reload instead.

After the production fix, the saved `audio-green.log` includes these regressions plus actual screen/lifecycle, visual flow and successful-settlement gates: 23 passed.
