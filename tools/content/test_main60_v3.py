"""Player-facing curve guards: solve actual bundled boards, not reference lengths."""
from pathlib import Path
import unittest

from validate import read_json
from measure_levels import bounded_search

ROOT = Path(__file__).resolve().parents[2]


class Main60V3Tests(unittest.TestCase):
    def test_level13_does_not_outstrip_later_chapter_finales(self):
        p = read_json(ROOT / 'app/assets/puzzles/main/main-013.json')
        result = bounded_search(p['initial_bottom_to_top'], p['target_labels'], 15)
        self.assertEqual(result['status'], 'found')
        self.assertGreaterEqual(result['shortest_within_bound'], 14)

    def test_challenge_and_finale_floors_use_real_maximal_pours(self):
        for n, floor in [(20, 16), (21, 15), (28, 16), (32, 15), (35, 16),
                         (40, 17), (41, 16), (44, 17), (48, 17),
                         (51, 17), (55, 17), (58, 18), (59, 16), (60, 18)]:
            with self.subTest(level=n):
                p = read_json(ROOT / f'app/assets/puzzles/main/main-{n:03}.json')
                result = bounded_search(p['initial_bottom_to_top'], p['target_labels'], floor-1)
                self.assertEqual(result['status'], 'excluded', result)


if __name__ == '__main__':
    unittest.main()
