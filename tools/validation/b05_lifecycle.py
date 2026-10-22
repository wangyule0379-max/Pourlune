#!/usr/bin/env python3
"""Run the B05 QA entrypoint already installed on iOS Simulator.
Only dev.pourlune.b05Validation is launched/killed. No installs, user DB deletes,
production config or device performance claims. Reads/copies QA sandbox evidence.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import sqlite3
import subprocess
import time
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--reveal-only', action='store_true', help='Run only the focused reveal-interruption regression')
    args = parser.parse_args()
    bundle = 'dev.pourlune.b05Validation'
    args.out.mkdir(parents=True, exist_ok=True)
    events = []

    def run(*cmd, check=True):
        p = subprocess.run(cmd, text=True, capture_output=True)
        events.append(dict(command=list(cmd), exit_code=p.returncode, stdout=p.stdout, stderr=p.stderr))
        (args.out / 'commands.json').write_text(json.dumps(events, indent=2) + '\n')
        if check and p.returncode:
            raise RuntimeError(f'{cmd}: {p.stderr}')
        return p.stdout.strip()

    container = Path(run('xcrun', 'simctl', 'get_app_container', args.device, bundle, 'data'))
    binary = Path(run('xcrun', 'simctl', 'get_app_container', args.device, bundle, 'app')) / 'Runner'
    executable_hash = hashlib.sha256(binary.read_bytes()).hexdigest()
    sandbox = container / 'Documents/b05-lifecycle-evidence'
    sandbox.mkdir(parents=True, exist_ok=True)
    results = []

    def read_when(name, predicate=lambda x: True, timeout=90):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            try:
                data = json.loads((sandbox / name).read_text())
                if predicate(data):
                    if data.get('error'):
                        raise RuntimeError(data)
                    return data
            except (FileNotFoundError, json.JSONDecodeError):
                pass
            time.sleep(0.02)
        raise TimeoutError(f'Timed out waiting for {name}')

    def launch():
        (sandbox / 'ready.json').unlink(missing_ok=True)
        start = time.monotonic()
        run('xcrun', 'simctl', 'launch', args.device, bundle)
        data = read_when('ready.json')
        data['host_launch_to_ready_ms'] = round((time.monotonic() - start) * 1000, 2)
        assert Path(run('xcrun', 'simctl', 'get_app_container', args.device, bundle, 'data')) == container
        assert hashlib.sha256(binary.read_bytes()).hexdigest() == executable_hash
        return data

    def command(action, wait=True, **values):
        identity = str(uuid.uuid4())
        payload = {'id': identity, 'action': action, **values}
        temporary = sandbox / 'pending.json'
        temporary.write_text(json.dumps(payload))
        temporary.replace(sandbox / 'command.json')
        return read_when('result.json', lambda d: d.get('id') == identity) if wait else identity

    def kill(data):
        process = int(data['pid'])
        actual = run('ps', '-p', str(process), '-o', 'command=')
        assert str(binary) in actual, (process, actual, str(binary))
        os.kill(process, signal.SIGKILL)
        events.append({'command': ['kill', '-9', str(process)], 'exit_code': 0})
        (args.out / 'commands.json').write_text(json.dumps(events, indent=2) + '\n')

    def capture(name, data):
        (args.out / f'{name}.json').write_text(json.dumps(data, indent=2) + '\n')
        if (sandbox / 'latest.png').exists():
            shutil.copy2(sandbox / 'latest.png', args.out / f'{name}.png')
        db = container / 'Documents/b05_lifecycle.sqlite'
        with sqlite3.connect(f'file:{db}?mode=ro', uri=True) as connection:
            assert connection.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
            assert connection.execute('PRAGMA user_version').fetchone()[0] == 5
            state = connection.execute("SELECT payload FROM active_slots WHERE slot='ordinary'").fetchone()
            assert json.loads(state[0]) == data['current']
        print(name, 'PASS', flush=True)

    run('xcrun', 'simctl', 'terminate', args.device, bundle, check=False)
    launches = [launch()]
    # Seven exact boundaries, on the SAME installation, actual abrupt process death.
    stages = ('reveal',) if args.reveal_only else ('before', 'snapshot', 'completion', 'piece', 'receipt', 'after', 'reveal')
    for stage in stages:
        before = command('prepare12')
        (sandbox / 'barrier.json').unlink(missing_ok=True)
        command('finish', wait=False, stage=stage)
        barrier = read_when('barrier.json')
        assert barrier['stage'] == stage
        if stage == 'reveal':
            assert 0 < barrier.get('reveal_opacity', 0) < 1, 'Must observe actual active reveal before kill'
            assert barrier['scene_images_decoded'] == 4, 'Base + three owned pieces must be decoded before interruption'
            assert barrier['reveal_opacity'] < .95
            assert time.time() * 1000 - barrier['reveal_sampled_ms'] < 150, 'Kill must follow observed active frame promptly'
            assert 'color_studio:3' not in barrier['revealed']
            shutil.copy2(sandbox / 'reveal-mid.png', args.out / 'reveal-interrupted.png')
        kill(barrier)
        restored = launch()
        assert restored['daily'] == before['daily'] and restored['daily']['move_count'] == 1
        launches.append(restored)
        if stage in ('after', 'reveal'):
            assert restored['current']['completed']
            assert restored['first'] == 12 and restored['counter'] == 2
            assert restored['pieces'].count('color_studio:3') == 1
        else:
            assert restored['current'] == before['current']
            assert restored['first'] == 11 and restored['counter'] == 1
            assert 'color_studio:3' not in restored['pieces']
            command('finish-restored')
        if stage == 'reveal':
            assert 'color_studio:3' not in restored['revealed']
            reentered = command('reveal-restored')
            assert 0 < reentered['reveal_opacity'] < 1
            capture('reveal-restored-presentation', reentered)
            acknowledged = command('acknowledge-reveal')
            assert acknowledged['revealed'].count('color_studio:3') == 1
            revisited = command('visit-collection')
            assert revisited['page'] == 'scene' and 'color_studio' in revisited['rendered_scenes']
            assert revisited['rendered_reveals'] == [], 'Revisit must not restart awarded reveal'
            capture('reveal-acknowledged-no-repeat', revisited)
            kill(revisited)
            relaunched = launch()
            assert relaunched['revealed'].count('color_studio:3') == 1
            assert relaunched['first'] == 12 and relaunched['receipts'] == 12
            assert relaunched['daily'] == before['daily']
            second_visit = command('visit-collection')
            assert second_visit['rendered_reveals'] == []
        final = command('inspect')
        assert final['daily'] == before['daily']
        assert final['first'] == 12 and final['counter'] == 2
        assert final['pieces'].count('color_studio:3') == 1
        assert final['receipts'] == 12
        assert final['current']['completed']
        capture('settlement-' + stage, final)
        results.append({'stage': stage, 'barrier': barrier, 'restored': restored, 'final': final})

    if args.reveal_only:
        (args.out / 'reveal-only.json').write_text(json.dumps({'status': 'passed', 'cases': results}, indent=2) + '\n')
        print('B05_REVEAL_ONLY_PASS', flush=True)
        return

    command('prepare11')
    (sandbox / 'barrier.json').unlink(missing_ok=True)
    command('pour-animation', wait=False)
    during = read_when('barrier.json')
    assert during['motion'], 'Must actually kill while production animation is active'
    kill(during)
    restored = launch()
    assert restored['daily'] == during['daily']
    assert restored['current'] == during['current']
    assert not restored['motion']
    after_undo = command('undo')
    assert after_undo['current']['move_count'] == 0
    assert after_undo['current']['board'] == after_undo['current']['puzzle']['initial_bottom_to_top']
    capture('animation-restored-undo', after_undo)
    results.append({'stage': 'animation', 'during': during, 'restored': restored})

    command('prepare-reward')
    pending = command('reward-pending')
    kill(pending)
    restored = launch()
    assert restored['current']['puzzle']['main_level'] == 3
    assert len(restored['entitlements']) == 1
    assert restored['rewards'][0]['status'] == 'pending_restore'
    granted = command('restore-reward')
    assert granted['current']['puzzle']['main_level'] == 13
    assert granted['current']['extra_bottle_granted']
    assert len(granted['entitlements']) == 1
    assert granted['daily'] == restored['daily']
    capture('controlled-confirmed-reward-restored', granted)

    unconfirmed = command('prepare-reward')
    kill(unconfirmed)
    restored = launch()
    assert not restored['current']['extra_bottle_granted']
    assert not restored['entitlements']
    assert restored['rewards'][0]['status'] == 'unconfirmed'
    capture('unconfirmed-no-reward', command('inspect'))

    command('prepare-reward')
    (sandbox / 'barrier.json').unlink(missing_ok=True)
    command('reward-uncommitted', wait=False)
    barrier = read_when('barrier.json')
    assert barrier['stage'] == 'reward_grant'
    kill(barrier)
    restored = launch()
    assert not restored['current']['extra_bottle_granted'] and not restored['entitlements']
    assert restored['rewards'][0]['confirmed'] == 0
    capture('controlled-confirmation-uncommitted', command('inspect'))

    command('prepare11')
    diagnostic = command('diagnose')
    capture('diagnostic-stability', diagnostic)
    shutil.copy2(sandbox / 'diagnostics.json', args.out / 'diagnostics.json')
    (args.out / 'lifecycle.json').write_text(json.dumps({
        'status': 'passed', 'scope': 'Simulator debug, formal bundled content, real native SQLite/abrupt process death; controlled reward confirmations, no SDK earn',
        'bundle': bundle, 'same_container': str(container), 'same_executable_sha256': executable_hash,
        'settlement_and_animation': results, 'launches': launches,
        'reward_cases': 3,
    }, indent=2) + '\n')
    print('B05_LIFECYCLE_PASS', flush=True)


if __name__ == '__main__':
    main()
