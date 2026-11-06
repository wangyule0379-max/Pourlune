# Glass detail and mobile controls

User-approved direction: refine the existing glass garden. iOS and Android phones are the primary target; desktop is secondary. No level/progression changes.

## Implementation

- Replaced overlapping raster collar/shoulder/foot highlights with two clean procedural lip contours, a tapered shoulder reflection and a single foot refraction. Kept the existing body reflection at restrained opacity. The unused 187 KB collar image is no longer downloaded at startup; source art remains preserved.
- Kept liquid volume, pour angle, outlet position, stream and pigment gradients unchanged. Surface highlights now occupy part of the perimeter, with small curved wall menisci that scale down with remaining volume. RGB shade colors are supported by the alpha helper.
- Contact shadows fade when the bottle lifts and return on landing; subtle ground color comes only from visible bottom water, never hidden layers.
- Softened the top backdrop with a static translucent gradient, thinned control borders and shadows, tightened collector count/label spacing and reduced secondary text weight. No new perpetual effects, filters or asset downloads.
- Top icons/help are 48 × 48 CSS px; tool buttons are 48 px tall. Visual chrome remains thin. Hover effects apply only to fine-pointer hover devices. HUD text selection is disabled. Restored-game notification expires after 3 seconds, including mystery levels; initial mystery instructions remain available.

## Verification

- Existing automated suite: 67 passing checks, including all-layout pour lip clearance, vertical streams, thin-liquid saturation, cache, save and viewport checks.
- Browser CSS 390 × 844: bottle details reviewed at actual size and a magnified screenshot; one purple layer drained between regular bottles with flow frames captured.
- Browser CSS 320 × 568: levels 7, 10, 11, 12 inspected for two/three-row tall collectors at left/right/center. Document width/height equals viewport with no overflow. Top/footer controls measured approximately 48 px high; regular tool widths 69–88 px.
- Level 11: undo then one-pink-layer pour into a three-row collector; vertical flow and saturated final film captured, controls return to enabled after pouring.
- Browser console: no warnings/errors in inspected local pages.
- Evidence: adjacent `outputs/glass-detail-qa-2026-11-05/`. These are browser viewport checks, not iOS/Android physical-device or native-package tests. No simulator/emulator started.

Existing idle rendering pause and bottle cache remain in place. A native release still needs platform-specific safe-area, lifecycle, memory, frame-time, touch and audio validation on actual iOS/Android builds.
