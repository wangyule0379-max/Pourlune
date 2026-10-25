"""Offline content preparation checks. This is not the Dart game engine."""
import argparse
from collections import Counter
from datetime import date
import hashlib
import json
from itertools import permutations
from pathlib import Path
import sys

from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parents[2]
CONTRACTS = ROOT / 'docs/content/contracts'


class ContentError(ValueError):
    pass


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ContentError(f'duplicate JSON key: {key}')
        result[key] = value
    return result


def read_json(path):
    def invalid_constant(value):
        raise ContentError(f'invalid JSON constant: {value}')
    def non_integer_token(value):
        raise ContentError(f'numbers must use integer tokens without decimals or exponents: {value}')
    try:
        return json.loads(Path(path).read_text(encoding='utf-8-sig'),
                          object_pairs_hook=unique_object, parse_constant=invalid_constant,
                          parse_float=non_integer_token)
    except (OSError, UnicodeError, ValueError) as error:
        raise ContentError(f'{path}: {error}') from error


def check_schema(data, name):
    schema = read_json(CONTRACTS / name)
    Draft202012Validator.check_schema(schema)
    errors = list(Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(data))
    if errors:
        messages = [f'{e.json_path}: {e.message}' for e in errors]
        raise ContentError('schema: ' + '; '.join(messages))


def pour(board, source, target):
    """Return a fresh board, moved color and units. Labels never restrict receiving."""
    if (type(source) is not int or type(target) is not int or source == target
            or not 0 <= source < len(board) or not 0 <= target < len(board)):
        raise ContentError('invalid move indexes')
    src, dst = board[source], board[target]
    if not src or len(dst) >= 4 or (dst and dst[-1] != src[-1]):
        raise ContentError('illegal pour: empty source, full target or incompatible top')
    color = src[-1]
    count = 0
    for value in reversed(src):
        if value != color:
            break
        count += 1
    units = min(count, 4 - len(dst))
    result = [list(bottle) for bottle in board]
    del result[source][-units:]
    result[target].extend([color] * units)
    return result, color, units


def is_won(board, labels):
    return len(board) == len(labels) and all(
        bottle == ([label] * 4 if label is not None else [])
        for bottle, label in zip(board, labels)
    )


def validate_puzzle(puzzle):
    check_schema(puzzle, 'puzzle.schema.json')
    board, labels = puzzle['initial_bottom_to_top'], puzzle['target_labels']
    totals = Counter(color for bottle in board for color in bottle)
    if not 2 <= len(totals) <= 4 or set(totals.values()) != {4}:
        raise ContentError('expected 2..4 colors, exactly 4 units per color')
    if len(board) != len(totals) + 2 or len(labels) != len(board):
        raise ContentError('bottle and label count must equal color count + 2')
    if Counter(label for label in labels if label is not None) != Counter({c: 1 for c in totals}):
        raise ContentError('each color must have exactly one target label')
    if labels.count(None) != 2 or any(board[i] for i, label in enumerate(labels) if label is None):
        raise ContentError('exactly two initially empty buffer bottles are required')
    if puzzle['mode'] == 'main' and puzzle['puzzle_id'] != f"main-{puzzle['main_level']:03}":
        raise ContentError('main puzzle_id does not match main_level')
    for index, move in enumerate(puzzle['reference_moves'], 1):
        if is_won(board, labels):
            raise ContentError(f'already solved before reference move {index}')
        try:
            board, _, _ = pour(board, move['from_index'], move['to_index'])
        except ContentError as error:
            raise ContentError(f'reference move {index}: {error}') from error
        if Counter(color for bottle in board for color in bottle) != totals:
            raise ContentError(f'color conservation failed at move {index}')
    if not is_won(board, labels):
        raise ContentError('reference solution does not finish at labeled targets with empty buffers')
    return {'puzzle_id': puzzle['puzzle_id'], 'move_count': len(puzzle['reference_moves']),
            'content_status': puzzle['content_status'], 'final_board': board}


def validate_catalog(catalog, validated_puzzles):
    """References must resolve into the caller's already validated puzzle map."""
    check_schema(catalog, 'daily-catalog.schema.json')
    for puzzle_id in catalog['puzzle_ids']:
        if puzzle_id not in validated_puzzles:
            raise ContentError(f'catalog references missing or invalid puzzle: {puzzle_id}')
        if validated_puzzles[puzzle_id]['mode'] != 'daily':
            raise ContentError(f'catalog reference is not daily: {puzzle_id}')


def daily_id(catalog, puzzle_date):
    """Use local Gregorian calendar dates, never seconds divided by 86400."""
    check_schema(catalog, 'daily-catalog.schema.json')
    try:
        day = date.fromisoformat(puzzle_date)
        if day.isoformat() != puzzle_date:
            raise ValueError('date must be YYYY-MM-DD')
    except (ValueError, TypeError) as error:
        raise ContentError(f'invalid puzzle_date: {puzzle_date}') from error
    offset = (day - date.fromisoformat(catalog['epoch_date'])).days
    return catalog['puzzle_ids'][offset % len(catalog['puzzle_ids'])]


