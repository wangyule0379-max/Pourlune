"""Release checks catch renamed/rotated copies and asset drift."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

import validate

ROOT = Path(__file__).resolve().parents[2]


class ProductionTests(unittest.TestCase):
    def setUp(self):
        self.p = json.loads((ROOT / 'docs/content/fixtures/main-001.reference.json').read_text())

    def test_repetition_audit_catches_color_and_bottle_permutation(self):
        other = copy.deepcopy(self.p)
        other['puzzle_id'] = 'main-002'
        other['main_level'] = 2
        other['initial_bottom_to_top'] = [['G', 'G', 'O', 'O'], [], ['O', 'O', 'G', 'G'], []]
        other['target_labels'] = ['O', None, 'G', None]
        # Swap colors globally and move whole labeled bottle pairs together.
        color = {'O': 'G', 'G': 'O'}
        other['initial_bottom_to_top'] = [[color[c] for c in b] for b in other['initial_bottom_to_top']]
        other['target_labels'] = [color.get(c) for c in other['target_labels']]
        audit = validate.repetition_audit([self.p, other])
        self.assertEqual(audit['equivalent_groups'], [['main-001', 'main-002']])
        self.assertEqual(audit['exact_groups'], [])

    def test_repetition_audit_keeps_different_target_assignment_distinct(self):
        other = copy.deepcopy(self.p)
        other['puzzle_id'] = 'main-002'
        other['initial_bottom_to_top'] = [['O', 'O', 'O', 'G'], ['G', 'G', 'G', 'O'], [], []]
        self.assertEqual(validate.repetition_audit([self.p, other])['equivalent_groups'], [])

    def test_liquid_structure_audit_also_exposes_target_only_variants(self):
        self.p['initial_bottom_to_top'] = [['O', 'O', 'O', 'G'], ['O', 'G', 'G', 'G'], [], []]
        other = copy.deepcopy(self.p)
        other['puzzle_id'] = 'main-002'
        other['target_labels'] = ['G', 'O', None, None]
        audit = validate.repetition_audit([self.p, other])
        self.assertEqual(audit['equivalent_groups'], [])
        self.assertEqual(audit['liquid_structure_groups'], [['main-001', 'main-002']])

    def test_packaging_check_rejects_missing_extra_and_changed_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, target = root / 'source', root / 'target'
            source.mkdir(); target.mkdir()
            (source / 'one.json').write_text('{"a":1}\n')
            with self.assertRaises(validate.ContentError):
                validate.verify_packaging(source, target)
            (target / 'one.json').write_text('{"a":1}\n')
            self.assertEqual(validate.verify_packaging(source, target)['count'], 1)
            (target / 'one.json').write_text('{"a":2}\n')
            with self.assertRaises(validate.ContentError):
                validate.verify_packaging(source, target)
            (target / 'one.json').write_bytes((source / 'one.json').read_bytes())
            (target / 'extra.json').write_text('{}')
            with self.assertRaises(validate.ContentError):
                validate.verify_packaging(source, target)

    def test_release_rejects_equivalent_renamed_candidates(self):
        with tempfile.TemporaryDirectory() as directory:
            import subprocess, sys
            paths = []
            for level in [1, 2]:
                p = copy.deepcopy(self.p)
                p.update(puzzle_id=f'main-{level:03}', main_level=level,
                         content_status='production_candidate')
                path = Path(directory) / f'{level}.json'
                path.write_text(json.dumps(p)); paths.append(str(path))
            result = subprocess.run([sys.executable, str(ROOT / 'tools/content/validate.py'),
                                     '--release', *paths], text=True, capture_output=True)
            self.assertIn('equivalent duplicate', ' '.join(json.loads(result.stdout)['errors']))


if __name__ == '__main__':
    unittest.main()
