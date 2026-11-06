# Glass garden — main play surface

Scope: visual cohesion of the existing gameplay screen. Level definitions, liquid pigment, pour geometry, interactions, audio and bottle dimensions are unchanged.

Art direction: upper-left daylight; warm ivory and blush garden with mint reflected light; restrained corner blossoms; clear cool-edged glass; cream glazed ceramic controls and collector socket. Saturated water is the focal point.

## Assets and provenance

- `app/assets/art/garden-daylight.webp`: OpenAI ImageGen edit of the existing garden background. Generated 916 × 1717, converted to WebP quality 85. Full-screen cover, also preloaded for startup.
- `app/assets/art/collector-porcelain.png`: OpenAI ImageGen edit of the existing collector socket. Transparent source 1774 × 887. Technically cropped to alpha-content bounds (185,144)-(1612,711), resized to 440 px wide with Lanczos and PNG optimization. Rendered at 110 × 44 logical pixels. Original files retained outside the repository.
- Existing glass reflection/collar sprites retained. Canvas glass edge palette and HUD CSS adjusted to match the new light and ceramic material. No extra animation loops or shaders.

## Generation prompts

### Background

Use case: precise-object-edit. Edit target: attached existing Pourlune garden background, retain the joyful soft peach/pink blossom garden identity, full bleed tall portrait mobile game background. Produce ONLY the background asset, no text, UI, bottles, borders or objects in the play area. Upgrade it to a cohesive luminous glass-garden art direction: clean polished 2.5D illustration, gentle upper-left morning daylight, warm ivory central area (#fff8ef), airy pale mint reflected light along the distant edges, a soft peach-blush top and lower edge. Replace the large uniform orange wash with extremely subtle spatial depth, soft out-of-focus garden colors at outer edges, a graceful diffused pool of daylight in the center. Keep the central 80% of width and vertical 15%-88% very quiet and high-key so colored glass bottles remain perfectly readable. Delicate sculpted pink blossoms and fresh mint/sage leaves only at top-right and bottom corners, smaller and more restrained than reference, softly receding background foliage. No dark outlines, no cloudy haze over the center, no grain, no extra decorative particles, no bokeh dots in the play area. Fresh, bright, playful, airy, never dim or desaturated. Maintain seamless full-screen artwork suitable for CSS cover cropping; no frame or beige margins. Tall portrait approximately 960x1800.

### Socket

Use case: precise-object-edit. Edit target: attached existing collector socket game sprite. Keep the centered front-facing slightly overhead orthographic view, elliptical recess accepting a glass bottle, and small centered mint crescent emblem on the front. Redesign this single socket as a premium slim glazed cream ceramic receiver base for Pourlune's luminous glass garden. Reduce the heavy red plastic outer plinth to a very thin pale mint lower rim. Warm ivory ceramic body (#fff8ed), subtle peach reflected light, clean porcelain glaze, upper-left soft daylight, precise luminous rim, gentle cool sage shadow on lower-right. Wider-than-tall low profile, approximately 2.5:1 visible silhouette. Circular opening in perspective approximately 60% of total width, empty, no bottle, no liquid. Keep all parts within canvas and tightly composed with a modest transparent margin. No large bright red parts, no metallic gold, no pedestal stand, no text or numerals, no scene. Transparent RGBA background. Single production game sprite, crisp clean silhouette at 110px display width, consistent polished 2.5D casual game material, readable smooth forms not noisy texture.

A follow-up transparent-edge cleanup generation was inspected and rejected because it produced a more visible fringe. The first socket's low-alpha margin was excluded by content-bound cropping; the normalized sprite was visually checked on the actual game background at phone size.

## Verification

- Existing automated suite: 67/67 pass, including pouring geometry, liquid color, cache and layout checks.
- Browser CSS viewport 390 × 844: two-row normal bottles, empty glass, mystery layers, regular bottle one-layer drain captured during flow.
- Browser CSS viewport 320 × 568: level 7 two-row-tall collector; levels 10/11/12 three-row collectors left/right/center. No page overflow; level 11 bottle hit areas measured approximately 44 × 89 px (collector 44 × 280).
- Level 11: undo then pour one pink layer into three-row collector; captured saturated final film and vertical stream. Control state returns after pouring.
- Screenshots stored in adjacent outputs/glass-garden-qa-2026-11-05. Browser viewport tests are not physical-device tests.

No level data or save storage modified. Public progress is verified after deployment without playing a move there.
