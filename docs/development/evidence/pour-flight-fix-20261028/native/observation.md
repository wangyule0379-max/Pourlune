# Pour flight native observation — 2026-10-28

Independent QA bundle dev.pourlune.pourFlightValidation, normal main, Firebase/ads/GM disabled, on existing Pourlune GM QA 20261028 iPhone 17 Pro, iOS 26.5, identifier 2894A85E-04FC-4857-A856-3BEFF2CCB565. Simulator UI Record Screen, no device mask; AVFoundation readback of each recording is 1206×2622. Each board came from prepared isolated SQLite fixture; 8 bottles is a core extra-bottle QA fixture, not an ad reward or natural play.

| Bottles | Action | Before → after revision / moves | Native observation |
|---|---|---|---|
| 4, level 4 | 3→2 | 8→9 / 8→9 | Green transferred, buffer 3 empty; no victory because orange buffer remains. `4-bottles.mov`; flow frame `frames-4/06.50.jpg`. |
| 5, level 6 | 2→4 | 0→1 / 0→1 | Two orange units transferred; buffer 4 contains two. `5-bottles.mov`; flow frame `frames-5/04.50.jpg`. |
| 6, level 11 | 5→2 | 10→11 / 10→11 | Four green units transferred; native success page appeared; SQLite recorded completed=true and first-clear receipt for pour-qa-6/main-011. `6-bottles.mov`; flow frame `frames-6/05.00.jpg`. |
| 7, level 21 | 5→2 | 11→12 / 11→12 | Purple transferred; returned board persisted. `7-bottles.mov`; flow frame `frames-7/05.50.jpg`. |
| 8, level 21 | 5→2 | 12→13 / 11→12 | Purple transferred; returned board persisted. `8-bottles.mov`; flow frame `frames-8/05.00.jpg`. |

Observed source bottle stays full-sized in sampled steady-flow frames, stream joins source mouth and target, headings and bottom controls remain in frame, and board restores after animation. The shifted target temporarily covers its own fixed label/count in the 7/8 flow frames; the label and count reappear after return. This is recorded for independent visual judgment. Sampled frames are at 0.25 second intervals; continuous frame-by-frame quality has not been independently established. The 4 case did not reach the win transition; 6 did. No physical-device, audio/haptics, or SDK/ad-reward claim is made.

4, 5, 6, 7, 8 fixture board snapshots and native SQLite states were read from the named QA app container only. Xcode stopped that QA app between fixtures, Finder copied each fixture into that app's named database, and the existing scheme ran without building. No old app or F9 interaction.
