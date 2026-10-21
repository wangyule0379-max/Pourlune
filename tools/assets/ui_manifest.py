#!/usr/bin/env python3
"""Inspect the ten B03-R01 UI PNGs; --write changes JSON only, never pixels."""

import argparse
import json
from pathlib import Path
import re

from PIL import Image

from visual_manifest import require, sha

CANDIDATE = Path('docs/design/production-candidates/runtime/ui')
RUNTIME = Path('app/assets/art/ui')
EVIDENCE = Path('docs/development/evidence/B03-R01')
GEOMETRY = Path('app/lib/presentation/knit_components.dart')
BOARDS = Path('docs/design/original/Pourlune_Design_Pack/boards')
CROPS = Path('docs/design/ui-addendum/assets/source-crops.json')
RECORDS = [EVIDENCE / name for name in [
    'root-ui-assets.json', 'root-ui-prompts.json', 'cream-generation.json',
    'map-generation.json', 'calendar-generation.json', 'success-generation.json',
]]
EXPECTED = {
    'logo': ((1969, 799), 'RGBA'),
    'green-frame': ((2079, 756), 'RGBA'),
    'cream-frame': ((1896, 830), 'RGBA'),
    'moon': ((1374, 1145), 'RGBA'),
    'chapters': ((1474, 1067), 'RGBA'),
    'calendar': ((1254, 1254), 'RGBA'),
    'success': ((1254, 1254), 'RGBA'),
    'cream-tile': ((60, 35), 'RGB'),
    'green-tile': ((25, 20), 'RGB'),
    'patch-tile': ((64, 57), 'RGB'),
}
GENERATED = {
    'cream-frame': 'cream-generation.json', 'chapters': 'map-generation.json',
    'calendar': 'calendar-generation.json', 'success': 'success-generation.json',
}


def runtime_geometry(root):
    source = (root / GEOMETRY).read_text()
    table = source.split('const _art = <String, (Size, Rect)>{', 1)[1].split('};', 1)[0]
    pattern = r"'([^']+)':\s*\(Size\(([^)]+)\),\s*Rect\.from(LTRB|LTWH)\(([^)]+)\)\)"
    geometry = {}
    for name, size, kind, rectangle in re.findall(pattern, table):
        size = [int(value.strip()) for value in size.split(',')]
        bounds = [int(value.strip()) for value in rectangle.split(',')]
        if kind == 'LTWH':
            bounds[2] += bounds[0]
            bounds[3] += bounds[1]
        require(name not in geometry, f'duplicate runtime geometry: {name}')
        geometry[name] = (size, bounds)
    require(set(geometry) == set(EXPECTED) - {'cream-tile', 'green-tile'}, 'runtime geometry inventory mismatch')
    return geometry


def provenance(root, name, digest, records, image):
    if name in GENERATED:
        filename = GENERATED[name]
        record = records[filename]
        require(record.get('prompt'), f'generation prompt missing: {name}')
        raw = record.get('source_output') or record.get('source', {}).get('path')
        recorded_sha = record.get('sha256') or record.get('source', {}).get('sha256')
        references = record.get('references') or [record['input']]
        for reference in references:
            require(sha(root / reference['path']) == reference['sha256'], f'reference digest differs: {name}')
        link = {'path': str(EVIDENCE / filename), 'json_pointer': ''}
        extra = {'references': references}
    else:
        rows = records['root-ui-assets.json']
        matches = [(index, row) for index, row in enumerate(rows) if row.get('id') == name]
        require(len(matches) == 1, f'provenance missing/ambiguous: {name}')
        index, record = matches[0]
        raw, recorded_sha = record.get('source'), record.get('sha256')
        link = {'path': str(EVIDENCE / 'root-ui-assets.json'), 'json_pointer': f'/{index}'}
        extra = {}
        if name.endswith('-tile'):
            crop_name = name.removesuffix('-tile')
            definition = json.loads((root / CROPS).read_text())[crop_name]
            original, x, y, width, height = definition
            require(record['original'] == str(BOARDS / original) and record['crop'] == [x, y, width, height], f'source crop definition differs: {name}')
            require((root / raw).read_bytes() == (root / CANDIDATE / (name + '.png')).read_bytes(), f'prototype copy differs: {name}')
            with Image.open(root / BOARDS / original) as source:
                require(0 <= x < x + width <= source.width and 0 <= y < y + height <= source.height, f'source crop bounds invalid: {name}')
                pixels = source.crop((x, y, x + width, y + height)).convert(image.mode)
                require(pixels.size == image.size and pixels.tobytes() == image.tobytes(), f'source crop pixels differ: {name}')
            extra = {
                'source_crop_definition': {'path': str(CROPS), 'json_pointer': '/' + crop_name},
                'source_original': str(BOARDS / original),
                'source_original_sha256': sha(root / BOARDS / original),
                'source_crop_xywh': [x, y, width, height],
                'source_crop_pixels_identical': True,
            }
        else:
            prompt_key = 'green' if name == 'green-frame' else name
            require(records['root-ui-prompts.json'].get(prompt_key), f'generation prompt missing: {name}')
            extra = {
                'prompt_record': {'path': str(EVIDENCE / 'root-ui-prompts.json'), 'json_pointer': '/' + prompt_key},
                'reference_record_limit': 'Prompt describes image references; exact generation input file paths are not recorded in root-ui-assets.json. Original board remains the visual baseline, not a fabricated generation-input record.',
            }
    require(raw, f'raw source path missing: {name}')
    require(recorded_sha == digest, f'provenance digest differs: {name}')
    return {
        'kind': 'original_texture_crop' if name.endswith('-tile') else 'imagegen_reference_derived',
        'evidence_record': link, 'source_path': raw,
        'source_selected_sha256': recorded_sha,
        'raw_generated_path_policy': 'External generation path is archival metadata, not required to exist on another machine.',
        **extra,
    }


