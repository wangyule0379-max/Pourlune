"""Restore the single pinned private SDK; never fetch or publish source code."""
import argparse
import base64
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[2]
PIN = ROOT / 'tools/validation/gamemunchies-sdk.json'
DESTINATION = ROOT / '.private-dependencies/gamemunchies_client'


class SDKSourceError(ValueError):
    pass


def require(valid, code):
    if not valid:
        raise SDKSourceError(code)


def digest(content):
    return hashlib.sha256(content).hexdigest()


def verify_installed(pin, destination=DESTINATION):
    require(destination.is_dir() and not destination.is_symlink(), 'private_sdk_missing')
    actual = {}
    for path in destination.rglob('*'):
        require(not path.is_symlink(), 'private_sdk_symlink')
        if path.is_file():
            actual[path.relative_to(destination).as_posix()] = digest(path.read_bytes())
    require(actual == pin['files'], 'private_sdk_source_drift')
    return actual


def install(payload, pin, destination=DESTINATION):
    require(len(payload) <= 49152 and digest(payload) == pin['archive_sha256'],
            'private_sdk_archive_mismatch')
    files = {}
    try:
        with tarfile.open(fileobj=io.BytesIO(payload), mode='r:gz') as archive:
            for item in archive:
                name = PurePosixPath(item.name)
                require(item.isfile() and not item.linkname and not name.is_absolute()
                        and '..' not in name.parts and str(name) == item.name
                        and item.name in pin['files'] and item.name not in files
                        and 0 <= item.size <= 300000 and len(files) < 20,
                        'private_sdk_unsafe_archive')
                files[item.name] = archive.extractfile(item).read()
                require(sum(map(len, files.values())) <= 1000000,
                        'private_sdk_archive_limit')
    except (tarfile.TarError, OSError, EOFError) as error:
        raise SDKSourceError('private_sdk_invalid_archive') from error
    require({name: digest(content) for name, content in files.items()} == pin['files'],
            'private_sdk_files_mismatch')
    if destination.exists() or destination.is_symlink():
        return verify_installed(pin, destination)
    require(not destination.parent.is_symlink(), 'private_sdk_parent_symlink')
    destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = Path(tempfile.mkdtemp(prefix='.sdk-', dir=destination.parent))
    try:
        for name, content in files.items():
            path = temporary / name
            path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            path.write_bytes(content)
            path.chmod(0o600)
        temporary.rename(destination)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)
    return verify_installed(pin, destination)


def inspect_source():
    pin = json.loads(PIN.read_text())
    verify_installed(pin)
    return pin


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    try:
        pin = json.loads(PIN.read_text())
        if args.check:
            verify_installed(pin)
        else:
            encoded = os.environ.get('POURLUNE_GM_SDK_ARCHIVE', '')
            require(args.archive is not None or bool(encoded), 'pinned_private_sdk_archive_required')
            payload = args.archive.read_bytes() if args.archive else base64.b64decode(encoded, validate=True)
            install(payload, pin)
        print(json.dumps({'ok': True, 'source_commit': pin['source_commit'],
                          'archive_sha256': pin['archive_sha256'], 'files': len(pin['files'])}))
    except (SDKSourceError, OSError, ValueError, KeyError):
        # Neither archive bytes, environment values nor decoded source enter logs.
        print(json.dumps({'ok': False, 'error': 'pinned_private_sdk_unavailable_or_mismatched'}))
        raise SystemExit(2)


if __name__ == '__main__':
    main()
