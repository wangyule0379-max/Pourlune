#!/usr/bin/env python3
"""Drive the isolated full-board normal-main native QA app's file protocol, never the normal DB."""
import argparse
import hashlib
import os
import signal
import shutil
import datetime
import json
import re
import subprocess
import select
import time
from pathlib import Path

ROOT = Path('/Volumes/data/App Development/Pourlune')
SIM = '255890D5-B4A3-42F9-B1A2-409E77118348'
IOS = 'dev.pourlune.fullBoardValidation'
ANDROID = 'dev.pourlune.pourlune_dev'
ADB = ['/Users/wangyule/Library/Android/sdk/platform-tools/adb', '-s', 'emulator-5588']


def run(args):
    return subprocess.run(args, capture_output=True, text=True, check=True, timeout=20).stdout.strip()


def ios_code_signature(app):
    names = ['Runner', 'Runner.debug.dylib', 'Info.plist',
             'Frameworks/App.framework/App',
             'Frameworks/App.framework/flutter_assets/kernel_blob.bin']
    return {name: hashlib.sha256((app / name).read_bytes()).hexdigest()
            for name in names if (app / name).is_file()}


def startup_samples(platform, output, phase):
    records = []
    if platform == 'ios':
        base = Path(run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'data'])) / 'Documents/flame-full-board'
    for index in range(3):
        if platform == 'ios':
            subprocess.run(['xcrun', 'simctl', 'terminate', SIM, IOS], capture_output=True)
            began = time.monotonic()
            process = run(['xcrun', 'simctl', 'launch', SIM, IOS]).rsplit(':', 1)[-1].strip()
        else:
            run([*ADB, 'shell', 'am', 'force-stop', ANDROID])
            began = time.monotonic()
            run([*ADB, 'shell', 'am', 'start', '-n', ANDROID + '/.MainActivity'])
            end = time.monotonic() + 10
            while True:
                try:
                    process = run([*ADB, 'shell', 'pidof', ANDROID])
                    break
                except subprocess.CalledProcessError:
                    if time.monotonic() > end:
                        raise
                    time.sleep(.1)
        launch_ms = round((time.monotonic() - began) * 1000)
        end = time.monotonic() + 40
        while True:
            try:
                if platform == 'ios':
                    data = json.loads((base / ('startup-' + process + '.json')).read_text())
                else:
                    data = json.loads(run([*ADB, 'exec-out', 'run-as', ANDROID, 'cat', 'databases/flame-full-board/startup-' + process + '.json']))
                if data['phase'] != phase:
                    raise RuntimeError('Installed QA binary phase mismatch')
                if str(data['pid']) != process:
                    raise ValueError('PID mismatch')
                break
            except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError):
                if time.monotonic() > end:
                    raise TimeoutError('fresh startup receipt')
                time.sleep(.1)
        records.append({'host_launch_command_ms': launch_ms, **data})
        print(platform, index + 1, 'pid', process, 'ready_us', data['dart_main_to_first_app_host_frame_us'], flush=True)
    output.mkdir(parents=True, exist_ok=True)
    (output / 'startup-samples.json').write_text(json.dumps(records, indent=2) + '\n')



def observation_age(sample_utc, observed_epoch):
    age = observed_epoch - datetime.datetime.fromisoformat(sample_utc).timestamp()
    assert 0 <= age < .25, ('kill must follow the observed move in the same clock domain', age)
    return age


