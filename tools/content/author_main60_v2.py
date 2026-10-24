"""Build the explicitly curated main60 pack; never generate puzzles at runtime.

Exploration/selection is separate. The checked-in authored inputs are the
reviewable source. This command replays and measures those inputs before writing
anything; --install copies only the 60 main files, never daily or catalog data.
"""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path

from main60_v2 import make_candidate, inspect_route, check_measured_reference
from measure_levels import bounded_search, trace_solution, deletion_audit
from validate import ContentError, read_json, repetition_audit, validate_puzzle

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'docs/development/evidence/main60-content-redesign'


def json_text(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + '\n'


def digest(value):
    return hashlib.sha256(value).hexdigest()


def build_pack(contracts, authored, old, daily):
    expected = set(range(1, 61))
    if ({r['level'] for r in authored} != expected or len(authored) != 60 or
            {r['level'] for r in contracts} != expected or len(contracts) != 60):
        raise ContentError('requires exactly60 unique authored levels and contracts')
    contracts = {r['level']: r for r in contracts}
    pack, cards = {}, []
    for entry in sorted(authored, key=lambda r: r['level']):
        level = entry['level']
        contract = contracts[level]
        pid = contract['puzzle_id']
        previous = old[pid]
        if not entry.get('strategy_notes'):
            raise ContentError(f'{pid}: missing concrete author strategy review')
        if level in [1, 12]:
            if not entry.get('preserve'):
                raise ContentError('immutable anchor must be explicitly preserved')
            puzzle = deepcopy(previous)
        else:
            puzzle = make_candidate(previous, entry['board'], entry['reference_moves'], contract)
        validate_puzzle(puzzle)
        measured = bounded_search(puzzle['initial_bottom_to_top'], puzzle['target_labels'],
                                  len(puzzle['reference_moves']), seconds=30)
        check_measured_reference(puzzle, measured)
        trace = trace_solution(puzzle['initial_bottom_to_top'], puzzle['target_labels'],
                               puzzle['reference_moves'])
        removable = deletion_audit(puzzle['initial_bottom_to_top'], puzzle['target_labels'],
                                   puzzle['reference_moves'])
        if removable and level not in [1, 12]:
            raise ContentError(f'{pid}: reference has removable actions')
        pack[pid] = puzzle
        cards.append({
            'puzzle_id': pid, 'level': level,
            'status': 'authored_and_rule_measured_not_human_difficulty_or_visual_accepted',
            'contract': contract, 'author_strategy_notes': entry['strategy_notes'],
            'old_content_version': previous['content_version'],
            'new_content_version': puzzle['content_version'],
            'source': entry.get('source', 'unchanged anchor'),
            'new_definition_sha256': digest(json_text(puzzle).encode()),
            'search': measured, 'reference_replay': trace,
            'route_observations': inspect_route(puzzle, trace),
            'single_action_deletion_findings': removable,
            'human_playtest': 'not performed; algorithmic replay is not play experience',
        })
    duplicates = repetition_audit(list(pack.values()) + daily)
    if any(duplicates[k] for k in ['exact_groups', 'equivalent_groups', 'liquid_structure_groups']):
        raise ContentError(f'90-pack duplicate: {duplicates}')
    return pack, cards, duplicates


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--install', action='store_true')
    args = parser.parse_args()
    contracts_path = ROOT / 'docs/content/design/main60-level-contracts-v2.json'
    authored_path = ROOT / 'docs/content/design/main60-authored-v2.json'
    old = {p.stem: read_json(p) for p in (EVIDENCE / 'old-main').glob('*.json')}
    daily_files = sorted((ROOT / 'app/assets/puzzles/daily').glob('*.json'))
    protected = daily_files + [ROOT / 'app/assets/catalog/daily.json']
    before = {str(p.relative_to(ROOT)): digest(p.read_bytes()) for p in protected}
    pack, cards, duplicates = build_pack(read_json(contracts_path)['levels'],
                                         read_json(authored_path)['levels'], old,
                                         [read_json(p) for p in daily_files])
    # Check every existing destination before any writes; don't overwrite an
    # unknown concurrent content edit. A reproducible rerun is allowed.
    destinations = [ROOT / 'app/assets/puzzles/main',
                    ROOT / 'docs/content/production-candidates/puzzles/main']
    if args.install:
        for directory in destinations:
            for pid, puzzle in pack.items():
                existing = read_json(directory / f'{pid}.json')
                if existing not in [old[pid], puzzle]:
                    raise ContentError(f'unknown destination edit: {directory / pid}')
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'levels').mkdir(exist_ok=True)
    for card in cards:
        pid = card['puzzle_id']
        (args.output / 'levels' / f'{pid}.json').write_text(json_text(card))
        # Anchors retain bytes as well as semantic identity.
        data = ((EVIDENCE / 'old-main' / f'{pid}.json').read_bytes() if pid in ['main-001', 'main-012']
                else json_text(pack[pid]).encode())
        (args.output / 'levels' / f'{pid}.runtime.json').write_bytes(data)
        card['new_definition_sha256'] = digest(data)
        (args.output / 'levels' / f'{pid}.json').write_text(json_text(card))
        if args.install:
            for directory in destinations:
                (directory / f'{pid}.json').write_bytes(data)
    after = {str(p.relative_to(ROOT)): digest(p.read_bytes()) for p in protected}
    if before != after:
        raise ContentError('protected daily/catalog changed during authoring')
    manifest = {'scope': '60 explicit authored definitions; human/UI/release gates separate',
                'installed': args.install, 'count': len(pack), 'daily_unchanged': before == after,
                'protected_hashes': before, 'duplicates': duplicates,
                'contracts_sha256': digest(contracts_path.read_bytes()),
                'authored_sha256': digest(authored_path.read_bytes()),
                'levels': [{'id': c['puzzle_id'], 'sha256': c['new_definition_sha256'],
                            'version': c['new_content_version'],
                            'shortest': c['search'].get('shortest_within_bound'),
                            'reference_steps': len(c['reference_replay']['steps'])} for c in cards]}
    (args.output / 'manifest.json').write_text(json_text(manifest))
    print(json_text({'count': len(pack), 'installed': args.install, 'daily_unchanged': before == after,
                     'unique90': duplicates['unique_equivalent_boards']}))


if __name__ == '__main__':
    main()
