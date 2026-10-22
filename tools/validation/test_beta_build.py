import tempfile
import unittest
from pathlib import Path
from beta_build import BuildError, prepare_output, read_version


class CandidateSafetyTest(unittest.TestCase):
    def test_existing_candidate_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / 'build/beta/ios'
            path.mkdir(parents=True)
            (path / 'previous.aab').write_bytes(b'frozen')
            with self.assertRaises(BuildError):
                prepare_output(root, path)
            self.assertEqual((path / 'previous.aab').read_bytes(), b'frozen')

    def test_output_must_stay_inside_ignored_build_tree(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for path in [root / 'app', root / 'docs/evidence', root / 'build/../app']:
                with self.subTest(path=path), self.assertRaises(BuildError):
                    prepare_output(root, path)
            (root / 'build').mkdir(exist_ok=True)
            (root / 'build/escape').symlink_to(root / 'docs')
            with self.assertRaises(BuildError):
                prepare_output(root, root / 'build/escape/candidate')
            self.assertFalse((root / 'docs').exists())

    def test_rejects_missing_or_invalid_build_version(self):
        for source in ['version: 0.5.0', 'version: 0.5.0+0', 'version: 0.5.0+9999999999', 'version: 0.5.0+5\nversion: 0.5.0+6']:
            with self.subTest(source=source), self.assertRaises(BuildError):
                read_version(source)
        self.assertEqual(read_version('name: app\nversion: 0.5.0+5\n'), ('0.5.0', 5))


if __name__ == '__main__':
    unittest.main()
