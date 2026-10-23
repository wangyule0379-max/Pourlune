"""Parent-owned DC02 audit; no imports from authoring/validation implementation.
Run against a copied snapshot; never changes runtime content.
"""
import json, hashlib, time, itertools
from pathlib import Path
from collections import deque, Counter
ROOT=Path(__file__).resolve().parents[4]
SNAP=ROOT/'build/main60-parent-review-20261023'
EVD=SNAP/'docs/development/evidence/main60-content-redesign/levels'
OUT=Path(__file__).with_name('independent-dc02-results.json')

def initial(p): return tuple(tuple(x) for x in p['initial_bottom_to_top'])
def goal(p): return tuple(tuple([c]*4) if c else () for c in p['target_labels'])
def successors(s):
    for a,src in enumerate(s):
        if not src: continue
        run=1
        while run<len(src) and src[-run-1]==src[-1]:run+=1
        for b,dst in enumerate(s):
            if a==b or len(dst)==4 or (dst and dst[-1]!=src[-1]):continue
            n=min(run,4-len(dst));state=list(s)
            state[a]=src[:-n];state[b]=dst+src[-n:]
            yield (a,b),tuple(state),n,run

def replay(p,moves,expected=None):
    state=initial(p);seen={state};units=Counter(x for b in state for x in b); rows=[]
    for i,m in enumerate(moves):
        assert state!=goal(p),'action after victory'
        nxt=next((x for x in successors(state) if x[0]==(m['from_index'],m['to_index'])),None)
        assert nxt is not None, f'illegal move {i+1}'
        pair,follow,n,run=nxt
        assert Counter(x for b in follow for x in b)==units
        assert follow not in seen,'repeated board'
        row={'step':i+1,'before':[''.join(b) for b in state],'after':[''.join(b) for b in follow],'units':n,'capacity_truncated':n<run}
        if expected is not None:
            e=expected['steps'][i]
            for k in row: assert row[k]==e[k],f'trace mismatch {i+1}/{k}'
        rows.append(row);state=follow;seen.add(state)
    assert state==goal(p),'did not win'
    return rows

def search(p,bound,cap=500000,seconds=8):
    start=initial(p);win=goal(p);todo=deque([(start,0)]);seen={start};layers=Counter({0:1});t=time.monotonic()
    while todo:
        if time.monotonic()-t>seconds:return {'status':'unknown','reason':'time budget','visited':len(seen)}
        s,d=todo.popleft()
        if s==win:return {'status':'found','shortest_depth':d,'visited':len(seen),'layers':dict(layers)}
        if d==bound:continue
        for _,nxt,_,_ in successors(s):
            if nxt in seen:continue
            if len(seen)==cap:return {'status':'unknown','reason':'state budget','visited':len(seen)}
            seen.add(nxt);layers[d+1]+=1;todo.append((nxt,d+1))
    return {'status':'excluded','excluded_through':bound,'visited':len(seen),'layers':dict(layers)}

def removable(p,moves):
    results=[]
    for i in range(len(moves)):
        shortened=moves[:i]+moves[i+1:]
        try:r=replay(p,shortened)
        except AssertionError:continue
        results.append({'removed_1_based_step':i+1,'moves':shortened,'steps':r})
    return results

def canonical(p,labels=False):
    colors=sorted({c for b in p['initial_bottom_to_top'] for c in b});candidates=[]
    for perm in itertools.permutations(range(len(colors))):
        mapping=dict(zip(colors,perm)); bottles=[tuple(mapping[c] for c in b) for b in p['initial_bottom_to_top']]
        if labels:bottles=[((mapping[c] if c is not None else -1),b) for c,b in zip(p['target_labels'],bottles)]
        candidates.append(tuple(sorted(bottles)))
    return min(candidates)

old=[json.loads(p.read_text()) for p in (SNAP/'app/assets/puzzles').rglob('*.json')]
rows=[];known={False:{canonical(p):p['puzzle_id'] for p in old},True:{canonical(p,True):p['puzzle_id'] for p in old}}
for path in sorted(EVD.glob('*.runtime.json')):
    p=json.loads(path.read_text());card=json.loads(path.with_name(path.name.replace('.runtime','')).read_text());n=p['main_level'];prior=next(x for x in old if x['puzzle_id']==p['puzzle_id'])
    assert p['content_version']==prior['content_version']+1
    assert p['puzzle_id']==card['puzzle_id'] and n==card['level']
    assert hashlib.sha256(path.read_bytes()).hexdigest()==card['new_definition_sha256']
    assert len(initial(p))==6 and initial(p)[-2:]==((),())
    assert sorted(Counter(c for b in initial(p) for c in b).values())==[4]*4
    assert all(not label or b!=tuple([label]*4) for b,label in zip(initial(p),p['target_labels']))
    reference=replay(p,p['reference_moves'],card['reference_replay'])
    assert len(reference)==card['legal_solution_upper_bound']
    depth=8 if n<=20 else 10 if n<=40 else 11
    proof=search(p,depth);assert proof['status']=='excluded'
    assert proof['visited']==card['short_solution_proof']['visited']
    branch_results=[]
    for b in card['opening_branches']:
        trace=replay(p,b['moves'],b['replay']);assert len(trace)==b['upper_bound']
        branch_results.append({'first_move':b['first_move'],'steps':len(trace)})
    alt=card['capacity_truncation_alternative'];alt_result=None
    if alt:
        trace=replay(p,alt['moves'],alt['replay'])
        alt_result={'steps':len(trace),'truncation_steps':[r['step'] for r in trace if r['capacity_truncated']],'single_move_deletions_still_win':removable(p,alt['moves'])}
    duplicate=[]
    for labels in [False,True]:
        k=canonical(p,labels)
        if k in known[labels]:duplicate.append({'labels':labels,'other':known[labels][k]})
        known[labels][k]=p['puzzle_id']
    rows.append({'level':n,'hash':card['new_definition_sha256'],'version':p['content_version'],'reference_steps':len(reference),'independent_exclusion':proof,'independent_shortest_search':search(p,len(reference)), 'branches':branch_results,'reference_single_move_deletions_still_win':removable(p,p['reference_moves']),'capacity_alternative':alt_result,'duplicates':duplicate})
OUT.write_text(json.dumps({'method':'Independent tuple-array legal moves/replay/exhaustive ordered BFS; frozen input. Not human playtest or UI verification.','snapshot':str(SNAP),'rows':rows},ensure_ascii=False,indent=2)+'\n')
for r in rows:print(json.dumps({k:v for k,v in r.items() if k not in ['branches','capacity_alternative','reference_single_move_deletions_still_win','independent_exclusion','independent_shortest_search']}|{'excluded':r['independent_exclusion']['excluded_through'],'shortest':r['independent_shortest_search'].get('shortest_depth',r['independent_shortest_search']['status']),'reference_deletable':[x['removed_1_based_step'] for x in r['reference_single_move_deletions_still_win']],'alternative_deletable':[x['removed_1_based_step'] for x in r['capacity_alternative']['single_move_deletions_still_win']] if r['capacity_alternative'] else []}))