def restore(platform, output, phase, background=False):
    """Observed active move interrupted by actual OS app switch or abrupt kill."""
    script = Path(__file__).resolve()
    def command(action, identity):
        subprocess.run([str(Path(__import__('sys').executable)), str(script), platform, action,
                        '--phase', phase, '--id', identity], check=True)
        return json.loads((output / (identity + '.json')).read_text())
    prefix = 'background' if background else 'restore'
    if platform == 'ios':
        container = run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'data'])
        binary = Path(run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'app'])) / 'Runner'
        signature = ios_code_signature(binary.parent)
    else:
        container = run([*ADB, 'shell', 'run-as', ANDROID, 'pwd'])
        signature = run([*ADB, 'shell', 'dumpsys', 'package', ANDROID])
        signature = '\n'.join(x.strip() for x in signature.splitlines() if any(k in x for k in ['codePath=', 'firstInstallTime=', 'lastUpdateTime=']))
    def lifecycle_snapshot():
        if platform == 'ios':
            return json.loads((Path(container) / 'Documents/flame-full-board/lifecycle.json').read_text())
        return json.loads(run([*ADB, 'exec-out', 'run-as', ANDROID, 'cat', 'databases/flame-full-board/lifecycle.json']))
    def lifecycle_since(state, baseline, process=None):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            try:
                events = lifecycle_snapshot()
                fresh = [e for e in events[baseline:] if process is None or e['pid'] == process]
                if any(e['state'] == state for e in fresh): return fresh
            except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError):
                pass
            time.sleep(.02)
        raise TimeoutError('actual OS ' + state + ' event not observed')
    if background:
        # Warm the OS destination before the short real four-unit action.
        returned = len(lifecycle_snapshot())
        if platform == 'ios':
            run(['xcrun', 'simctl', 'launch', SIM, 'com.apple.Preferences'])
            run(['xcrun', 'simctl', 'launch', SIM, IOS])
        else:
            run([*ADB, 'shell', 'am', 'start', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME'])
            run([*ADB, 'shell', 'am', 'start', '-n', ANDROID + '/.MainActivity'])
        lifecycle_since('resumed', returned)
        command('resume', 'background-prewarm-ready')
    before = command('prepare-restore', prefix + '-during')
    assert before['ok'] and before['motion'] is not None and before['save_phase'] == 'clean'
    assert before['instance'] == before['saved_ordinary']
    assert before['saved_daily'] and before['saved_daily']['move_count'] == 1, 'Run the complete route before two-slot recovery'
    if phase == 'after':
        assert before['visual']['in_stream'] > .02 and before['visual']['out'] < 1
    age = None
    dispatch_age = None
    clock_domain = None
    lifecycle_events = []
    if background:
        dispatched = len(lifecycle_snapshot())
        if platform == 'ios':
            run(['xcrun', 'simctl', 'launch', SIM, 'com.apple.Preferences'])
        else:
            run([*ADB, 'shell', 'am', 'start', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.HOME'])
        lifecycle_events = lifecycle_since('paused', dispatched, before['pid'])
        assert any(e['token'] == before['motion'] for e in lifecycle_events), 'Must interrupt a still-active presentation'
    elif platform == 'ios':
        actual = run(['ps', '-p', str(before['pid']), '-o', 'command='])
        assert str(binary) in actual
        dispatch_age = observation_age(before['utc'], time.time())
        os.kill(before['pid'], signal.SIGKILL)
        age = observation_age(before['utc'], time.time())
        clock_domain = 'simulator and host same OS wall clock; completion checked after SIGKILL'
    else:
        assert run([*ADB, 'shell', 'pidof', ANDROID]) == str(before['pid'])
        stopped = run([*ADB, 'shell', 'run-as', ANDROID, 'sh', '-c', "'date +%s%N; kill -9 " + str(before['pid']) + "; date +%s%N'"])
        epochs = [int(x) / 1e9 for x in stopped.splitlines() if x.isdigit()]
        assert len(epochs) == 2, stopped
        dispatch_age = observation_age(before['utc'], epochs[0])
        age = observation_age(before['utc'], epochs[1])
        clock_domain = 'Android device OS wall clock for app snapshot and pre/post same-UID SIGKILL date; host clock excluded'
        # A SIGKILL signal returns before Android finishes retiring its Activity.
        deadline = time.monotonic() + 10
        while subprocess.run([*ADB, 'shell', 'pidof', ANDROID], capture_output=True).returncode == 0:
            if time.monotonic() > deadline: raise TimeoutError('killed process did not exit')
            time.sleep(.05)
    interrupted = datetime.datetime.now(datetime.timezone.utc).isoformat()
    returning = len(lifecycle_snapshot()) if background else None
    if platform == 'ios':
        run(['xcrun', 'simctl', 'launch', SIM, IOS])
    else:
        run([*ADB, 'shell', 'am', 'start', '-n', ANDROID + '/.MainActivity'])
    if background: lifecycle_since('resumed', returning, before['pid'])
    after = command('resume', prefix + '-after')
    assert after['ok']
    assert (after['pid'] == before['pid']) == background
    assert after['instance'] == before['saved_ordinary'] == after['saved_ordinary']
    assert after['saved_daily'] == before['saved_daily']
    assert after['motion'] is None and after['save_phase'] == 'clean'
    for key in ['settings', 'first_clears', 'receipts', 'pieces', 'revealed']:
        assert after[key] == before[key], key
    assert after['instance']['extra_bottle_granted'] and after['instance']['move_count'] == 7
    if phase == 'after':
        assert after['visual']['active_token'] is None
        assert after['visual']['counts'] == [len(b) for b in after['instance']['board']]
    if platform == 'ios':
        assert run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'data']) == container
        assert ios_code_signature(binary.parent) == signature
    else:
        assert run([*ADB, 'shell', 'run-as', ANDROID, 'pwd']) == container
        final = run([*ADB, 'shell', 'dumpsys', 'package', ANDROID])
        final = '\n'.join(x.strip() for x in final.splitlines() if any(k in x for k in ['codePath=', 'firstInstallTime=', 'lastUpdateTime=']))
        assert final == signature
    undo = command('undo-restored', prefix + '-native-undo')
    assert undo['ok'] and undo['instance']['move_count'] == 6
    assert undo['instance']['extra_bottle_granted']
    assert undo['instance'] == undo['saved_ordinary']
    assert undo['saved_daily'] == before['saved_daily']
    for key in ['first_clears', 'receipts', 'pieces', 'revealed']:
        assert undo[key] == before[key]
    name = 'same-process-background' if background else 'same-install-restore'
    (output / (name + '.json')).write_text(json.dumps({'passed': True, 'interruption_utc': interrupted,
        'method': 'real OS Settings/Launcher app switch' if background else 'abrupt SIGKILL/relaunch (Android run-as same app UID)' if platform == 'android' else 'abrupt SIGKILL/relaunch',
        'observed_lifecycle': lifecycle_events,
        'observation_age_at_kill_completion_seconds': age, 'observation_age_at_dispatch_seconds': dispatch_age, 'clock_domain': clock_domain, 'container': container, 'unchanged_install': signature,
        'during': before, 'restored': after, 'native_undo': undo}, indent=2) + '\n')
    print(platform, name, 'active-pour recovery PASS', flush=True)


def record_route(platform, phase, identity, output):
    raw = ROOT / 'build/flame-full-board-raw'
    raw.mkdir(exist_ok=True)
    name = f'{platform}-{phase}-{identity}'
    movie = Path('/tmp') / (name + '.mp4') if platform == 'ios' else Path('/data/local/tmp') / (name + '.mp4')
    command = ['xcrun', 'simctl', 'io', SIM, 'recordVideo', '--codec=h264', '--force', str(movie)] if platform == 'ios' else [*ADB, 'shell', 'screenrecord', '--size', '720x1600', '--bit-rate', '4000000', '--time-limit', '180', str(movie)]
    began = datetime.datetime.now(datetime.timezone.utc).isoformat()
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    recorder_output = []
    route_code = None
    try:
        deadline = time.monotonic() + 10
        while True:
            if process.poll() is not None: raise RuntimeError('native recorder exited before route')
            if platform == 'ios':
                if select.select([process.stdout], [], [], .1)[0]:
                    line = os.read(process.stdout.fileno(), 4096).decode(errors='replace')
                    recorder_output.append(line)
                    if 'Recording started' in ''.join(recorder_output): break
            else:
                try:
                    if run([*ADB, 'shell', 'pidof', 'screenrecord']): break
                except subprocess.CalledProcessError:
                    pass
            if time.monotonic() >= deadline: raise TimeoutError('native recorder readiness')
        result = subprocess.run([__import__('sys').executable, str(Path(__file__).resolve()), platform,
            'route', '--phase', phase, '--id', identity, '--timeout', '240'], capture_output=True, text=True, timeout=260)
        route_code = result.returncode
        (output / (identity + '-host.log')).write_text(result.stdout + result.stderr)
    finally:
        ended_early = process.poll() is not None
        if process.poll() is None:
            if platform == 'ios':
                process.send_signal(signal.SIGINT)
            else:
                remote = run([*ADB, 'shell', 'pidof', 'screenrecord']).split()
                if len(remote) != 1: raise RuntimeError('ambiguous private-device recorder PID')
                run([*ADB, 'shell', 'kill', '-2', remote[0]])
        tail, _ = process.communicate(timeout=20)
        recorder_output.append(tail.decode(errors='replace'))
        (output / (identity + '-recorder.log')).write_text(''.join(recorder_output))
    destination = raw / (name + '.mp4')
    if platform == 'ios':
        shutil.copy2(movie, destination)
    else:
        run([*ADB, 'pull', str(movie), str(destination)])
    metadata = {'platform': platform, 'phase': phase, 'command': command, 'recording_started_host_utc': began,
                'recording_ended_host_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'route_exit_code': route_code, 'recorder_ended_before_route': ended_early,
                'recorder_exit_code': process.returncode,
                'raw_movie': str(destination), 'sha256': hashlib.sha256(destination.read_bytes()).hexdigest()}
    (output / (identity + '-recording.json')).write_text(json.dumps(metadata, indent=2) + '\n')
    print(json.dumps(metadata), flush=True)
    if route_code != 0 or ended_early: raise SystemExit(1)

def main():
    if not __debug__:
        raise RuntimeError('QA acceptance assertions require Python without -O')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('platform', choices=['ios', 'android'])
    parser.add_argument('action', choices=['state', 'route', 'capture', 'sample-start', 'sample-end', 'prepare-restore', 'prepare-background', 'prepare-startup', 'resume', 'undo-restored', 'startups', 'restore', 'background', 'timed-moves', 'record-route'])
    parser.add_argument('--id', default='board-' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S'))
    parser.add_argument('--timeout', type=int, default=180)
    parser.add_argument('--phase', required=True, choices=['before', 'after'])
    args = parser.parse_args()
    output = ROOT / 'docs/development/review/flame-full-board-evidence' / args.platform / args.phase
    output.mkdir(parents=True, exist_ok=True)
    if args.platform == 'ios':
        devices = json.loads(run(['xcrun', 'simctl', 'list', 'devices', 'available', '-j']))['devices']
        device = next(d for group in devices.values() for d in group if d['udid'] == SIM)
        if device['name'] != 'Pourlune-FB-Review-20261022' or device['state'] != 'Booted':
            raise RuntimeError('Only the explicit full-board simulator may be used')
    elif run([*ADB, 'emu', 'avd', 'name']).splitlines()[0] != 'Pourlune_FullBoard_API36':
        raise RuntimeError('Only the explicit full-board AVD may be used')
    if args.action == 'record-route':
        if not re.fullmatch('[a-z0-9_-]+', args.id): raise ValueError('safe id required')
        record_route(args.platform, args.phase, args.id, output)
        return
    if args.action in ('restore', 'background'):
        restore(args.platform, output, args.phase, background=args.action == 'background')
        return
    if args.action == 'startups':
        startup_samples(args.platform, output, args.phase)
        return
    if not re.fullmatch('[a-z0-9_-]+', args.id):
        raise ValueError('safe id required')
    if args.platform == 'ios':
        base = Path(run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'data'])) / 'Documents/flame-full-board'
        command = base / 'command.json'
        if not base.is_dir():
            raise RuntimeError('QA startup receipt must exist before commands')
        def read():
            return json.loads((base / (args.id + '.json')).read_text())
        # Reusing an explicit QA id must never return a previous response.
        (base / (args.id + '.json')).unlink(missing_ok=True)
        temporary = base / ('command-' + args.id + '.tmp')
        temporary.write_text(json.dumps({'id': args.id, 'action': args.action}))
        temporary.replace(command)
    else:
        base = 'databases/flame-full-board'
        # run-as checks the debuggable installed identity; the exact named app
        # protocol is inside its sandbox, never external/shared files.
        data = json.dumps({'id': args.id, 'action': args.action})
        run([*ADB, 'shell', 'run-as', ANDROID, 'rm', '-f', base + '/' + args.id + '.json'])
        temporary = base + '/command-' + args.id + '.tmp'
        subprocess.run([*ADB, 'shell', 'run-as', ANDROID, 'tee', temporary], input=data,
                       text=True, capture_output=True, check=True)
        run([*ADB, 'shell', 'run-as', ANDROID, 'mv', temporary, base + '/command.json'])
        def read():
            return json.loads(run([*ADB, 'exec-out', 'run-as', ANDROID, 'cat', base + '/' + args.id + '.json']))
    deadline = time.monotonic() + args.timeout
    while True:
        try:
            response = read()
            break
        except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError):
            if time.monotonic() >= deadline:
                raise TimeoutError(args.id)
            time.sleep(.01 if args.action == 'prepare-restore' else .1)
    if response.get('phase', args.phase) != args.phase:
        raise RuntimeError('Installed QA binary phase mismatch')
    path = output / (args.id + '.json')
    path.write_text(json.dumps(response, indent=2) + '\n')
    print(json.dumps({'ok': response.get('ok'), 'path': str(path),
                      'steps': len(response.get('steps', [])),
                      'frames': len(response.get('frame_timings', [])),
                      'error': response.get('error')}))
    if args.action in ('route', 'capture') and response.get('ok'):
        screens = output / ('screens-' + args.id)
        screens.mkdir(exist_ok=True)
        if args.platform == 'ios':
            for item in (base / 'screens').iterdir():
                if item.is_file(): shutil.copy2(item, screens / item.name)
        else:
            for name in run([*ADB, 'shell', 'run-as', ANDROID, 'ls', base + '/screens']).splitlines():
                if not re.fullmatch(r'[a-z0-9_.-]+', name): raise ValueError('safe QA filename')
                data = subprocess.run([*ADB, 'exec-out', 'run-as', ANDROID, 'cat', base + '/screens/' + name], capture_output=True, check=True).stdout
                (screens / name).write_bytes(data)
    if response.get('ok') is False:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
