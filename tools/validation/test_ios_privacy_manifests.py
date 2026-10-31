from pathlib import Path
import plistlib
import tempfile
import unittest

from build_version import BuildError
from ios_privacy_manifests import inspect_app


class PrivacyManifestTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.app = Path(self.temp.name) / 'Runner.app'
        self.app.mkdir()

    def manifest(self, directory, value, binary=False):
        folder = self.app / directory
        folder.mkdir(parents=True, exist_ok=True)
        if folder.suffix == '.bundle':
            (folder / 'Info.plist').write_bytes(plistlib.dumps({'CFBundlePackageType': 'BNDL'}))
        path = folder / 'PrivacyInfo.xcprivacy'
        path.write_bytes(plistlib.dumps(value, fmt=plistlib.FMT_BINARY if binary else plistlib.FMT_XML))
        return path

    def test_only_empty_api_key_in_known_resource_bundle_is_removed(self):
        value = {'NSPrivacyAccessedAPITypes': [], 'NSPrivacyTracking': False,
                 'NSPrivacyCollectedDataTypes': [], 'NSPrivacyTrackingDomains': []}
        path = self.manifest('nanopb_nanopb.bundle', value, binary=True)
        valid = self.manifest('Frameworks/Flutter.framework', {
            'NSPrivacyAccessedAPITypes': [{'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryFileTimestamp',
                                         'NSPrivacyAccessedAPITypeReasons': ['C617.1']}]})
        before = valid.read_bytes()
        with self.assertRaisesRegex(BuildError, 'empty_api_array'):
            inspect_app(self.app)
        result = inspect_app(self.app, repair=True)
        self.assertEqual(plistlib.loads(path.read_bytes()), {k: v for k, v in value.items() if k != 'NSPrivacyAccessedAPITypes'})
        self.assertTrue(path.read_bytes().startswith(b'bplist00'))
        self.assertEqual(valid.read_bytes(), before)
        self.assertEqual(len(result['changed']), 1)
        self.assertEqual(inspect_app(self.app)['changed'], [])
        self.assertEqual(inspect_app(self.app, repair=True)['changed'], [])

    def test_unknown_or_code_bundles_fail_before_any_write(self):
        for directory, mode in [('Other.bundle', ''), ('Frameworks/Other.framework', ''),
                                ('nanopb_nanopb.bundle', 'executable'),
                                ('nanopb_nanopb.bundle', 'signature')]:
            with self.subTest(directory=directory, mode=mode):
                good = self.manifest('Firebase_FirebaseInstallations.bundle', {'NSPrivacyAccessedAPITypes': []})
                bad = self.manifest(directory, {'NSPrivacyAccessedAPITypes': []})
                if mode == 'executable':
                    (bad.parent / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable': 'code'}))
                if mode == 'signature':
                    (bad.parent / '_CodeSignature').mkdir(exist_ok=True)
                before = good.read_bytes()
                with self.assertRaises(BuildError):
                    inspect_app(self.app, repair=True)
                self.assertEqual(good.read_bytes(), before)
                import shutil
                shutil.rmtree(bad.parent)

    def test_invalid_api_declaration_is_not_silently_erased(self):
        for value in [0, {}, ['bad'], [{'NSPrivacyAccessedAPIType': 'category',
                                         'NSPrivacyAccessedAPITypeReasons': []}]]:
            with self.subTest(value=value):
                path = self.manifest('nanopb_nanopb.bundle', {'NSPrivacyAccessedAPITypes': value})
                before = path.read_bytes()
                with self.assertRaises(BuildError):
                    inspect_app(self.app, repair=True)
                self.assertEqual(path.read_bytes(), before)

    def test_symlink_and_absent_manifest_rejected(self):
        with self.assertRaisesRegex(BuildError, 'no_privacy_manifests'):
            inspect_app(self.app)
        outside = Path(self.temp.name) / 'external.xcprivacy'
        outside.write_bytes(plistlib.dumps({'NSPrivacyAccessedAPITypes': []}))
        folder = self.app / 'nanopb_nanopb.bundle'
        folder.mkdir()
        (folder / 'PrivacyInfo.xcprivacy').symlink_to(outside)
        with self.assertRaisesRegex(BuildError, 'symlink'):
            inspect_app(self.app, repair=True)
        self.assertIn('NSPrivacyAccessedAPITypes', plistlib.loads(outside.read_bytes()))


if __name__ == '__main__':
    unittest.main()
