"""Read public provisioning metadata; reuse only an existing Pourlune signer."""
import datetime as dt
import hashlib
from pathlib import Path
import plistlib
import re
import subprocess

TEAM = 'T7U878Z8H6'
BUNDLE = 'com.pourlune.app'


class ProfileError(Exception):
    pass


def validate_profile(profile, now, available_identities):
    ent = profile.get('Entitlements', {})
    expiry = profile.get('ExpirationDate')
    if isinstance(expiry, dt.datetime) and expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=dt.timezone.utc)
    if (profile.get('TeamIdentifier') != [TEAM]
            or ent.get('application-identifier') != f'{TEAM}.{BUNDLE}'
            or ent.get('com.apple.developer.team-identifier') != TEAM
            or ent.get('get-task-allow') is not False
            or ent.get('beta-reports-active') is not True
            or 'ProvisionedDevices' in profile
            or profile.get('ProvisionsAllDevices')
            or not isinstance(expiry, dt.datetime) or expiry <= now
            or not isinstance(profile.get('UUID'), str) or not profile['UUID']):
        raise ProfileError('profile_not_current_pourlune_app_store')
    fingerprints = [hashlib.sha1(c).hexdigest().upper()
                    for c in profile.get('DeveloperCertificates', []) if isinstance(c, bytes)]
    matching = [c for c in fingerprints if c in available_identities]
    if len(matching) != 1:
        raise ProfileError('profile_needs_one_existing_local_signer')
    return {'uuid': profile['UUID'], 'name': profile.get('Name'), 'team': TEAM,
            'bundle': BUNDLE, 'certificate_sha1': matching[0],
            'expires': expiry.isoformat()}


def inspect_profile(path):
    # CMS and Keychain output stays in memory; never print full profile/keys.
    decoded = subprocess.run(['security', 'cms', '-D', '-i', str(Path(path).resolve())],
                             capture_output=True)
    identities = subprocess.run(['security', 'find-identity', '-v', '-p', 'codesigning'],
                                capture_output=True, text=True)
    if decoded.returncode or identities.returncode:
        raise ProfileError('cannot_read_existing_profile_or_identities')
    try:
        profile = plistlib.loads(decoded.stdout)
        available = set(re.findall(r'\b[0-9A-F]{40}\b', identities.stdout))
        return validate_profile(profile, dt.datetime.now(dt.timezone.utc), available)
    except (ValueError, TypeError, AttributeError, plistlib.InvalidFileException):
        raise ProfileError('invalid_profile_metadata') from None
