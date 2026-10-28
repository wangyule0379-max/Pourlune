"""Explicit public GameMunchies identity/environment selection, with no secrets."""
import argparse
import base64
import binascii
import json
import os

TEST_ID = '566121d2-a3f5-4950-8bd9-6ff2f673a0ac'
PRODUCTION_ID = '8feaf0dc-ec12-4308-ac58-16b2180f2d63'
QA_IDS = {'ios': 'dev.pourlune.gamemunchiesValidation',
          'android': 'dev.pourlune.pourlune_dev'}
BASE_URL = 'https://api.gamemunchies.com'


class ConfigError(ValueError):
    pass


def require(valid, code):
    if not valid:
        raise ConfigError(code)


def selection(environment, platform, native_id):
    require(platform in QA_IDS and environment in {'disabled', 'test', 'production'},
            'invalid_gamemunchies_selection')
    if environment != 'disabled':
        expected = QA_IDS[platform] if environment == 'test' else 'com.pourlune.app'
        require(native_id == expected, 'gamemunchies_registration_identity_mismatch')
    return {'enabled': environment != 'disabled', 'environment': environment,
            'game_id': TEST_ID if environment == 'test' else
                       PRODUCTION_ID if environment == 'production' else '',
            'platform': platform, 'native_id': native_id, 'base_url': BASE_URL,
            'analytics_default_off': True, 'rules_independent_of_statistics': True}


def check_build(platform, native_id, encoded):
    fields = {}
    try:
        for item in encoded.split(',') if encoded else []:
            key, value = base64.b64decode(item, validate=True).decode().split('=', 1)
            if key.startswith('POURLUNE_GAMEMUNCHIES_'):
                require(key in {'POURLUNE_GAMEMUNCHIES_GAME_ID', 'POURLUNE_GAMEMUNCHIES_ENVIRONMENT'}
                        and key not in fields, 'unsupported_or_duplicate_gamemunchies_define')
                fields[key] = value
    except (ValueError, UnicodeError, binascii.Error) as error:
        raise ConfigError('invalid_gamemunchies_defines') from error
    if not fields:
        return selection('disabled', platform, native_id)
    require(len(fields) == 2, 'incomplete_gamemunchies_selection')
    selected = selection(fields['POURLUNE_GAMEMUNCHIES_ENVIRONMENT'], platform, native_id)
    require(fields['POURLUNE_GAMEMUNCHIES_GAME_ID'] == selected['game_id'],
            'gamemunchies_game_environment_mismatch')
    return selected


def add_arguments(parser):
    parser.add_argument('--gamemunchies-environment', choices=['disabled', 'test', 'production'],
                        default='disabled')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['ios', 'android'], required=True)
    parser.add_argument('--native-id', required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(check_build(args.platform, args.native_id, os.environ.get('DART_DEFINES', ''))))
    except ConfigError as error:
        print(json.dumps({'ok': False, 'code': str(error)}))
        raise SystemExit(1)


if __name__ == '__main__':
    main()
