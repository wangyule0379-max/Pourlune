"""Reproduce/check all60 explicit v4 inputs; install only after all byte checks.

No runtime generation, store access, SDK calls or release operation. Measurement
records finite strategy outcomes, never player difficulty or unsolvability.
"""
import argparse
from collections import Counter
from copy import deepcopy
import csv
import hashlib
import json
from pathlib import Path
import random

from main60_v2 import inspect_route
from measure_levels import successors, trace_solution
from validate import ContentError, read_json, repetition_audit, validate_puzzle, pour

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'docs/development/evidence/main60-five-color-difficulty'
SOURCE = ROOT / 'docs/content/design/main60-five-color-v4.json'
CONTRACTS = ROOT / 'docs/content/design/main60-five-color-contracts-v4.json'
DESTINATIONS = [ROOT/'app/assets/puzzles/main', ROOT/'docs/content/production-candidates/puzzles/main']
SEEDS = tuple(202610250000 + n for n in range(64))
POLICIES = ('greedy', 'random')
STATUSES = ('win', 'cycle', 'no_legal_move', 'action_budget')


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def frozen_bytes(pid):
    return (EVIDENCE/'old-main'/f'{pid}.json').read_bytes()


def output_bytes(pid, puzzle):
    before = frozen_bytes(pid)
    return before if read_json(EVIDENCE/'old-main'/f'{pid}.json') == puzzle else encoded(puzzle)


def protected_check():
    for name, digest in read_json(EVIDENCE/'baseline.json')['hashes'].items():
        if '/daily/' in name or '/catalog/' in name:
            if sha((ROOT/name).read_bytes()) != digest:
                raise ContentError(f'protected daily/catalog changed: {name}')


def build_pack():
    authored = read_json(SOURCE)['levels']
    contracts = read_json(CONTRACTS)['levels']
    expected = set(range(1,61))
    if len(authored)!=60 or {r['level'] for r in authored}!=expected or len(contracts)!=60 or {r['level'] for r in contracts}!=expected:
        raise ContentError('requires exactly60 unique definitions/contracts')
    contracts = {r['level']:r for r in contracts}
    pack,cards = {},[]
    for entry in sorted(authored,key=lambda r:r['level']):
        n=entry['level'];pid=f'main-{n:03}';before=frozen_bytes(pid);old=json.loads(before);p=deepcopy(entry['puzzle']);contract=contracts[n]
        if entry['previous_sha256']!=sha(before):
            raise ContentError(f'{pid}: frozen baseline mismatch')
        if p['puzzle_id']!=pid or p['main_level']!=n:
            raise ContentError(f'{pid}: identity changed')
        colors=2 if n<=4 else 3 if n<=8 else 4 if n<=20 else 5
        if len(p['initial_bottom_to_top'])!=colors+2 or contract['colors']!=colors:
            raise ContentError(f'{pid}: progression mismatch')
        changed = any(p[k]!=old[k] for k in ['initial_bottom_to_top','target_labels'])
        if p['content_version']!=old['content_version']+int(changed):
            raise ContentError(f'{pid}: version must advance only for changed definition')
        if not changed and p!=old:
            raise ContentError(f'{pid}: retained definition must keep every field')
        validate_puzzle(p)
        trace=trace_solution(p['initial_bottom_to_top'],p['target_labels'],p['reference_moves'])
        observations=inspect_route(p,trace)
        point=deepcopy(entry['planning_point'])
        prefix=trace_solution(p['initial_bottom_to_top'],p['target_labels'],point['prefix'],require_win=False)
        reached=prefix['steps'][-1]['after'] if prefix['steps'] else [''.join(b) for b in p['initial_bottom_to_top']]
        if reached!=point['board']:
            raise ContentError(f'{pid}: decision prefix mismatch')
        if n>=21:
            if not observations['target_space_freed_while_mixed_steps'] or not (observations['strategic_buffer_reuse_steps'] or observations['target_reborrow']):
                raise ContentError(f'{pid}: route lacks actual space/reuse evidence')
            if len(point['branches'])<2 or not point['explanation']:
                raise ContentError(f'{pid}: missing concrete decision evidence')
            choices=point['branches'][:2]
            a,b=[x['first_move'] for x in choices]
            if sum(not x for x in point['board'])!=1 or a['to_index']!=b['to_index'] or point['board'][a['to_index']] or point['board'][a['from_index']][-1]==point['board'][b['from_index']][-1]:
                raise ContentError(f'{pid}: decision must compete for the sole empty receiver')
            following,_,_=pour([list(x) for x in point['board']],a['from_index'],a['to_index'])
            try:
                pour(following,b['from_index'],b['to_index'])
            except ContentError:
                pass
            else:
                raise ContentError(f'{pid}: competing choice was not actually deferred')
        first_moves=[]
        for branch in point['branches']:
            branch_trace=trace_solution(point['board'],p['target_labels'],branch['moves'])
            if branch['first_move']!=branch['moves'][0]:
                raise ContentError(f'{pid}: first move mismatch')
            first_moves.append(tuple(branch['first_move'].values()))
            branch['replay']=branch_trace
        if len(first_moves)!=len(set(first_moves)):
            raise ContentError(f'{pid}: repeated choices')
        pack[pid]=p
        cards.append(dict(puzzle_id=pid,level=n,contract=contract,
            old_version=old['content_version'],new_version=p['content_version'],
            previous_sha256=sha(before),new_sha256=sha(output_bytes(pid,p)),
            retained_reason=entry['review_notes'],reference_replay=trace,
            route_observations=observations,planning_point=point,
            measurement=entry['measurement'],human_play_status='not yet played; algorithmic evidence only'))
    daily=[read_json(p) for p in sorted((ROOT/'app/assets/puzzles/daily').glob('*.json'))]
    duplicates=repetition_audit(list(pack.values())+daily)
    if any(duplicates[k] for k in ['exact_groups','equivalent_groups','liquid_structure_groups']):
        raise ContentError(f'duplicate pack: {duplicates}')
    protected_check()
    return pack,cards


