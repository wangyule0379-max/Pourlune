"""Freeze a production candidate; never upload, install or create signing keys.

Uses validated prod Firebase selection (ads disabled unless explicit beta test).
Outputs are immutable named folders inside ignored build/. Requires local prod
client configuration. See tools/validation/README.md for signing handoff.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import time
import zipfile

from ios_signing import ProfileError, inspect_profile
from public_destinations import DestinationError, add_destination_arguments, validate_destinations
from android_signing import SigningError, inspect_signer, sign_aab
from admob_config import AdConfigError, add_arguments as add_ad_arguments, selection as ad_selection
from build_version import BuildError, read_version
from ios_release_plugins import verify_no_test_plugin

ROOT = Path(__file__).resolve().parents[2]


def prepare_output(root, output):
    output = output.resolve()
    build = (root / 'build').resolve()
    if not output.is_relative_to(build) or output == build or output.exists():
        raise BuildError('output_not_new_build_subdirectory')
    output.mkdir(parents=True)
    return output


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sources():
    names = subprocess.check_output([
        'git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--',
        'app', 'packages', 'tools', '.flutter-version', '.github',
    ], cwd=ROOT).decode().split('\0')
    return {name: sha(ROOT / name) for name in sorted(set(names))
            if name and (ROOT / name).is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['ios', 'android'], required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--flutter', default='flutter')
    parser.add_argument('--ios-profile', type=Path,
                        help='Export an IPA using this existing App Store profile')
    add_destination_arguments(parser)
    add_ad_arguments(parser)
    parser.add_argument('--android-keystore', type=Path)
    parser.add_argument('--android-key-alias')
    parser.add_argument('--android-store-password-file', type=Path)
    parser.add_argument('--android-key-password-file', type=Path)
    parser.add_argument('--android-certificate-sha256')
    args = parser.parse_args()
    try:
        destinations = validate_destinations(args.support_url, args.privacy_url, args.feedback_email)
        ads = ad_selection(args.ad_mode, args.platform, 'com.pourlune.app', args.admob_registration)
        version, number = read_version((ROOT / 'app/pubspec.yaml').read_text())
        android_inputs = [args.android_keystore, args.android_key_alias,
                          args.android_store_password_file, args.android_certificate_sha256]
        credentials = None
        if any(android_inputs) or args.android_key_password_file:
            if args.platform != 'android' or not all(android_inputs):
                raise BuildError('android_signing_requires_android_and_complete_explicit_assets')
            credentials = dict(keystore=args.android_keystore, alias=args.android_key_alias,
                               password_file=args.android_store_password_file,
                               key_password_file=args.android_key_password_file,
                               expected_sha256=args.android_certificate_sha256, root=ROOT)
            inspect_signer(**credentials)  # Reject before compiling or allocating output.
        if args.ios_profile and args.platform != 'ios':
            raise BuildError('ios_profile_requires_ios')
        profile = inspect_profile(args.ios_profile) if args.ios_profile else None
        output = prepare_output(ROOT, args.output)
        registration = None
        if args.admob_registration:
            registration = output / 'admob-registration.json'
            registration.write_bytes(args.admob_registration.read_bytes())
            registration.chmod(0o444)
            ads = ad_selection(args.ad_mode, args.platform, 'com.pourlune.app', registration)
        source = sources()
        (output / 'sources.json').write_text(json.dumps(source, indent=2) + '\n')
        environment = dict(os.environ, FIREBASE_ANALYTICS_WITHOUT_ADID='1')
        # No silent caller target, SDK config, signing, AdMob or Dart overrides.
        command = [sys.executable, str(ROOT / 'tools/validation/firebase_build.py'),
                   '--environment', 'prod', '--platform', args.platform,
                   '--flutter', args.flutter, '--ad-mode', args.ad_mode]
        if registration:
            command.extend(['--admob-registration', str(registration)])
        for name, value in destinations.items():
            if name != 'ready' and value:
                command.extend(['--' + name.replace('_', '-'), value])
        if profile:
            command.extend(['--ios-profile', str(args.ios_profile.resolve()),
                            '--ios-output', str(output / 'ios-export')])
        command.extend(['--', 'build',
                   ('ipa' if profile else 'ios') if args.platform == 'ios' else 'appbundle',
                   '--release', f'--build-name={version}',
                   f'--build-number={number}'])
        if args.platform == 'ios' and not profile:
            command.append('--no-codesign')
        began = time.time()
        with (output / 'build.log').open('w') as log:
            result = subprocess.run(command, cwd=ROOT, env=environment,
                                    stdout=log, stderr=subprocess.STDOUT)
        if result.returncode:
            raise BuildError('compile_failed_see_redacted_log')
        if source != sources():
            raise BuildError('source_changed_during_build')
        if ads != ad_selection(args.ad_mode, args.platform, 'com.pourlune.app', registration):
            raise BuildError('ad_registration_changed_during_build')
        if args.platform == 'ios':
            if profile:
                artifacts = list((output / 'ios-export/ipa').glob('*.ipa'))
                if len(artifacts) != 1 or artifacts[0].stat().st_mtime < began:
                    raise BuildError('missing_new_exported_ipa')
                ipa = output / f'Pourlune-{version}-{number}.ipa'
                shutil.copy2(artifacts[0], ipa)
                with zipfile.ZipFile(ipa) as package:
                    package.extractall(output / 'ipa-inspection')
                apps = list((output / 'ipa-inspection/Payload').glob('*.app'))
                if len(apps) != 1:
                    raise BuildError('invalid_ipa_payload')
                artifact = apps[0]
            else:
                artifact = output / 'Runner.app'
                shutil.copytree(ROOT / 'app/build/ios/iphoneos/Runner.app', artifact)
            info = plistlib.loads((artifact / 'Info.plist').read_bytes())
            if (info['CFBundleIdentifier'], info['CFBundleDisplayName'],
                info['CFBundleShortVersionString'], info['CFBundleVersion']) != (
                    'com.pourlune.app', 'Pourlune', version, str(number)):
                raise BuildError('ios_packaging_mismatch')
            if info.get('GADApplicationIdentifier') != ads['app_id']:
                raise BuildError('ios_ad_app_id_mismatch')
            verify_no_test_plugin(artifact / 'Runner')
            for nested in artifact.rglob('Info.plist'):
                if nested == artifact / 'Info.plist':
                    continue
                nested_info = plistlib.loads(nested.read_bytes())
                if nested_info.get('CFBundleIdentifier') == info['CFBundleIdentifier']:
                    raise BuildError('app_identity_leaked_into_embedded_bundle')
            signature = subprocess.run(
                ['codesign', '--verify', '--deep', '--strict', str(artifact)]
                if profile else ['codesign', '-d', '--verbose=4', str(artifact)],
                text=True, capture_output=True)
            if bool(signature.returncode == 0) != bool(profile):
                raise BuildError('unexpected_ios_signature_state')
            if profile:
                metadata = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(artifact)],
                                          capture_output=True)
                ent = plistlib.loads(metadata.stdout)
                if (ent.get('application-identifier') != 'T7U878Z8H6.com.pourlune.app'
                        or ent.get('com.apple.developer.team-identifier') != profile['team']
                        or ent.get('get-task-allow') is not False):
                    raise BuildError('exported_ipa_entitlements_mismatch')
                embedded = inspect_profile(artifact / 'embedded.mobileprovision')
                if embedded['uuid'] != profile['uuid']:
                    raise BuildError('exported_ipa_profile_mismatch')
                (output / 'signing.json').write_text(json.dumps({
                    **profile, 'codesign_verify_deep_strict': True,
                    'application_identifier': ent['application-identifier'],
                    'get_task_allow': False, 'uploaded': False,
                }, indent=2) + '\n')
            hashes = {str(p.relative_to(output)): sha(p)
                      for p in sorted(output.rglob('*')) if p.is_file()
                      and p.name not in {'build.log', 'sources.json'}}
        else:
            artifact = output / 'app-release-unsigned.aab'
            shutil.copy2(ROOT / 'app/build/app/outputs/bundle/release/app-release.aab', artifact)
            signature = subprocess.run(['jarsigner', '-J-Duser.language=en', '-verify',
                                        str(artifact)], text=True, capture_output=True)
            if 'jar is unsigned' not in signature.stdout.lower():
                raise BuildError('unexpected_aab_signature_state')
            hashes = {artifact.name: sha(artifact)}
            if registration:
                hashes[registration.name] = sha(registration)
            if credentials:
                signed = output / f'Pourlune-{version}-{number}-upload-signed.aab'
                signing = sign_aab(artifact, signed, **credentials)
                (output / 'signing.json').write_text(json.dumps(signing, indent=2) + '\n')
                hashes[signed.name] = sha(signed)
                hashes['signing.json'] = sha(output / 'signing.json')
                artifact = signed
        signature_log = signature.stdout + signature.stderr
        if credentials:
            (output / 'unsigned-signature-check.log').write_text(signature_log)
            signature_log = json.dumps(signing, indent=2) + '\n'
        (output / 'signature-check.log').write_text(signature_log)
        manifest = {'status': ('signed local IPA; account/privacy/content gates pending'
                               if profile else 'signed local upload AAB; external gates pending'
                               if credentials else 'compile-only unsigned; not upload-ready'),
                    'platform': args.platform, 'identity': 'com.pourlune.app',
                    'version': version, 'build_number': number,
                    'firebase_environment': 'prod', 'ads': args.ad_mode,
                    'ad_configuration': ads,
                    'collection': ('analytics/crash independent opt-in, defaults off; RC may process installation data'
                                   + ('; test ads/UMP may process IP/device/interaction data'
                                      if args.ad_mode == 'test' else '')),
                    'production_run_or_upload': False,
                    'public_destinations': destinations,
                    'signed_for_upload': bool(profile or credentials),
                    'external_store_gates_verified': False,
                    'git_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                    'source_manifest_sha256': sha(output / 'sources.json'),
                    'artifact': str(artifact), 'files_sha256': hashes}
        (output / 'candidate.json').write_text(json.dumps(manifest, indent=2) + '\n')
        print(json.dumps({'ok': True, 'candidate': str(output / 'candidate.json'),
                          'status': manifest['status']}))
        return 0
    except (BuildError, ProfileError, DestinationError, SigningError, AdConfigError, OSError) as error:
        print(json.dumps({'ok': False, 'code': str(error) if isinstance(error, (BuildError, ProfileError, DestinationError, SigningError, AdConfigError))
                          else 'candidate_io_error'}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
