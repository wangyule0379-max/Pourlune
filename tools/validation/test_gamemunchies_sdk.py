import hashlib
import io
from pathlib import Path
import tarfile
import tempfile
import unittest

import gamemunchies_sdk as sdk


def fixture(entries=None):
    files = {'pubspec.yaml': b'name: gamemunchies_client\nversion: 0.1.0\n',
             'lib/gamemunchies_client.dart': b'// fixture only\n'}
    payload = io.BytesIO()
    with tarfile.open(fileobj=payload, mode='w:gz') as archive:
        for name, content in (entries or files).items():
            info = tarfile.TarInfo(name)
            info.size = len(content)
            archive.addfile(info, io.BytesIO(content))
    raw = payload.getvalue()
    return raw, {'archive_sha256': hashlib.sha256(raw).hexdigest(),
                 'files': {name: hashlib.sha256(content).hexdigest() for name, content in files.items()}}


class PrivateSDKTest(unittest.TestCase):
    def test_exact_install_idempotent_and_drift_refused(self):
        raw, pin = fixture()
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'sdk'
            sdk.install(raw, pin, target)
            sdk.install(raw, pin, target)
            sdk.verify_installed(pin, target)
            (target / 'lib/gamemunchies_client.dart').write_text('changed')
            with self.assertRaises(sdk.SDKSourceError):
                sdk.install(raw, pin, target)

    def test_missing_or_wrong_archive_is_rejected_before_output(self):
        raw, pin = fixture()
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'sdk'
            with self.assertRaises(sdk.SDKSourceError):
                sdk.install(raw + b'changed', pin, target)
            self.assertFalse(target.exists())

    def test_traversal_and_unexpected_files_rejected_even_when_archive_hash_matches(self):
        for entries in [{'../outside': b'no'}, {'/absolute': b'no'}, {'other.dart': b'no'}]:
            raw, pin = fixture(entries)
            with tempfile.TemporaryDirectory() as directory:
                target = Path(directory) / 'sdk'
                with self.assertRaises(sdk.SDKSourceError):
                    sdk.install(raw, pin, target)
                self.assertFalse(target.exists())


if __name__ == '__main__':
    unittest.main()
