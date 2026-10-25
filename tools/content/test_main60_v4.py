import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from validate import ContentError, read_json, validate_puzzle, repetition_audit
from measure_levels import trace_solution

ROOT=Path(__file__).resolve().parents[2]
EVIDENCE=ROOT/'docs/development/evidence/main60-five-color-difficulty'

class Main60V4Tests(unittest.TestCase):
    def test_entire_pack_and_contracts_not_samples(self):
        from author_main60_v4 import build_pack
        pack,cards=build_pack()
        self.assertEqual(len(pack),60)
        self.assertEqual(len(cards),60)
        for n,(pid,p) in enumerate(sorted(pack.items()),1):
            old=read_json(EVIDENCE/'old-main'/f'{pid}.json')
            colors=2 if n<=4 else 3 if n<=8 else 4 if n<=20 else 5
            self.assertEqual(len(p['initial_bottom_to_top']),colors+2)
            changed=p['initial_bottom_to_top']!=old['initial_bottom_to_top'] or p['target_labels']!=old['target_labels']
            self.assertEqual(p['content_version'],old['content_version']+int(changed))
            validate_puzzle(p)
            if n>=21:
                card=cards[n-1]
                self.assertTrue(card['planning_point']['explanation'])
                self.assertGreaterEqual(len(card['planning_point']['branches']),2)
                self.assertNotEqual(card['planning_point']['branches'][0]['first_move'],card['planning_point']['branches'][1]['first_move'])
                for branch in card['planning_point']['branches']:
                    trace_solution(card['planning_point']['board'],p['target_labels'],branch['moves'])
        daily=[read_json(p) for p in (ROOT/'app/assets/puzzles/daily').glob('*.json')]
        audit=repetition_audit(list(pack.values())+daily)
        for field in ['exact_groups','equivalent_groups','liquid_structure_groups']:
            self.assertEqual(audit[field],[])

    def test_installer_prechecks_every_destination_before_any_write(self):
        from author_main60_v4 import build_pack, install_pack, encoded
        pack,_=build_pack()
        old={p.stem:p.read_bytes() for p in (EVIDENCE/'old-main').glob('*.json')}
        with tempfile.TemporaryDirectory() as tmp:
            first=Path(tmp)/'first';second=Path(tmp)/'second'
            for directory in [first,second]:
                directory.mkdir()
                for pid,data in old.items():(directory/f'{pid}.json').write_bytes(data)
            (second/'main-060.json').write_text('{}')
            with self.assertRaisesRegex(ContentError,'unknown destination'):
                install_pack(pack,[first,second])
            self.assertEqual((first/'main-021.json').read_bytes(),old['main-021'])
            (second/'main-060.json').write_bytes(old['main-060'])
            install_pack(pack,[first,second])
            install_pack(pack,[first,second])
            self.assertEqual((first/'main-060.json').read_bytes(),encoded(pack['main-060']))

    def test_finite_policies_replay_real_actions_and_keep_terminal_states_distinct(self):
        from author_main60_v4 import strategy, SEEDS
        from validate import pour, is_won
        from measure_levels import successors
        for n in [20,30,40,50,60]:
            p=read_json(ROOT/f'app/assets/puzzles/main/main-{n:03}.json')
            for policy in ['greedy','random']:
                for seed in SEEDS[:4]:
                    a=strategy(p['initial_bottom_to_top'],p['target_labels'],seed,policy)
                    self.assertEqual(a,strategy(p['initial_bottom_to_top'],p['target_labels'],seed,policy))
                    board=p['initial_bottom_to_top']
                    for source,target in a['moves']:board,_,_=pour(board,source,target)
                    self.assertEqual([''.join(b) for b in board],a['final_board'])
                    self.assertLessEqual(a['actions'],120)
                    self.assertEqual(a['status']=='win',is_won(board,p['target_labels']))
                    if a['status']=='no_legal_move':self.assertFalse(list(successors(tuple(a['final_board']))))
                    if a['status']=='action_budget':self.assertEqual(a['actions'],120)

    def test_five_checkpoints_extra_and_undo_comparisons_are_real_replays(self):
        data=read_json(EVIDENCE/'extra-space-comparisons.json')['levels']
        self.assertEqual([r['level'] for r in data],[20,30,40,50,60])
        for row in data:
            p=read_json(ROOT/f"app/assets/puzzles/main/{row['id']}.json")
            prefix=trace_solution(p['initial_bottom_to_top'],p['target_labels'],row['prefix'],require_win=False)
            self.assertEqual(prefix['steps'][-1]['after'],row['board'])
            trace_solution(row['board'],p['target_labels'],row['without_extra']['moves'])
            trace_solution(row['board'],p['target_labels'],row['without_extra']['alternative_after_one_undo'])
            trace_solution(row['board']+[''],p['target_labels']+[None],row['with_extra']['moves'])

    def test_daily_and_catalog_still_match_frozen_bytes(self):
        baseline=read_json(EVIDENCE/'baseline.json')['hashes']
        for name,digest in baseline.items():
            if '/daily/' in name or '/catalog/' in name:
                self.assertEqual(hashlib.sha256((ROOT/name).read_bytes()).hexdigest(),digest,name)

if __name__=='__main__':unittest.main()
