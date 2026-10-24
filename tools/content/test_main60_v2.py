import json
from pathlib import Path
import unittest

from main60_v2 import make_candidate, classify_capacity_example, inspect_route, check_measured_reference
from validate import ContentError, read_json


ROOT = Path(__file__).resolve().parents[2]


class Main60V2Tests(unittest.TestCase):
    def test_046_competing_choices_really_need_the_same_empty_receiver(self):
        from validate import pour
        base = ROOT / 'docs/development/evidence/main60-content-redesign/full60'
        data = json.loads((base / 'branch-comparisons.json').read_text())
        node = next(row for row in data['levels'] if row['level'] == 46)
        card = json.loads((base / 'levels/main-046.json').read_text())
        self.assertEqual(node['state'], card['reference_replay']['steps'][node['before_reference_step'] - 1]['before'])
        first, second = [b['first_move'] for b in node['branches'][:2]]
        self.assertEqual(first['to_index'], second['to_index'])
        board = [list(b) for b in node['state']]
        self.assertEqual(board[first['to_index']], [])
        self.assertNotEqual(board[first['from_index']][-1], board[second['from_index']][-1])
        for chosen, deferred in [(first, second), (second, first)]:
            after, _, _ = pour(board, chosen['from_index'], chosen['to_index'])
            with self.assertRaises(ContentError):
                pour(after, deferred['from_index'], deferred['to_index'])

    def test_short_solution_guard_does_not_turn_unknown_or_a_long_reference_into_proof(self):
        p = read_json(ROOT / 'docs/development/evidence/main60-content-redesign/levels/main-021.runtime.json')
        for proof in [
            {'status': 'unknown', 'excluded_through': None},
            {'status': 'found', 'shortest_within_bound': 9, 'excluded_through': 8},
        ]:
            with self.assertRaises(ContentError):
                check_measured_reference(p, proof)

    def test_short_solution_guard_rejects_mismatched_measured_route(self):
        p = read_json(ROOT / 'docs/development/evidence/main60-content-redesign/levels/main-021.runtime.json')
        with self.assertRaises(ContentError):
            check_measured_reference(p, {'status': 'found', 'shortest_within_bound': 13,
                                       'excluded_through': 12, 'moves': [{'from_index': 0, 'to_index': 1}]})

    def test_changed_021_keeps_identity_and_increments_actual_version_two_to_three(self):
        old = read_json(ROOT / 'docs/development/evidence/main60-content-redesign/old-main/main-021.json')
        original = json.dumps(old, sort_keys=True)
        four = read_json(ROOT / 'app/assets/puzzles/main/main-012.json')
        contracts = read_json(ROOT / 'docs/content/design/main60-level-contracts-v2.json')
        contract = next(row for row in contracts['levels'] if row['level'] == 21)
        result = make_candidate(old, four['initial_bottom_to_top'], four['reference_moves'], contract)
        self.assertEqual(result['puzzle_id'], 'main-021')
        self.assertEqual(result['content_version'], 3)
        self.assertEqual(result['main_level'], 21)
        self.assertEqual(json.dumps(old, sort_keys=True), original)

    def test_authored_anchors_cannot_be_replaced_by_candidate_helper(self):
        contracts = read_json(ROOT / 'docs/content/design/main60-level-contracts-v2.json')
        for n in [1, 12]:
            old = read_json(ROOT / f'app/assets/puzzles/main/main-{n:03}.json')
            with self.assertRaises(ContentError):
                make_candidate(old, old['initial_bottom_to_top'], old['reference_moves'], contracts['levels'][n - 1])

    def test_three_colour_021_cannot_pass_four_colour_contract(self):
        old = read_json(ROOT / 'docs/development/evidence/main60-content-redesign/old-main/main-021.json')
        contracts = read_json(ROOT / 'docs/content/design/main60-level-contracts-v2.json')
        with self.assertRaises(ContentError):
            make_candidate(old, old['initial_bottom_to_top'], old['reference_moves'], contracts['levels'][20])

    def test_revised028_keeps_removable_truncation_as_negative_not_recommended(self):
        example = read_json(ROOT / 'docs/development/evidence/main60-content-redesign/dc02-r01-original-capacity-route.json')
        p = example['puzzle']
        result = classify_capacity_example(p, example['alternative']['moves'])
        self.assertEqual(result['classification'], 'negative_comparison_not_recommended')
        self.assertEqual(result['deletable_steps'], [2])
        self.assertEqual(result['truncated_steps'], [2])
        self.assertFalse(result['space_benefit_proven'])

    def test_route_links_refer_to_real_emptied_capacity_and_fixed_completion(self):
        base = ROOT / 'docs/development/evidence/main60-content-redesign/history/dc02-r2/levels'
        p = read_json(base / 'main-053.runtime.json')
        # Evidence cards include timing measurements; only runtime definitions
        # use the strict integer-token puzzle parser.
        c = json.loads((base / 'main-053.json').read_text())
        inspection = inspect_route(p, c['reference_replay'])
        self.assertIn({'empty_step': 9, 'use_step': 10, 'bottle': 4}, inspection['space_links'])
        self.assertIn({'step': 9, 'bottle': 1, 'color': 'G'}, inspection['stable_goal_events'])


if __name__ == '__main__':
    unittest.main()
