"""The probe must never fabricate events or accept another game/environment."""
import copy
import base64
import contextlib
import datetime as dt
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import json

import gamemunchies_replay_probe as probe


class ReplayProbeTest(unittest.TestCase):
    def setUp(self):
        self.now = dt.datetime(2026, 10, 28, tzinfo=dt.timezone.utc)
        self.state = {
            'schemaVersion': 1,
            'installationId': 'unit-only-installation',
            'events': [{
                'id': 'round:unit-only-instance',
                'installationId': 'unit-only-installation',
                'type': 'round_start',
                'environment': 'test',
                'occurredAt': '2026-10-28T00:00:00.000Z',
            }],
        }

    def prepare(self, state=None, **kwargs):
        return probe.prepare(
            self.snapshot(self.state if state is None else state),
            platform='ios', now=self.now, **kwargs)

    def snapshot(self, state, game_id='566121d2-a3f5-4950-8bd9-6ff2f673a0ac'):
        scope = ['https://studio-k7m4.gamemunchies.com', game_id, 'ios', 'test']
        key = 'gamemunchies.v1.' + base64.urlsafe_b64encode(
            json.dumps(scope, separators=(',', ':')).encode()).decode()
        return {'preferencesKey': key, 'state': state,
                'sourceDevice': '2894A85E-04FC-4857-A856-3BEFF2CCB565',
                'sourceAppId': 'dev.pourlune.gamemunchiesValidation'}

    def test_original_fields_and_first_time_survive_unchanged(self):
        original = copy.deepcopy(self.state)
        prepared = self.prepare()
        self.assertEqual(json.loads(prepared['body'])['events'], original['events'])
        self.assertEqual(self.state, original)
        self.assertEqual(prepared['url'],
                         'https://studio-k7m4.gamemunchies.com/api/client/games/'
                         '566121d2-a3f5-4950-8bd9-6ff2f673a0ac/ios/events')

    def test_production_or_overshared_payload_is_rejected_before_network(self):
        for key, value in [('environment', 'production'), ('email', 'unit@example.invalid')]:
            state = copy.deepcopy(self.state)
            state['events'][0][key] = value
            with self.assertRaises(ValueError):
                self.prepare(state)

    def test_missing_id_or_timestamp_is_rejected_not_replaced(self):
        for key in ['id', 'occurredAt', 'installationId']:
            state = copy.deepcopy(self.state)
            del state['events'][0][key]
            with self.assertRaises(ValueError):
                self.prepare(state)

    def test_corrupt_or_empty_or_duplicate_queue_is_rejected(self):
        for events in [[], self.state['events'] * 2]:
            state = {**self.state, 'events': events}
            with self.assertRaises(ValueError):
                self.prepare(state)

    def test_another_game_scope_or_installation_is_rejected(self):
        state = copy.deepcopy(self.state)
        state['events'][0]['installationId'] = 'another-installation'
        with self.assertRaises(ValueError):
            self.prepare(state)
        with self.assertRaises(ValueError):
            probe.prepare(self.snapshot(self.state), platform='web', now=self.now)
        with self.assertRaises(ValueError):
            probe.prepare(self.snapshot(self.state, 'another-game'),
                          platform='ios', now=self.now)

    def test_ack_accepting_new_events_is_not_a_deduplication_pass(self):
        self.assertTrue(probe.duplicate_ack({'accepted': 0, 'received': 1}, 1))
        self.assertFalse(probe.duplicate_ack({'accepted': 1, 'received': 1}, 1))
        self.assertFalse(probe.duplicate_ack({'accepted': 0, 'received': 2}, 1))
        self.assertFalse(probe.duplicate_ack({'accepted': False, 'received': 1}, 1))

    def test_cli_dry_run_never_opens_network_and_receipt_omits_original_ids(self):
        root = Path(__file__).resolve().parents[2] / 'build/gamemunchies-integration/runtime-private'
        root.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='unit-probe-', dir=root) as directory:
            source = Path(directory) / 'synthetic-unit-only.json'
            receipt = Path(directory) / 'receipt.json'
            state = copy.deepcopy(self.state)
            state['events'][0]['occurredAt'] = dt.datetime.now(dt.timezone.utc).isoformat()
            source.write_text(json.dumps(self.snapshot(state)))
            source.chmod(0o600)
            with patch('sys.argv', ['probe', '--snapshot', str(source), '--platform', 'ios',
                                    '--receipt', str(receipt)]), \
                 patch.object(probe.urllib.request, 'build_opener', side_effect=AssertionError('network forbidden')), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(probe.main(), 0)
            text = receipt.read_text()
            self.assertNotIn('unit-only-installation', text)
            self.assertNotIn('round:unit-only-instance', text)
            self.assertFalse(json.loads(text)['sent'])


if __name__ == '__main__':
    unittest.main()
