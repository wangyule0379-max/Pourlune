"""Five-color content contract and real schema/reference replay boundaries."""
from copy import deepcopy
import unittest

from validate import ContentError, validate_puzzle


def five_color_definition():
    return {
        'schema_version': 1, 'puzzle_id': 'main-021', 'content_version': 4,
        'mode': 'main', 'content_status': 'production_candidate', 'main_level': 21,
        'capacity': 4,
        'initial_bottom_to_top': [list(s) for s in ['OORR', 'GGOO', 'PPGG', 'BBPP', 'RRBB', '', '']],
        'target_labels': ['O', 'G', 'P', 'B', 'R', None, None],
        'reference_moves': [{'from_index': a, 'to_index': b} for a, b in
                            [(0, 5), (1, 0), (2, 1), (3, 2), (4, 3), (5, 4)]],
        'difficulty_intent': 'Independent five-color validation fixture, not authored difficulty.',
    }


class FiveColorTest(unittest.TestCase):
    def test_five_targets_and_seven_initial_bottles_finish_without_extra(self):
        result = validate_puzzle(five_color_definition())
        self.assertEqual(result['move_count'], 6)
        self.assertEqual(result['final_board'], [list(c * 4) for c in 'OGPBR'] + [[], []])

    def test_unknown_sixth_color_extra_initial_buffer_and_corrupt_quantities_fail(self):
        for change in ['unknown', 'sixth', 'extra', 'quantity', 'target', 'index']:
            p = deepcopy(five_color_definition())
            if change == 'unknown': p['initial_bottom_to_top'][0][0] = 'Y'
            if change == 'sixth':
                p['initial_bottom_to_top'].insert(5, ['Y'] * 4)
                p['target_labels'].insert(5, 'Y')
            if change == 'extra':
                p['initial_bottom_to_top'].append([])
                p['target_labels'].append(None)
            if change == 'quantity': p['initial_bottom_to_top'][0][0] = 'R'
            if change == 'target': p['target_labels'][4] = 'O'
            if change == 'index': p['reference_moves'][0]['to_index'] = 7
            with self.subTest(change=change), self.assertRaises(ContentError):
                validate_puzzle(p)


if __name__ == '__main__':
    unittest.main()
