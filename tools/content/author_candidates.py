"""Deterministic B03 candidate authoring, offline only; not runtime generation."""
import argparse
import heapq
from itertools import count
import json
from pathlib import Path
import random
import shutil
import time

from validate import ContentError, canonical_board, read_json, validate_puzzle, verify_packaging

ROOT = Path(__file__).resolve().parents[2]
CANDIDATES = ROOT / 'docs/content/production-candidates'
EVIDENCE = ROOT / 'docs/development/evidence/B03'
COLORS = 'OGPB'


def runs(board):
    return sum(sum(i == 0 or c != bottle[i-1] for i, c in enumerate(bottle)) for bottle in board)


def authored_board(n, band, seed):
    rng = random.Random(seed)
    parts = {'easy': [2, 2], 'moderate': [2, 1, 1], 'challenge': [1, 1, 1, 1]}[band]
    for _ in range(10000):
        chunks = [c * size for c in COLORS[:n]
                  for size in (rng.choice([[3, 1], [2, 2]]) if band == 'easy' else parts)]
        rng.shuffle(chunks)
        liquid = ''.join(chunks)
        board = [list(liquid[i:i+4]) for i in range(0, n*4, 4)] + [[], []]
        r = runs(board)
        if (band == 'easy' and n < r <= 2*n or
                band == 'moderate' and 2*n < r <= 3*n or
                band == 'challenge' and 3*n < r <= 4*n):
            return board
    raise ContentError('authoring structural band budget exhausted')


def solve(board, labels, max_states=100000):
    """Weighted best-first search for a legal reference, without shortest claims."""
    started = time.perf_counter()
    start = tuple(''.join(b) for b in board)
    goal = tuple(c * 4 if c else '' for c in labels)
    def estimate(state):
        segments = runs(state) - sum(bool(b) for b in state)
        misplaced = sum(bool(b) and b != goal[i] for i, b in enumerate(state))
        return segments * 4 + misplaced * 2
    serial = count()
    frontier = [(estimate(start), 0, next(serial), start)]
    parents = {start: None}
    depths = {start: 0}
    expanded = 0
    while frontier:
        if len(parents) >= max_states:
            raise ContentError('reference search state budget exhausted (not proof of unsolvability)')
        _, depth, _, state = heapq.heappop(frontier)
        if depth != depths[state]:
            continue
        if state == goal:
            moves = []
            cursor = state
            while parents[cursor] is not None:
                previous, source, target = parents[cursor]
                moves.append({'from_index': source, 'to_index': target})
                cursor = previous
            return list(reversed(moves)), {'visited': len(parents), 'expanded': expanded,
                                           'elapsed_ms': round((time.perf_counter() - started) * 1000, 3),
                                           'max_states': max_states, 'status': 'found'}
        expanded += 1
        for source, src in enumerate(state):
            if not src:
                continue
            color = src[-1]
            segment = len(src) - len(src.rstrip(color))
            for target, dst in enumerate(state):
                if source == target or len(dst) == 4 or dst and dst[-1] != color:
                    continue
                units = min(segment, 4-len(dst))
                candidate = list(state)
                candidate[source], candidate[target] = src[:-units], dst + color*units
                candidate = tuple(candidate)
                new_depth = depth + 1
                if new_depth >= depths.get(candidate, 10**9):
                    continue
                parents[candidate] = (state, source, target)
                depths[candidate] = new_depth
                heapq.heappush(frontier, (new_depth + estimate(candidate), new_depth,
                                         next(serial), candidate))
    raise ContentError('reference search exhausted graph: proven unsolvable')


def schedule():
    result = []
    for level in range(1, 61):
        if level <= 4:
            n = 2
        elif level <= 8 or 13 <= level <= 16 or 21 <= level <= 24 or 29 <= level <= 32:
            n = 3
        else:
            n = 4
        band = ['easy', 'moderate', 'challenge', 'moderate'][(level-1) % 4]
        if level == 12:
            band = 'challenge'
        result.append((f'main-{level:03}', level, n, band))
    for day in range(1, 31):
        result.append((f'daily-{day:03}', None, 3 if day % 3 == 1 else 4,
                       ['easy', 'moderate', 'challenge'][(day-1) % 3]))
    return result


