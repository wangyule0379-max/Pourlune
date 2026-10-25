#!/usr/bin/env python3
"""Drive the isolated native Flame QA app's file protocol, never the normal DB."""
import argparse
import datetime
import json
import re
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = '9B172C50-E5CB-4F3F-8F16-0A3DB04F495D'
IOS = 'dev.pourlune.pourluneDev'
ANDROID = 'dev.pourlune.pourlune_dev'
ADB = ['/Users/wangyule/Library/Android/sdk/platform-tools/adb', '-s', 'emulator-5584']


def run(args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout.strip()


def startup_samples(platform):
    records = []
    if platform == 'ios':
        base = Path(run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'data'])) / 'Documents/flame-sample'
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
                    data = json.loads(run([*ADB, 'exec-out', 'run-as', ANDROID, 'cat', 'databases/flame-sample/startup-' + process + '.json']))
                if str(data['pid']) != process:
                    raise ValueError('PID mismatch')
                break
            except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError):
                if time.monotonic() > end:
                    raise TimeoutError('fresh startup receipt')
                time.sleep(.1)
        records.append({'host_launch_command_ms': launch_ms, **data})
        print(platform, index + 1, 'pid', process, 'ready_us', data['dart_main_to_first_ready_bottle_frame_us'], flush=True)
    output = ROOT / 'docs/development/evidence/flame-sample' / platform
    output.mkdir(parents=True, exist_ok=True)
    (output / 'startup-samples.json').write_text(json.dumps(records, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('platform', choices=['ios', 'android'])
    parser.add_argument('action', choices=['state', 'route', 'capture', 'sample-start', 'sample-end', 'prepare-restore', 'startups'])
    parser.add_argument('--id', default='flame-' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S'))
    parser.add_argument('--timeout', type=int, default=180)
    args = parser.parse_args()
    if args.action == 'startups':
        startup_samples(args.platform)
        return
    if not re.fullmatch('[a-z0-9_-]+', args.id):
        raise ValueError('safe id required')
    if args.platform == 'ios':
        base = Path(run(['xcrun', 'simctl', 'get_app_container', SIM, IOS, 'data'])) / 'Documents/flame-sample'
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
        base = 'databases/flame-sample'
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
            time.sleep(.1)
    output = ROOT / 'docs/development/evidence/flame-sample' / args.platform
    output.mkdir(parents=True, exist_ok=True)
    path = output / (args.id + '.json')
    path.write_text(json.dumps(response, indent=2) + '\n')
    print(json.dumps({'ok': response.get('ok'), 'path': str(path),
                      'steps': len(response.get('steps', [])),
                      'frames': len(response.get('frame_timings', [])),
                      'error': response.get('error')}))
    if response.get('ok') is False:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
