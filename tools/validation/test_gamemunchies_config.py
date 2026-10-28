import base64
import unittest
from gamemunchies_config import ConfigError, selection, check_build, TEST_ID, PRODUCTION_ID


def encoded(values):
    return ','.join(base64.b64encode((k+'='+v).encode()).decode() for k,v in values)


class RegistrationTest(unittest.TestCase):
    def test_exact_production_and_test_pairs_match_actual_native_identities(self):
        for platform, native in [('ios','dev.pourlune.gamemunchiesValidation'),('android','dev.pourlune.pourlune_dev')]:
            self.assertEqual(selection('test',platform,native)['game_id'],TEST_ID)
            self.assertEqual(selection('production',platform,'com.pourlune.app')['game_id'],PRODUCTION_ID)
        self.assertFalse(selection('disabled','ios','dev.pourlune.pourluneDev')['enabled'])

    def test_unknown_mixed_or_wrong_native_registration_rejected(self):
        for platform,native in [('ios','com.pourlune.app'),('ios','dev.pourlune.pourluneDev'),('android','unknown')]:
            with self.assertRaises(ConfigError):selection('test',platform,native)
        with self.assertRaises(ConfigError):selection('production','ios','dev.pourlune.gamemunchiesValidation')
        for game,env in [(PRODUCTION_ID,'test'),(TEST_ID,'production'),('unknown','production')]:
            with self.assertRaises(ConfigError):check_build('ios','com.pourlune.app',encoded([('POURLUNE_GAMEMUNCHIES_GAME_ID',game),('POURLUNE_GAMEMUNCHIES_ENVIRONMENT',env)]))

    def test_native_check_rejects_partial_duplicate_or_unknown_fields(self):
        self.assertFalse(check_build('ios','dev.pourlune.pourluneDev','')['enabled'])
        valid=[('POURLUNE_GAMEMUNCHIES_GAME_ID',PRODUCTION_ID),('POURLUNE_GAMEMUNCHIES_ENVIRONMENT','production')]
        self.assertEqual(check_build('ios','com.pourlune.app',encoded(valid))['base_url'],'https://api.gamemunchies.com')
        for values in [valid[:1],valid+valid[:1],valid+[('POURLUNE_GAMEMUNCHIES_BASE_URL','https://example.com')]]:
            with self.assertRaises(ConfigError):check_build('ios','com.pourlune.app',encoded(values))


if __name__=='__main__':unittest.main()
