# Selected Audio Implementation Plan

> Execute inline with superpowers:executing-plans; parent owns independent review. No new workers or parallel toolchains.

**Goal:** Integrate the two user-selected recordings and synchronize water with visible flow.
**Architecture:** Keep GameAudio/audioplayers and full original Dream Culture MP3 at low gain. Loop a stable water PCM segment only during the existing renderer flow; forward start/end through current board widgets. No business or animation changes.
**Spec:** docs/pmpowers/specs/2026-10-26-selected-audio.md
**Tech:** pinned Flutter/Dart/audioplayers/Flame, Python stdlib, afconvert for one-time source decode.

Constraints: F9/D79 untouched; ordinary main on dedicated QA with Firebase none/ads disabled; no dependency/lock changes or upload. Keep four original effects. Ship CC BY4 credit/editing disclosure and CC0 provenance in existing Licenses. Original design package immutable.

Review focus: delayed decoder cannot start water after flow end; approach/landing silent; short/long and reduced-motion flows stop; pause/background/mute stop; generator cannot overwrite selected recordings.

- [x] Add failing late-queue and real-renderer flow/cancel checks; observe failure.
- [x] Invalidate queued effect at flow end; forward renderer callbacks (including existing large-text path), loop water, remove premature controller-feedback pour sound.
- [x] Copy full music; derive faded/leveled stable water PCM from official HQ MP3; keep four originals. Save hashes/derivation and shipped credit; protect third-party files in generator/verification.
- [x] Run relevant audio/Flame tests, analysis and assets checks; serial build dedicated ordinary main, observe actual native playback and interruption. Parent reviews result; record physical/subjective limits, no upload.

Ruling: Native loop acceptance uses directly advancing native position after wrap; Dart completed state also occurs during native loops in the pinned package. No SDK change; subjective acoustic quality remains independent.
