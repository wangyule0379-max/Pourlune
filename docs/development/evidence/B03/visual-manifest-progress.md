# B03 visual manifest and read-only verification

2026-10-22. Fixed inventory: **23 selected PNGs** (3 scene bases, 15 object layers,
3 bottle layers, game background and icon source), with **22 exact app copies**.
Icon source is not an app-bundle asset; root's platform exports are a separate
deliverable. This subtask inspected metadata/pixels/hashes only and did not edit
any production image or Flutter source.

Files: `tools/assets/visual_manifest.py`, `tools/assets/test_visual_manifest.py`,
`docs/design/production-candidates/runtime/manifest.json` and this evidence set.
Only Python stdlib plus the already bundled Pillow are used; no runtime app
dependency or package installation.

From project root, the routine commands are:

```sh
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/assets/visual_manifest.py --write
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/assets/visual_manifest.py --check
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest discover -s tools/assets -v
```

`--write` explicitly records the current selected bytes and geometry-source
hashes after intended changes are reviewed. `--check` never rewrites the manifest:
it fails on image, app copy, geometry, reference or provenance-record drift.
Both modes print one compact machine-readable JSON object and return nonzero on
failure. Root must rerun `--write` after final scene/bottle calibration or raw
generation metadata updates, then run `--check` for the final delivery snapshot.

Per asset, the deterministic manifest includes a stable ID, candidate and app
paths, SHA256/bytes, actual PNG format/dimensions/mode, alpha min/max and pixel
counts, dominant-alpha (>8) bounding box, ImageGen record JSON pointer and raw
source path, original design comparison references, logical geometry source,
candidate status and **UNCONFIRMED** commercial authorization. The five source
record files, four original reference boards and the two Flutter geometry source
files also have hashes. The raw sources outside the repo are provenance records;
the routine check reads the repository copies, not the user's external generator
directory. Exact ImageGen input roles remain in linked source records; the
manifest's board pointers are design comparison sources.

The fixed path set rejects missing/extra PNGs. Each candidate SHA must be unique;
this detects exact accidental content duplication, not subjective visual
similarity. All 22 app PNGs must match candidate bytes exactly. The selected scene
and icon canvases are 1254×1254; bottle/background canvases are 1024×1536. Scene
and bottle layers must be RGBA with actual zero alpha and a nonempty visible
subject. Their dominant-alpha bounds must stay inside the canvas. RGB opaque
background/icon sources are checked as such. No hard alpha255 core is required,
so the documented alpha252/253 Seaside object cores are retained. Low-alpha
speckles outside the dominant bounds are permitted and recorded without cleanup.

The bottle front center ROI x=.32..68, y=.32..82 is decoded and must have max
alpha <=1. This preliminary transparent-center condition is **not** the final
liquid clipping path or proof that assembled bottle art is correct. The manifest
binds `bottle.dart` and `scene_art.dart` source hashes to this snapshot, while
rendered placement, clipping and animation correctness require runtime evidence.

Actual checks run:

- Test-first no-op implementation: **10 failures** for missing required behavior
  (`visual-manifest-red.log`).
- Complete tools/assets unittest discovery after implementation: **10 passed**
  (`visual-manifest-tests.log`). Each image mutation is confined to temporary
  copies: missing/extra file, app drift, modified valid PNG bytes, wrong size,
  duplicate content, flattened alpha, and an opaque front-window pixel. A source
  calibration mutation also proves geometry drift requires an explicit refresh.
- Initial `--write`: pass, 23 assets / 22 copies / 0 exact duplicates
  (`visual-manifest-write.json`).
- Immediate `--check`: same pass result (`visual-manifest-check.json`). These
  are initial snapshots; subsequent root calibration intentionally invalidates
  the old geometry hashes until refreshed.

No 18 scene-progress compositions, 15 milestones, actual native visuals,
commercial rights, performance, font rendering or UI/device acceptance is
asserted. Root's combined native capture and independent acceptance remain
separate. No changes to other metadata, image pixels, platform exports, app
source, tracking or independent reports; no staging/commit/push.
