"""T-R01 normal-main cold-launch capture; isolated identity only, no Dart hooks."""
from pathlib import Path
import argparse
import json
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
APP = 'dev.pourlune.transitionsr01'
SIM = '3497E78D-608C-415C-8326-26E46F1B6E29'
ADB = ['/Users/wangyule/Library/Android/sdk/platform-tools/adb', '-s', 'emulator-5586']


def call(args, check=True):
    return subprocess.run(args, capture_output=True, check=check).stdout


def capture(platform, appearance):
    out = ROOT / f'docs/development/evidence/page-transitions/T-R01/{platform}-{appearance}'
    out.mkdir(parents=True, exist_ok=True)
    raw = ROOT / 'build/page-transitions-r01-candidates'
    raw.mkdir(exist_ok=True)
    name = f'cold-{platform}-{appearance}'
    video = Path('/tmp') / (name + ('.mov' if platform == 'ios' else '.mp4'))
    report = {'platform': platform, 'appearance': appearance, 'identity': APP,
              'target': 'lib/main.dart', 'database': 'ui_transition_r01.sqlite',
              'mode': 'debug process cold start, same install', 'artificial_product_delay': False,
              'performance_pass': False, 'recorded_audio': False}
    log = (out / 'recorder.log').open('wb')
    if platform == 'ios':
        container = Path(call(['xcrun', 'simctl', 'get_app_container', SIM, APP, 'data']).decode().strip())
        stopped = subprocess.run(['xcrun', 'simctl', 'terminate', SIM, APP], capture_output=True)
        report['terminate_exit'] = stopped.returncode
        call(['xcrun', 'simctl', 'ui', SIM, 'appearance', appearance])
        recorder = subprocess.Popen(['xcrun', 'simctl', 'io', SIM, 'recordVideo', '--codec=h264', '--force', str(video)], stdout=log, stderr=log)
        time.sleep(.8)  # Host recorder preparation, never app code.
        report['launch_epoch'] = time.time()
        report['launch_output'] = call(['xcrun', 'simctl', 'launch', SIM, APP]).decode().strip()
        time.sleep(12)  # Observation only: do not delay or drive the app.
        shot = Path('/tmp') / (name + '-home.png')
        call(['xcrun', 'simctl', 'io', SIM, 'screenshot', str(shot)])
        import shutil
        shutil.copy2(shot, out / 'home.png')
        report['database_present'] = (container / 'Documents/ui_transition_r01.sqlite').exists()
        recorder.send_signal(signal.SIGINT)
        recorder.wait(timeout=15)
        report['recorder_exit'] = recorder.returncode
    else:
        if not call([*ADB, 'shell', 'pm', 'path', APP]).decode().strip().startswith('package:'):
            raise RuntimeError('Install the dedicated normal-main R01 candidate first')
        call([*ADB, 'shell', 'am', 'force-stop', APP])
        call([*ADB, 'shell', 'cmd', 'uimode', 'night', 'yes' if appearance == 'dark' else 'no'])
        report['pid_before'] = call([*ADB, 'shell', 'pidof', APP], check=False).decode().strip()
        before = set(call([*ADB, 'shell', 'pidof', 'screenrecord'], check=False).decode().split())
        remote = f'/sdcard/{name}.mp4'
        recorder = subprocess.Popen([*ADB, 'shell', 'screenrecord', '--bit-rate', '2000000', '--time-limit', '30', remote], stdout=log, stderr=log)
        time.sleep(.8)
        owned = set(call([*ADB, 'shell', 'pidof', 'screenrecord'], check=False).decode().split()) - before
        report['launch_epoch'] = time.time()
        report['launch_output'] = call([*ADB, 'shell', 'am', 'start', '-W', '-n', f'{APP}/dev.pourlune.pourlune_dev.MainActivity']).decode().strip()
        time.sleep(12)
        (out / 'home.png').write_bytes(call([*ADB, 'exec-out', 'screencap', '-p']))
        report['pid_after'] = call([*ADB, 'shell', 'pidof', APP], check=False).decode().strip()
        report['database_present'] = 'ui_transition_r01.sqlite' in call([*ADB, 'exec-out', 'run-as', APP, 'ls', 'databases']).decode().split()
        for pid in owned:
            if not pid.isdigit():
                raise RuntimeError('Unexpected recorder PID')
            call([*ADB, 'shell', 'kill', '-2', pid], check=False)
        recorder.wait(timeout=35)
        report['recorder_exit'] = recorder.returncode
        call([*ADB, 'pull', remote, str(video)])
    log.close()
    import shutil
    target = raw / video.name
    shutil.copy2(video, target)
    report['raw_video'] = str(target)
    report['capture_end_epoch'] = time.time()
    (out / 'capture.json').write_text(json.dumps(report, indent=2) + '\n')
    if not report['database_present']:
        raise RuntimeError('Normal main did not create its isolated database')
    if platform == 'android' and (report['pid_before'] or not report['pid_after']):
        raise RuntimeError('Cold process identity check failed')
    print(json.dumps(report))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('platform', choices=['ios', 'android'])
    parser.add_argument('appearance', choices=['light', 'dark'])
    args = parser.parse_args()
    capture(args.platform, args.appearance)
