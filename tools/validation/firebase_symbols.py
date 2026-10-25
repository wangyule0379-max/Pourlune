"""Upload selected development iOS dSYMs and retain a public receipt."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime, timezone

from firebase_config import ConfigError, ROOT, REGISTRY, check_build, require


def upload_symbols(environment, run=None):
    if environment.get('POURLUNE_FIREBASE_UPLOAD_SYMBOLS') != 'YES':
        return {'status': 'disabled'}
    require(environment.get('POURLUNE_FIREBASE_ENV') == 'dev', 'symbol_upload_dev_only')
    run = run or subprocess.run
    _, config = check_build(
        Path(environment.get('POURLUNE_FIREBASE_CONFIG_DIR', ROOT / 'app/config/firebase')),
        'dev', 'ios', environment['PRODUCT_BUNDLE_IDENTIFIER'],
        environment.get('DART_DEFINES', ''),
        Path(environment.get('POURLUNE_FIREBASE_REGISTRY', REGISTRY)),
    )
    product = Path(environment['TARGET_BUILD_DIR'])
    native = product / environment['UNLOCALIZED_RESOURCES_FOLDER_PATH'] / 'GoogleService-Info.plist'
    require(native.read_bytes() == config['native_path'].read_bytes(), 'symbol_native_config_mismatch')
    binary = product / environment['EXECUTABLE_PATH']
    dsym = Path(environment['DWARF_DSYM_FOLDER_PATH']) / environment['DWARF_DSYM_FILE_NAME']
    dwarf = dsym / 'Contents/Resources/DWARF' / environment['PRODUCT_NAME']
    def uuids(path):
        result = run(['/usr/bin/dwarfdump', '--uuid', str(path)],
                     capture_output=True, text=True, timeout=30)
        values = sorted(set(re.findall(r'UUID: ([A-Fa-f0-9-]{36})', result.stdout)))
        require(result.returncode == 0 and bool(values), 'symbol_uuid_missing')
        return values
    binary_ids, dsym_ids = uuids(binary), uuids(dsym)
    require(binary_ids == dsym_ids, 'symbol_uuid_mismatch')
    build_dir = environment['BUILD_DIR']
    uploader = Path(build_dir.split('/Build/')[0]) / 'SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols'
    result = run([str(uploader), '-gsp', str(native), '-p', 'ios', str(dsym)],
                 capture_output=True, text=True, timeout=180)
    # Provider output may echo client configuration. Keep only the exit status.
    require(result.returncode == 0, 'symbol_upload_failed')
    return {
        'status': 'uploader_exit_0', 'environment': 'dev',
        'project_id': config['project_id'], 'app_id': config['app_id'],
        'native_id': config['native_id'], 'uuids': binary_ids,
        'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
        'dwarf_sha256': hashlib.sha256(dwarf.read_bytes()).hexdigest(),
        'native_sha256': hashlib.sha256(native.read_bytes()).hexdigest(),
        'utc': datetime.now(timezone.utc).isoformat(),
    }


def main():
    try:
        receipt = upload_symbols(os.environ)
        if receipt['status'] != 'disabled':
            path = Path(os.environ['POURLUNE_FIREBASE_CONFIG_DIR']) / 'dev/ios/symbol-upload.json'
            path.write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps(receipt))
        return 0
    except ConfigError as error:
        print(json.dumps({'ok': False, 'code': str(error)}), file=sys.stderr)
    except (OSError, KeyError, subprocess.TimeoutExpired):
        print(json.dumps({'ok': False, 'code': 'symbol_upload_io_or_timeout'}), file=sys.stderr)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
