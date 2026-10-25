"""Read-only, exact ordered-bottle BFS and replay evidence for content review.

No target/colour/buffer symmetry reduction and no heuristic pruning is used.
A completed depth bound proves only that no solution at or below that bound
exists. A state/time budget never becomes a no-solution certificate.
"""
from collections import Counter, deque
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time

from validate import ContentError, is_won, pour, read_json, validate_puzzle


def successors(state):
    """Same maximal top-run/capacity rule, without changing fixed identities."""
    for source, src in enumerate(state):
        if not src:
            continue
        color = src[-1]
        segment = len(src) - len(src.rstrip(color))
        for target, dst in enumerate(state):
            if source == target or len(dst) >= 4 or (dst and dst[-1] != color):
                continue
            units = min(segment, 4 - len(dst))
            following = list(state)
            following[source], following[target] = src[:-units], dst + color * units
            yield source, target, tuple(following)


def bounded_search(board, labels, depth_limit, *, max_states=500000, seconds=30):
    if (type(depth_limit) is not int or depth_limit < 0 or
            type(max_states) is not int or max_states < 1 or
            not math.isfinite(seconds) or seconds <= 0):
        raise ValueError('nonnegative depth and positive state/time budgets required')
    start = tuple(''.join(b) for b in board)
    if len(start) != len(labels) or any(len(b) > 4 for b in start):
        raise ContentError('board/target shape or capacity')
    goal = tuple(c * 4 if c else '' for c in labels)
    begun = time.monotonic()
    queue = deque([(start, 0)])
    parents = {start: None}
    layers, branches = Counter({0: 1}), Counter()
    expanded, generated, max_frontier = 0, 0, 1

    def result(status, *, depth=None, reason=None):
        value = {
            'algorithm': 'exact BFS, ordered bottle and colour identities; no pruning',
            'status': status, 'depth_limit': depth_limit,
            'excluded_through': depth_limit if status == 'excluded' else None,
            'visited': len(parents), 'expanded': expanded, 'generated': generated,
            'layer_states': dict(sorted(layers.items())),
            'layer_legal_edges': dict(sorted(branches.items())),
            'max_frontier': max_frontier,
            'max_states': max_states, 'time_budget_seconds': seconds,
            'elapsed_ms': round((time.monotonic() - begun) * 1000, 3),
        }
        if reason:
            value['reason'] = reason
        if depth is not None:
            moves, cursor = [], goal
            while parents[cursor] is not None:
                cursor, source, target = parents[cursor]
                moves.append({'from_index': source, 'to_index': target})
            value['moves'] = moves[::-1]
            value['shortest_within_bound'] = depth
            value['excluded_through'] = depth - 1 if depth else None
        return value

    while queue:
        if time.monotonic() - begun >= seconds:
            return result('unknown', reason='time budget exhausted')
        state, depth = queue.popleft()
        if state == goal:
            return result('found', depth=depth)
        if depth == depth_limit:
            continue
        expanded += 1
        for source, target, candidate in successors(state):
            generated += 1
            branches[depth] += 1
            if candidate in parents:
                continue
            if len(parents) >= max_states:
                return result('unknown', reason='state budget exhausted')
            parents[candidate] = (state, source, target)
            layers[depth + 1] += 1
            queue.append((candidate, depth + 1))
        max_frontier = max(max_frontier, len(queue))
    return result('excluded')


def state_hash(board):
    return hashlib.sha256(json.dumps(board, separators=(',', ':')).encode()).hexdigest()


def trace_solution(board, labels, moves, *, require_win=True):
    state = [list(b) for b in board]
    initial_units = Counter(c for b in state for c in b)
    seen = {tuple(''.join(b) for b in state)}
    steps = []
    for index, move in enumerate(moves, 1):
        if require_win and is_won(state, labels):
            raise ContentError('reference continues after victory')
        source, target = move['from_index'], move['to_index']
        before = [''.join(b) for b in state]
        following, color, units = pour(state, source, target)
        after = [''.join(b) for b in following]
        signature = tuple(after)
        if require_win and signature in seen:
            raise ContentError('reference repeats a board state')
        seen.add(signature)
        assert Counter(c for b in following for c in b) == initial_units
        top_run = len(before[source]) - len(before[source].rstrip(color))
        steps.append({
            'step': index, 'from_index': source, 'to_index': target,
            'color': color, 'units': units, 'source_top_run': top_run,
            'receiver_space_before': 4 - len(before[target]),
            'capacity_truncated': units < top_run,
            'target_borrowed': labels[target] is not None and labels[target] != color,
            'source_became_empty': not following[source],
            'buffer_contents_before': [before[i] for i, label in enumerate(labels) if label is None],
            'buffer_contents_after': [after[i] for i, label in enumerate(labels) if label is None],
            'before': before, 'after': after, 'after_sha256': state_hash(after),
        })
        state = following
    won = is_won(state, labels)
    if require_win and not won:
        raise ContentError('reference does not reach fixed-label victory')
    return {'steps': steps, 'won': won, 'initial_sha256': state_hash([''.join(b) for b in board]),
            'final': [''.join(b) for b in state], 'extra_bottles': 0}


