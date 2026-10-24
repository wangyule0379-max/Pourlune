import tempfile
import unittest
import contextlib
import io
import json
import sys
import subprocess
import zipfile
import hashlib
import plistlib
from unittest.mock import patch
import beta_build
from pathlib import Path
from beta_build import BuildError, prepare_output, read_version


class CandidateSafetyTest(unittest.TestCase):
    def test_packaged_native_test_plugin_is_rejected_before_candidate_manifest(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); (root / 'app').mkdir()
            (root / 'app/pubspec.yaml').write_text('version: 0.5.0+10\n')
            output = root / 'build/test-ios'
            def build(args, **kwargs):
                app = root / 'app/build/ios/iphoneos/Runner.app'; app.mkdir(parents=True)
                (app / 'Runner').write_bytes(b'actual-file-boundary: IntegrationTestPlugin')
                (app / 'Info.plist').write_bytes(plistlib.dumps({
                    'CFBundleIdentifier': 'com.pourlune.app', 'CFBundleDisplayName': 'Pourlune',
                    'CFBundleShortVersionString': '0.5.0', 'CFBundleVersion': '10',
                    'GADApplicationIdentifier': 'ca-app-pub-3940256099942544~1458002511'}))
                return subprocess.CompletedProcess(args, 0)
            error = io.StringIO()
            with patch.object(beta_build, 'ROOT', root), patch.object(beta_build, 'sources', return_value={}), \
                 patch('beta_build.subprocess.run', side_effect=build), \
                 patch.object(sys, 'argv', ['beta_build.py', '--platform', 'ios', '--output', str(output)]), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(error):
                self.assertEqual(beta_build.main(), 1)
            self.assertEqual(json.loads(error.getvalue())['code'], 'ios_native_test_plugin_packaged')
            self.assertFalse((output / 'candidate.json').exists())

    def test_ios_candidate_rejects_packaged_native_ad_app_id_different_from_selection(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); (root / 'app').mkdir()
            (root / 'app/pubspec.yaml').write_text('version: 0.5.0+8\n')
            output = root / 'build/test-ios'
            def build(args, **kwargs):
                if args[0] == sys.executable:
                    app = root / 'app/build/ios/iphoneos/Runner.app'; app.mkdir(parents=True)
                    (app / 'Info.plist').write_bytes(plistlib.dumps({
                        'CFBundleIdentifier': 'com.pourlune.app', 'CFBundleDisplayName': 'Pourlune',
                        'CFBundleShortVersionString': '0.5.0', 'CFBundleVersion': '8',
                        'GADApplicationIdentifier': 'ca-app-pub-3940256099942544~3347511713'}))
                    return subprocess.CompletedProcess(args, 0)
                return subprocess.CompletedProcess(args, 1, '', '')
            error = io.StringIO()
            with patch.object(beta_build, 'ROOT', root), patch.object(beta_build, 'sources', return_value={}), \
                 patch('beta_build.subprocess.run', side_effect=build), \
                 patch('beta_build.subprocess.check_output', return_value='fixture-head\n'), \
                 patch.object(sys, 'argv', ['beta_build.py', '--platform', 'ios', '--output', str(output),
                                          '--ad-mode', 'test']), contextlib.redirect_stdout(io.StringIO()), \
                 contextlib.redirect_stderr(error):
                self.assertEqual(beta_build.main(), 1)
            self.assertEqual(json.loads(error.getvalue())['code'], 'ios_ad_app_id_mismatch')
            self.assertFalse((output / 'candidate.json').exists())

    def test_registration_is_frozen_before_delegated_build_and_matches_packaged_app(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); (root / 'app').mkdir()
            (root / 'app/pubspec.yaml').write_text('version: 0.5.0+8\n')
            registration = root / 'outside-registration.json'
            data = {'schema': 1, 'apps': {'android': {'native_id': 'com.pourlune.app',
                    'app_id': 'ca-app-pub-1111111111111111~1111111111'}}}
            registration.write_text(json.dumps(data)); original = registration.read_bytes()
            output = root / 'build/test-ads'; compiled = {}
            def build(args, **kwargs):
                if args[0] == sys.executable:
                    data['apps']['android']['app_id'] = 'ca-app-pub-1111111111111111~2222222222'
                    registration.write_text(json.dumps(data))
                    selected = Path(args[args.index('--admob-registration') + 1])
                    compiled['app_id'] = json.loads(selected.read_text())['apps']['android']['app_id']
                    artifact = root / 'app/build/app/outputs/bundle/release/app-release.aab'
                    artifact.parent.mkdir(parents=True)
                    with zipfile.ZipFile(artifact, 'w') as z:
                        z.writestr('base/fixture-app-id.txt', compiled['app_id'])
                    return subprocess.CompletedProcess(args, 0)
                return subprocess.CompletedProcess(args, 0, 'jar is unsigned.', '')
            with patch.object(beta_build, 'ROOT', root), patch.object(beta_build, 'sources', return_value={}), \
                 patch('beta_build.subprocess.run', side_effect=build), \
                 patch('beta_build.subprocess.check_output', return_value='fixture-head\n'), \
                 patch.object(sys, 'argv', ['beta_build.py', '--platform', 'android', '--output', str(output),
                                          '--ad-mode', 'test', '--admob-registration', str(registration)]), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(beta_build.main(), 0)
            candidate = json.loads((output / 'candidate.json').read_text())
            self.assertEqual(compiled['app_id'], candidate['ad_configuration']['app_id'])
            self.assertEqual(candidate['ad_configuration']['registration_sha256'], hashlib.sha256(original).hexdigest())
            with zipfile.ZipFile(candidate['artifact']) as package:
                self.assertEqual(package.read('base/fixture-app-id.txt').decode(),
                                 candidate['ad_configuration']['app_id'])
            frozen = output / 'admob-registration.json'
            self.assertEqual(frozen.read_bytes(), original)
            self.assertEqual(candidate['files_sha256'][frozen.name], hashlib.sha256(original).hexdigest())

    def test_explicit_test_candidate_records_sample_app_without_claiming_owned_registration(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); (root / 'app').mkdir()
            (root / 'app/pubspec.yaml').write_text('version: 0.5.0+8\n')
            output = root / 'build/test-ads'
            def build(args, **kwargs):
                if args[0] == sys.executable:
                    self.assertIn('--ad-mode', args)
                    self.assertEqual(args[args.index('--ad-mode') + 1], 'test')
                    artifact = root / 'app/build/app/outputs/bundle/release/app-release.aab'
                    artifact.parent.mkdir(parents=True)
                    with zipfile.ZipFile(artifact, 'w') as z:
                        z.writestr('base/assets/puzzle.json', b'payload fixture')
                return subprocess.CompletedProcess(args, 0, 'jar is unsigned.', '')
            with patch.object(beta_build, 'ROOT', root), patch.object(beta_build, 'sources', return_value={}), \
                 patch('beta_build.subprocess.run', side_effect=build), \
                 patch('beta_build.subprocess.check_output', return_value='fixture-head\n'), \
                 patch.object(sys, 'argv', ['beta_build.py', '--platform', 'android', '--output', str(output),
                                          '--ad-mode', 'test']), contextlib.redirect_stdout(io.StringIO()), \
                 contextlib.redirect_stderr(io.StringIO()):
                try:
                    code = beta_build.main()
                except SystemExit as error:
                    code = error.code
                self.assertEqual(code, 0)
            candidate = json.loads((output / 'candidate.json').read_text())
            self.assertEqual(candidate['ads'], 'test')
            self.assertEqual(candidate['ad_configuration']['app_id'],
                             'ca-app-pub-3940256099942544~3347511713')
            self.assertFalse(candidate['ad_configuration']['owned_registration_verified'])
            self.assertFalse(candidate['external_store_gates_verified'])

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

    def test_candidate_cli_rejects_partial_or_foreign_signing_before_build(self):
        for args in [
            ['--platform', 'android', '--android-key-alias', 'pourlune-upload'],
            ['--platform', 'ios', '--android-key-alias', 'pourlune-upload'],
        ]:
            with self.subTest(args=args), patch.object(sys, 'argv', [
                'beta_build.py', '--output', 'build/br04-must-not-build', *args
            ]), patch('beta_build.subprocess.run') as process, contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(beta_build.main(), 1)
                process.assert_not_called()

    def test_destination_metadata_distinguishes_missing_partial_and_complete(self):
        from public_destinations import validate_destinations
        self.assertFalse(validate_destinations()['ready'])
        self.assertFalse(validate_destinations(support_url='https://pourlune-fixture.github.io')['ready'])
        self.assertEqual(validate_destinations(
            'https://pourlune-fixture.github.io/help',
            'https://pourlune-fixture.github.io/privacy', 'beta@pourlune-fixture.org'), {
                'support_url': 'https://pourlune-fixture.github.io/help',
                'privacy_url': 'https://pourlune-fixture.github.io/privacy',
                'feedback_email': 'beta@pourlune-fixture.org', 'ready': True})

    def test_unsigned_candidate_records_destinations_without_mislabeling_signed(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); (root / 'app').mkdir()
            (root / 'app/pubspec.yaml').write_text('version: 0.5.0+5\n')
            output = root / 'build/candidate'
            calls = []
            def build(args, **kwargs):
                calls.append(args)
                if args[0] == sys.executable:
                    artifact = root / 'app/build/app/outputs/bundle/release/app-release.aab'
                    artifact.parent.mkdir(parents=True)
                    with zipfile.ZipFile(artifact, 'w') as z:
                        z.writestr('base/assets/puzzle.json', b'real payload boundary fixture')
                    return subprocess.CompletedProcess(args, 0)
                return subprocess.CompletedProcess(args, 0, 'jar is unsigned.', '')
            with patch.object(beta_build, 'ROOT', root), patch.object(beta_build, 'sources', return_value={}), \
                 patch('beta_build.subprocess.run', side_effect=build), \
                 patch('beta_build.subprocess.check_output', return_value='fixture-head\n'), \
                 patch.object(sys, 'argv', ['beta_build.py', '--platform', 'android', '--output', str(output),
                     '--support-url', 'https://pourlune-fixture.github.io/help']), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(beta_build.main(), 0)
            manifest = json.loads((output / 'candidate.json').read_text())
            self.assertFalse(manifest['signed_for_upload'])
            self.assertFalse(manifest['public_destinations']['ready'])
            self.assertFalse(manifest['external_store_gates_verified'])
            self.assertEqual(manifest['public_destinations']['support_url'],
                             'https://pourlune-fixture.github.io/help')
            self.assertTrue(Path(manifest['artifact']).name.endswith('-unsigned.aab'))
            self.assertIn('--support-url', calls[0])
            self.assertFalse((output / 'signing.json').exists())

    def test_upload_signed_manifest_keeps_unsigned_input_and_never_records_password_file(self):
        from test_android_signing import LISTING, CERT
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp); root = home / 'repo'; (root / 'app').mkdir(parents=True)
            (root / 'app/pubspec.yaml').write_text('version: 0.5.0+5\n')
            private = home / 'private'; private.mkdir(mode=0o700)
            key = private / 'upload.p12'; key.write_bytes(b'not a real key'); key.chmod(0o600)
            password = private / 'store-password'; password.write_text('fixture-secret\n'); password.chmod(0o600)
            output = root / 'build/candidate'
            def transport(args, **kwargs):
                self.assertNotIn('fixture-secret', str(args))
                if args[0] == sys.executable:
                    built = root / 'app/build/app/outputs/bundle/release/app-release.aab'
                    built.parent.mkdir(parents=True)
                    with zipfile.ZipFile(built, 'w') as z:
                        z.writestr('base/assets/puzzle.json', b'unchanged fixture')
                    return subprocess.CompletedProcess(args, 0)
                if args[0] == 'keytool':
                    return subprocess.CompletedProcess(args, 0, LISTING, '')
                if '-signedjar' in args:
                    with zipfile.ZipFile(args[args.index('-signedjar') + 1], 'w') as z:
                        z.writestr('base/assets/puzzle.json', b'unchanged fixture')
                        z.writestr('META-INF/UPLOAD.SF', b'fixture only')
                        z.writestr('META-INF/UPLOAD.RSA', b'not crypto evidence')
                return subprocess.CompletedProcess(args, 0,
                    'jar verified.' if '-strict' in args else 'jar is unsigned.', '')
            with patch.object(beta_build, 'ROOT', root), patch.object(beta_build, 'sources', return_value={}), \
                 patch('beta_build.subprocess.run', side_effect=transport), \
                 patch('beta_build.subprocess.check_output', return_value='fixture-head\n'), \
                 patch.object(sys, 'argv', ['beta_build.py', '--platform', 'android', '--output', str(output),
                    '--android-keystore', str(key), '--android-key-alias', 'pourlune-upload',
                    '--android-store-password-file', str(password), '--android-certificate-sha256', CERT]), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(beta_build.main(), 0)
            metadata = json.loads((output / 'candidate.json').read_text())
            self.assertTrue(metadata['signed_for_upload'])
            self.assertFalse(metadata['external_store_gates_verified'])
            self.assertFalse(metadata['public_destinations']['ready'])
            self.assertEqual(Path(metadata['artifact']).name, 'Pourlune-0.5.0-5-upload-signed.aab')
            self.assertTrue((output / 'app-release-unsigned.aab').exists())
            self.assertIn('jar is unsigned', (output / 'unsigned-signature-check.log').read_text())
            self.assertTrue(json.loads((output / 'signature-check.log').read_text())['jarsigner_strict_verified'])
            for filename in ['candidate.json', 'signing.json', 'signature-check.log', 'build.log']:
                self.assertNotIn('fixture-secret', (output / filename).read_text())
                self.assertNotIn(str(password), (output / filename).read_text())


if __name__ == '__main__':
    unittest.main()
