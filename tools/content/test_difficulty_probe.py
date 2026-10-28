import unittest
from difficulty_probe import state_key, probe
from validate import pour, is_won


class DifficultyProbeTests(unittest.TestCase):
    def test_only_unlabeled_buffers_are_interchangeable(self):
        labels = ['O', 'G', None, None]
        self.assertEqual(state_key(('OG', 'GO', 'O', ''), labels),
                         state_key(('OG', 'GO', '', 'O'), labels))
        self.assertNotEqual(state_key(('OG', 'GO', '', ''), labels),
                            state_key(('GO', 'OG', '', ''), labels))

    def test_recorded_actions_are_real_and_budget_is_not_unsolvability(self):
        initial = [list('OOGG'), list('GGOO'), [], []]
        for prefer_target in [False, True]:
            for extra in [False, True]:
                row = probe(initial, ['O', 'G', None, None], 71,
                            prefer_target=prefer_target, extra=extra)
                board = initial + ([[]] if extra else [])
                labels = ['O', 'G', None, None] + ([None] if extra else [])
                for move in row['moves']:
                    board, _, _ = pour(board, move['from_index'], move['to_index'])
                self.assertEqual(row['board'], [''.join(b) for b in board])
                self.assertTrue(is_won(board, labels))
                self.assertEqual(row['status'], 'win')
        row = probe(initial, ['O', 'G', None, None], 71, budget=1)
        self.assertEqual(row['status'], 'budget')
        self.assertEqual(len(row['moves']), 1)


if __name__ == '__main__':
    unittest.main()
