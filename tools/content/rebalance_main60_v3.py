"""Install/check explicit difficulty corrections; never generate runtime puzzles.

Only selected definitions advance one version. Existing instances retain their
embedded definitions; neither daily content nor any player database is touched.
"""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
from measure_levels import bounded_search, trace_solution, successors
from main60_v2 import inspect_route
from validate import ContentError, read_json, repetition_audit, validate_puzzle

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'docs/content/design/main60-rebalance-v3.json'
EVIDENCE = ROOT / 'docs/development/evidence/difficulty-direct-bottle'
BASELINE = EVIDENCE / 'v2-baseline'
DESTINATIONS = [ROOT / 'app/assets/puzzles/main', ROOT / 'docs/content/production-candidates/puzzles/main']


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def build(entry):
    n = entry['level']; pid = f'main-{n:03}'
    before = (BASELINE / f'{pid}.json').read_bytes()
    if n <= 12 or sha(before) != entry['previous_sha256']:
        raise ContentError(f'{pid}: anchor or baseline mismatch')
    old = read_json(BASELINE / f'{pid}.json')
    p = deepcopy(old)
    p.update(content_version=old['content_version'] + 1,
             initial_bottom_to_top=entry['board'], reference_moves=entry['reference_moves'],
             source_reference='docs/content/design/main60-rebalance-v3.json',
             difficulty_intent=f"节奏校准：最短{entry['minimum_moves']}次最大连续倒水；腾空后再利用目标瓶和双缓冲。" +
                 ('误入已验证的无合法步分支时，一只额外缓冲瓶可恢复通关。' if entry['extra_rescue'] else '保留双缓冲的常规通关路线。') +
                 '算法距离用于校准节奏，不等于人类难度评分。')
    validate_puzzle(p)
    result = bounded_search(p['initial_bottom_to_top'], p['target_labels'], entry['minimum_moves'])
    if result['status'] != 'found' or result['shortest_within_bound'] != entry['minimum_moves']:
        raise ContentError(f'{pid}: exact minimum mismatch')
    if len(p['reference_moves']) != entry['minimum_moves']:
        raise ContentError(f'{pid}: reference not shortest')
    trace = trace_solution(p['initial_bottom_to_top'], p['target_labels'], p['reference_moves'])
    observations = inspect_route(p, trace)
    if not observations['space_links']:
        raise ContentError(f'{pid}: no meaningful empty-and-reuse sequence')
    rescue = entry['extra_rescue']
    if rescue:
        partial = trace_solution(entry['board'], p['target_labels'], rescue['route'], require_win=False)
        stuck = tuple(rescue['board'])
        if tuple(partial['steps'][-1]['after']) != stuck or list(successors(stuck)):
            raise ContentError(f'{pid}: rescue is not a reachable blocked board')
        trace_solution(list(stuck) + [''], p['target_labels'] + [None], rescue['recovery']['moves'])
    openings = []
    for a, b, state in successors(tuple(''.join(x) for x in entry['board'])):
        route = bounded_search(state, p['target_labels'], entry['minimum_moves'] + 2)
        if route['status'] != 'found':
            continue
        moves = [dict(from_index=a, to_index=b)] + route['moves']
        try:
            replay = trace_solution(entry['board'], p['target_labels'], moves)
        except ContentError:
            continue
        openings.append(dict(first_move=moves[0], replay=replay))
    return p, dict(puzzle_id=pid, search=result, reference_replay=trace,
                   route_observations=observations, opening_branches=openings,
                   extra_rescue=rescue, human_playtest=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--install', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    inputs = read_json(SOURCE)['levels']
    if len({e['level'] for e in inputs}) != len(inputs):
        raise ContentError('duplicate replacement levels')
    protected = {str(p.relative_to(ROOT)): sha(p.read_bytes()) for p in
                 list((ROOT / 'app/assets/puzzles/daily').glob('*.json')) +
                 [ROOT / 'app/assets/catalog/daily.json'] +
                 [DESTINATIONS[0] / f'main-{i:03}.json' for i in range(1, 13)]}
    changes = {}; cards = []
    for entry in inputs:
        p, card = build(entry)
        changes[p['puzzle_id']] = p; cards.append(card)
    pack = [changes.get(path.stem, read_json(path)) for path in sorted(DESTINATIONS[0].glob('*.json'))]
    daily = [read_json(path) for path in sorted((ROOT / 'app/assets/puzzles/daily').glob('*.json'))]
    if len(pack) != 60 or len(daily) != 30:
        raise ContentError('incomplete pack')
    duplicates = repetition_audit(pack + daily)
    if any(duplicates[k] for k in ['exact_groups', 'equivalent_groups', 'liquid_structure_groups']):
        raise ContentError(f'duplicate content: {duplicates}')
    for directory in DESTINATIONS:
        for pid, p in changes.items():
            actual = (directory / f'{pid}.json').read_bytes()
            if args.check and actual != encoded(p):
                raise ContentError(f'not installed: {directory / pid}')
            if args.install and actual not in [(BASELINE / f'{pid}.json').read_bytes(), encoded(p)]:
                raise ContentError(f'unknown concurrent change: {directory / pid}')
    if args.install:
        for directory in DESTINATIONS:
            for pid, p in changes.items():
                (directory / f'{pid}.json').write_bytes(encoded(p))
    if any(sha((ROOT / path).read_bytes()) != digest for path, digest in protected.items()):
        raise ContentError('protected early/daily content changed')
    (EVIDENCE / 'levels').mkdir(parents=True, exist_ok=True)
    for card in cards:
        (EVIDENCE / 'levels' / f"{card['puzzle_id']}.json").write_bytes(encoded(card))
    rows=[]
    for p in pack:
        s=bounded_search(p['initial_bottom_to_top'],p['target_labels'],len(p['reference_moves']))
        if s['status'] != 'found': raise ContentError(f"incomplete full-pack proof: {p['puzzle_id']}")
        rows.append(dict(level=p['main_level'],version=p['content_version'],minimum=s['shortest_within_bound'],
                         changed=p['puzzle_id'] in changes,
                         sha256=sha(encoded(p)) if p['puzzle_id'] in changes else sha((DESTINATIONS[0]/f"{p['puzzle_id']}.json").read_bytes())))
    (EVIDENCE / 'content-report.json').write_bytes(encoded(dict(replacements=len(changes),
        protected_hashes=protected, unique90=duplicates['unique_equivalent_boards'],
        levels=rows, human_playtest=False)))
    print(json.dumps(dict(replacements=len(changes),unique90=duplicates['unique_equivalent_boards'],
                          protected=len(protected),installed=args.install,checked=args.check)))


if __name__ == '__main__': main()
