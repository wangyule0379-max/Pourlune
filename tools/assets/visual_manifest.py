#!/usr/bin/env python3
"""B03's fixed 23-image inventory. Inspect/hash only; never modify image pixels.

Run with bundled Python/Pillow: visual_manifest.py --write | --check.
--write explicitly refreshes the snapshot after approved asset/geometry changes;
--check compares without rewriting. Neither mode establishes visual acceptance.
"""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

CANDIDATE = Path("docs/design/production-candidates/runtime")
EVIDENCE = "docs/development/evidence/B03/"
GEOMETRY = ["app/lib/presentation/bottle.dart", "app/lib/presentation/scene_art.dart"]
RECORDS = ["root-generated-assets.json", "image-prompts-base.json", "garden-generation.json", "seaside-generation.json", "bottle-generation.json"]
BOARDS = "docs/design/original/Pourlune_Design_Pack/boards/"
REFERENCES = [BOARDS + name + ".png" for name in ["00_Approved_Style_Reference", "01_Entry_and_Chapters", "02_Tutorial_Play_Pause", "04_Win_and_Collection"]]
EXPECTED = {
    "background.game": "backgrounds/game.png",
    **{"bottle." + name: "bottles/" + name + ".png" for name in ["back", "front", "shadow"]},
    "icon.brand_source": "icons/brand-source.png",
    **{"scene." + scene + "." + name: "scenes/" + scene + "/" + name + ".png"
       for scene in ["color_studio", "garden_nook", "seaside_corner"]
       for name in ["base", *["piece-" + str(n) for n in range(1, 6)]]},
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def provenance(relative, records):
    candidate = str(CANDIDATE / relative)
    if relative.startswith("bottles/"):
        file, rows, prefix = "bottle-generation.json", records["bottle-generation.json"]["generations"], "/generations"
        matches = [(i, row) for i, row in enumerate(rows) if row.get("selected") and row.get("asset") == Path(relative).stem]
        source_key = "raw_path"
    elif "/piece-" in relative and any(s in relative for s in ["garden_nook", "seaside_corner"]):
        garden = "garden_nook" in relative
        file = "garden-generation.json" if garden else "seaside-generation.json"
        key = "pieces" if garden else "assets"
        rows, prefix = records[file][key], "/" + key
        matches = [(i, row) for i, row in enumerate(rows) if row.get("candidate_path") == candidate]
        source_key = "generated_source_path" if garden else "raw_generated_path"
    else:
        file, rows, prefix = "root-generated-assets.json", records["root-generated-assets.json"], ""
        matches = [(i, row) for i, row in enumerate(rows) if row.get("candidate") == candidate]
        source_key = "source"
    require(len(matches) == 1, f"ImageGen provenance missing/ambiguous: {candidate}")
    index, record = matches[0]
    require(record.get(source_key) and record.get("prompt"), f"ImageGen source/prompt missing: {candidate}")
    links = [{"path": EVIDENCE + file, "json_pointer": prefix + "/" + str(index)}]
    if relative.endswith("/base.png"):
        key = {"color_studio": "studio_base", "garden_nook": "garden_base", "seaside_corner": "seaside_base"}[Path(relative).parent.name]
        require(key in records["image-prompts-base.json"], f"base prompt missing: {key}")
        links.append({"path": EVIDENCE + "image-prompts-base.json", "json_pointer": "/" + key})
    return links, record[source_key]


def build_manifest(root: Path):
    # UI owns a separate exact inventory in ui_manifest.py; retain all 23 rules.
    actual = {str(p.relative_to(root / CANDIDATE)) for p in (root / CANDIDATE).rglob("*.png")
              if p.relative_to(root / CANDIDATE).parts[0] != "ui"}
    wanted = set(EXPECTED.values())
    require(actual == wanted, f"PNG inventory mismatch: missing={sorted(wanted - actual)} extra={sorted(actual - wanted)}")
    records = {name: json.loads((root / (EVIDENCE + name)).read_text()) for name in RECORDS}
    entries, seen = [], {}
    for identity, relative in sorted(EXPECTED.items()):
        candidate = CANDIDATE / relative
        path = root / candidate
        digest = sha(path)
        require(digest not in seen, f"duplicate content: {relative} and {seen.get(digest)}")
        seen[digest] = relative
        runtime = None if relative.startswith("icons/") else Path("app/assets/art") / relative
        require(runtime is None or (root / runtime).read_bytes() == path.read_bytes(), f"runtime copy differs: {relative}")
        transparent = not relative.startswith(("backgrounds/", "icons/"))
        with Image.open(path) as image:
            expected_size = (1024, 1536) if relative.startswith(("bottles/", "backgrounds/")) else (1254, 1254)
            require(image.format == "PNG", f"not PNG: {relative}")
            require(image.size == expected_size, f"wrong dimensions: {relative}: {image.size}")
            require(image.mode == ("RGBA" if transparent else "RGB"), f"expected {'RGBA' if transparent else 'RGB'}: {relative}")
            alpha = image.getchannel("A") if transparent else None
            histogram = alpha.histogram() if alpha else None
            bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox() if alpha else (0, 0, image.width, image.height)
            if transparent:
                require(histogram[0] > 0 and sum(histogram[9:]) > 0, f"missing true transparency/subject: {relative}")
                require(bbox and 0 < bbox[0] < bbox[2] < image.width and 0 < bbox[1] < bbox[3] < image.height, f"dominant alpha bounds clipped: {relative}")
            window = None
            if relative == "bottles/front.png":
                roi = (.32, .32, .68, .82)
                extrema = alpha.crop(tuple(round(v * (image.width if i % 2 == 0 else image.height)) for i, v in enumerate(roi))).getextrema()
                require(extrema[1] <= 1, f"front window alpha exceeds 1: {extrema}")
                window = {"normalized_roi_xyxy": roi, "alpha_min_max": extrema, "meaning": "Preliminary transparent center only; not the final liquid clip or render acceptance."}
            links, raw_source = provenance(relative, records)
            bottle = relative.startswith("bottles/")
            entry = {
                "id": identity, "status": "production_candidate", "rights_status": "UNCONFIRMED",
                "rights_basis": "Generated derivative of user-provided visual reference; commercial authorization remains unconfirmed.",
                "candidate_path": str(candidate), "runtime_path": str(runtime) if runtime else None,
                "platform_exports": "Separate root-owned platform export manifest; source is not bundled." if runtime is None else None,
                "sha256": digest, "bytes": path.stat().st_size, "format": image.format,
                "dimensions_px": image.size, "mode": image.mode,
                "alpha_min_max": alpha.getextrema() if alpha else (255, 255),
                "transparent_pixels": histogram[0] if histogram else 0,
                "partial_alpha_pixels": sum(histogram[1:255]) if histogram else 0,
                "dominant_alpha_gt8_bbox_xyxy": bbox,
                "raw_imagegen_metadata": links, "raw_imagegen_source_path": raw_source,
                "design_reference_paths": [REFERENCES[0]] if relative.startswith("icons/") else [REFERENCES[0], REFERENCES[2]] if bottle or relative.startswith("backgrounds/") else [REFERENCES[1], REFERENCES[3]],
                "design_reference_role": "Design comparison sources; exact generation input roles remain in the linked ImageGen records.",
                "logical_geometry_source": GEOMETRY[0] if bottle else GEOMETRY[1] if relative.startswith("scenes/") else None,
            }
            if window:
                entry["front_window_inspection"] = window
            entries.append(entry)
    # JSON roundtrip normalizes tuples so check agrees with the saved JSON.
    return json.loads(json.dumps({
        "schema_version": 1, "task": "B03 ART-01/03/04/05/06/09 visual inventory",
        "status": "production_candidate", "rights_status": "UNCONFIRMED",
        "inspection_policy": "Read-only pixels/hash. Dominant alpha >8 tolerates documented low-alpha speckles; no hard-opaque core requirement (some cores are alpha252). Exact expected dimensions apply to these 23 selected outputs.",
        "acceptance_limits": "No claim that 18 scene compositions, 15 milestones, font/UI, devices, performance or commercial rights have passed. Geometry hashes bind source versions, not visual correctness.",
        "geometry_sources": [{"path": p, "sha256": sha(root / p)} for p in GEOMETRY],
        "generation_records": [{"path": EVIDENCE + p, "sha256": sha(root / (EVIDENCE + p))} for p in RECORDS],
        "visual_reference_sources": [{"path": p, "sha256": sha(root / p)} for p in REFERENCES],
        "assets": entries,
    }))


def check_manifest(root: Path):
    recorded = json.loads((root / CANDIDATE / "manifest.json").read_text())
    require(recorded == build_manifest(root), "visual manifest drift; inspect intended changes and explicitly refresh with --write")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--write", action="store_true")
    modes.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    try:
        if args.write:
            (root / CANDIDATE / "manifest.json").write_text(json.dumps(build_manifest(root), indent=2, ensure_ascii=False) + "\n")
        else:
            check_manifest(root)
        print(json.dumps({"status": "pass", "mode": "write" if args.write else "check", "assets": 23, "runtime_copies": 22, "duplicates": 0, "rights_status": "UNCONFIRMED", "visual_acceptance": "NOT_ASSERTED"}))
    except (OSError, ValueError, KeyError) as error:
        print(json.dumps({"status": "fail", "error": str(error)}))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
