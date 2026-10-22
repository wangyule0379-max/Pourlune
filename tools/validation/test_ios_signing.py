import copy
import datetime as dt
import unittest
from ios_signing import ProfileError, validate_profile

NOW = dt.datetime(2026, 10, 22, tzinfo=dt.timezone.utc)
CERT = b'existing public certificate DER'


class ExistingProfileTest(unittest.TestCase):
    def profile(self):
        return {'UUID': 'pourlune-profile', 'Name': 'Pourlune Beta',
                'TeamIdentifier': ['T7U878Z8H6'],
                'ExpirationDate': NOW + dt.timedelta(days=30),
                'DeveloperCertificates': [CERT],
                'Entitlements': {'application-identifier': 'T7U878Z8H6.com.pourlune.app',
                                 'com.apple.developer.team-identifier': 'T7U878Z8H6',
                                 'get-task-allow': False, 'beta-reports-active': True}}

    def test_only_existing_matching_app_store_identity_is_usable(self):
        import hashlib
        fingerprint = hashlib.sha1(CERT).hexdigest().upper()
        self.assertEqual(validate_profile(self.profile(), NOW, {fingerprint})['certificate_sha1'], fingerprint)
        with self.assertRaises(ProfileError):
            validate_profile(self.profile(), NOW, set())

    def test_foreign_apps_teams_and_expired_profiles_rejected(self):
        import hashlib
        identities = {hashlib.sha1(CERT).hexdigest().upper()}
        for mutation in [
            {'TeamIdentifier': ['ANOTHERTEAM']},
            {'ExpirationDate': NOW - dt.timedelta(seconds=1)},
            {'Entitlements': {**self.profile()['Entitlements'], 'application-identifier': 'T7U878Z8H6.com.fishtk.fishpilot'}},
            {'Entitlements': {**self.profile()['Entitlements'], 'com.apple.developer.team-identifier': 'ANOTHERTEAM'}},
        ]:
            with self.subTest(mutation=mutation), self.assertRaises(ProfileError):
                validate_profile({**self.profile(), **mutation}, NOW, identities)

    def test_dev_adhoc_enterprise_or_non_beta_profile_cannot_export(self):
        import hashlib
        identities = {hashlib.sha1(CERT).hexdigest().upper()}
        for field in ['development', 'adhoc', 'enterprise', 'not-beta']:
            p = copy.deepcopy(self.profile())
            if field == 'development': p['Entitlements']['get-task-allow'] = True
            if field == 'adhoc': p['ProvisionedDevices'] = ['device']
            if field == 'enterprise': p['ProvisionsAllDevices'] = True
            if field == 'not-beta': p['Entitlements']['beta-reports-active'] = False
            with self.subTest(field=field), self.assertRaises(ProfileError):
                validate_profile(p, NOW, identities)


if __name__ == '__main__':
    unittest.main()
