"""Independent finite-graph check of the labeled 4-color hint regression fixture."""
import json
from pathlib import Path
initial = (tuple('PBBG'), tuple('GOOO'), tuple('PBBP'), tuple('GO'), tuple('P'), tuple('G'))
def successors(board):
    for source, liquid in enumerate(board):
        if not liquid:
            continue
        group = 1
        while group < len(liquid) and liquid[-group-1] == liquid[-1]:
            group += 1
        for destination, target in enumerate(board):
            if source == destination or len(target) == 4 or (target and target[-1] != liquid[-1]):
                continue
            units = min(group, 4-len(target))
            result = list(board)
            result[source], result[destination] = liquid[:-units], target + liquid[-units:]
            yield source, destination, tuple(result)
def won(board):
    return all(board[i] == (color,)*4 for i, color in enumerate('OGPB')) and not board[4] and not board[5]
seen = {initial}
queue = [initial]
edges = []
for board in queue:
    assert not won(board)
    for source, destination, result in successors(board):
        edges.append({'from_board': board, 'move': [source, destination], 'to_board': result})
        if result not in seen:
            seen.add(result)
            queue.append(result)
assert len(seen) == 12
output = {'initial': initial, 'reachable_states': queue, 'state_count':len(seen), 'no_winning_states':True, 'edges':edges, 'scope':'independent exhaustive exact labeled graph, no symmetry folding'}
Path(__file__).with_name('unsatisfiable-proof.json').write_text(json.dumps(output, indent=2)+'\n')
print(f'{len(seen)} reachable states, {len(edges)} legal edges, none winning')