def install_pack(pack, destinations=DESTINATIONS):
    # Check all destinations before the first write, including the last file.
    for directory in destinations:
        for pid,p in pack.items():
            data=(directory/f'{pid}.json').read_bytes()
            if data not in [frozen_bytes(pid), output_bytes(pid,p)]:
                raise ContentError(f'unknown destination edit: {directory/pid}')
    protected_check()
    for directory in destinations:
        for pid,p in pack.items():
            path=directory/f'{pid}.json';data=output_bytes(pid,p)
            if path.read_bytes()!=data:path.write_bytes(data)
    protected_check()


def strategy(board, labels, seed, kind):
    """Fixed finite baseline policies. No search or reference knowledge.

    Both avoid immediately reversing the preceding bottle pair when another
    action exists. Greedy lexicographically prefers: don't disturb an already
    correct full target; pour to matching target; merge nonempty top; empty the
    source. Ties use the same seeded RNG. Random chooses uniformly. End on the
    third exact board visit, no legal move, victory, or120 legal actions.
    """
    if kind not in POLICIES:raise ValueError('unknown strategy')
    rng=random.Random(seed);state=tuple(''.join(b) for b in board)
    goal=tuple(c*4 if c else '' for c in labels)
    seen={state:1};last=None;moves=[]
    status='action_budget'
    for step in range(120):
        if state==goal:status='win';break
        options=list(successors(state))
        if not options:status='no_legal_move';break
        alternatives=[x for x in options if last is None or (x[0],x[1])!=last[::-1]]
        if alternatives:options=alternatives
        if kind=='greedy':
            def score(x):
                a,b,n=x;color=state[a][-1]
                return (state[a]!=goal[a] or labels[a] is None,labels[b]==color,bool(state[b]),not n[a])
            maximum=max(map(score,options));options=[x for x in options if score(x)==maximum]
        a,b,following=rng.choice(options);moves.append([a,b]);last=(a,b);state=following
        seen[state]=seen.get(state,0)+1
        if state==goal:status='win';break
        if seen[state]>=3:status='cycle';break
    return dict(seed=seed,status=status,actions=len(moves),moves=moves,final_board=list(state))


