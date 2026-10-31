"""Finite one-step policies for content comparison, never a human difficulty score.

Unlike the historical v4 policy these remember visited positions (including
swapped unlabeled buffers), so cycling between empty spaces is not mistaken for
planning difficulty. They use neither search/lookahead nor a reference answer.
"""
import random
import argparse
from collections import Counter
import json
from pathlib import Path
from measure_levels import successors


def state_key(board, labels):
    return (tuple(b for b, label in zip(board, labels) if label is not None),
            tuple(sorted(b for b, label in zip(board, labels) if label is None)))


def probe(board, labels, seed, *, extra=False, prefer_target=False, budget=100):
    labels = list(labels) + ([None] if extra else [])
    state = tuple(''.join(b) for b in board) + (('',) if extra else ())
    goal = tuple(c * 4 if c else '' for c in labels)
    rng = random.Random(seed)
    seen = {state_key(state, labels)}
    moves = []
    for _ in range(budget):
        if state == goal:
            return dict(status='win', moves=moves, board=list(state))
        options = list(successors(state))
        fresh = [x for x in options if state_key(x[2], labels) not in seen]
        if not fresh:
            return dict(status='no_new_choice' if options else 'no_legal_move',
                        moves=moves, board=list(state))

        def score(move):
            source, target, following = move
            color = state[source][-1]
            match, merge = labels[target] == color, bool(state[target])
            return (not (labels[source] and state[source] == goal[source]),
                    following[target] == goal[target],
                    match if prefer_target else merge,
                    merge if prefer_target else match, not following[source])

        maximum = max(map(score, fresh))
        source, target, state = rng.choice([x for x in fresh if score(x) == maximum])
        moves.append(dict(from_index=source, to_index=target))
        seen.add(state_key(state, labels))
    return dict(status='win' if state == goal else 'budget', moves=moves, board=list(state))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    old = json.loads((root / 'docs/content/design/main60-five-color-v4.json').read_text())['levels']
    rows = []
    for n in range(21, 61):
        before = old[n - 1]['puzzle']
        after = json.loads((root / f'app/assets/puzzles/main/main-{n:03}.json').read_text())
        row = dict(level=n, id=after['puzzle_id'],
                   reference_before=len(before['reference_moves']),
                   reference_after=len(after['reference_moves']), policies={})
        for name, prefer in [('merge_first', False), ('target_first', True)]:
            row['policies'][name] = {}
            for version, puzzle, extra in [('before', before, False), ('after', after, False), ('after_extra', after, True)]:
                outcomes = [probe(puzzle['initial_bottom_to_top'], puzzle['target_labels'],
                                  seed, extra=extra, prefer_target=prefer)
                            for seed in range(1000, 1032)]
                row['policies'][name][version] = dict(
                    counts=dict(Counter(r['status'] for r in outcomes)),
                    winning_move_counts=[len(r['moves']) for r in outcomes if r['status'] == 'win'])
        rows.append(row)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(dict(
        seeds=list(range(1000, 1032)), action_budget=100,
        scope='Finite noncycling one-step policies; no_new_choice/budget are not unsolvability or human failure. Extra is present from start, not SDK evidence.',
        levels=rows), ensure_ascii=False, indent=2) + '\n')
    print(f'Measured {len(rows)} actual packaged levels; no assets or stores modified.')


if __name__ == '__main__':
    main()
