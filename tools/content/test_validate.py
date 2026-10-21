"""Behavior checks for the preparation tool, not the future Dart core."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from validate import ContentError, daily_id, is_won, pour, validate_catalog, validate_puzzle

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'docs/content/fixtures/main-012.reference.json'


class RuleTests(unittest.TestCase):
    def test_capacity_limits_contiguous_pour_without_mutating_input(self):
        board = [['G', 'O', 'O', 'O'], ['O', 'O'], [], []]
        result, color, units = pour(board, 0, 1)
        self.assertEqual(result, [['G', 'O'], ['O'] * 4, [], []])
        self.assertEqual((color, units), ('O', 2))
        self.assertEqual(board[0], ['G', 'O', 'O', 'O'])

    def test_pour_stops_at_different_color_in_source(self):
        result, _, units = pour([['O', 'G', 'O'], [], [], []], 0, 1)
        self.assertEqual(result, [['O', 'G'], ['O'], [], []])
        self.assertEqual(units, 1)

    def test_rejects_illegal_moves(self):
        cases = [([['O'], [], [], []], 0, 0),
                 ([['O'], ['G'], [], []], 0, 1),
                 ([['O'], ['O'] * 4, [], []], 0, 1),
                 ([[], [], [], []], 0, 1),
                 ([['O'], [], [], []], -1, 1),
                 ([['O'], [], [], []], 0, 4)]
        for board, source, target in cases:
            with self.subTest(source=source, target=target, board=board):
                with self.assertRaises(ContentError):
                    pour(board, source, target)

    def test_labels_and_empty_buffers_are_required_for_win(self):
        labels = ['O', 'G', None, None]
        self.assertTrue(is_won([['O'] * 4, ['G'] * 4, [], []], labels))
        self.assertFalse(is_won([['G'] * 4, ['O'] * 4, [], []], labels))
        self.assertFalse(is_won([['O'] * 4, ['G'] * 4, ['P'], []], labels))
        self.assertFalse(is_won([['O'] * 3, ['G'] * 4, [], []], labels))


class PuzzleTests(unittest.TestCase):
    def setUp(self):
        self.puzzle = json.loads(FIXTURE.read_text())

    def test_original_level_12_all_step_snapshots_and_final_targets(self):
        original = json.loads((ROOT / self.puzzle['source_reference']).read_text())
        board = self.puzzle['initial_bottom_to_top']
        for move in original['moves']:
            board, color, units = pour(board, move['from_bottle'] - 1, move['to_bottle'] - 1)
            self.assertEqual((color, units), (move['color'], move['units']))
            self.assertEqual(board, move['board_after_bottom_to_top'])
        result = validate_puzzle(self.puzzle)
        self.assertEqual(result['move_count'], 15)
        self.assertEqual(result['final_board'], [['O']*4, ['G']*4, ['P']*4, ['B']*4, [], []])

    def test_schema_rejects_unknown_fields_types_versions_and_empty_moves(self):
        for field, value in [('surprise', 1), ('capacity', True), ('schema_version', 2),
                             ('main_level', None), ('reference_moves', []),
                             ('difficulty_intent', '')]:
            bad = copy.deepcopy(self.puzzle)
            bad[field] = value
            with self.subTest(field=field), self.assertRaises(ContentError):
                validate_puzzle(bad)

    def test_cross_field_corruption_is_rejected(self):
        cases = []
        bad = copy.deepcopy(self.puzzle); bad['main_level'] = 13; cases.append(bad)
        bad = copy.deepcopy(self.puzzle); bad['target_labels'][0] = 'G'; cases.append(bad)
        bad = copy.deepcopy(self.puzzle); bad['initial_bottom_to_top'][0][0] = 'O'; cases.append(bad)
        bad = copy.deepcopy(self.puzzle); bad['initial_bottom_to_top'][4] = bad['initial_bottom_to_top'][0]; bad['initial_bottom_to_top'][0] = []; cases.append(bad)
        bad = copy.deepcopy(self.puzzle); bad['target_labels'].pop(); cases.append(bad)
        for bad in cases:
            with self.subTest(bad=bad), self.assertRaises(ContentError):
                validate_puzzle(bad)

    def test_incomplete_solution_and_moves_after_win_are_rejected(self):
        self.puzzle['reference_moves'].pop()
        with self.assertRaises(ContentError):
            validate_puzzle(self.puzzle)
        self.setUp()
        self.puzzle['reference_moves'].append({'from_index': 0, 'to_index': 4})
        with self.assertRaises(ContentError):
            validate_puzzle(self.puzzle)

    def test_initially_solved_puzzle_is_not_playable_content(self):
        self.puzzle['initial_bottom_to_top'] = [['O']*4, ['G']*4, ['P']*4, ['B']*4, [], []]
        with self.assertRaises(ContentError):
            validate_puzzle(self.puzzle)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.ids = [f'daily-{i:03}' for i in range(30)]
        self.catalog = {'schema_version': 1, 'catalog_version': 1,
                        'epoch_date': '2026-01-01', 'puzzle_ids': self.ids}
        self.known = {pid: {'mode': 'daily'} for pid in self.ids}

    def test_catalog_accepts_resolved_daily_ids(self):
        validate_catalog(self.catalog, self.known)

    def test_date_mapping_wraps_across_year_and_before_epoch(self):
        for date, expected in [('2026-01-01', 'daily-000'), ('2026-01-30', 'daily-029'),
                               ('2026-01-31', 'daily-000'), ('2025-12-31', 'daily-029')]:
            self.assertEqual(daily_id(self.catalog, date), expected)

    def test_leap_day_uses_calendar_days(self):
        self.catalog['epoch_date'] = '2024-02-28'
        self.assertEqual(daily_id(self.catalog, '2024-03-01'), 'daily-002')

    def test_short_duplicate_unknown_wrong_mode_and_invalid_date_catalogs_fail(self):
        cases = []
        bad = copy.deepcopy(self.catalog); bad['puzzle_ids'].pop(); cases.append(bad)
        bad = copy.deepcopy(self.catalog); bad['puzzle_ids'][1] = self.ids[0]; cases.append(bad)
        bad = copy.deepcopy(self.catalog); bad['puzzle_ids'][1] = 'daily-missing'; cases.append(bad)
        bad = copy.deepcopy(self.catalog); bad['epoch_date'] = '2026-02-30'; cases.append(bad)
        for bad in cases:
            with self.subTest(bad=bad), self.assertRaises(ContentError):
                validate_catalog(bad, self.known)
        self.known[self.ids[0]]['mode'] = 'main'
        with self.assertRaises(ContentError):
            validate_catalog(self.catalog, self.known)


class CommandTests(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run([sys.executable, str(ROOT / 'tools/content/validate.py'), *map(str, args)],
                              text=True, capture_output=True)

    def test_fixture_passes_with_machine_readable_evidence(self):
        result = self.run_cli(FIXTURE)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertTrue(report['ok'])
        self.assertEqual(report['checked'][0]['move_count'], 15)
        self.assertEqual(len(report['checked'][0]['sha256']), 64)
        self.assertFalse(report['release_gate'])

    def test_empty_input_invalid_json_missing_file_and_duplicate_ids_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            bad = Path(directory) / 'broken.json'; bad.write_text('{oops')
            repeated = Path(directory) / 'repeated-key.json'
            repeated.write_text('{"schema_version": 1, "schema_version": 2}')
            for args in [[], [bad], [repeated], [Path(directory)/'missing.json'], [FIXTURE, FIXTURE]]:
                with self.subTest(args=args):
                    self.assertNotEqual(self.run_cli(*args).returncode, 0)

    def test_release_mode_rejects_reference_fixture_incomplete_main_and_missing_catalog(self):
        result = self.run_cli('--release', FIXTURE)
        self.assertEqual(result.returncode, 1)
        errors = ' '.join(json.loads(result.stdout)['errors'])
        for expected in ['main', 'catalog', 'production_candidate']:
            self.assertIn(expected, errors)

    def test_fractional_numeric_tokens_cannot_round_into_accepted_versions(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fractional.json'
            for token in ['1.00000000000000001', '0.99999999999999999', '1e0']:
                path.write_text(FIXTURE.read_text().replace('"schema_version": 1,', f'"schema_version": {token},'))
                with self.subTest(token=token):
                    self.assertNotEqual(self.run_cli(path).returncode, 0)

    def test_report_cannot_replace_input_via_direct_symlink_or_hardlink_alias(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'puzzle.json'
            content = FIXTURE.read_bytes()
            source.write_bytes(content)
            symlink = Path(directory) / 'symbolic.json'; symlink.symlink_to(source)
            hardlink = Path(directory) / 'hard.json'; hardlink.hardlink_to(source)
            for report in [source, symlink, hardlink]:
                source.write_bytes(content)
                with self.subTest(report=report):
                    result = self.run_cli(source, '--report', report)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(source.read_bytes(), content)

    def test_report_cannot_replace_catalog_even_when_catalog_invalid(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'catalog.json'; path.write_text('{}')
            self.assertNotEqual(self.run_cli(FIXTURE, '--catalog', path, '--report', path).returncode, 0)
            self.assertEqual(path.read_text(), '{}')


if __name__ == '__main__':
    unittest.main()
