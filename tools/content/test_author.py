"""Candidate authoring keeps fixed targets, determinism and historical identity."""
import json
from pathlib import Path
import unittest

from author_candidates import solve, authored_board
from validate import ContentError, pour, is_won

ROOT = Path(__file__).resolve().parents[2]


class AuthorTests(unittest.TestCase):
    def test_solver_routes_wrong_targets_back_without_an_extra_bottle(self):
        board = [['G'] * 4, ['O'] * 4, [], []]
        moves, evidence = solve(board, ['O', 'G', None, None])
        for move in moves:
            board, _, _ = pour(board, move['from_index'], move['to_index'])
        self.assertTrue(is_won(board, ['O', 'G', None, None]))
        self.assertEqual(len(board), 4)
        self.assertGreater(evidence['visited'], 0)

    def test_budget_exhaustion_is_not_unsolvable(self):
        with self.assertRaisesRegex(ContentError, 'budget'):
            solve([['G', 'O'] * 2, ['O', 'G'] * 2, [], []], ['O', 'G', None, None], max_states=1)

    def test_authored_seed_is_reproducible_and_preserves_four_units(self):
        first = authored_board(4, 'moderate', 42)
        self.assertEqual(first, authored_board(4, 'moderate', 42))
        self.assertEqual(first[-2:], [[], []])
        self.assertEqual([len(b) for b in first], [4, 4, 4, 4, 0, 0])
        from collections import Counter
        self.assertEqual(Counter(c for b in first for c in b), {'O': 4, 'G': 4, 'P': 4, 'B': 4})


if __name__ == '__main__':
    unittest.main()