def describe(n, band, board):
    buried = sum(c != board[i][-1] for i, c in enumerate(COLORS[:n]))
    themes = {'easy': '先合并连续色块（1–3单位）；保留一只空缓冲，最后按固定标签回收',
              'moderate': '双层与单层交错；规划两个缓冲的交替释放，避免同色整瓶停在错误目标',
              'challenge': '深层颜色被多次切断；先判断可解开的顶层依赖，延迟目标归位并回收两只缓冲'}
    return f'{n}色／{band}候选：{themes[band]}。初始{runs(board)}个色段，{buried}个目标色不在自身瓶顶；结构编排，未经人类难度标定。'


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Read-only exact package path/hash comparison')
    args = parser.parse_args()
    if args.check:
        print(json.dumps({folder: verify_packaging(CANDIDATES / folder, ROOT / 'app/assets' / folder)
                          for folder in ['puzzles', 'catalog']}, indent=2))
        return
    rows, seen, liquid_seen = [], set(), set()
    # main-001 deliberately keeps the already implemented tutorial sequence.
    # main-012 keeps recovered original identity and exact solution.
    originals = {i: read_json(ROOT / f'docs/content/fixtures/main-{i:03}.reference.json') for i in [1, 12]}
    reserved = {canonical_board(p) for p in originals.values()}
    reserved.add(canonical_board(read_json(ROOT / 'docs/content/fixtures/main-021.reference.json')))
    liquid_reserved = {canonical_board(p, include_labels=False) for p in originals.values()}
    liquid_reserved.add(canonical_board(read_json(ROOT / 'docs/content/fixtures/main-021.reference.json'), include_labels=False))
    for pid, level, n, band in schedule():
        seed = 202610220000 + (level if level else 100 + int(pid[-3:]))
        attempt = 0
        if level in originals:
            puzzle = originals[level].copy()
            puzzle['content_status'] = 'production_candidate'
            puzzle['difficulty_intent'] = describe(n, band, puzzle['initial_bottom_to_top'])
            moves, measured = solve(puzzle['initial_bottom_to_top'], puzzle['target_labels'])
            measured['reference_origin'] = 'preserved historical reference, solver independently finds a solution'
            source = (f'docs/content/fixtures/main-001.reference.json' if level == 1 else puzzle['source_reference'])
            puzzle['source_reference'] = source
        else:
            for attempt in range(10000):
                board = authored_board(n, band, seed + attempt * 1000)
                proposed = {'initial_bottom_to_top': board, 'target_labels': list(COLORS[:n])+[None, None]}
                key = canonical_board(proposed)
                liquid_key = canonical_board(proposed, include_labels=False)
                if key not in seen and key not in reserved and liquid_key not in liquid_seen and liquid_key not in liquid_reserved:
                    break
            else:
                raise ContentError(f'cannot author unique structural candidate: {pid}')
            labels = list(COLORS[:n]) + [None, None]
            moves, measured = solve(board, labels)
            source = 'tools/content/author_candidates.py'
            puzzle = {'schema_version': 1, 'puzzle_id': pid, 'content_version': 2 if level == 21 else 1,
                      'mode': 'main' if level else 'daily', 'content_status': 'production_candidate',
                      'main_level': level, 'capacity': 4, 'initial_bottom_to_top': board,
                      'target_labels': labels, 'reference_moves': moves,
                      'difficulty_intent': describe(n, band, board), 'source_reference': source}
            measured['reference_origin'] = 'offline weighted best-first legal search, no extra bottle'
        validate_puzzle(puzzle)
        seen.add(canonical_board(puzzle))
        liquid_seen.add(canonical_board(puzzle, include_labels=False))
        write_json(CANDIDATES / 'puzzles' / puzzle['mode'] / f'{pid}.json', puzzle)
        rows.append({'puzzle_id': pid, 'colors': n, 'band': band, 'seed': seed + attempt * 1000,
                     'reference_steps': len(puzzle['reference_moves']), 'initial_runs': runs(puzzle['initial_bottom_to_top']),
                     'learning_point': puzzle['difficulty_intent'], 'source': source, 'solver': measured,
                     'human_playtest': 'not performed by content author; app representative play recorded separately'})
        print(f'{pid}: {n} colors {band}, {len(puzzle["reference_moves"])} steps, {measured["visited"]} states', flush=True)
    catalog = {'schema_version': 1, 'catalog_version': 1, 'epoch_date': '2026-01-01',
               'puzzle_ids': [f'daily-{i:03}' for i in range(1, 31)]}
    write_json(CANDIDATES / 'catalog/daily.json', catalog)
    for folder in ['puzzles', 'catalog']:
        shutil.copytree(CANDIDATES / folder, ROOT / 'app/assets' / folder, dirs_exist_ok=True)
    write_json(EVIDENCE / 'content-authoring.json', {'algorithm_version': 1,
        'scope': 'automated structure and legal solution measurements; neither shortest path nor human difficulty approval',
        'daily_epoch_choice': '2026-01-01 is a fixed content scheduling origin, not a runtime clock or launch date',
        'intentional_fixture_reuse': ['main-001: unchanged board/targets/tutorial solution, intentional tutorial continuity',
                                     'main-012: recovered historical original unchanged board/targets/solution'],
        'puzzles': rows})
    write_json(EVIDENCE / 'content-packaging.json', {folder: verify_packaging(CANDIDATES / folder, ROOT / 'app/assets' / folder)
                                                   for folder in ['puzzles', 'catalog']})


if __name__ == '__main__':
    main()
