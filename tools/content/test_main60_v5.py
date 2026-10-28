from pathlib import Path
import tempfile
import unittest

from calibrate_main60_v5 import build_pack, expected_bytes, install, DESTINATIONS
from author_main60_v4 import output_bytes
from validate import ContentError


class CalibrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.previous, cls.pack = build_pack()

    def test_current_assets_and_candidate_copy_are_the_validated_pack(self):
        self.assertEqual(len(self.pack), 60)
        for directory in DESTINATIONS:
            for pid, puzzle in self.pack.items():
                self.assertEqual((directory / f'{pid}.json').read_bytes(),
                                 expected_bytes(pid, puzzle), pid)
                if puzzle['main_level'] <= 20:
                    self.assertEqual(puzzle, self.previous[pid])

    def test_unknown_last_file_prevents_any_install_and_reinstall_is_safe(self):
        with tempfile.TemporaryDirectory() as temporary:
            directories = [Path(temporary) / 'app', Path(temporary) / 'candidate']
            for directory in directories:
                directory.mkdir()
                for pid, puzzle in self.previous.items():
                    (directory / f'{pid}.json').write_bytes(output_bytes(pid, puzzle))
            (directories[1] / 'main-060.json').write_text('{}')
            with self.assertRaisesRegex(ContentError, 'unknown content edit'):
                install(self.previous, self.pack, directories)
            self.assertEqual((directories[0] / 'main-021.json').read_bytes(),
                             output_bytes('main-021', self.previous['main-021']))
            (directories[1] / 'main-060.json').write_bytes(output_bytes('main-060', self.previous['main-060']))
            install(self.previous, self.pack, directories)
            install(self.previous, self.pack, directories)
            self.assertEqual((directories[0] / 'main-060.json').read_bytes(),
                             expected_bytes('main-060', self.pack['main-060']))


if __name__ == '__main__':
    unittest.main()
