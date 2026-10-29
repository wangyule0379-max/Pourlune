"""Read-only review of already-exported dedicated QA data. No device or SDK calls."""
from pathlib import Path
import collections
import hashlib
import json
import sqlite3
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[4]
PRIVATE = ROOT / 'build/google-play-latest-20261029'
OUT = Path(__file__).with_suffix('.json')

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def db(folder, normal=False):
    p = PRIVATE / folder / ('gm_020_normal_20261028.sqlite' if normal else 'gm_020_recovery_20261028.sqlite')
    c = sqlite3.connect(f'file:{p}?mode=ro')
    assert c.execute('pragma integrity_check').fetchone()[0] == 'ok'
    assert c.execute('pragma user_version').fetchone()[0] == 5
    return c, p

def rows(c, table):
    return sorted(c.execute('select * from ' + table).fetchall())

def varint(b, i):
    v = shift = 0
    while True:
        x = b[i]; i += 1; v |= (x & 127) << shift
        if x < 128:
            return v, i
        shift += 7

def fields(b):
    i = 0
    while i < len(b):
        k, i = varint(b, i); typ = k & 7
        if typ == 2:
            n, i = varint(b, i); v = b[i:i+n]; i += n
        elif typ == 0:
            v, i = varint(b, i)
        elif typ in (1, 5):
            n = 8 if typ == 1 else 4; v = b[i:i+n]; i += n
        else:
            raise ValueError(typ)
        yield k >> 3, typ, v

def sdk(folder):
    p = PRIVATE / folder / 'files/datastore/FlutterSharedPreferences.preferences_pb'
    found = []
    for num, typ, entry in fields(p.read_bytes()):
        assert num == 1 and typ == 2
        kv = {n:v for n,t,v in fields(entry)}
        key = kv[1].decode()
        for n,t,v in fields(kv[2]):
            if n != 5 or t != 2:
                continue
            try:
                state = json.loads(v)
            except (ValueError, UnicodeDecodeError):
                continue
            if isinstance(state, dict) and 'configEnvelope' in state and 'installationId' in state:
                found.append((key, state))
    assert len(found) == 1
    return found[0][1]

committed, _ = db('private-r2-reward-committed')
restart, _ = db('private-r2-reward-restart')
off, offpath = db('private-r2-off-ad-fast-restart')
normal, normalpath = db('private-normal-after-flow', True)
for table in ['active_slots', 'reward_attempts', 'reward_entitlements']:
    assert rows(committed, table) == rows(restart, table) == rows(off, table)
active = json.loads(off.execute('select payload from active_slots where slot="ordinary"').fetchone()[0])
assert active['extra_bottle_granted'] and len(active['board']) == 5
assert off.execute('select count(*) from reward_entitlements').fetchone()[0] == 1
assert off.execute("select count(*) from reward_attempts where status='done' and confirmed=1").fetchone()[0] == 1
assert off.execute("select count(*) from reward_attempts where status in ('open','unconfirmed','pending_restore')").fetchone()[0] == 0
assert off.execute('select count(*) from reward_entitlements e join reward_attempts a on e.attempt_id=a.attempt_id and e.instance_id=a.instance_id where e.instance_id=?', (active['instance_id'],)).fetchone()[0] == 1
shows = dict(off.execute('select kind,count(*) from fullscreen_shows group by kind'))
assert shows == {'interstitial': 2, 'rewarded': 2}
for c in [off, normal]:
    assert json.loads(c.execute("select value from service_values where key='privacy_choices'").fetchone()[0]) == {'analytics': False, 'crash': False}
states = [sdk(n) for n in ['private-r2-reward-committed', 'private-r2-reward-restart', 'private-r2-off-ad-fast-restart', 'private-normal-after-flow']]
assert len({s['installationId'] for s in states}) == 1
assert all(not s['events'] for s in states)
assert states[2]['lastShownAt'] and states[3]['lastShownAt'] == states[2]['lastShownAt']

export = PRIVATE / 'private-r2-off-ad-fast-restart'
processes = {d.name.rsplit('-',1)[-1]: d for d in export.glob('gm-020-evidence-recovery/process-*')}
for pid in ['8738','9089']:
    d = processes[pid]; s = json.loads((d/'status.json').read_text())
    assert s['statistics'] is False and s['queued'] == 0 and s['cooldownSeconds'] > 0
    assert s['adConsent'] and s['interstitial'] == 'ready' and s['sdkCooldownSaved']
    http = json.loads((d/'http.json').read_text()) if (d/'http.json').exists() else []
    assert all(h['method'] != 'POST' for h in http)
    assert not list(d.glob('*batch*'))
