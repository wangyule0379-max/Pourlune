"""Check/install the explicit v5 calibration; no runtime generation or store access."""
import argparse
import hashlib
import json
from pathlib import Path

from author_main60_v4 import build_pack as previous_pack, output_bytes, DESTINATIONS
from validate import ContentError, read_json, repetition_audit, validate_puzzle

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'docs/content/design/main60-calibration-v5.json'


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


def build_pack():
    data = read_json(SOURCE)
    previous, _ = previous_pack()
    pack = dict(previous)
    rows = data['levels']
    if len(rows) != 40 or {r['level'] for r in rows} != set(range(21, 61)):
        raise ContentError('v5 must replace exactly levels21–60')
    for row in rows:
        n = row['level']
        pid = f'main-{n:03}'
        old, p = previous[pid], row['puzzle']
        if hashlib.sha256(output_bytes(pid, old)).hexdigest() != row['previous_sha256']:
            raise ContentError(f'{pid}: v4 baseline mismatch')
        if p['puzzle_id'] != pid or p['main_level'] != n:
            raise ContentError(f'{pid}: identity mismatch')
        if p['content_version'] != old['content_version'] + 1:
            raise ContentError(f'{pid}: revision must advance exactly once')
        if p['initial_bottom_to_top'] == old['initial_bottom_to_top']:
            raise ContentError(f'{pid}: unchanged board must not be a replacement')
        if p['target_labels'] != old['target_labels'] or p['capacity'] != 4:
            raise ContentError(f'{pid}: fixed five-color/two-buffer rules changed')
        validate_puzzle(p)
        pack[pid] = p
    for name, digest in data['protected_sha256'].items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
            raise ContentError(f'protected first20/daily/catalog changed: {name}')
    daily = [read_json(p) for p in (ROOT / 'app/assets/puzzles/daily').glob('*.json')]
    audit = repetition_audit(list(pack.values()) + daily)
    if any(audit[k] for k in ('exact_groups', 'equivalent_groups', 'liquid_structure_groups')):
        raise ContentError(f'duplicate content: {audit}')
    return previous, pack


def expected_bytes(pid, puzzle):
    return output_bytes(pid, puzzle) if puzzle['main_level'] <= 20 else encoded(puzzle)


def install(previous, pack, destinations=DESTINATIONS):
    # Validate BOTH complete destinations before any write. Existing edits are
    # never silently overwritten; repeated installation is idempotent.
    for directory in destinations:
        for pid, p in pack.items():
            if (directory / f'{pid}.json').read_bytes() not in (
                output_bytes(pid, previous[pid]), expected_bytes(pid, p)):
                raise ContentError(f'unknown content edit: {directory / pid}')
    for directory in destinations:
        for pid, p in pack.items():
            path = directory / f'{pid}.json'
            value = expected_bytes(pid, p)
            if path.read_bytes() != value:
                path.write_bytes(value)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--install', action='store_true')
    args = parser.parse_args()
    previous, pack = build_pack()
    if args.install:
        install(previous, pack)
    for directory in DESTINATIONS:
        for pid, p in pack.items():
            if (directory / f'{pid}.json').read_bytes() != expected_bytes(pid, p):
                raise ContentError(f'packaged definition differs: {directory / pid}')
    print(json.dumps(dict(main=60, changed=40, first20_daily_catalog_unchanged=True,
                         human_difficulty='unverified', installed=args.install)))


if __name__ == '__main__':
    main()