def report(pack,cards,directory):
    directory.mkdir(parents=True,exist_ok=True);(directory/'levels').mkdir(exist_ok=True)
    totals=[]
    with (directory/'simple-strategies.jsonl').open('w') as raw:
        for card in cards:
            pid=card['puzzle_id'];old=json.loads(frozen_bytes(pid))
            comparisons={}
            for version,p in [('old',old),('new',pack[pid])]:
                comparisons[version]={}
                for policy in POLICIES:
                    outcomes=[]
                    for seed in SEEDS:
                        row=strategy(p['initial_bottom_to_top'],p['target_labels'],seed,policy)
                        raw.write(json.dumps(dict(id=pid,definition=version,policy=policy,**row),ensure_ascii=False,separators=(',',':'))+'\n')
                        outcomes.append(row)
                    counts=Counter(r['status'] for r in outcomes)
                    comparisons[version][policy]={s:counts[s] for s in STATUSES}
            card['simple_strategy_comparison']=comparisons
            if card['level']>=21 and comparisons['new']['greedy']['win']>32:
                raise ContentError(f'{pid}: simple policy reliably clears candidate; re-review')
            (directory/'levels'/f'{pid}.json').write_bytes(encoded(card))
            totals.append(dict(id=pid,level=card['level'],**comparisons))
    (directory/'strategy-summary.json').write_bytes(encoded(dict(seeds=list(SEEDS),action_budget=120,cycle_definition='third exact board visit',policies=strategy.__doc__,levels=totals,scope='finite strategy simulations; not human difficulty, shortest or no-solution proofs')))
    with (directory/'curve.csv').open('w',newline='') as stream:
        writer=csv.writer(stream);writer.writerow(['id','old_version','new_version','colors','initial_bottles','stage','title','planning_point','reference_steps','lower_bound','shortest_status','old_greedy_wins_64','new_greedy_wins_64','old_random_wins_64','new_random_wins_64','human_play'])
        for c in cards:
            comparison=c['simple_strategy_comparison'];contract=c['contract']
            writer.writerow([c['puzzle_id'],c['old_version'],c['new_version'],contract['colors'],contract['initial_bottles'],contract['stage'],contract['title'],c['planning_point']['explanation'],len(c['reference_replay']['steps']),c['measurement']['group_lower_bound'],c['measurement']['shortest_status'],comparison['old']['greedy']['win'],comparison['new']['greedy']['win'],comparison['old']['random']['win'],comparison['new']['random']['win'],c['human_play_status']])
    (directory/'manifest.json').write_bytes(encoded(dict(count=60,source_sha256=sha(SOURCE.read_bytes()),contracts_sha256=sha(CONTRACTS.read_bytes()),daily_catalog_unchanged=True,levels=[dict(id=c['puzzle_id'],old_sha256=c['previous_sha256'],new_sha256=c['new_sha256'],old_version=c['old_version'],new_version=c['new_version']) for c in cards])))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True);group.add_argument('--check',action='store_true');group.add_argument('--install',action='store_true');group.add_argument('--measure',action='store_true')
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    if args.check and args.report:parser.error('--check is strictly read-only; use --measure --report')
    if args.measure and not args.report:parser.error('--measure requires --report')
    pack,cards=build_pack()
    if args.install:install_pack(pack)
    for directory in DESTINATIONS:
        for pid,p in pack.items():
            if (directory/f'{pid}.json').read_bytes()!=output_bytes(pid,p):
                raise ContentError(f'packaging differs: {directory/pid}')
    if args.report:report(pack,cards,args.report)
    print(json.dumps(dict(count=60,installed=args.install,daily_catalog_unchanged=True,scope='legal full pack and byte integrity; human/visual acceptance separate')))

if __name__=='__main__':main()
