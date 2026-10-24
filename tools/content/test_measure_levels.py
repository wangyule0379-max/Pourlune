"""Exact fixed-label short-solution checks must never confuse budget with proof."""
import unittest
import subprocess
import sys
import json
from pathlib import Path

from measure_levels import bounded_search, trace_solution, trace_features, shorten_reference, deletion_audit
from validate import ContentError


class MeasurementTests(unittest.TestCase):
    def test_maximal_pour_is_truncated_by_receiver_space(self):
        # Full receiver is illegal, even when its top matches.
        with self.assertRaises(ContentError):
            trace_solution(['GOOO', 'GOOO', '', ''], ['O', 'G', None, None],
                           [{'from_index': 0, 'to_index': 1}], require_win=False)

    def test_capacity_truncation_and_partial_source_are_recorded(self):
        trace = trace_solution(['GOOO', 'GOO', '', ''], ['O', 'G', None, None],
                               [{'from_index': 0, 'to_index': 1}], require_win=False)
        self.assertEqual(trace['steps'][0]['units'], 1)
        self.assertTrue(trace['steps'][0]['capacity_truncated'])
        self.assertEqual(trace['steps'][0]['after'], ['GOO', 'GOOO', '', ''])

    def test_wrong_label_full_bottles_need_three_moves_not_zero(self):
        board, labels = ['GGGG', 'OOOO', '', ''], ['O', 'G', None, None]
        short = bounded_search(board, labels, 2, max_states=1000)
        self.assertEqual(short['status'], 'excluded')
        self.assertEqual(short['excluded_through'], 2)
        solved = bounded_search(board, labels, 3, max_states=1000)
        self.assertEqual(solved['status'], 'found')
        self.assertEqual(solved['shortest_within_bound'], 3)
        self.assertTrue(trace_solution(board, labels, solved['moves'])['won'])

    def test_budget_exhaustion_never_certifies_exclusion(self):
        result = bounded_search(['OGOG', 'GOGO', '', ''], ['O', 'G', None, None],
                                8, max_states=1)
        self.assertEqual(result['status'], 'unknown')
        self.assertIsNone(result['excluded_through'])

    def test_both_buffer_orderings_preserve_the_fixed_target_proof(self):
        labels = ['O', 'G', None, None]
        for board in [['OOO', 'GGGG', 'O', ''], ['OOO', 'GGGG', '', 'O']]:
            result = bounded_search(board, labels, 1, max_states=1000)
            self.assertEqual(result['shortest_within_bound'], 1)

    def test_readonly_cli_reports_known_short_solution(self):
        root = Path(__file__).resolve().parents[2]
        # This is the known old six-move regression, not a promise that the
        # redesigned runtime level13 stays easy.
        puzzle = root / 'docs/development/evidence/main60-content-redesign/old-main/main-013.json'
        before = puzzle.read_bytes()
        run = subprocess.run([sys.executable, str(root / 'tools/content/measure_levels.py'),
                              '--depth', '8', str(puzzle)], capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertTrue(run.stdout.strip(), 'measurement CLI must actually report the bound')
        self.assertEqual(json.loads(run.stdout)['rows'][0]['search']['shortest_within_bound'], 6)
        self.assertEqual(puzzle.read_bytes(), before)

    def test_label_swap_buffer_reuse_is_not_planning_during_mixed_liquids(self):
        board = ['GOPP', 'BBPB', 'GPGO', 'GBOO', '', '']
        pairs = [(0,4),(2,0),(0,5),(2,0),(2,4),(3,5),(1,3),(1,4),
                 (3,1),(0,2),(2,3),(4,2),(5,0),(1,4),(3,1),(4,3)]
        trace = trace_solution(board, ['O','G','P','B',None,None],
                               [{'from_index':a,'to_index':b} for a,b in pairs])
        self.assertEqual(trace_features(trace)['strategic_buffer_reuse_steps'], [])

    def test_empty_buffer_accepts_new_colour_while_another_bottle_is_still_mixed(self):
        board = ['PGBG', 'GPBO', 'POBB', 'POOG', '', '']
        pairs = [(0,4),(3,4),(1,3),(0,1),(0,4),(1,5),(1,0),(2,5),
                 (4,1),(2,4),(3,4),(0,2),(3,2),(4,0),(5,3)]
        trace = trace_solution(board, ['O','G','P','B',None,None],
                               [{'from_index':a,'to_index':b} for a,b in pairs])
        self.assertEqual(trace_features(trace)['strategic_buffer_reuse_steps'], [10])

    def test_removable_three_move_full_colour_detour_is_shortened(self):
        board = ['OO', 'GGGG', 'O', 'O', 'PPPP', 'BBBB']
        labels = ['O', 'G', 'P', 'B', None, None]
        pairs = [(0,2),(2,3),(3,0),(4,2),(5,3)]
        moves = [{'from_index':a,'to_index':b} for a,b in pairs]
        reduced = shorten_reference(board, labels, moves)
        self.assertEqual(len(reduced['moves']), 4)
        self.assertTrue(trace_solution(board, labels, reduced['moves'])['won'])
        self.assertEqual(len(moves), 5)

    def test_dc02_r01_deleted_capacity_move_changes_later_maximum_units_but_still_wins(self):
        board = ['BBGP', 'OPOO', 'GPOB', 'BGGP', '', '']
        labels = ['O', 'G', 'P', 'B', None, None]
        pairs = [(2,4),(1,2),(0,5),(3,5),(0,3),(0,4),(1,0),(1,5),
                 (2,0),(1,0),(2,5),(3,2),(4,3),(2,1),(5,2)]
        moves = [{'from_index':a,'to_index':b} for a,b in pairs]
        original = trace_solution(board, labels, moves)
        self.assertTrue(original['steps'][1]['capacity_truncated'])
        audited = deletion_audit(board, labels, moves)
        self.assertEqual([r['removed_1_based_step'] for r in audited], [2])
        self.assertEqual(len(audited[0]['replay']['steps']), 14)
        self.assertEqual(audited[0]['replay']['steps'][5]['units'], 2)
        self.assertFalse(any(s['capacity_truncated'] for s in audited[0]['replay']['steps']))


if __name__ == '__main__':
    unittest.main()