def trace_features(trace):
    """Separate mid-sort space planning from final whole-colour label swaps."""
    buffer_count = len(trace['steps'][0]['buffer_contents_before'])
    target_count = len(trace['steps'][0]['before']) - buffer_count
    history = {i: [] for i in range(target_count, target_count + buffer_count)}
    strategic, freed = [], []
    for row in trace['steps']:
        target = row['to_index']
        mixed_before = any(len(set(b)) > 1 for b in row['before'])
        mixed_after = any(len(set(b)) > 1 for b in row['after'])
        if target in history and (not history[target] or history[target][-1] != row['color']):
            if history[target] and mixed_before:
                strategic.append(row['step'])
            history[target].append(row['color'])
        if row['source_became_empty'] and row['from_index'] < target_count and mixed_after:
            freed.append(row['step'])
    return {
        'buffer_roles': history, 'both_buffers_used': all(history.values()),
        'buffer_reused': any(len(v) >= 2 for v in history.values()),
        'strategic_buffer_reuse_steps': strategic,
        'target_space_freed_while_mixed_steps': freed,
        'target_borrow_steps': [s['step'] for s in trace['steps'] if s['target_borrowed']],
        'truncation_steps': [s['step'] for s in trace['steps'] if s['capacity_truncated']],
        'nonbuffer_empty_steps': [s['step'] for s in trace['steps'] if s['source_became_empty'] and s['from_index'] < target_count],
    }


def shorten_reference(board, labels, moves, *, window=6, max_states=10000):
    """Remove known shorter equivalent local subpaths; never claim optimality.

    A budget-limited window is recorded, not certified irreducible. This is for
    reference quality only and never supplies a puzzle's short-solution proof.
    """
    moves = list(moves)
    replacements, unknown = [], 0
    victory = tuple(c * 4 if c else '' for c in labels)

    def between(start, goal, limit):
        nonlocal unknown
        queue, parents = deque([(start, 0)]), {start: None}
        while queue:
            state, depth = queue.popleft()
            if state == goal:
                route = []
                while parents[state] is not None:
                    state, a, b = parents[state]
                    route.append({'from_index': a, 'to_index': b})
                return route[::-1]
            if depth == limit:
                continue
            if state == victory:
                continue
            for a, b, following in successors(state):
                if following in parents:
                    continue
                if len(parents) >= max_states:
                    unknown += 1
                    return None
                parents[following] = (state, a, b)
                queue.append((following, depth + 1))
        return None

    while True:
        replay = trace_solution(board, labels, moves)
        states = [tuple(''.join(b) for b in board)] + [tuple(s['after']) for s in replay['steps']]
        changed = False
        for length in range(min(window, len(moves)), 1, -1):
            for start in range(len(moves) - length + 1):
                route = between(states[start], states[start + length], length - 1)
                if route is not None:
                    replacements.append({'start_action': start + 1, 'old_length': length, 'new_length': len(route)})
                    moves[start:start + length] = route
                    changed = True
                    break
            if changed:
                break
        if not changed:
            return {'moves': moves, 'replacements': replacements,
                    'checked_window_actions': window, 'budget_unknown_windows': unknown,
                    'shortest_claim': False}


def deletion_audit(board, labels, moves):
    """Replay every single-command deletion, recalculating actual pour units.

    Original intermediate states are deliberately not used as expected values:
    an omitted move may change later maximal pours yet preserve the final win.
    """
    findings = []
    for index in range(len(moves)):
        shortened = moves[:index] + moves[index + 1:]
        try:
            replay = trace_solution(board, labels, shortened)
        except ContentError:
            continue
        findings.append({'removed_1_based_step': index + 1,
                         'moves': shortened, 'replay': replay})
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--depth', type=int, required=True)
    parser.add_argument('--max-states', type=int, default=500000)
    parser.add_argument('--seconds', type=float, default=30)
    parser.add_argument('puzzles', type=Path, nargs='+')
    args = parser.parse_args()
    try:
        rows = []
        for path in args.puzzles:
            puzzle = read_json(path)
            validate_puzzle(puzzle)
            rows.append({
                'source': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'reference': trace_solution(puzzle['initial_bottom_to_top'], puzzle['target_labels'], puzzle['reference_moves']),
                'search': bounded_search(puzzle['initial_bottom_to_top'], puzzle['target_labels'],
                                         args.depth, max_states=args.max_states, seconds=args.seconds),
            })
        print(json.dumps({'scope': 'read-only exact bound; unknown is not exclusion or unsolvability',
                          'rows': rows}, ensure_ascii=False, indent=2))
    except (ContentError, OSError, ValueError) as error:
        print(json.dumps({'error': str(error)}, ensure_ascii=False), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
