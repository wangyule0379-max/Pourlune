"""One-shot replay of genuine SDK test observations, never an event producer.

Only use with the human-authorized new GM QA device snapshot. Raw snapshots stay
under ignored build/, mode 0600. Public receipts contain hashes/counts, not IDs.
This is a verification probe, not another application SDK or retry transport.
"""
import argparse
import base64
from collections import Counter
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import sys
import urllib.error
import urllib.request

ORIGIN = 'https://studio-k7m4.gamemunchies.com'
API_ORIGIN = 'https://api.gamemunchies.com'
GAME_ID = '566121d2-a3f5-4950-8bd9-6ff2f673a0ac'
FIELDS = {'id', 'installationId', 'type', 'environment', 'occurredAt'}
TYPES = {'active', 'round_start', 'ad_impression', 'ad_load_failed'}
DEVICES = {'ios': '2894A85E-04FC-4857-A856-3BEFF2CCB565',
           'android': 'Pourlune_GM_QA_20261028'}
APP_IDS = {'ios': 'dev.pourlune.gamemunchiesValidation',
           'android': 'dev.pourlune.pourlune_dev'}


def require(condition, code):
    if not condition:
        raise ValueError(code)


def printable_id(value):
    return isinstance(value, str) and bool(value.strip()) and bool(
        re.fullmatch(r'[\x20-\x7e]{1,128}', value))


def prepare(snapshot, *, platform, now=None, origin=ORIGIN):
    require(origin in {ORIGIN, API_ORIGIN}, 'known_client_origin_required')
    require(platform in {'ios', 'android'}, 'test_mobile_platform_required')
    require(isinstance(snapshot, dict), 'sdk_snapshot_required')
    require(snapshot.get('sourceDevice') == DEVICES[platform] and
            snapshot.get('sourceAppId') == APP_IDS[platform], 'new_qa_device_and_app_required')
    key = snapshot.get('preferencesKey', '')
    if isinstance(key, str) and key.startswith('flutter.'):
        key = key[len('flutter.'):]
    require(isinstance(key, str) and key.startswith('gamemunchies.v1.'),
            'sdk_preferences_key_required')
    try:
        encoded = key[len('gamemunchies.v1.'):]
        scope = json.loads(base64.urlsafe_b64decode(encoded + '=' * (-len(encoded) % 4)))
    except (ValueError, TypeError, UnicodeError):
        raise ValueError('invalid_sdk_scope') from None
    require(scope == [origin, GAME_ID, platform, 'test'], 'wrong_test_scope')
    state = snapshot.get('state')
    require(isinstance(state, dict) and state.get('schemaVersion') == 1,
            'sdk_state_required')
    events = state.get('events')
    require(isinstance(events, list) and 1 <= len(events) <= 50,
            'genuine_nonempty_single_batch_required')
    current = now or dt.datetime.now(dt.timezone.utc)
    ids = set()
    for event in events:
        require(isinstance(event, dict) and set(event) == FIELDS, 'event_fields_rejected')
        require(event['environment'] == 'test' and event['type'] in TYPES,
                'test_events_only')
        require(printable_id(event['id']) and printable_id(event['installationId']),
                'original_ids_required')
        require(event['installationId'] == state.get('installationId'),
                'installation_scope_mismatch')
        require(event['id'] not in ids, 'duplicate_in_source_queue')
        ids.add(event['id'])
        text = event['occurredAt']
        require(isinstance(text, str) and re.fullmatch(
            r'\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)', text),
            'original_utc_time_required')
        try:
            at = dt.datetime.fromisoformat(text.replace('Z', '+00:00'))
        except ValueError:
            raise ValueError('invalid_original_time') from None
        require(current - dt.timedelta(days=30) <= at <= current + dt.timedelta(minutes=5),
                'source_event_outside_server_time_window')
    # Preserve every field, including the very first SDK timestamp and IDs.
    body = json.dumps({'events': events}, separators=(',', ':'), ensure_ascii=True).encode()
    require(len(body) <= 49152, 'source_batch_too_large')
    return {'url': f'{origin}/api/client/games/{GAME_ID}/{platform}/events',
            'body': body, 'event_count': len(events),
            'type_counts': dict(Counter(e['type'] for e in events))}


def duplicate_ack(body, count):
    return isinstance(body, dict) and type(body.get('accepted')) is int and \
        type(body.get('received')) is int and body['accepted'] == 0 and body['received'] == count


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


def main(*, origin=ORIGIN, private_subdirectory='gamemunchies-integration/runtime-private'):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', type=Path, required=True)
    parser.add_argument('--platform', choices=['ios', 'android'], required=True)
    parser.add_argument('--receipt', type=Path, required=True)
    parser.add_argument('--confirm-test-replay', action='store_true',
                        help='Send once after explicit human authorization; otherwise validate only')
    args = parser.parse_args()
    try:
        private_root = Path(__file__).resolve().parents[2] / 'build' / private_subdirectory
        require(args.snapshot.resolve().is_relative_to(private_root.resolve()),
                'raw_snapshot_must_stay_in_ignored_private_qa_directory')
        require(args.snapshot.stat().st_mode & 0o077 == 0, 'raw_snapshot_requires_mode_0600')
        require(args.snapshot.resolve() != args.receipt.resolve(), 'receipt_cannot_overwrite_snapshot')
        require(args.snapshot.stat().st_size <= 1048576, 'sdk_snapshot_too_large')
        source = args.snapshot.read_bytes()
        prepared = prepare(json.loads(source), platform=args.platform, origin=origin)
        result = {'destination': prepared['url'], 'platform': args.platform,
                  'environment': 'test', 'game_id': GAME_ID,
                  'source_sha256': hashlib.sha256(source).hexdigest(),
                  'request_sha256': hashlib.sha256(prepared['body']).hexdigest(),
                  'event_count': prepared['event_count'], 'type_counts': prepared['type_counts'],
                  'raw_ids_or_event_times_in_receipt': False, 'sent': False}
        if args.confirm_test_replay:
            ledger = private_root / ('replayed-' + result['request_sha256'])
            # Mark before any network operation; an uncertain outcome is not
            # permission to retry the human-approved one-shot transmission.
            with ledger.open('x') as marker:
                marker.write('one authorized test replay attempted\n')
            request = urllib.request.Request(prepared['url'], data=prepared['body'],
                                             headers={'Content-Type': 'application/json'}, method='POST')
            # Default TLS validation stays enabled; no cookies/auth or redirects.
            with urllib.request.build_opener(NoRedirect()).open(request, timeout=10) as response:
                ack = json.loads(response.read(65536))
                result.update(sent=True, status=response.status,
                              ack={k: ack.get(k) for k in ['accepted', 'received']},
                              duplicate_pass=duplicate_ack(ack, prepared['event_count']))
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        print(json.dumps(result, ensure_ascii=False))
        return 0 if not result['sent'] or result['duplicate_pass'] else 1
    except (ValueError, OSError, urllib.error.URLError) as error:
        # Never print a server body, raw event, request headers, or credentials.
        print(json.dumps({'error': type(error).__name__,
                          'code': str(error) if isinstance(error, ValueError) else
                          getattr(error, 'code', 'io_or_network')}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
