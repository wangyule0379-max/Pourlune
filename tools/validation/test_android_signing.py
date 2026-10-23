"""Command substitutes only: never generate a private key or claim live signing."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from android_signing import SigningError, inspect_signer, sign_aab

CERT = 'A1' * 32
LISTING = '''Alias name: pourlune-upload
Entry type: PrivateKeyEntry
Certificate chain length: 1
Owner: CN=Pourlune Upload
Issuer: CN=Pourlune Upload
Serial number: 1
Valid from: Thu Oct 22 00:00:00 UTC 2026 until: Sun Oct 22 00:00:00 UTC 2056
Certificate fingerprints:
 SHA1: 11:22
 SHA256: ''' + ':'.join(['A1'] * 32) + '\nSignature algorithm name: SHA256withRSA\n'


class AndroidSigningGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.repo = self.home / 'repo'
        self.repo.mkdir()
        self.private = self.home / 'private'
        self.private.mkdir(mode=0o700)
        self.key = self.private / 'upload.jks'
        # Deliberately not a keystore: external cryptographic commands are doubled.
        self.key.write_bytes(b'not a real key')
        self.password = self.private / 'store-password'
        self.password.write_text('fixture-password-never-argv\n')
        for p in [self.key, self.password]:
            p.chmod(0o600)
        self.source = self.repo / 'unsigned.aab'
        with zipfile.ZipFile(self.source, 'w') as z:
            z.writestr('base/manifest/AndroidManifest.xml', b'unchanged payload')
        self.output = self.repo / 'signed.aab'
        self.calls = []

    def invoke(self, args, **kwargs):
        self.calls.append(args)
        self.assertNotIn('fixture-password-never-argv', json.dumps(args))
        if '-signedjar' in args:
            out = Path(args[args.index('-signedjar') + 1])
            with zipfile.ZipFile(self.source) as source, zipfile.ZipFile(out, 'w') as target:
                for name in source.namelist():
                    target.writestr(name, source.read(name))
                target.writestr('META-INF/UPLOAD.SF', b'fixture signature marker')
                target.writestr('META-INF/UPLOAD.RSA', b'not cryptographic evidence')
            return subprocess.CompletedProcess(args, 0, 'jar signed.', '')
        if '-verify' in args:
            return subprocess.CompletedProcess(args, 0, 'jar verified.', '')
        return subprocess.CompletedProcess(args, 0, LISTING, '')

    def options(self, **extra):
        return dict(keystore=self.key, alias='pourlune-upload',
                    password_file=self.password, expected_sha256=CERT,
                    root=self.repo, **extra)

    def test_explicit_signer_produces_separate_verified_copy_without_password_metadata(self):
        original = self.source.read_bytes()
        with patch('android_signing.subprocess.run', side_effect=self.invoke):
            metadata = sign_aab(self.source, self.output, **self.options())
        self.assertEqual(self.source.read_bytes(), original)
        self.assertEqual(metadata['certificate_sha256'], CERT)
        self.assertEqual(metadata['alias'], 'pourlune-upload')
        self.assertTrue(metadata['jarsigner_strict_verified'])
        self.assertNotIn('password', json.dumps(metadata))
        self.assertNotIn(str(self.password), json.dumps(metadata))
        self.assertTrue(any('-storepass:file' in c for c in self.calls))
        self.assertTrue(any('-verify' in c and '-strict' in c for c in self.calls))
        with zipfile.ZipFile(self.output) as z:
            self.assertEqual(z.read('base/manifest/AndroidManifest.xml'), b'unchanged payload')

    def test_bad_assets_and_aliases_fail_before_any_tool_or_output(self):
        variants = [{'alias': 'androiddebugkey'}, {'alias': '-option'},
                    {'keystore': self.private / 'missing.jks'},
                    {'password_file': self.private / 'missing-password'},
                    {'expected_sha256': 'not-a-certificate'}]
        for extra in variants:
            options = self.options(); options.update(extra)
            with self.subTest(extra=extra), patch('android_signing.subprocess.run', side_effect=self.invoke):
                with self.assertRaises(SigningError):
                    inspect_signer(**options)
        self.assertEqual(self.calls, [])
        self.assertFalse(self.output.exists())

    def test_private_material_in_repo_or_readable_by_others_rejected(self):
        for which in ['key', 'password']:
            target = self.key if which == 'key' else self.password
            target.chmod(0o644)
            with self.assertRaises(SigningError):
                inspect_signer(**self.options())
            target.chmod(0o600)
        inside = self.repo / 'private'; inside.mkdir(mode=0o700)
        local_key = inside / 'key.jks'; local_key.write_bytes(b'not a key'); local_key.chmod(0o600)
        options = self.options(); options['keystore'] = local_key
        with self.assertRaises(SigningError):
            inspect_signer(**options)

    def test_multiline_or_empty_password_file_never_reaches_keytool(self):
        for value in [b'', b'short', b'long-password\n\n', b'long-password\rhidden']:
            self.password.write_bytes(value)
            with self.subTest(value=value), patch('android_signing.subprocess.run', side_effect=self.invoke):
                with self.assertRaises(SigningError):
                    inspect_signer(**self.options())
        self.assertEqual(self.calls, [])

    def test_wrong_alias_password_debug_certificate_pin_or_expiry_never_sign(self):
        outputs = [subprocess.CompletedProcess([], 1, '', 'fixture-password-never-argv wrong alias'),
                   subprocess.CompletedProcess([], 0, LISTING.replace('PrivateKeyEntry', 'trustedCertEntry'), ''),
                   subprocess.CompletedProcess([], 0, LISTING.replace('CN=Pourlune Upload', 'CN=Android Debug'), ''),
                   subprocess.CompletedProcess([], 0, LISTING.replace('A1:', 'B2:'), ''),
                   subprocess.CompletedProcess([], 0, LISTING.replace('2056', '2020'), '')]
        for result in outputs:
            with self.subTest(result=result.returncode), patch('android_signing.subprocess.run', return_value=result):
                with self.assertRaises(SigningError) as caught:
                    sign_aab(self.source, self.output, **self.options())
                self.assertNotIn('fixture-password-never-argv', str(caught.exception))
                self.assertFalse(self.output.exists())

    def test_failed_verification_or_changed_payload_removes_incomplete_copy(self):
        def failing(args, **kwargs):
            result = self.invoke(args, **kwargs)
            if '-verify' in args:
                return subprocess.CompletedProcess(args, 1, '', 'fixture-password-never-argv')
            return result
        with patch('android_signing.subprocess.run', side_effect=failing):
            with self.assertRaises(SigningError):
                sign_aab(self.source, self.output, **self.options())
        self.assertFalse(self.output.exists())
        self.assertTrue(self.source.exists())
        def tampering(args, **kwargs):
            result = self.invoke(args, **kwargs)
            if '-signedjar' in args:
                with zipfile.ZipFile(self.output, 'w') as z:
                    z.writestr('base/manifest/AndroidManifest.xml', b'wrong app payload')
                    z.writestr('META-INF/UPLOAD.SF', b'fixture')
                    z.writestr('META-INF/UPLOAD.RSA', b'fixture')
            return result
        with patch('android_signing.subprocess.run', side_effect=tampering):
            with self.assertRaises(SigningError):
                sign_aab(self.source, self.output, **self.options())
        self.assertFalse(self.output.exists())
        self.output.write_bytes(b'frozen previous signed output')
        with patch('android_signing.subprocess.run', side_effect=self.invoke):
            with self.assertRaises(SigningError):
                sign_aab(self.source, self.output, **self.options())
        self.assertEqual(self.output.read_bytes(), b'frozen previous signed output')

    def test_exported_aab_signer_must_match_pin_even_if_keystore_changes_mid_sign(self):
        def wrong_certificate(args, **kwargs):
            if '-printcert' in args:
                return subprocess.CompletedProcess(args, 0, LISTING.replace('A1:', 'B2:'), '')
            return self.invoke(args, **kwargs)
        with patch('android_signing.subprocess.run', side_effect=wrong_certificate):
            with self.assertRaises(SigningError):
                sign_aab(self.source, self.output, **self.options())
        self.assertFalse(self.output.exists())


if __name__ == '__main__':
    unittest.main()
