import base64
import copy
import datetime as dt
import json
import unittest
import gamemunchies_api_replay_probe as probe
import gamemunchies_replay_probe as legacy


class APIScopeReplayTest(unittest.TestCase):
    def snapshot(self, origin=probe.ORIGIN):
        scope=[origin,legacy.GAME_ID,'ios','test']
        key='gamemunchies.v1.'+base64.urlsafe_b64encode(json.dumps(scope,separators=(',',':')).encode()).decode()
        return {'sourceDevice':legacy.DEVICES['ios'],'sourceAppId':legacy.APP_IDS['ios'],
                'preferencesKey':key,'state':{'schemaVersion':1,'installationId':'actual-queue-fixture',
                'events':[{'id':'original-id','installationId':'actual-queue-fixture','type':'round_start','environment':'test','occurredAt':'2026-10-28T00:00:00.000Z'}]}}

    def test_new_scope_uses_identical_observations_and_neither_tool_accepts_other_scope(self):
        now=dt.datetime(2026,10,28,tzinfo=dt.timezone.utc)
        snapshot=self.snapshot();before=copy.deepcopy(snapshot)
        result=probe.prepare(snapshot,platform='ios',now=now)
        self.assertEqual(snapshot,before)
        self.assertEqual(json.loads(result['body'])['events'],snapshot['state']['events'])
        self.assertEqual(result['url'],probe.ORIGIN+'/api/client/games/'+legacy.GAME_ID+'/ios/events')
        with self.assertRaises(ValueError):legacy.prepare(snapshot,platform='ios',now=now)
        with self.assertRaises(ValueError):probe.prepare(self.snapshot(legacy.ORIGIN),platform='ios',now=now)

    def test_rejects_production_other_device_and_extra_data(self):
        for kind in ['production','other-device','extra-field']:
            snapshot=self.snapshot()
            if kind=='production':snapshot['state']['events'][0]['environment']='production'
            if kind=='other-device':snapshot['sourceDevice']='F9'
            if kind=='extra-field':snapshot['state']['events'][0]['board']='not-allowed'
            with self.assertRaises(ValueError):probe.prepare(snapshot,platform='ios')


if __name__=='__main__':unittest.main()