def canonical_board(puzzle, include_labels=True):
    """Ignore global color names and permutation of whole labeled bottles.

    A bottle moves with its target label. Changing the liquid/target relation is
    a different puzzle; buffer identities are interchangeable for this audit.
    """
    board, labels = puzzle['initial_bottom_to_top'], puzzle['target_labels']
    colors = sorted({c for b in board for c in b})
    variants = []
    for order in permutations(range(len(colors))):
        rename = dict(zip(colors, order))
        variants.append(tuple(sorted(
            ((rename[label] if label is not None else -1) if include_labels else -1,
             tuple(rename[c] for c in bottle))
            for label, bottle in zip(labels, board))))
    return min(variants)


def repetition_audit(puzzles):
    exact, equivalent, liquid = {}, {}, {}
    for puzzle in puzzles:
        pid = puzzle['puzzle_id']
        raw = json.dumps([puzzle['initial_bottom_to_top'], puzzle['target_labels']])
        exact.setdefault(raw, []).append(pid)
        equivalent.setdefault(canonical_board(puzzle), []).append(pid)
        liquid.setdefault(canonical_board(puzzle, include_labels=False), []).append(pid)
    return {'exact_groups': [sorted(v) for v in exact.values() if len(v) > 1],
            'equivalent_groups': [sorted(v) for v in equivalent.values() if len(v) > 1],
            'liquid_structure_groups': [sorted(v) for v in liquid.values() if len(v) > 1],
            'unique_equivalent_boards': len(equivalent),
            'definition': 'global color bijections and whole labeled bottle permutations; buffers interchangeable'}


def verify_packaging(source, target):
    """Compare relative JSON paths and bytes, rejecting stale or extra assets."""
    def hashes(root):
        return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(Path(root).rglob('*.json'))}
    original, packaged = hashes(source), hashes(target)
    if not original or original != packaged:
        raise ContentError(f'packaging differs: missing={sorted(original.keys() - packaged.keys())}, '
                           f'extra={sorted(packaged.keys() - original.keys())}, '
                           f'changed={sorted(k for k in original.keys() & packaged.keys() if original[k] != packaged[k])}')
    return {'count': len(original), 'sha256_by_path': original}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('puzzles', nargs='+', type=Path)
    parser.add_argument('--catalog', type=Path)
    parser.add_argument('--release', action='store_true', help='Require 60 main puzzles and a complete daily catalog')
    parser.add_argument('--report', type=Path, help='Also save the JSON report to this path')
    args = parser.parse_args()
    if args.report:
        protected = args.puzzles + list(CONTRACTS.glob('*.json'))
        if args.catalog:
            protected.append(args.catalog)
        try:
            for path in protected:
                if (args.report.resolve() == path.resolve() or
                        (args.report.exists() and path.exists() and args.report.samefile(path))):
                    parser.error(f'--report must not overwrite input or schema: {path}')
        except OSError as error:
            parser.error(f'cannot safely resolve --report: {error}')
    report = {'ok': False, 'release_gate': args.release, 'checked': [], 'errors': [],
              'scope': 'schema, semantics and reference replay only; no difficulty, playtest or Dart runtime approval'}
    known = {}
    seen = set()
    for path in args.puzzles:
        try:
            puzzle = read_json(path)
            evidence = validate_puzzle(puzzle)
            pid = puzzle['puzzle_id']
            if pid in seen:
                raise ContentError(f'duplicate puzzle_id: {pid}')
            seen.add(pid)
            known[pid] = puzzle
            evidence.update(path=str(path), sha256=hashlib.sha256(path.read_bytes()).hexdigest())
            report['checked'].append(evidence)
        except (ContentError, OSError) as error:
            report['errors'].append(f'{path}: {error}')
    if args.catalog:
        try:
            catalog = read_json(args.catalog)
            validate_catalog(catalog, known)
            report['catalog'] = {'path': str(args.catalog), 'catalog_version': catalog['catalog_version'],
                                 'count': len(catalog['puzzle_ids']),
                                 'sha256': hashlib.sha256(args.catalog.read_bytes()).hexdigest()}
        except (ContentError, OSError) as error:
            report['errors'].append(f'catalog: {error}')
    if args.release:
        report['repetition_audit'] = repetition_audit(known.values())
        for group in report['repetition_audit']['equivalent_groups']:
            report['errors'].append(f'equivalent duplicate candidates: {group}')
        for group in report['repetition_audit']['liquid_structure_groups']:
            report['errors'].append(f'liquid structure duplicate candidates: {group}')
        missing = sorted(set(range(1, 61)) - {p['main_level'] for p in known.values() if p['mode'] == 'main'})
        if missing:
            report['errors'].append(f'main coverage missing levels: {missing}')
        if not args.catalog:
            report['errors'].append('release requires --catalog with at least 30 validated daily puzzles')
        for pid, puzzle in known.items():
            if puzzle['content_status'] != 'production_candidate':
                report['errors'].append(f'{pid}: release requires production_candidate; reference fixtures are not release content')
    report['ok'] = not report['errors']
    output = json.dumps(report, ensure_ascii=False, indent=2) + '\n'
    if args.report:
        try:
            args.report.write_text(output, encoding='utf-8')
        except OSError as error:
            print(f'cannot write report: {error}', file=sys.stderr)
            return 2
    print(output, end='')
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
