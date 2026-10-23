"""Parent R2 audit. Read frozen inputs; no authoring code in rule checks."""
from collections import deque
from pathlib import Path
import ast,hashlib,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).parent
SNAP=ROOT/'build/main60-parent-review-20261023-r2'
E=SNAP/'docs/development/evidence/main60-content-redesign'
# Reuse only the previously reviewed parent rule function definitions, not the
# top-level full-suite runner, and never import the author's measuring rules.
tree=ast.parse((OUT/'independent_dc02.py').read_text())
keep=[n for n in tree.body if isinstance(n,(ast.Import,ast.ImportFrom,ast.FunctionDef))]
ns={'__file__':str(OUT/'independent_dc02.py')};exec(compile(ast.Module(body=keep,type_ignores=[]),'<parent-independent-rules>','exec'),ns)
notes=json.loads((E/'strategy-notes.json').read_text())['levels'];md=(E/'strategy-review.md').read_text()
rows=[]
for level in [13,20,21,40,41,53,60]:
 p=json.loads((E/f'levels/main-{level:03}.runtime.json').read_text());c=json.loads((E/f'levels/main-{level:03}.json').read_text());trace=ns['replay'](p,p['reference_moves'])
 n=notes[str(level)];assert n['phases'][0][0]==1 and n['phases'][-1][1]==len(trace)
 for a,b in zip(n['phases'],n['phases'][1:]):assert a[1]+1==b[0]
 nodes=[]
 for step,reason in n['nodes']:
  t=trace[step-1];line='`'+' / '.join(x or '∅' for x in t['before'])+'` → `'+ ' / '.join(x or '∅' for x in t['after'])+'`'
  assert line in md,(level,step)
  nodes.append({'step':step,'before':t['before'],'after':t['after'],'units':t['units'],'author_causal_claim':reason})
 rows.append({'level':level,'nodes_verified':nodes,'scope':'exact node states and contiguous phase ranges; causal prose separately read by parent; no human playtest'})
p=json.loads((E/'levels/main-028.runtime.json').read_text());c=json.loads((E/'levels/main-028.json').read_text());moves=c['capacity_truncation_alternative']['moves'];alt=ns['replay'](p,moves);removed=ns['removable'](p,moves)
assert [r['removed_1_based_step'] for r in removed]==[2]
assert alt[1]['capacity_truncated'] and len(removed[0]['steps'])==14
# Exact augmented search of this one board, retaining ordered bottle identities.
start=ns['initial'](p);goal=ns['goal'](p);q=deque([(start,False,0)]);seen={(start,False)};found=[]
while q:
 s,flag,d=q.popleft()
 if s==goal:
  if flag:found.append(d)
  continue
 if d==14:continue
 for _,next_s,amount,run in ns['successors'](s):
  key=(next_s,flag or amount<run)
  if key not in seen:seen.add(key);q.append((*key,d+1))
assert not found
# Isolated mutation: a no-op deletion detector must fail the actual regression.
measure=SNAP/'tools/content/measure_levels.py';original=measure.read_text();t=ast.parse(original);fn=next(x for x in t.body if isinstance(x,ast.FunctionDef) and x.name=='deletion_audit');lines=original.splitlines(True)
mutant=''.join(lines[:fn.lineno-1])+"def deletion_audit(board, labels, moves):\n    return []\n"+''.join(lines[fn.end_lineno:])
cmd=[str(ROOT/'.venv/bin/python'),'-m','unittest','test_measure_levels.MeasurementTests.test_dc02_r01_deleted_capacity_move_changes_later_maximum_units_but_still_wins','-v']
try:
 measure.write_text(mutant);red=subprocess.run(cmd,cwd=measure.parent,text=True,capture_output=True);assert red.returncode!=0 and 'AssertionError: Lists differ: [] != [2]' in red.stderr
finally:measure.write_text(original)
green=subprocess.run(cmd,cwd=measure.parent,text=True,capture_output=True);assert green.returncode==0
snapshot=json.loads((OUT/'snapshot-dc02-r2.json').read_text())
assert all(hashlib.sha256((SNAP/f).read_bytes()).hexdigest()==h for f,h in snapshot['files'].items())
result={'scope_frozen_files':34,'snapshot_files_unchanged_after_checks':len(snapshot['files']),'strategy_nodes':rows,'level28':{'old_positive_claim':'failed; preserved','independent_conditional_depth':14,'independent_conditional_visited':len(seen),'solution_with_truncation_found':False,'single_deletion_wins':[x['removed_1_based_step'] for x in removed],'negative_branch_length':len(alt),'without_redundant_step_length':len(removed[0]['steps']),'general_impossibility_claim':False},'regression_mutation':{'red_exit':red.returncode,'red_output':red.stdout+red.stderr,'green_exit':green.returncode,'green_output':green.stdout+green.stderr},'physical_or_human_playtest':False}
(OUT/'dc02-r2-independent.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'nodes':sum(len(x['nodes_verified']) for x in rows),'augmented28_states':len(seen),'regression_red':red.returncode,'regression_green':green.returncode,'frozen_files':len(snapshot['files'])}))
