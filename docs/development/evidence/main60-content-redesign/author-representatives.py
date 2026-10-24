"""Historical authoring helper plus R01 rejection guard; current028 remains failed.
Do not regenerate the frozen review set without resolving its design gate.
Reproduce eight review-only candidates. Writes only this evidence directory.
Never calls the old cyclic schedule or copies files into app/assets.
"""
from collections import Counter, deque
import hashlib
import json
from pathlib import Path
import random
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools/content'))
from author_candidates import solve
from main60_v2 import make_candidate
from measure_levels import bounded_search, successors, trace_solution, trace_features, shorten_reference, deletion_audit
from validate import ContentError, canonical_board, read_json

DEST = Path(__file__).resolve().parent
REPRESENTATIVES = [13, 20, 21, 28, 40, 41, 53, 60]
LABELS = list('OGPB') + [None, None]


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


features = trace_features


def matches(level, feature, length):
    if not feature['target_borrow_steps'] or not feature['both_buffers_used']:
        return False
    if level in [20, 21, 40, 41, 53, 60] and not feature['strategic_buffer_reuse_steps']:
        return False
    if level in [20, 21, 40, 41, 60] and not feature['target_space_freed_while_mixed_steps']:
        return False
    if level == 53 and (feature['truncation_steps'] or length > 16):
        return False
    return True


def branch_routes(board):
    """Opening states are compared modulo buffer swap only, not target swap.
    This quotient is only for explanation, never used in the proof BFS.
    """
    distinct = set()
    result = []
    for source, target, state in successors(tuple(''.join(b) for b in board)):
        key = state[:4] + tuple(sorted(state[4:]))
        if key in distinct:
            continue
        distinct.add(key)
        first = {'from_index': source, 'to_index': target}
        try:
            moves, evidence = solve([list(b) for b in state], LABELS, max_states=100000)
            quality = shorten_reference([list(b) for b in state], LABELS, moves)
            route = [first] + quality['moves']
            replay = trace_solution(board, LABELS, route)
            result.append({'first_move': first, 'first_state': list(state),
                           'moves': route, 'upper_bound': len(route),
                           'search': evidence, 'replay': replay, 'reference_quality': quality})
        except ContentError as error:
            result.append({'first_move': first, 'first_state': list(state),
                           'status': 'unknown_or_reference_redundancy', 'detail': str(error),
                           'not_a_dead_end_proof': True})
    return result


def short_truncation_branch(board, upper):
    start = tuple(''.join(b) for b in board)
    queue = deque([(start, [])])
    seen = {start}
    tried = 0
    while queue and len(seen) < 10000:
        state, prefix = queue.popleft()
        if len(prefix) >= 6:
            continue
        for a, b, following in successors(state):
            move = {'from_index': a, 'to_index': b}
            if following in seen:
                continue
            seen.add(following)
            route = prefix + [move]
            color = state[a][-1]
            run = len(state[a]) - len(state[a].rstrip(color))
            if run > 4 - len(state[b]):
                tried += 1
                try:
                    suffix, search = solve([list(c) for c in following], LABELS, max_states=100000)
                    complete = route + suffix
                    if len(complete) > upper + 4:
                        continue
                    quality = shorten_reference(board, LABELS, complete)
                    replay = trace_solution(board, LABELS, quality['moves'])
                    if (quality['budget_unknown_windows'] or not trace_features(replay)['truncation_steps'] or
                            deletion_audit(board, LABELS, quality['moves'])):
                        continue
                    return {'moves': quality['moves'], 'upper_bound': len(quality['moves']), 'reference_upper_bound': upper,
                            'replay': replay, 'prefix_states_visited': len(seen), 'truncation_routes_tested': tried,
                            'reference_quality': quality,
                            'local_detours': 'no repeated board; no known shorter 2–6 action subpath, complete exact local searches',
                            'status': 'legal alternative; not claimed shortest or mandatory'}
                except ContentError:
                    pass
            queue.append((following, route))
    return {'status': 'unknown_no_qualifying_branch_in_budget', 'prefix_states_visited': len(seen), 'truncation_routes_tested': tried}


