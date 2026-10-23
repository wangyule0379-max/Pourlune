"""Public AdMob selection for disabled builds or explicit beta test ads only."""
import argparse
import base64
import binascii
import hashlib
import json
import os
from pathlib import Path
import re
import sys

SAMPLES = {
    'ios': {'app_id': 'ca-app-pub-3940256099942544~1458002511',
            'interstitial_id': 'ca-app-pub-3940256099942544/4411468910',
            'rewarded_id': 'ca-app-pub-3940256099942544/1712485313'},
    'android': {'app_id': 'ca-app-pub-3940256099942544~3347511713',
                'interstitial_id': 'ca-app-pub-3940256099942544/1033173712',
                'rewarded_id': 'ca-app-pub-3940256099942544/5224354917'},
}


class AdConfigError(Exception):
    pass


def require(condition, code):
    if not condition:
        raise AdConfigError(code)


def selection(mode, platform, native_id, registration=None):
    require(mode in {'disabled', 'test'} and platform in SAMPLES, 'invalid_ad_selection')
    result = {'mode': mode, 'platform': platform, 'native_id': native_id,
              **SAMPLES[platform], 'app_id_source': 'official_sample',
              'owned_registration_verified': False}
    if registration:
        require(mode == 'test', 'ad_registration_requires_explicit_test_mode')
        try:
            payload = Path(registration).read_bytes()
            data = json.loads(payload)
            app = data['apps'][platform]
            require(data['schema'] == 1 and app['native_id'] == native_id
                    and native_id == 'com.pourlune.app', 'ad_registration_identity_mismatch')
            app_id = app['app_id']
            require(isinstance(app_id, str) and bool(re.fullmatch(
                r'ca-app-pub-[0-9]{16}~[0-9]{10}', app_id))
                and not app_id.startswith('ca-app-pub-3940256099942544'),
                'invalid_owned_ad_app_id')
        except (OSError, ValueError, KeyError, TypeError):
            raise AdConfigError('invalid_ad_registration') from None
        result.update(app_id=app_id, app_id_source='registered_pourlune',
                      owned_registration_verified=True,
                      registration_sha256=hashlib.sha256(payload).hexdigest())
    return result


def check_build(platform, native_id, native_app_id, encoded, registration=None):
    defines = {}
    try:
        for part in encoded.split(',') if encoded else []:
            key, value = base64.b64decode(part, validate=True).decode().split('=', 1)
            if key.startswith(('POURLUNE_AD', 'POURLUNE_INTERSTITIAL', 'POURLUNE_REWARDED')):
                require(key not in defines, 'duplicate_ad_define')
                require(key in {'POURLUNE_AD_MODE', 'POURLUNE_AD_APP_ID',
                                'POURLUNE_AD_PLATFORM', 'POURLUNE_AD_NATIVE_ID'}, 'unsupported_ad_define')
                defines[key] = value
    except (ValueError, UnicodeError, binascii.Error):
        raise AdConfigError('invalid_ad_defines') from None
    mode = defines.get('POURLUNE_AD_MODE', 'disabled')
    selected = selection(mode, platform, native_id, registration)
    require(native_app_id == selected['app_id'], 'native_ad_app_id_mismatch')
    if mode == 'test':
        require(defines.get('POURLUNE_AD_APP_ID') == selected['app_id']
                and defines.get('POURLUNE_AD_PLATFORM') == platform
                and defines.get('POURLUNE_AD_NATIVE_ID') == native_id,
                'ad_build_selection_mismatch')
    if 'POURLUNE_AD_MODE' not in defines:
        selected['mode'] = 'dart_default'
    return selected


def add_arguments(parser):
    parser.add_argument('--ad-mode', choices=['disabled', 'test'], default='disabled')
    parser.add_argument('--admob-registration', type=Path,
                        help='Public Pourlune platform registration, verified against the console')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['ios', 'android'], required=True)
    parser.add_argument('--native-id', required=True)
    parser.add_argument('--native-app-id', required=True)
    parser.add_argument('--registration', type=Path)
    args = parser.parse_args()
    try:
        result = check_build(args.platform, args.native_id, args.native_app_id,
                             os.environ.get('DART_DEFINES', ''), args.registration)
        print(json.dumps(result))
        return 0
    except AdConfigError as error:
        print(json.dumps({'ok': False, 'code': str(error)}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
