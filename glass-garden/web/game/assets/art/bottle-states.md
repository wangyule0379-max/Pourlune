# Pourlune bottle state family

Cocos Canvas renderer; fixed 480 × 1040 logical board, portrait browser target. Existing peach garden, clear slender glass and saturated cylindrical liquid remain the visual target. UI is separately anchored in physical CSS pixels.

## Production assets and provenance
Existing bottle-reflection.png, bottle-glass.png and collector-socket.png are unchanged; original provenance remains in CREDITS.md. New rings, arrows, checks and caustics are original runtime Canvas geometry in src/render.js; no added raster textures or external dependencies. Smooth filtering; static composites capped at 2× device scale. Mouth pivot (0, 0), bottom at capacity × unit + 33; collector socket anchors to bottom. Visual effects do not alter collision/hit regions or puzzle state.

## State manifest
| Family/state | Appearance | Duration / behavior |
|---|---|---|
| Ordinary / idle | Existing glass reflections and convex water bands | Cached after waves settle |
| Ordinary / empty | Clear center, reinforced transparent foot | Cached, no fake water |
| Ordinary / selected | Pearl-backed rose outline and floor ellipse | 120 ms lift; stable while selected |
| Either / legal receiver | Pearl-backed teal mouth ring and downward chevron | Static, no idle animation |
| Either / hinted | Rose source/destination outlines, teal directional arrow | Remains until next input |
| Ordinary / pouring | Curved travel, horizontal liquid surface, moving stream, two tail drops | Distance and volume dependent; rigid glass |
| Ordinary / reveal | Mystery veil fades with a brief surface glint | 420 ms; fixed underlying color |
| Ordinary / complete | Surface response, body sweep, floor rings and check | Starts at last water arrival; 900 ms, then fixed small check |
| Collector / receiving | Water impact, socket pulse, quantity feedback | Starts at last water arrival |
| Collector / full | Surface rings, top-to-bottom caustic, delayed socket ring and crescent seal | 1800 ms; source return runs independently |
| Reduced motion | Final visual state and readable badges remain | Short pours; no particles, reveals or full-bottle bloom |

All effects finish, then rendering returns to pause. Existing recorded water and feedback audio remain unchanged. Completion audio fires once at arrival, never again on return. Mobile dialogs cover the viewport; 44 px top controls / close / settings switches, 46 px tools; phone landscape pauses and presents portrait guidance.

## Liquid color during transfer
Liquid keeps the same pigment throughout a pour. Surface shading uses tinted light and dark stops; the curved cap and narrow specular rims shrink with remaining liquid depth. External and internal streams use colored highlights, never a gradient to white. Tail drops shrink without fading against the peach background. Glass reflection textures, edge thickness, body shading, pour geometry and arrival celebrations remain unchanged.
