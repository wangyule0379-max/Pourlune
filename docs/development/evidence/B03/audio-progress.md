# B03-06 / ART-07–08 audio and font delivery evidence

2026-10-22, Pourlune B03 implementation. This is implementation evidence, not
independent acceptance or an assertion that a person listened to the mix.

## Files and provenance

- `app/lib/application/game_audio.dart`: real local-asset `audioplayers` transport
  and injectable policy service. `app/test/game_audio_test.dart`: host policy tests.
- `tools/assets/audio_generate.py`: complete deterministic synthesis source;
  Python 3.11+ stdlib only, seeded noise, no samples/network/downloaded music.
- `tools/assets/audio_verify.py`: separate decoder checks of actual packaged WAVs
  and original Nunito hashes, sizes, Git blob identities and unchanged copies.
- `docs/design/production-candidates/audio/{select,pour,error,win,reveal,background}.wav`
  and byte-identical `app/assets/audio/` copies. Candidate `manifest.json` records
  source hash, every delivered hash, encoding and actual signal measurements.
- Candidate `AUDIO-AUTHORING.md` records the explicit B03 authorization, actual
  synthesis inputs and limits. No third-party audio input or commercial music.
- `app/assets/fonts/nunito/{Nunito[wght].ttf,OFL.txt,METADATA.pb,source.json}`:
  unchanged copies of the pre-existing candidate package. Original Google Fonts
  SHA256 and Git blob checks passed for all three content files before copying.
  This is the upright Nunito variable font only; italic is not supplied. Existing
  metadata gives the weight axis as 200–1000. OFL and copyright remain intact.

The Nunito TTF SHA256 is
`bb55a5ca5c2042335b3991af27c4d0705d0ef41cac6164ac737fd8f2a1e85207`.
The OFL SHA256 is
`580df76c95a1ec5ab878ceb25bb3d85c6a076804e9c970c8c6972aea775fdf65`.
Complete source URLs and original file facts remain in the unchanged source.json.
Root integration owns font registration, app license entry and actual text layout.

## Measured digital signals

All files are 44,100 Hz mono signed 16-bit PCM WAV. The table describes decoded
full-file samples; these measurements are not LUFS, true peak, perceived loudness
or sound pressure. Runtime gains are 0.65 for effects and 0.45 for music.

| File | Duration (s) | Sample peak (dBFS) | Unweighted RMS (dBFS) |
|---|---:|---:|---:|
| select.wav | 0.14 | -12.40 | -23.34 |
| pour.wav | 0.84 | -12.40 | -25.35 |
| error.wav | 0.28 | -12.40 | -22.77 |
| win.wav | 1.20 | -12.40 | -24.43 |
| reveal.wav | 1.05 | -12.40 | -24.11 |
| background.wav | 24.00 | -18.42 | -31.53 |

The background is an original eight-bar 4/4 pad/bell sequence at 80 BPM. Whole-file
loop points are frame 0 through frame 1,058,400 exclusive. All six files start and
end at digital zero with soft envelopes. Native-player gaps and audible seam
quality still require listening on target devices; no gapless claim is made.

## Dependency and platform decisions

Root added exact `audioplayers: 6.8.1` and retained the resolved lockfile. The
official package and the locally downloaded release pubspec require Dart ^3.6.0
and Flutter >=3.44.0, compatible with this project's fixed versions. This subtask
did not edit pubspec, lockfiles, bootstrap, controller, settings or localization.

Primary documentation checked on 2026-10-22:

- [Official audioplayers 6.8.1 package](https://pub.dev/packages/audioplayers/versions/6.8.1)
  and [release pubspec source](https://github.com/bluefireteam/audioplayers/blob/main/packages/audioplayers/pubspec.yaml).
- [Official getting started / local assets, release modes and context](https://github.com/bluefireteam/audioplayers/blob/main/getting_started.md).
- [Audio context definitions](https://github.com/bluefireteam/audioplayers/blob/main/packages/audioplayers_platform_interface/lib/src/api/audio_context.dart).
- [Android plugin manifest](https://github.com/bluefireteam/audioplayers/blob/main/packages/audioplayers_android/android/src/main/AndroidManifest.xml)
  has no permission declarations; [Darwin podspec](https://github.com/bluefireteam/audioplayers/blob/main/packages/audioplayers_darwin/darwin/audioplayers_darwin.podspec)
  has iOS deployment target 13.0, below the existing app target 15.0.

The real transport uses only bundled `AssetSource('audio/…wav')`; it does not
request microphone, media-library, network or storage permissions. No iOS
background-audio mode, microphone usage description or Android service is needed
for this foreground local output path. The package's transitive HTTP capability
is unused by this service. iOS uses `ambient`, respecting the Ring/Silent switch
and implicitly mixing with other audio; no invalid explicit `mixWithOthers`
option is supplied. Android uses game usage, music/sonification content types,
no audio-focus request, and `stayAwake: false`, so this path does not deliberately
steal focus or hold the screen on. Other-app coexistence and call interruptions
need device validation; these are configuration facts only.

## Behavior and integration contract

Create one `GameAudio()` per app/controller lifetime. On settings, route/pause or
lifecycle change, call `unawaited(audio.update(settings: settings, foreground:
isResumed, paused: isPaused))`. Foreground should be true only for the resumed
app lifecycle state. Pause/background stop both channels; music restarts from
the beginning when allowed again. Music and sound settings operate independently.
Reduced motion changes visual motion and does not silently mute either setting.
No sound plays before the initial settings/lifecycle update.

Call `unawaited(audio.play(GameSound.select/pour/error/win/reveal))` on the actual
corresponding state transition. Choose the enum value, rather than a string path.
One effects voice intentionally replaces its preceding short cue; music has a
separate looping player. Calls are serialized, queued effects carry an activity
revision, and pause/off/dispose drops obsolete effects instead of replaying them
after resume. `stop()` gates and stops both channels until the next update;
`dispose()` releases both players permanently and is idempotent. All returned
futures contain decoder errors. Gameplay, navigation and persistence must never
await audio to complete and must not use audio success as a business signal.

## Actual verification and limits

From `app/`:

- Initial test-first stub: six behavior failures (empty sink instead of required
  playback/stop effects), one initial negative test passed. The latter was then
  strengthened to include a positive post-resume cue.
- `flutter test --no-pub test/game_audio_test.dart`: **8 passed**, including
  independent switches, reduced motion, pause/background, queued stale effects,
  initial mute/settings gate, decoder failure recovery, stop and final disposal.
  Expected decoder failure prints the generic nonfatal message once.
  Evidence: `audio-unit-tests.log`.
- Removing the revision comparison temporarily caused the stale-effect test to
  fail with actual `music,pour,reveal` instead of `music,reveal`; source restored
  and the complete audio suite rerun green. `audio-stale-effect-mutation.log`.
- `flutter analyze --no-pub lib/application/game_audio.dart test/game_audio_test.dart`:
  no issues. `audio-analyze.log`.
- `dart format --output=none --set-exit-if-changed lib/application/game_audio.dart test/game_audio_test.dart`:
  zero files changed. `audio-format.log`.
- Full `flutter test --no-pub` was attempted during sibling UI integration:
  **54 passed, 4 load failures** (`motion_test.dart`, `offline_ui_test.dart`,
  `replay_navigation_test.dart`, `ui_test.dart`). Errors were the then-missing
  `LiquidBand` and `BottleButton.visualLiquid` in the in-progress board/bottle
  interface. The audio tests passed within that run. Preserve this snapshot in
  `audio-flutter-suite.log`; root will perform final combined regression after
  integration settles. This run does not establish a passing app suite.

From project root:

- `.venv/bin/python tools/assets/audio_generate.py --check`: six deterministic
  originals reproduced exactly at both destinations, bounds and zero endpoints
  passed. `audio-generation-check.log`.
- `.venv/bin/python tools/assets/audio_verify.py`: independently decoded all six
  packaged assets; hashes/frames/format/durations/RMS/peaks/loop points passed;
  original Nunito package identities and unchanged copies passed.
  `audio-asset-verification.log`.

Requirements covered here: ART-07 provenance/copy, ART-08 original independent
files/traceability and policy, AC-31 nonblocking audio-off policy. Real plugin
instantiation/playback on iOS/Android, human audible quality, native loop gaps,
device interruption behavior, actual rendered font weights/digits/punctuation,
and narrow-screen/large-text acceptance are not established by host sink tests.
Root's real-app integration and independent acceptance own those remaining checks.