def main():
    contracts = read_json(ROOT / 'docs/content/design/main60-level-contracts-v2.json')['levels']
    existing = [read_json(p) for p in sorted((ROOT / 'app/assets/puzzles').rglob('*.json'))]
    reserved = {canonical_board(q) for q in existing}
    liquid_reserved = {canonical_board(q, include_labels=False) for q in existing}
    selected = []
    for level in REPRESENTATIVES:
        old_path = ROOT / f'app/assets/puzzles/main/main-{level:03}.json'
        old = read_json(old_path)
        contract = contracts[level - 1]
        rejected = Counter()
        for attempt in range(5000):
            seed = 202610230000 + level * 10000 + attempt
            liquid = list('OOOO' + 'GGGG' + 'PPPP' + 'BBBB')
            random.Random(seed).shuffle(liquid)
            board = [liquid[i:i + 4] for i in range(0, 16, 4)] + [[], []]
            draft = {'initial_bottom_to_top': board, 'target_labels': LABELS}
            if canonical_board(draft) in reserved or canonical_board(draft, include_labels=False) in liquid_reserved:
                rejected['old_or_selected_equivalent'] += 1
                continue
            if any(b == [c] * 4 for b, c in zip(board, LABELS) if c):
                rejected['already_completed_target'] += 1
                continue
            try:
                moves, upper_evidence = solve(board, LABELS, max_states=100000)
                replay = trace_solution(board, LABELS, moves)
            except ContentError:
                rejected['reference_unknown_or_redundant'] += 1
                continue
            # Early filter saves work, but passing is never a difficulty verdict.
            if not matches(level, features(replay), len(moves)):
                rejected['specific_trace_features_missing'] += 1
                continue
            branches = branch_routes(board)
            known = [r for r in branches if 'moves' in r]
            if len(known) < 2:
                rejected['two_nonbuffer_symmetric_branches_missing'] += 1
                continue
            best = min([{'moves': moves, 'replay': replay}] + known, key=lambda r: len(r['moves']))
            quality = shorten_reference(board, LABELS, best['moves'])
            moves = quality['moves']
            replay = trace_solution(board, LABELS, moves)
            feature = features(replay)
            if not matches(level, feature, len(moves)):
                rejected['known_shorter_route_removes_required_features'] += 1
                continue
            limit = 8 if level <= 20 else 10 if level <= 40 else 11
            proof = bounded_search(board, LABELS, limit, max_states=500000, seconds=30)
            if proof['status'] != 'excluded':
                rejected['short_solution_or_unknown'] += 1
                continue
            truncation_branch = None
            if level == 28:
                truncation_branch = short_truncation_branch(board, len(moves))
                if 'moves' not in truncation_branch:
                    rejected['no_irreducible_short_truncation_branch'] += 1
                    continue
            puzzle = make_candidate(old, board, moves, contract)
            puzzle_path = DEST / 'levels' / f'main-{level:03}.runtime.json'
            write(puzzle_path, puzzle)
            card = {
                'puzzle_id': puzzle['puzzle_id'], 'level': level,
                'status': 'authored_review_candidate_not_runtime_or_independent_pass',
                'contract': contract, 'source_seed': seed, 'attempts': attempt + 1,
                'rejected_counts': dict(rejected),
                'old_content_version': old['content_version'], 'new_content_version': puzzle['content_version'],
                'old_definition_sha256': hashlib.sha256(old_path.read_bytes()).hexdigest(),
                'new_definition_path': str(puzzle_path.relative_to(ROOT)),
                'new_definition_sha256': hashlib.sha256(puzzle_path.read_bytes()).hexdigest(),
                'bottles_1_based_bottom_to_top': [{'bottle': i + 1, 'contents': contents, 'target': LABELS[i]} for i, contents in enumerate(board)],
                'legal_solution_upper_bound': len(moves),
                'upper_search': upper_evidence, 'short_solution_proof': proof,
                'reference_quality': quality,
                'reference_selection': 'best known weighted/4 opening routes, then exact local shortening; not global shortest',
                'trace_features': feature, 'reference_replay': replay,
                'opening_branches': branches,
                'capacity_truncation_alternative': truncation_branch,
                'duplicate_check': 'distinct from all90 old definitions and all earlier selected representatives, with and without labels',
                'design_interpretation': 'Concrete features are evidence, not automatic strategy/difficulty approval. Manual node/causal explanation follows separately.',
                'human_playtest': {'performed': False, 'platform': None, 'prior_solution_knowledge': 'content author knows reference', 'first_time_unassisted_pass': False},
            }
            write(DEST / 'levels' / f'main-{level:03}.json', card)
            reserved.add(canonical_board(puzzle))
            liquid_reserved.add(canonical_board(puzzle, include_labels=False))
            selected.append({'level': level, 'seed': seed, 'U': len(moves), 'excluded_through': limit,
                             'visited': proof['visited'], 'features': feature})
            print(json.dumps(selected[-1], ensure_ascii=False), flush=True)
            break
        else:
            write(DEST / f'dc02-failure-{level}.json', {'attempted': 5000, 'rejected': dict(rejected)})
            raise RuntimeError(f'no acceptable reference sample for{level}; do not weaken design silently')
    write(DEST / 'dc02-selection.json', {'runtime_assets_modified': False, 'independent_gate': 'pending', 'rows': selected})


if __name__ == '__main__':
    main()
