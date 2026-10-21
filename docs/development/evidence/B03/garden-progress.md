# Garden Nook five object layers — B03-05 / ART-05

2026-10-22. Asset-generation evidence only; actual Flutter composition and
independent visual acceptance remain with the main B03 integration task.

Used the built-in imagegen skill and `image_gen.imagegen`, one call per distinct
object, with `transparent_background: true`. Before generation, inspected the
original `01_Entry_and_Chapters.png`, `04_Win_and_Collection.png` and the newly
generated Garden Nook `base.png`. The original Garden Nook thumbnails supplied
subject/style guidance; the base supplied camera, yarn material and lighting
guidance. No original board was cropped, enlarged or edited. The base was not
modified or baked into an object layer.

All five raw outputs are copied, unchanged, into both:

- `docs/design/production-candidates/runtime/scenes/garden_nook/`
- `app/assets/art/scenes/garden_nook/`

| Raw file | Independent subject | Dominant alpha > 8 bounds (x0,y0,x1,y1) |
|---|---|---|
| piece-1.png | Cream floral arch with green vines, pink roses and white flowers; open transparent center | 100,61,1201,1205 |
| piece-2.png | Empty round cream bistro table, lavender edge, pedestal and curled feet | 100,165,1154,1170 |
| piece-3.png | Single cream/lavender garden chair with seat facing right | 242,36,1058,1207 |
| piece-4.png | Two potted leafy flowering plants grouped as one overlay | 83,84,1187,1168 |
| piece-5.png | Cream cup/saucer beside a small floral vase, for tabletop placement | 77,78,1220,1143 |

All are actual **1254×1254 RGBA PNGs**, with alpha minimum 0, maximum 255 and
partial-alpha edge pixels. Read-only Pillow inspection checked actual alpha,
dimensions and subject bounding boxes; SHA256 and raw-byte comparisons checked
both delivery copies against each original generated file. No resizing,
cropping, recoloring, alpha processing, compositing or other programmatic image
edits were applied. The main subjects have complete margins without clipped
feet/leaves/flowers. Some raw images contain very faint alpha <= 8 speckles far
outside the main subject, occasionally reaching canvas edges; the manifest
records both strict nonzero-alpha and dominant-alpha bounds. Do not use the
strict nonzero-alpha box as an assumed object crop or placement anchor.

Full-size visual inspection found the requested standalone objects, coherent
cream/lavender/green/pink chunky yarn treatment and soft upper-left lighting,
with no room/base, painted rectangle, UI or text in the cutouts. Final relative
scale, footing, chair orientation within the arrangement, table/tea alignment,
edge appearance on the actual app background, overlap and occlusion remain for
runtime inspection. Each independent generator call can introduce small camera
or yarn-scale differences; this is not proof that the combined scene has passed.

`garden-generation.json` contains the **exact prompt per call**, input reference
roles and hashes, generated source paths, delivered paths, dimensions, actual
alpha statistics, byte counts, SHA256 values and provenance/rights statement.
The source files remain at their tool-returned paths under
`/Users/wangyule/.codex/generated_images/01a15ff6-48ff-7f70-ab39-008660e25520/`.
Workspace copies are the deliverables; no runtime asset depends on that source
directory. These are generated derivatives guided by user-provided reference
art whose commercial authorization remains unconfirmed. No new commercial
rights approval is asserted.

Checks actually run: RGBA/format/dimensions/alpha checks on every original,
dominant-alpha margin checks on all five, raw-source/candidate/app byte equality
and SHA256 checks on all five, plus unchanged hash checks of the three input
references. All passed. No Flutter, device or subjective human acceptance is
claimed here. Root owns normalized placement and the combined 18 progress / 15
milestone native QA. No changes to base.png, audio, controller, pubspec, original
designs, tracking or independent acceptance reports; no staging/commit/push.
