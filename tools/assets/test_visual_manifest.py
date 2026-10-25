"""Mutations are confined to temporary copies; production PNGs are read only."""

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from PIL import Image

import visual_manifest as vm

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE = Path("docs/design/production-candidates/runtime")


class VisualManifestTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        # Copy only the verification inputs, never a checkout or external images.
        for relative in [CANDIDATE, Path("app/assets/art"), Path("docs/design/original/Pourlune_Design_Pack/boards")]:
            shutil.copytree(ROOT / relative, self.root / relative)
        for relative in ["app/lib/presentation/bottle.dart", "app/lib/presentation/scene_art.dart"]:
            self.copy(relative)
        for name in ["root-generated-assets.json", "image-prompts-base.json", "garden-generation.json", "seaside-generation.json", "bottle-generation.json"]:
            self.copy("docs/development/evidence/B03/" + name)

    def copy(self, relative):
        target = self.root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / relative, target)

    def pair(self, relative, data):
        (self.root / CANDIDATE / relative).write_bytes(data)
        (self.root / "app/assets/art" / relative).write_bytes(data)

    def baseline(self):
        manifest = vm.build_manifest(self.root)
        (self.root / CANDIDATE / "manifest.json").write_text(json.dumps(manifest))
        return manifest

    def test_inventory_covers_23_unique_ids_and_22_exact_runtime_copies(self):
        result = self.baseline()
        self.assertEqual(len(result["assets"]), 23)
        self.assertEqual(len({e["id"] for e in result["assets"]}), 23)
        self.assertEqual(sum(e["runtime_path"] is not None for e in result["assets"]), 22)
        vm.check_manifest(self.root)

    def test_missing_expected_png_is_rejected(self):
        (self.root / CANDIDATE / "scenes/garden_nook/piece-1.png").unlink()
        with self.assertRaisesRegex(ValueError, "inventory"):
            vm.build_manifest(self.root)

    def test_unexpected_png_is_rejected(self):
        shutil.copyfile(self.root / CANDIDATE / "scenes/garden_nook/piece-1.png", self.root / CANDIDATE / "accidental.png")
        with self.assertRaisesRegex(ValueError, "inventory"):
            vm.build_manifest(self.root)

    def test_runtime_copy_drift_is_rejected(self):
        path = self.root / "app/assets/art/scenes/garden_nook/piece-1.png"
        path.write_bytes(path.read_bytes() + b"changed")
        with self.assertRaisesRegex(ValueError, "runtime copy"):
            vm.build_manifest(self.root)

    def test_changed_valid_png_bytes_cannot_silently_rebaseline_check(self):
        self.baseline()
        relative = "scenes/garden_nook/piece-1.png"
        data = (self.root / CANDIDATE / relative).read_bytes()
        self.pair(relative, data + b"changed PNG bytes")
        with self.assertRaisesRegex(ValueError, "manifest drift"):
            vm.check_manifest(self.root)

    def test_wrong_dimensions_are_rejected_even_before_baseline(self):
        relative = "scenes/garden_nook/piece-1.png"
        path = self.root / CANDIDATE / relative
        with Image.open(path) as image:
            image.resize((32, 32)).save(path)
        self.pair(relative, path.read_bytes())
        with self.assertRaisesRegex(ValueError, "dimensions"):
            vm.build_manifest(self.root)

    def test_accidental_duplicate_content_is_rejected(self):
        data = (self.root / CANDIDATE / "scenes/garden_nook/piece-1.png").read_bytes()
        self.pair("scenes/garden_nook/piece-2.png", data)
        with self.assertRaisesRegex(ValueError, "duplicate content"):
            vm.build_manifest(self.root)

    def test_flattened_transparency_is_rejected(self):
        relative = "scenes/garden_nook/piece-1.png"
        path = self.root / CANDIDATE / relative
        with Image.open(path) as image:
            image.convert("RGB").save(path)
        self.pair(relative, path.read_bytes())
        with self.assertRaisesRegex(ValueError, "RGBA"):
            vm.build_manifest(self.root)

    def test_opaque_front_window_pixel_is_rejected(self):
        relative = "bottles/front.png"
        path = self.root / CANDIDATE / relative
        with Image.open(path) as image:
            image.putpixel((image.width // 2, image.height // 2), (255, 255, 255, 255))
            image.save(path)
        self.pair(relative, path.read_bytes())
        with self.assertRaisesRegex(ValueError, "front window"):
            vm.build_manifest(self.root)

    def test_geometry_change_requires_explicit_manifest_refresh(self):
        self.baseline()
        path = self.root / "app/lib/presentation/bottle.dart"
        path.write_bytes(path.read_bytes() + b"\n// changed calibration\n")
        with self.assertRaisesRegex(ValueError, "manifest drift"):
            vm.check_manifest(self.root)


if __name__ == "__main__":
    unittest.main()