def build_manifest(root):
    wanted = {name + '.png' for name in EXPECTED}
    for folder in [CANDIDATE, RUNTIME]:
        actual = {str(path.relative_to(root / folder)) for path in (root / folder).rglob('*.png')}
        require(actual == wanted, f'UI PNG inventory mismatch in {folder}: missing={sorted(wanted - actual)} extra={sorted(actual - wanted)}')
    records = {path.name: json.loads((root / path).read_text()) for path in RECORDS}
    geometry = runtime_geometry(root)
    assets, seen = [], set()
    for name, (dimensions, mode) in sorted(EXPECTED.items()):
        candidate, runtime = CANDIDATE / (name + '.png'), RUNTIME / (name + '.png')
        path = root / candidate
        require(path.read_bytes() == (root / runtime).read_bytes(), f'UI runtime copy differs: {name}')
        digest = sha(path)
        require(digest not in seen, f'duplicate UI content: {name}')
        seen.add(digest)
        with Image.open(path) as image:
            require(image.format == 'PNG', f'not PNG: {name}')
            require(image.size == dimensions, f'wrong UI dimensions: {name}: {image.size}')
            require(image.mode == mode, f'wrong UI mode: {name}: {image.mode}, expected {mode}')
            size, bounds = geometry.get(name, (list(image.size), [0, 0, image.width, image.height]))
            require(size == list(image.size), f'runtime canvas dimensions differ: {name}')
            require(len(bounds) == 4 and 0 <= bounds[0] < bounds[2] <= image.width and 0 <= bounds[1] < bounds[3] <= image.height, f'runtime crop bounds invalid: {name}')
            alpha = image.getchannel('A') if mode == 'RGBA' else None
            if alpha:
                low, high = alpha.getextrema()
                require(low == 0 and high > 0, f'generated transparency missing: {name}')
            assets.append({
                'id': name, 'status': 'production_candidate', 'rights_status': 'UNCONFIRMED',
                'candidate_path': str(candidate), 'runtime_path': str(runtime),
                'candidate_appcopy_identical': True, 'sha256': digest,
                'bytes': path.stat().st_size, 'format': 'PNG', 'dimensions_px': list(image.size),
                'mode': mode, 'alpha_min_max': list(alpha.getextrema()) if alpha else [255, 255],
                'runtime_geometry': {
                    'source': str(GEOMETRY), 'kind': 'manual_runtime_display_crop' if name in geometry else 'full_canvas_repeating_texture',
                    'canvas_px': size, 'crop_xyxy': bounds,
                    'meaning': 'Manually declared Flutter display bounds, read from source; not an automated alpha crop or proof of visual correctness.',
                },
                'provenance': provenance(root, name, digest, records, image),
            })
    return {
        'schema_version': 1, 'task': 'B03-R01 bounded UI asset inventory',
        'status': 'production_candidate', 'rights_status': 'UNCONFIRMED',
        'rights_basis': 'Reference-derived generation and original texture crops; commercial authorization is unconfirmed.',
        'inspection_policy': 'Read-only image inspection. --write only writes this JSON. Display bounds are manual source geometry, not pixel edits.',
        'acceptance_limits': 'No independent visual, text/semantics, Flutter rendering, device, audio, performance or rights acceptance asserted.',
        'geometry_source': {'path': str(GEOMETRY), 'sha256': sha(root / GEOMETRY)},
        'provenance_records': [{'path': str(path), 'sha256': sha(root / path)} for path in [*RECORDS, CROPS]],
        'assets': assets,
    }


def check_manifest(root):
    recorded = json.loads((root / CANDIDATE / 'manifest.json').read_text())
    require(recorded == build_manifest(root), 'UI manifest drift; inspect intended changes before explicit --write')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--write', action='store_true')
    modes.add_argument('--check', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    try:
        if args.write:
            (root / CANDIDATE / 'manifest.json').write_text(json.dumps(build_manifest(root), indent=2, ensure_ascii=False) + '\n')
        else:
            check_manifest(root)
        print(json.dumps({'status': 'pass', 'mode': 'write' if args.write else 'check', 'assets': 10, 'runtime_copies': 10, 'rights_status': 'UNCONFIRMED', 'visual_acceptance': 'NOT_ASSERTED'}))
    except (OSError, ValueError, KeyError, IndexError) as error:
        print(json.dumps({'status': 'fail', 'error': str(error)}))
        raise SystemExit(1)


if __name__ == '__main__':
    main()