acks = json.loads((processes['5188']/'acks.json').read_text())['acks']
assert sum(a['received'] for a in acks) == sum(a['accepted'] for a in acks) == 16
restart_events = json.loads((processes['6633']/'last-batch.private.json').read_text())
assert [e['type'] for e in restart_events] == ['active']
offline = json.loads((processes['6350']/'acks.json').read_text())
assert offline['acks'][0]['accepted'] == 3 and offline['acks'][1]['accepted'] == 4 and offline['acks'][1]['received'] == 7
assert offline['retry_kept_original_ids_and_first_times'] and offline['originals_deduplicated']
unchanged = [p.name for p in (PRIVATE/'private-r2-reward-committed').glob('*.sqlite') if p.name != offpath.name and digest(p) == digest(export/p.name)]
assert len(unchanged) == 5

def pour(board, source, target, capacity):
    b = [list(x) for x in board]
    assert b[source] and (not b[target] or b[target][-1] == b[source][-1])
    color = b[source][-1]; run = 0
    for x in reversed(b[source]):
        if x != color:
            break
        run += 1
    count = min(run, capacity-len(b[target])); assert count > 0
    b[target].extend(b[source][-count:]); del b[source][-count:]
    return b

normal_summary = {}
for slot, payload in normal.execute('select slot,payload from active_slots'):
    p = json.loads(payload); spec = p['puzzle']; board = spec['initial_bottom_to_top']
    moves = spec['reference_moves'][:2] if slot == 'ordinary' else [{'from_index':0,'to_index':4}]
    for m in moves:
        board = pour(board, m['from_index'], m['to_index'], spec['capacity'])
    assert board == p['board'] and p['move_count'] == len(moves)
    normal_summary[slot] = {'puzzle':spec['puzzle_id'], 'moves':p['move_count'], 'revision':p['board_revision'], 'board_independently_replayed':True}
assert normal.execute('select count(*) from reward_attempts').fetchone()[0] == normal.execute('select count(*) from reward_entitlements').fetchone()[0] == 0
assert digest(normalpath) == '6906664a12923df5cfaa5f60184b81fc1b2c377c829fd08ef32dd665ee346e77'
backend = json.loads((OUT.parent/'backend-test-20261029.json').read_text())['response']
prod = json.loads((OUT.parent/'backend-production-20261029.json').read_text())['response']
assert backend['environment'] == 'test' and backend['funnel']['invalidOrderFlows'] == 0
assert prod['environment'] == 'production' and not prod['hasData']
result = {
    'at':datetime.now(timezone.utc).isoformat(),
    'status':'PASS_BOUNDED_ANDROID_QA_NATIVE_AND_BACKEND_EVIDENCE_REVIEW',
    'parent_method':'SQLite readonly, Android preferences protobuf parse, exported current-process diagnostics, archived actual browser responses; no device interaction or repeated toolchain',
    'source_files_sha256':{'reward_final_sqlite':digest(offpath),'normal_main_sqlite':digest(normalpath)},
    'same_full_active_payload_attempts_and_unique_entitlement_across_restart_and_stats_off':True,
    'fullscreen_shows':shows,
    'sdk_same_installation_and_empty_queues':True,
    'sdk_lastShownAt_saved_and_carried_into_normal_main':True,
    'stats_off_ready_allowed_positive_cooldown_processes':['8738','9089'],
    'no_sdk_POST_or_batch_file_in_two_off_processes':True,
    'other_existing_sqlite_unchanged':5,
    'reward_process_accepted_received':[16,16],
    'restart_event_types':['active'],
    'offline_retry_receipts':[[3,3],[4,7]],
    'offline_id_timestamp_scope':'QA runtime assertion and ACK archive inspected; retained last batch alone does not independently reconstruct every earlier payload',
    'normal_main':normal_summary,
    'final_privacy_analytics_and_crash_off':True,
    'backend_test_totals':backend['totals'],
    'backend_test_funnel':backend['funnel']['stages'],
    'backend_invalid_order':0,
    'production_filtered_hasData':False,
    'limits':['GUI sequence observed by Use Computer; parent independently checked exports, not every new GUI frame', 'Today totals are not version-filtered and include earlier QA; no single-run attribution', 'Production absence only checked today/android/version19 scope; no claim of zero global revenue', 'Debug official-test-ad QA does not prove commercial fill or final minified release startup', 'Synthetic old13 fixture runtime and fixed release19-3 startup remain pending'],
    'upload_approved':False,
}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
