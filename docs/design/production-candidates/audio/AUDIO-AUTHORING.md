> Current runtime update (2026-10-26): only select/error/win/reveal retain this original synthesis. Background and pour are replaced by the user-selected licensed recordings documented in `../audio-selected-20261026/`; the six-original record below is historical, not an authorship claim over those recordings.

# B03 audio authoring and authorization record

Date: 2026-10-22. Scope: B03-06 / ART-08.

These six recordings were created in this task by Codex for Pourlune using
`tools/assets/audio_generate.py`. Every sample comes from analytic sine waves,
envelopes and a Python stdlib seeded pseudo-random noise generator. The script
contains the entire note sequence, timing and timbre definitions. No recording,
sample pack, downloaded song, external melody reference, commercial music,
voice, system sound or third-party audio was used. Python stdlib is the only
generation dependency. This is procedural synthesis, not a human performance.

The explicit project authorization is the approved B03 execution plan,
`docs/pmpowers/plans/2026-10-22-B03-content-and-visuals.md`, B03-06:
“可制作原创短音效，不采购、不借用无授权商用音乐”. The dispatched B03 audio scope
also expressly requests an original quiet looping background soundtrack.
The resulting files are delivered for inclusion and editing in this project
under that instruction; there is no third-party audio license to obtain or
attribution to attach. This authoring record states the actual inputs and
authorization basis. It does not assert a separate human authorship claim or
settle the copyright status of generated output in every jurisdiction.

The candidate recordings and `app/assets/audio/` copies are byte-identical.
`manifest.json` records per-file hashes, durations, PCM format, whole-file loop
points, measured sample peak and unweighted RMS. These are digital signal
measurements, **not** LUFS, true peak, perceived loudness, device volume or
evidence that someone listened. The sample-rate and zero endpoint checks do not
prove native gapless playback. Each change must be regenerated and rechecked.

The background is a 24-second, 80 BPM, eight-bar original pad and sparse bell
sequence. Its whole-file loop has zero endpoints and soft note releases.
The runtime applies linear gain 0.45 to music and 0.65 to short cues, in addition
to the attenuation already in the PCM files. These are chosen levels pending
listening and device checks, not an independently approved audio mix.

Status: production candidates with source and authorization traceability.
Host tests validate settings/lifecycle policy; device decoding, audible quality,
speaker/headphone balance, interruptions and loop seam remain separate checks.
