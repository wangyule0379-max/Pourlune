"""Exercise asset safety checks against temporary inputs, never production PNGs."""

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from PIL import Image

import ui_manifest as ui

ROOT = Path(__file__).resolve().parents[2]


class UiManifestTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for relative in [ui.CANDIDATE, ui.RUNTIME, ui.BOARDS]:
            shutil.copytree(ROOT / relative, self.root / relative)
        for relative in [ui.GEOMETRY, ui.CROPS, *ui.RECORDS]:
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, destination)
        for name in ['cream', 'green', 'patch']:
            relative = Path('docs/design/ui-addendum/assets') / (name + '.png')
            shutil.copyfile(ROOT / relative, self.root / relative)

    def baseline(self):
        manifest = ui.build_manifest(self.root)
        (self.root / ui.CANDIDATE / 'manifest.json').write_text(json.dumps(manifest))
        return manifest

    def pair(self, name, data):
        for relative in [ui.CANDIDATE, ui.RUNTIME]:
            (self.root / relative / name).write_bytes(data)

    def test_exact_ten_copies_keep_rights_and_runtime_geometry_explicit(self):
        result = self.baseline()
        self.assertEqual(len(result['assets']), 10)
        self.assertEqual(len({item['sha256'] for item in result['assets']}), 10)
        self.assertTrue(all(item['candidate_appcopy_identical'] for item in result['assets']))
        self.assertTrue(all(item['rights_status'] == 'UNCONFIRMED' for item in result['assets']))
        assets = {item['id']: item for item in result['assets']}
        self.assertEqual(assets['moon']['runtime_geometry']['crop_xyxy'], [319, 208, 1135, 1043])
        self.assertEqual(assets['cream-tile']['provenance']['source_crop_xywh'], [1080, 360, 60, 35])
        ui.check_manifest(self.root)

    def test_missing_candidate_is_rejected(self):
        (self.root / ui.CANDIDATE / 'moon.png').unlink()
        with self.assertRaisesRegex(ValueError, 'inventory'):
            ui.build_manifest(self.root)

    def test_untracked_runtime_png_is_rejected(self):
        shutil.copyfile(self.root / ui.RUNTIME / 'moon.png', self.root / ui.RUNTIME / 'extra.png')
        with self.assertRaisesRegex(ValueError, 'inventory'):
            ui.build_manifest(self.root)

    def test_untracked_candidate_png_is_rejected(self):
        shutil.copyfile(self.root / ui.CANDIDATE / 'moon.png', self.root / ui.CANDIDATE / 'extra.png')
        with self.assertRaisesRegex(ValueError, 'inventory'):
            ui.build_manifest(self.root)

    def test_runtime_copy_drift_is_rejected(self):
        path = self.root / ui.RUNTIME / 'moon.png'
        path.write_bytes(path.read_bytes() + b'drift')
        with self.assertRaisesRegex(ValueError, 'copy differs'):
            ui.build_manifest(self.root)

    def test_paired_replacement_cannot_rebaseline_existing_manifest(self):
        self.baseline()
        path = self.root / ui.CANDIDATE / 'cream-tile.png'
        self.pair('cream-tile.png', path.read_bytes() + b'changed')
        with self.assertRaises(ValueError):
            ui.check_manifest(self.root)

    def test_wrong_dimensions_rejected_before_refresh(self):
        path = self.root / ui.CANDIDATE / 'moon.png'
        with Image.open(path) as image:
            image.resize((32, 32)).save(path)
        self.pair('moon.png', path.read_bytes())
        with self.assertRaisesRegex(ValueError, 'dimensions'):
            ui.build_manifest(self.root)

    def test_flattened_generated_transparency_rejected(self):
        path = self.root / ui.CANDIDATE / 'moon.png'
        with Image.open(path) as image:
            image.convert('RGB').save(path)
        self.pair('moon.png', path.read_bytes())
        with self.assertRaisesRegex(ValueError, 'mode'):
            ui.build_manifest(self.root)

    def test_generation_digest_must_match_selected_png(self):
        path = self.root / ui.EVIDENCE / 'root-ui-assets.json'
        records = json.loads(path.read_text())
        records[0]['sha256'] = '0' * 64
        path.write_text(json.dumps(records))
        with self.assertRaisesRegex(ValueError, 'provenance digest'):
            ui.build_manifest(self.root)

    def test_generation_prompt_cannot_be_missing(self):
        path = self.root / ui.EVIDENCE / 'calendar-generation.json'
        record = json.loads(path.read_text())
        record['prompt'] = ''
        path.write_text(json.dumps(record))
        with self.assertRaisesRegex(ValueError, 'prompt'):
            ui.build_manifest(self.root)

    def test_runtime_crop_cannot_extend_beyond_canvas(self):
        path = self.root / ui.GEOMETRY
        path.write_text(path.read_text().replace('319, 208, 1135, 1043', '319, 208, 9999, 1043'))
        with self.assertRaisesRegex(ValueError, 'crop bounds'):
            ui.build_manifest(self.root)

    def test_original_texture_pixels_are_checked_against_source_crop(self):
        path = self.root / ui.BOARDS / '02_Tutorial_Play_Pause.png'
        with Image.open(path) as image:
            image = image.convert('RGB')
            image.putpixel((1080, 360), (0, 0, 0))
            image.save(path)
        # Let reference hashing pass so this test reaches the crop-pixel check.
        record_path = self.root / ui.EVIDENCE / 'cream-generation.json'
        record = json.loads(record_path.read_text())
        record['references'][0]['sha256'] = ui.sha(path)
        record_path.write_text(json.dumps(record))
        with self.assertRaisesRegex(ValueError, 'source crop pixels'):
            ui.build_manifest(self.root)

    def test_geometry_change_requires_explicit_refresh(self):
        self.baseline()
        path = self.root / ui.GEOMETRY
        path.write_text(path.read_text().replace('319, 208, 1135, 1043', '320, 208, 1135, 1043'))
        with self.assertRaisesRegex(ValueError, 'manifest drift'):
            ui.check_manifest(self.root)


if __name__ == '__main__':
    unittest.main()
