"""Small offline content builder. Never writes runtime assets or store state."""
from copy import deepcopy

from validate import ContentError, validate_puzzle
from measure_levels import trace_solution, deletion_audit, successors, trace_features


def check_measured_reference(puzzle, measured):
    """Check a freshly measured result; a long reference is never a lower bound."""
    level = puzzle['main_level']
    floor = 11 if level >= 41 else 10 if level >= 21 else 8 if level >= 13 else -1
    if measured.get('status') not in ('found', 'excluded'):
        raise ContentError('unfinished search cannot certify the selection floor')
    excluded = measured.get('excluded_through')
    if excluded is None or excluded < floor:
        raise ContentError('short-solution selection floor not met')
    if measured['status'] == 'found':
        moves = measured.get('moves', [])
        if len(moves) != measured.get('shortest_within_bound') or excluded != len(moves) - 1:
            raise ContentError('measured route length and exclusion disagree')
        trace_solution(puzzle['initial_bottom_to_top'], puzzle['target_labels'], moves)
    trace_solution(puzzle['initial_bottom_to_top'], puzzle['target_labels'], puzzle['reference_moves'])


def classify_capacity_example(puzzle, moves):
    trace = trace_solution(puzzle['initial_bottom_to_top'], puzzle['target_labels'], moves)
    deleted = deletion_audit(puzzle['initial_bottom_to_top'], puzzle['target_labels'], moves)
    return {
        'classification': 'negative_comparison_not_recommended' if deleted else 'legal_route_benefit_unverified',
        'deletable_steps': [r['removed_1_based_step'] for r in deleted],
        'truncated_steps': [r['step'] for r in trace['steps'] if r['capacity_truncated']],
        'space_benefit_proven': False, 'replay': trace,
        'deletion_replays': deleted,
    }


def inspect_route(puzzle, trace):
    labels = puzzle['target_labels']
    steps = trace['steps']
    freed, links, reveals, stable, complete_options = {}, [], [], [], []
    borrow_uses = {i: [] for i, label in enumerate(labels) if label is not None}
    for index, row in enumerate(steps):
        a, b = row['from_index'], row['to_index']
        if b in freed:
            links.append({'empty_step': freed.pop(b), 'use_step': row['step'], 'bottle': b})
        if row['source_became_empty']:
            freed[a] = row['step']
        if row['after'][a] and row['after'][a][-1] != row['color']:
            exposed = row['after'][a][-1]
            reveals.append({'step': row['step'], 'bottle': a, 'removed': row['color'],
                            'exposed': exposed, 'exposed_run': len(row['after'][a]) - len(row['after'][a].rstrip(exposed))})
        if b in borrow_uses and labels[b] != row['color']:
            history = borrow_uses[b]
            if not history or history[-1]['color'] != row['color']:
                history.append({'step': row['step'], 'color': row['color'], 'empty_before': not row['before'][b]})
        if labels[b] and row['after'][b] == labels[b] * 4:
            if all(later['from_index'] != b for later in steps[index + 1:]):
                stable.append({'step': row['step'], 'bottle': b, 'color': labels[b]})
        state = tuple(row['before'])
        options = []
        for source, target, following in successors(state):
            if labels[target] and following[target] == labels[target] * 4:
                options.append({'from_index': source, 'to_index': target})
        if len({m['to_index'] for m in options}) >= 2 and any(len(set(s)) > 1 for s in state):
            complete_options.append({'before_step': row['step'], 'moves': options})
    reused_targets = [
        {'bottle': i, 'uses': history}
        for i, history in borrow_uses.items()
        if len(history) >= 2 and any(use['empty_before'] for use in history[1:])
    ]
    return dict(trace_features(trace), space_links=links, reveal_events=reveals,
                stable_goal_events=stable, target_reborrow=reused_targets,
                goal_order_choice_nodes=complete_options)


def make_candidate(old, board, moves, contract):
    level = old['main_level']
    if (contract['puzzle_id'] != old['puzzle_id'] or contract['level'] != level or
            contract['preserve_exact_existing_definition'] or level in [1, 12]):
        raise ContentError('identity mismatch or immutable anchor')
    colors = {color for bottle in board for color in bottle}
    if len(colors) != contract['colors'] or len(board) != contract['initial_bottles']:
        raise ContentError('design colour/bottle count mismatch')
    if any(len(bottle) != 4 for bottle in board[:-2]) or board[-2:] != [[], []]:
        raise ContentError('initial colours must occupy full targets with two empty buffers')
    labels = list('OGPB'[:contract['colors']]) + [None, None]
    if level >= 9 and any(bottle == [label] * 4 for bottle, label in zip(board, labels) if label):
        raise ContentError('initial completed target not allowed after level8')
    puzzle = deepcopy(old)
    puzzle.update(
        content_version=old['content_version'] + 1,
        initial_bottom_to_top=deepcopy(board), target_labels=labels,
        reference_moves=deepcopy(moves),
        difficulty_intent=f"{contract['title']}：{contract['learning_goal']}。{contract['intended_strategy']}。结构/求解证据见单关卡；人类难度未标定。",
        source_reference='docs/content/design/main60-level-contracts-v2.json',
    )
    validate_puzzle(puzzle)
    return puzzle
