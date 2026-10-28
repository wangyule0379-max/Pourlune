"""Validate packaged API declarations; normalize known empty resource manifests.

Apple TN3181 requires omitting NSPrivacyAccessedAPITypes when it is empty.
Only unsigned, code-free resource bundles already observed in Pourlune may be
normalized. Frameworks, valid API reasons and data-collection declarations stay
unchanged. The Xcode hook runs before Runner signing; this is not an IPA editor.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib

from build_version import BuildError

KEY = 'NSPrivacyAccessedAPITypes'
RESOURCE_BUNDLES = frozenset({
    'nanopb_nanopb.bundle',
    'GoogleUtilities_GoogleUtilities-AppDelegateSwizzler.bundle',
    'GoogleUtilities_GoogleUtilities-NSData.bundle',
    'Firebase_FirebaseInstallations.bundle',
    'GoogleUtilities_GoogleUtilities-Logger.bundle',
    'GoogleUtilities_GoogleUtilities-Reachability.bundle',
    'webview_flutter_wkwebview_webview_flutter_wkwebview.bundle',
    'Firebase_FirebaseABTesting.bundle',
    'GoogleDataTransport_GoogleDataTransport.bundle',
    'Promises_FBLPromises.bundle',
    'Firebase_FirebaseCoreExtension.bundle',
    'url_launcher_ios_url_launcher_ios.bundle',
    'sqflite_darwin_sqflite_darwin.bundle',
    'GoogleUtilities_GoogleUtilities-MethodSwizzler.bundle',
})


def inspect_app(app, *, repair=False):
    app = Path(app)
    if app.suffix != '.app' or not app.is_dir() or app.is_symlink():
        raise BuildError('privacy_expected_app_directory')
    paths = sorted(app.rglob('PrivacyInfo.xcprivacy'))
    if not paths:
        raise BuildError('no_privacy_manifests')
    pending, checked = [], []
    for path in paths:
        relative = path.relative_to(app)
        if any(p.is_symlink() for p in (path, *path.parents)
               if p == app or app in p.parents):
            raise BuildError(f'privacy_symlink:{relative}')
        raw = path.read_bytes()
        try:
            value = plistlib.loads(raw)
        except (plistlib.InvalidFileException, ValueError, TypeError) as error:
            raise BuildError(f'invalid_privacy_plist:{relative}') from error
        if not isinstance(value, dict):
            raise BuildError(f'invalid_privacy_dictionary:{relative}')
        checked.append(str(relative))
        if KEY not in value:
            continue
        entries = value[KEY]
        if not isinstance(entries, list):
            raise BuildError(f'invalid_api_array:{relative}')
        if entries:
            for entry in entries:
                if (not isinstance(entry, dict)
                        or not isinstance(entry.get('NSPrivacyAccessedAPIType'), str)
                        or not entry['NSPrivacyAccessedAPIType'].startswith('NSPrivacyAccessedAPICategory')
                        or not isinstance(entry.get('NSPrivacyAccessedAPITypeReasons'), list)
                        or not entry['NSPrivacyAccessedAPITypeReasons']
                        or any(not isinstance(r, str) or not r.strip()
                               for r in entry['NSPrivacyAccessedAPITypeReasons'])):
                    raise BuildError(f'invalid_api_declaration:{relative}')
            continue
        if not repair:
            raise BuildError(f'empty_api_array:{relative}')
        if len(relative.parts) != 2 or relative.parts[0] not in RESOURCE_BUNDLES:
            raise BuildError(f'unreviewed_empty_api_bundle:{relative}')
        bundle = path.parent
        if (bundle / '_CodeSignature').exists():
            raise BuildError(f'signed_resource_bundle:{relative}')
        info = bundle / 'Info.plist'
        if info.is_symlink():
            raise BuildError(f'privacy_symlink:{relative}')
        try:
            metadata = plistlib.loads(info.read_bytes())
        except (OSError, plistlib.InvalidFileException, ValueError) as error:
            raise BuildError(f'resource_bundle_info_unreadable:{relative}') from error
        if not isinstance(metadata, dict) or metadata.get('CFBundleExecutable'):
            raise BuildError(f'code_resource_bundle:{relative}')
        for child in bundle.rglob('*'):
            if child.is_symlink():
                raise BuildError(f'privacy_symlink:{relative}')
            if child.is_file():
                with child.open('rb') as stream:
                    if stream.read(4) in {b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf',
                                          b'\xca\xfe\xba\xbe', b'\xce\xfa\xed\xfe',
                                          b'\xfe\xed\xfa\xce', b'\xbe\xba\xfe\xca'}:
                        raise BuildError(f'code_resource_bundle:{relative}')
        del value[KEY]
        fixed = plistlib.dumps(value, sort_keys=False,
                              fmt=plistlib.FMT_BINARY if raw.startswith(b'bplist00') else plistlib.FMT_XML)
        pending.append((path, raw, fixed))
    # Validate every manifest before changing any file; unknown SDKs fail closed.
    for path, raw, fixed in pending:
        path.write_bytes(fixed)
    return {'checked': checked, 'changed': [
        {'path': str(p.relative_to(app)), 'removed_key': KEY,
         'before_sha256': hashlib.sha256(raw).hexdigest(),
         'after_sha256': hashlib.sha256(fixed).hexdigest()}
        for p, raw, fixed in pending]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, required=True)
    parser.add_argument('--repair-build-product', action='store_true')
    args = parser.parse_args()
    try:
        if args.repair_build_product:
            expected = Path(os.environ.get('TARGET_BUILD_DIR', '')) / os.environ.get('WRAPPER_NAME', '')
            if (os.environ.get('POURLUNE_REPAIR_PRIVACY_MANIFESTS') != '1'
                    or os.environ.get('ACTION') != 'install'
                    or os.environ.get('CONFIGURATION') != 'Release'
                    or os.environ.get('PLATFORM_NAME') != 'iphoneos'
                    or not os.environ.get('TARGET_BUILD_DIR')
                    or args.app.resolve() != expected.resolve()):
                raise BuildError('privacy_repair_requires_manual_archive_build_phase')
        result = inspect_app(args.app, repair=args.repair_build_product)
        print(json.dumps(result, indent=2))
        return 0
    except (BuildError, OSError) as error:
        print(json.dumps({'ok': False, 'code': str(error) if isinstance(error, BuildError)
                         else 'privacy_manifest_io_error'}))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
