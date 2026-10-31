# Runtime selection

The runtime `app/assets/audio/dream-culture.mp3` is the complete byte-identical official MP3; its candidate source is the existing `../dream-culture-original.mp3` (no redundant third copy). It contains 214.29 seconds of valid audio and is played at linear gain0.12 in a full-track loop. No time/pitch or content edits.

`pour.wav` is a 2-second stable excerpt at original pitch. Source is the official public HQ MP3, not a lossless original. Decode with macOS CoreAudio:

```sh
afconvert -f WAVE -d LEI16 -c 1 ../pouring-water-official-hq.mp3 /private/tmp/pourlune-water-decoded.wav
```

Read the decoded 44100Hz signed16 mono PCM frames52920:141120 (1.2–3.2 seconds). Apply a 16ms cosine fade to both ends (`sin(pi/2*i/706)^2` for i0:706); encode with `tools.assets.audio_generate.encode('pour', samples)`, which normalizes sample peak to0.24 and sets endpoints to zero. No speed change. `manifest.json` freezes actual bytes/hash/measurements. Asset is looped at gain0.65 only between renderer flow start/end; shorter pours stop early, longer pours may loop. Native player transport and subjective listening are separate evidence.

The older audio/ folder retains historical synthesized pour/background files; these are no longer runtime sources. audio_generate.py generates only the four retained original effects, and verifies these selected files without overwriting them. The shipped text app/assets/audio/ATTRIBUTION.txt is visible through the existing Licenses screen.
