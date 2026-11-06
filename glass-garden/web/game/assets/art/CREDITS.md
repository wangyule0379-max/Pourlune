# Sorbet Garden art

Main play surface update, 2026-11-05: `garden-daylight.webp` and `collector-porcelain.png` are OpenAI ImageGen edits of the original background and socket. Original art remains in this directory; generation prompts, normalization details and verification are recorded in `../../../docs/glass-garden-art-2026-11-05.md`.

Selected direction: the second displayed Product Design mockup, created for Pourlune.
Background, pink droplet, collector socket, and crystal-glass sprite generated with OpenAI ImageGen against that selected reference. Source assets are retained in the author's local generated_images directory. The glass sprite uses separately rendered neck, straight walls and base so the 10-layer collector preserves the normal bottle's neck proportions. Liquid, pouring, ripples and completion effects remain real-time Cocos rendering.

Typography: Nunito variable font, https://github.com/google/fonts/tree/main/ofl/nunito (SIL Open Font License; bundled at ../fonts/OFL.txt).
Icons: Phosphor Bold, https://github.com/phosphor-icons/core (MIT; bundled at ../icons/LICENSE). SVGs are unmodified upstream assets, rendered as images.
Water audio and its credits remain in ../audio/.

- `bottle-reflection.png`: generated with OpenAI ImageGen on 2026-11-04 from selected option 2. Black-backed reflection texture; black is converted to transparent alpha at load. Collar/body/foot are independently mapped to the original bottle geometry.
