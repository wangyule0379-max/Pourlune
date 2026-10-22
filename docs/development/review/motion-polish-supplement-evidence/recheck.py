"""Independent existing-install MS probe: no build, install or screen capture."""
import hashlib
import json
import subprocess
import time
from pathlib import Path

R = Path('/Volumes/data/App Development/Pourlune')
E = Path(__file__).parent
D = '255890D5-B4A3-42F9-B1A2-409E77118348'
I = 'dev.pourlune.motionSupplementValidation'
P = 'dev.pourlune.motion_supplement'
A = '/Users/wangyule/Library/Android/sdk/platform-tools/adb'
commands = []

def run(*args, check=True):
    p = subprocess.run(args, capture_output=True, text=True, timeout=30)
    commands.append({'argv': list(args), 'code': p.returncode,
                     'stdout': p.stdout, 'stderr': p.stderr})
    (E/'native-commands.json').write_text(json.dumps(commands, indent=2))
    if check and p.returncode:
        raise RuntimeError((args, p.returncode, p.stderr))
    return p.stdout.strip()

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def validate(d, pid):
    assert d['ok'] and d['pid'] == pid and d['prepared_for_next_launch']
    assert d['gesture_count'] == 1 and d['database'].endswith('/motion_supplement.sqlite')
    a = d['accepted']
    assert a['page'] == 'board' and a['phase'] == 'clean'
    assert a['snapshot_writes'] == a['new_instance_count'] == 1
    assert a['revision'] == a['moves'] == 0 and a['instance'] == a['saved_instance']
    assert d['before_gesture']['ordinary'] is None and d['before_gesture']['first_clears'] == 0
    points = [d[k] for k in ['product_main_call_us', 'home_enabled_hit_testable_us',
              'pointer_down_request_us', 'pointer_down_sent_us', 'pointer_up_request_us',
              'first_controller_response_us', 'first_accepted_committed_navigation_us']]
    assert points == sorted(points)
    assert d['initialization_shell_first_post_frame_us'] is not None
    assert d['home_first_post_frame_us'] is not None
    assert not d['captures_screen_or_audio'] and not d['theoretical_earliest_interactive_claim']

inventory = json.loads((R/'docs/development/evidence/motion-polish-supplement/device-inventory.json').read_text())
freeze = json.loads((R/'docs/development/evidence/motion-polish-supplement/freeze.json').read_text())
assert 'Booted' in run('xcrun', 'simctl', 'list', 'devices', D)
assert run(A, '-s', 'emulator-5588', 'emu', 'avd', 'name').splitlines()[0] == 'Pourlune_FullBoard_API36'
summary = {}
for platform in ['ios', 'android']:
    if platform == 'ios':
        data = Path(run('xcrun', 'simctl', 'get_app_container', D, I, 'data'))
        app = Path(run('xcrun', 'simctl', 'get_app_container', D, I, 'app'))
        kernel = 'Frameworks/App.framework/flutter_assets/kernel_blob.bin'
        assert sha(app/kernel) == freeze['ios_app_tree'][kernel]
        identity = str(data)
        run('xcrun', 'simctl', 'terminate', D, I, check=False)
        launched = run('xcrun', 'simctl', 'launch', D, I)
        pid = int(launched.rsplit(':', 1)[1].strip())
    else:
        identity = run(A, '-s', 'emulator-5588', 'shell', 'pm', 'path', P)
        apk = identity.removeprefix('package:')
        assert run(A, '-s', 'emulator-5588', 'shell', 'sha256sum', apk).split()[0] == freeze['android_apk_sha256']
        run(A, '-s', 'emulator-5588', 'shell', 'am', 'force-stop', P)
        run(A, '-s', 'emulator-5588', 'shell', 'am', 'start', '-n', P+'/dev.pourlune.pourlune_dev.MainActivity')
        until = time.monotonic()+15
        pid = 0
        while time.monotonic() < until and not pid:
            raw = run(A, '-s', 'emulator-5588', 'shell', 'pidof', P, check=False)
            if raw:
                pid = int(raw.split()[0])
            else:
                time.sleep(.1)
        assert pid
    deadline = time.monotonic()+45
    report = None
    while time.monotonic() < deadline:
        if platform == 'ios':
            found = list(data.rglob(f'startup-{pid}.json')) + list(data.rglob(f'error-{pid}.json'))
            raw = found[0].read_text() if found else ''
        else:
            raw = run(A, '-s', 'emulator-5588', 'shell', 'run-as', P, 'cat', f'databases/motion-supplement/startup-{pid}.json', check=False)
        if raw:
            report = json.loads(raw)
            break
        time.sleep(.2)
    assert report is not None
    (E/f'{platform}-independent.json').write_text(json.dumps(report, indent=2))
    validate(report, pid)
    if platform == 'ios':
        assert run('xcrun', 'simctl', 'get_app_container', D, I, 'data') == identity
        old = list(Path(inventory['ios']['old_fb_data']).rglob('flame_full_board.sqlite'))
        assert len(old) == 1
        old_sha = sha(old[0])
    else:
        assert run(A, '-s', 'emulator-5588', 'shell', 'pm', 'path', P) == identity
        old_sha = run(A, '-s', 'emulator-5588', 'shell', 'run-as', 'dev.pourlune.pourlune_dev', 'sha256sum', 'databases/flame_full_board.sqlite').split()[0]
    assert old_sha == inventory[platform]['old_db_sha256']
    summary[platform] = {'pid': pid, 'same_install': True, 'old_fb_db_unchanged': True,
                         'one_gesture_one_persisted_instance': True,
                         'accepted_us': report['first_accepted_committed_navigation_us']}
    (E/'native-summary.json').write_text(json.dumps(summary, indent=2))
    print(platform, 'independent existing-install probe PASS', flush=True)
