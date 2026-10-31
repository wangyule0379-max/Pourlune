"""Public AdMob selection; production requires an owned, verified registration."""
import argparse
import base64
import binascii
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

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
    require(mode in {'disabled', 'test', 'production'} and platform in SAMPLES, 'invalid_ad_selection')
    require(mode != 'production' or registration is not None, 'production_requires_registration')
    result = {'mode': mode, 'platform': platform, 'native_id': native_id,
              **SAMPLES[platform], 'app_id_source': 'official_sample',
              'owned_registration_verified': False}
    if registration:
        require(mode in {'test', 'production'}, 'ad_registration_requires_enabled_mode')
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
            if mode == 'production':
                publisher = app_id.split('~')[0]
                units = {key: app[key] for key in ('interstitial_id', 'rewarded_id')}
                require(all(isinstance(value, str) and bool(re.fullmatch(
                    re.escape(publisher) + r'/[0-9]{10}', value))
                    for value in units.values()) and len(set(units.values())) == 2,
                    'invalid_owned_ad_units')
                result.update(units)
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
                                'POURLUNE_AD_PLATFORM', 'POURLUNE_AD_NATIVE_ID',
                                'POURLUNE_INTERSTITIAL_ID', 'POURLUNE_REWARDED_ID'}, 'unsupported_ad_define')
                defines[key] = value
    except (ValueError, UnicodeError, binascii.Error):
        raise AdConfigError('invalid_ad_defines') from None
    mode = defines.get('POURLUNE_AD_MODE', 'disabled')
    selected = selection(mode, platform, native_id, registration)
    require(native_app_id == selected['app_id'], 'native_ad_app_id_mismatch')
    if mode in {'test', 'production'}:
        require(defines.get('POURLUNE_AD_APP_ID') == selected['app_id']
                and defines.get('POURLUNE_AD_PLATFORM') == platform
                and defines.get('POURLUNE_AD_NATIVE_ID') == native_id,
                'ad_build_selection_mismatch')
    if mode == 'production':
        require(defines.get('POURLUNE_INTERSTITIAL_ID') == selected['interstitial_id']
                and defines.get('POURLUNE_REWARDED_ID') == selected['rewarded_id'],
                'ad_unit_selection_mismatch')
    else:
        require(not {'POURLUNE_INTERSTITIAL_ID', 'POURLUNE_REWARDED_ID'} & defines.keys(),
                'ad_units_require_production')
    if 'POURLUNE_AD_MODE' not in defines:
        selected['mode'] = 'dart_default'
    return selected


def add_arguments(parser):
    parser.add_argument('--ad-mode', choices=['disabled', 'test', 'production'], default='disabled')
    parser.add_argument('--admob-registration', type=Path,
                        help='Public Pourlune platform registration, verified against the console')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['ios', 'android'], required=True)
    parser.add_argument('--native-id', required=True)
    parser.add_argument('--native-app-id', required=True)
    parser.add_argument('--registration', type=Path)
    parser.add_argument('--android-manifest', type=Path,
                        help='Decoded packaged/merged Android manifest to verify before upload')
    args = parser.parse_args()
    try:
        result = check_build(args.platform, args.native_id, args.native_app_id,
                             os.environ.get('DART_DEFINES', ''), args.registration)
        if args.android_manifest:
            require(args.platform == 'android', 'android_manifest_requires_android')
            try:
                manifest = ET.parse(args.android_manifest).getroot()
            except (OSError, ET.ParseError):
                raise AdConfigError('invalid_android_manifest') from None
            android = '{http://schemas.android.com/apk/res/android}'
            has_ad_id = any(node.tag.startswith('uses-permission') and
                            node.get(android + 'name') in {
                                'com.google.android.gms.permission.AD_ID',
                                'android.permission.ACCESS_ADSERVICES_AD_ID'}
                            for node in manifest)
            require(result['mode'] == 'test' or not has_ad_id,
                    'disabled_android_ad_id_permission')
            values = [node.get(android + 'value') for node in manifest.findall('application/meta-data')
                      if node.get(android + 'name') == 'google_analytics_adid_collection_enabled']
            require(values == ['false'], 'android_analytics_ad_id_collection')
            result['android_privacy'] = {'ad_id_permission': has_ad_id,
                                         'analytics_ad_id_collection': False}
        print(json.dumps(result))
        return 0
    except AdConfigError as error:
        print(json.dumps({'ok': False, 'code': str(error)}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
