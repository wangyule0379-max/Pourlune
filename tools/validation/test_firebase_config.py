"""Exercise the config CLI with synthetic native files, never real credentials."""
import copy
import base64
import json
from pathlib import Path
import plistlib
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

from firebase_symbols import upload_symbols
from firebase_config import ConfigError


SCRIPT = Path(__file__).with_name("firebase_config.py")
FAKE_KEY = "AIza" + "x" * 35


class FirebaseConfigTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.registry = self.root / "registration.json"
        self.matrix = {"environments": {}}
        for env, number in [("dev", "123456"), ("prod", "789012")]:
            apps = {}
            for platform, suffix in [("ios", "aabb"), ("android", "ccdd")]:
                native_id = (
                    "com.pourlune.app" if env == "prod" else
                    "dev.pourlune.pourluneDev" if platform == "ios" else
                    "dev.pourlune.pourlune_dev"
                )
                apps[platform] = {
                    "app_id": f"1:{number}:{platform}:{suffix}",
                    "native_id": native_id,
                }
                folder = self.root / env / platform
                folder.mkdir(parents=True)
                options = {
                    "apiKey": FAKE_KEY,
                    "appId": apps[platform]["app_id"],
                    "projectId": f"pourlune-{env}-fixture",
                    "messagingSenderId": number,
                }
                if platform == "ios":
                    options["iosBundleId"] = native_id
                    native = {
                        "API_KEY": FAKE_KEY,
                        "GOOGLE_APP_ID": apps[platform]["app_id"],
                        "PROJECT_ID": f"pourlune-{env}-fixture",
                        "GCM_SENDER_ID": number,
                        "BUNDLE_ID": native_id,
                    }
                    (folder / "GoogleService-Info.plist").write_bytes(
                        plistlib.dumps(native)
                    )
                else:
                    native = {
                        "project_info": {
                            "project_id": f"pourlune-{env}-fixture",
                            "project_number": number,
                        },
                        "client": [{
                            "client_info": {
                                "mobilesdk_app_id": apps[platform]["app_id"],
                                "android_client_info": {"package_name": native_id},
                            },
                            "api_key": [{"current_key": FAKE_KEY}],
                        }],
                    }
                    (folder / "google-services.json").write_text(json.dumps(native))
                (folder / "options.json").write_text(json.dumps(options))
            self.matrix["environments"][env] = {
                "project_id": f"pourlune-{env}-fixture",
                "project_number": number,
                "apps": apps,
            }
        self.registry.write_text(json.dumps(self.matrix))

    def run_cli(self, env="dev", platform="ios"):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--environment", env,
             "--platform", platform, "--config-dir", str(self.root),
             "--registry", str(self.registry)],
            text=True, capture_output=True,
        )

    def assert_rejected(self, env="dev", platform="ios"):
        result = self.run_cli(env, platform)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(FAKE_KEY, result.stdout + result.stderr)
        self.assertNotIn("Traceback", result.stdout + result.stderr)

    def change_options(self, field, value, env="dev", platform="ios"):
        p = self.root / env / platform / "options.json"
        data = json.loads(p.read_text())
        if value is None:
            del data[field]
        else:
            data[field] = value
        p.write_text(json.dumps(data))

    def test_four_matching_native_configs_pass_and_output_only_public_summary(self):
        for env, platform, native in [
            ("dev", "ios", "dev.pourlune.pourluneDev"),
            ("dev", "android", "dev.pourlune.pourlune_dev"),
            ("prod", "ios", "com.pourlune.app"),
            ("prod", "android", "com.pourlune.app"),
        ]:
            with self.subTest(env=env, platform=platform):
                result = self.run_cli(env, platform)
                self.assertEqual(result.returncode, 0, result.stderr)
                public = json.loads(result.stdout)
                self.assertTrue(public["ok"])
                self.assertEqual(public["native_id"], native)
                self.assertEqual(public["project_id"], f"pourlune-{env}-fixture")
                self.assertNotIn(FAKE_KEY, result.stdout + result.stderr)
                self.assertNotIn("apiKey", public)

    def test_options_cannot_choose_another_project_platform_app_or_bundle(self):
        for field, value in [
            ("projectId", "fishpilot-staging"),
            ("appId", "1:123456:android:ccdd"),
            ("appId", "1:123456:ios:ffff"),
            ("messagingSenderId", "999999"),
            ("iosBundleId", "com.pourlune.app"),
            ("apiKey", "AIza" + "y" * 35),
        ]:
            p = self.root / "dev/ios/options.json"
            saved = p.read_bytes()
            with self.subTest(field=field, value=value):
                self.change_options(field, value)
                self.assert_rejected()
            p.write_bytes(saved)

    def test_missing_fields_or_service_account_shapes_are_rejected(self):
        p = self.root / "dev/ios/options.json"
        saved = p.read_bytes()
        for field in ["apiKey", "appId", "messagingSenderId", "projectId", "iosBundleId"]:
            with self.subTest(field=field):
                self.change_options(field, None)
                self.assert_rejected()
            p.write_bytes(saved)
        self.change_options("private_key", "DO_NOT_PRINT_PRIVATE_SENTINEL")
        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("DO_NOT_PRINT_PRIVATE_SENTINEL", result.stdout + result.stderr)

    def test_native_bundle_and_android_client_must_match_registration(self):
        p = self.root / "dev/ios/GoogleService-Info.plist"
        native = plistlib.loads(p.read_bytes())
        native["BUNDLE_ID"] = "com.fishtk.fishpilot"
        p.write_bytes(plistlib.dumps(native))
        self.assert_rejected()
        p = self.root / "dev/android/google-services.json"
        native = json.loads(p.read_text())
        native["client"][0]["client_info"]["android_client_info"]["package_name"] = "com.pourlune.app"
        p.write_text(json.dumps(native))
        self.assert_rejected(platform="android")

    def test_native_project_sender_and_app_are_checked_even_if_options_agree(self):
        p = self.root / "dev/ios/GoogleService-Info.plist"
        original = plistlib.loads(p.read_bytes())
        for field, value in [
            ("PROJECT_ID", "pourlune-prod-fixture"),
            ("GCM_SENDER_ID", "789012"),
            ("GOOGLE_APP_ID", "1:123456:ios:ffff"),
        ]:
            with self.subTest(field=field):
                native = copy.deepcopy(original)
                native[field] = value
                p.write_bytes(plistlib.dumps(native))
                self.assert_rejected()
        p.write_bytes(plistlib.dumps(original))

    def test_registration_cannot_rebind_pourlune_to_foreign_project_or_identity(self):
        for field, value in [("project_id", "fishpilot-staging"), ("project_number", "999999")]:
            altered = copy.deepcopy(self.matrix)
            altered["environments"]["dev"][field] = value
            self.registry.write_text(json.dumps(altered))
            self.assert_rejected()
        altered = copy.deepcopy(self.matrix)
        altered["environments"]["dev"]["apps"]["ios"]["native_id"] = "com.fishtk.fishpilot"
        self.registry.write_text(json.dumps(altered))
        self.assert_rejected()

    def test_missing_or_malformed_files_fail_without_echoing_contents(self):
        p = self.root / "dev/ios/options.json"
        p.write_text('{"apiKey":"' + FAKE_KEY + '", broken SECRET_SENTINEL')
        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(FAKE_KEY, result.stdout + result.stderr)
        self.assertNotIn("SECRET_SENTINEL", result.stdout + result.stderr)
        p.unlink()
        self.assert_rejected()

    def test_malformed_native_xml_is_a_redacted_failure_not_a_traceback(self):
        (self.root / "dev/ios/GoogleService-Info.plist").write_text(
            '<plist><dict><key>API_KEY</key><string>' + FAKE_KEY + '</bad>'
        )
        self.assert_rejected()

    def symbol_environment(self):
        product = self.root / 'Runner.app'
        product.mkdir()
        shutil.copy(self.root / 'dev/ios/GoogleService-Info.plist', product)
        (product / 'Runner').write_bytes(b'fixture-binary')
        dsym = self.root / 'Runner.app.dSYM/Contents/Resources/DWARF'
        dsym.mkdir(parents=True)
        (dsym / 'Runner').write_bytes(b'fixture-dwarf')
        return {
            'POURLUNE_FIREBASE_UPLOAD_SYMBOLS': 'YES',
            'POURLUNE_FIREBASE_ENV': 'dev',
            'POURLUNE_FIREBASE_CONFIG_DIR': str(self.root),
            'POURLUNE_FIREBASE_REGISTRY': str(self.registry),
            'PRODUCT_BUNDLE_IDENTIFIER': 'dev.pourlune.pourluneDev',
            'TARGET_BUILD_DIR': str(self.root),
            'UNLOCALIZED_RESOURCES_FOLDER_PATH': 'Runner.app',
            'EXECUTABLE_PATH': 'Runner.app/Runner',
            'DWARF_DSYM_FOLDER_PATH': str(self.root),
            'DWARF_DSYM_FILE_NAME': 'Runner.app.dSYM',
            'PRODUCT_NAME': 'Runner',
            'BUILD_DIR': str(self.root / 'Build/Products'),
            'DART_DEFINES': ','.join(base64.b64encode(f'{k}={v}'.encode()).decode()
                                     for k, v in self.defines('dev', 'ios')),
        }

    def test_symbols_explicit_dev_upload_receipt_binds_target_binary_and_uuid(self):
        env = self.symbol_environment()
        calls = []
        def run(command, **kwargs):
            calls.append(command)
            return subprocess.CompletedProcess(command, 0,
                'UUID: 01234567-0123-0123-0123-0123456789AB (arm64) fixture\n', '')
        receipt = upload_symbols(env, run)
        self.assertEqual(receipt['app_id'], '1:123456:ios:aabb')
        self.assertEqual(receipt['status'], 'uploader_exit_0')
        self.assertEqual(receipt['uuids'], ['01234567-0123-0123-0123-0123456789AB'])
        self.assertEqual(len(receipt['binary_sha256']), 64)
        self.assertEqual(calls[-1][-1], str(self.root / 'Runner.app.dSYM'))
        self.assertIn('SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols', calls[-1][0])
        self.assertNotIn(FAKE_KEY, json.dumps(receipt))

    def test_symbols_off_skips_and_production_upload_rejects_before_process(self):
        def forbidden(*args, **kwargs):
            self.fail('uploader should never start')
        self.assertEqual(upload_symbols({}, forbidden), {'status': 'disabled'})
        with self.assertRaises(ConfigError):
            upload_symbols({'POURLUNE_FIREBASE_ENV': 'prod',
                            'POURLUNE_FIREBASE_UPLOAD_SYMBOLS': 'YES'}, forbidden)

    def test_symbols_support_flutter_flat_build_directory(self):
        env = self.symbol_environment()
        env['BUILD_DIR'] = str(self.root / 'ios')
        calls = []
        def run(command, **kwargs):
            calls.append(command)
            return subprocess.CompletedProcess(command, 0,
                'UUID: 01234567-0123-0123-0123-0123456789AB (arm64) x', '')
        upload_symbols(env, run)
        self.assertEqual(calls[-1][0], str(self.root / 'ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols'))

    def test_symbols_reject_different_binary_uuid_before_upload(self):
        env = self.symbol_environment()
        calls = []
        def run(command, **kwargs):
            calls.append(command)
            uuid = '01234567-0123-0123-0123-0123456789AB' if len(calls) == 1 else 'ABCDEFAB-0123-0123-0123-0123456789AB'
            return subprocess.CompletedProcess(command, 0, f'UUID: {uuid} (arm64) x', '')
        with self.assertRaisesRegex(ConfigError, 'symbol_uuid_mismatch'):
            upload_symbols(env, run)
        self.assertEqual(len(calls), 2)

    def test_symbols_failure_never_reprints_uploader_output(self):
        env = self.symbol_environment()
        def run(command, **kwargs):
            if 'dwarfdump' in command[0]:
                return subprocess.CompletedProcess(command, 0,
                    'UUID: 01234567-0123-0123-0123-0123456789AB (arm64) x', '')
            return subprocess.CompletedProcess(command, 1, FAKE_KEY, 'PRIVATE_SENTINEL')
        with self.assertRaisesRegex(ConfigError, '^symbol_upload_failed$'):
            upload_symbols(env, run)

    def build_check(self, env, platform, native_id, defines, stage=None):
        encoded = ",".join(base64.b64encode(f"{k}={v}".encode()).decode()
                           for k, v in defines)
        args = [sys.executable, str(SCRIPT), "--environment", env,
                "--platform", platform, "--config-dir", str(self.root),
                "--registry", str(self.registry), "--check-build", "--native-id", native_id]
        if stage:
            args.extend(["--stage-ios", str(stage)])
        return subprocess.run(args, env={**os.environ, "DART_DEFINES": encoded},
                              capture_output=True, text=True)

    def defines(self, env, platform):
        return [("POURLUNE_FIREBASE_ENV", env),
                ("POURLUNE_FIREBASE_NATIVE_READY", "true"),
                ("POURLUNE_FIREBASE_OPTIONS", (self.root / env / platform / "options.json").read_text())]

    def test_native_ready_alone_cannot_enable_an_unconfigured_build(self):
        result = self.build_check("none", "ios", "dev.pourlune.pourluneDev",
                                  [("POURLUNE_FIREBASE_NATIVE_READY", "true")])
        self.assertNotEqual(result.returncode, 0)
        clean = self.build_check("none", "ios", "dev.pourlune.b05Validation", [])
        self.assertEqual(clean.returncode, 0, clean.stderr)

    def test_build_defines_and_actual_native_id_must_match_selected_environment(self):
        good = self.build_check("dev", "ios", "dev.pourlune.pourluneDev", self.defines("dev", "ios"))
        self.assertEqual(good.returncode, 0, good.stderr)
        for native, definitions in [
            ("com.pourlune.app", self.defines("dev", "ios")),
            ("dev.pourlune.pourluneDev", self.defines("prod", "ios")),
            ("dev.pourlune.pourluneDev", self.defines("dev", "android")),
            ("dev.pourlune.pourluneDev", self.defines("dev", "ios") + [("POURLUNE_FIREBASE_NATIVE_READY", "false")]),
        ]:
            with self.subTest(native=native):
                r = self.build_check("dev", "ios", native, definitions)
                self.assertNotEqual(r.returncode, 0)
                self.assertNotIn(FAKE_KEY, r.stdout + r.stderr)

    def test_dev_prod_dev_and_offline_restage_resource_without_stale_plist(self):
        target = self.root / "Runner.app"
        target.mkdir()
        for env, native in [("dev", "dev.pourlune.pourluneDev"),
                            ("prod", "com.pourlune.app"),
                            ("dev", "dev.pourlune.pourluneDev")]:
            r = self.build_check(env, "ios", native, self.defines(env, "ios"), target)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertEqual(plistlib.loads((target / "GoogleService-Info.plist").read_bytes())["BUNDLE_ID"], native)
        r = self.build_check("none", "ios", "dev.pourlune.pourluneDev", [], target)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse((target / "GoogleService-Info.plist").exists())
        self.assertEqual(json.loads((target / ".pourlune-firebase.json").read_text())["environment"], "none")

    def test_bad_selection_does_not_overwrite_previous_native_resource(self):
        target = self.root / "Runner.app"
        target.mkdir()
        p = target / "GoogleService-Info.plist"
        p.write_bytes(b"previous-owned-resource")
        r = self.build_check("prod", "ios", "dev.pourlune.pourluneDev", self.defines("prod", "ios"), target)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(p.read_bytes(), b"previous-owned-resource")

    def wrapper(self, env, command=None, **destinations):
        capture = self.root / "flutter-input.json"
        fake = self.root / "flutter-fixture"
        fake.write_text(
            f"#!{Path(sys.executable).resolve()}\n"
            "import json,os,sys\nfrom pathlib import Path\n"
            "p=next(a.split('=',1)[1] for a in sys.argv if a.startswith('--dart-define-from-file='))\n"
            "d=json.loads(Path(p).read_text())\n"
            "x=Path(os.environ['XCODE_XCCONFIG_FILE']).read_text()\n"
            "Path(os.environ['FIREBASE_FIXTURE_CAPTURE']).write_text(json.dumps({'argv':sys.argv[1:],'defines':d,'xcconfig':x,'gradle_env':os.environ['ORG_GRADLE_PROJECT_POURLUNE_FIREBASE_ENV']}))\n"
            "if 'POURLUNE_FIREBASE_OPTIONS' in d: print(json.loads(d['POURLUNE_FIREBASE_OPTIONS'])['apiKey'])\n"
        )
        fake.chmod(0o700)
        args = [sys.executable, str(SCRIPT.with_name("firebase_build.py")),
                "--environment", env, "--platform", "ios", "--config-dir", str(self.root),
                "--registry", str(self.registry), "--flutter", str(fake)]
        for flag, value in destinations.items():
            args.extend(['--' + flag.replace('_', '-'), value])
        args.append('--')
        args.extend(command or ["build", "ios", "--no-codesign"])
        return subprocess.run(args, env={**os.environ, "FIREBASE_FIXTURE_CAPTURE": str(capture)},
                              capture_output=True, text=True)

    def test_wrapper_selects_dev_prod_dev_and_keeps_source_configs_unchanged(self):
        before = {str(p): p.read_bytes() for p in self.root.rglob("*.json")}
        for env, native in [("dev", "dev.pourlune.pourluneDev"),
                            ("prod", "com.pourlune.app"),
                            ("dev", "dev.pourlune.pourluneDev")]:
            r = self.wrapper(env)
            self.assertEqual(r.returncode, 0, r.stderr)
            sent = json.loads((self.root / "flutter-input.json").read_text())
            self.assertEqual(sent["gradle_env"], env)
            self.assertIn(f"POURLUNE_BUNDLE_IDENTIFIER = {native}", sent["xcconfig"])
            self.assertNotIn("\nPRODUCT_BUNDLE_IDENTIFIER =", sent["xcconfig"])
            self.assertEqual(json.loads(sent["defines"]["POURLUNE_FIREBASE_OPTIONS"])["projectId"], f"pourlune-{env}-fixture")
            self.assertNotIn(FAKE_KEY, r.stdout + r.stderr)
        for name, content in before.items():
            self.assertEqual(Path(name).read_bytes(), content)

    def test_wrapper_offline_omits_options_and_does_not_require_local_configs(self):
        shutil.rmtree(self.root / "dev")
        self.registry.unlink()
        r = self.wrapper("none")
        self.assertEqual(r.returncode, 0, r.stderr)
        sent = json.loads((self.root / "flutter-input.json").read_text())
        self.assertNotIn("POURLUNE_FIREBASE_OPTIONS", sent["defines"])
        self.assertEqual(sent["gradle_env"], "none")

    def test_wrapper_rejects_bad_config_before_invoking_flutter(self):
        self.change_options("projectId", "fishpilot-staging")
        r = self.wrapper("dev")
        self.assertNotEqual(r.returncode, 0)
        self.assertFalse((self.root / "flutter-input.json").exists())
        self.assertNotIn(FAKE_KEY, r.stdout + r.stderr)

    def test_wrapper_does_not_run_production_or_accept_overriding_firebase_defines(self):
        for env, command in [("prod", ["run"]),
                             ("dev", ["build", "ios", "--dart-define=POURLUNE_FIREBASE_NATIVE_READY=false"])]:
            r = self.wrapper(env, command)
            self.assertNotEqual(r.returncode, 0)
            self.assertFalse((self.root / "flutter-input.json").exists())

    def test_production_rejects_all_foreign_target_forms_before_flutter(self):
        target = 'integration_test/firebase_services_app.dart'
        for extra in [[target], ['-t' + target], ['-t', target],
                      ['--target', target], ['--target=' + target],
                      ['diagnostic_without_dart_suffix'], ['--', target]]:
            with self.subTest(extra=extra):
                capture = self.root / 'flutter-input.json'
                capture.unlink(missing_ok=True)
                r = self.wrapper('prod', ['build', 'ios', *extra])
                self.assertNotEqual(r.returncode, 0)
                self.assertFalse(capture.exists())

    def test_production_pins_default_target_for_supported_default_forms(self):
        for extra in [[], ['lib/main.dart'], ['-tlib/main.dart'],
                      ['-t', 'lib/main.dart'], ['--target', 'lib/main.dart'],
                      ['--target=lib/main.dart']]:
            with self.subTest(extra=extra):
                r = self.wrapper('prod', ['build', 'ios', '--debug', *extra])
                self.assertEqual(r.returncode, 0, r.stderr)
                sent = json.loads((self.root / 'flutter-input.json').read_text())
                self.assertEqual(sent['argv'][-2], '--target=lib/main.dart')

    def test_development_keeps_diagnostic_entrypoint_support(self):
        r = self.wrapper('dev', ['build', 'ios', '-tintegration_test/firebase_services_app.dart'])
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_public_destinations_reach_actual_flutter_definitions(self):
        r = self.wrapper('prod', support_url='https://pourlune-fixture.github.io/help',
                         privacy_url='https://pourlune-fixture.github.io/privacy',
                         feedback_email='beta@pourlune-fixture.org')
        self.assertEqual(r.returncode, 0, r.stderr)
        sent = json.loads((self.root / 'flutter-input.json').read_text())['defines']
        self.assertEqual(sent['POURLUNE_SUPPORT_URL'], 'https://pourlune-fixture.github.io/help')
        self.assertEqual(sent['POURLUNE_PRIVACY_URL'], 'https://pourlune-fixture.github.io/privacy')
        self.assertEqual(sent['POURLUNE_FEEDBACK_EMAIL'], 'beta@pourlune-fixture.org')
        self.assertEqual(sent['POURLUNE_AD_MODE'], 'disabled')

    def test_display_version_matches_native_build_override(self):
        r = self.wrapper('prod', ['build', 'ios', '--no-codesign',
                                 '--build-name=0.5.1', '--build-number=17'])
        self.assertEqual(r.returncode, 0, r.stderr)
        sent = json.loads((self.root / 'flutter-input.json').read_text())['defines']
        self.assertFalse(any(key.startswith('FLUTTER_BUILD_') for key in sent))
        self.assertEqual(sent['POURLUNE_VERSION_NAME'], '0.5.1')
        self.assertEqual(sent['POURLUNE_VERSION_CODE'], '17')

    def test_display_version_uses_pubspec_when_no_override(self):
        from beta_build import read_version
        name, number = read_version((SCRIPT.parents[2] / 'app/pubspec.yaml').read_text())
        r = self.wrapper('none')
        self.assertEqual(r.returncode, 0, r.stderr)
        sent = json.loads((self.root / 'flutter-input.json').read_text())['defines']
        self.assertEqual((sent['POURLUNE_VERSION_NAME'], sent['POURLUNE_VERSION_CODE']),
                         (name, str(number)))

    def test_caller_cannot_spoof_display_version(self):
        r = self.wrapper('dev', ['build', 'ios',
                                '--dart-define=POURLUNE_VERSION_CODE=999'])
        self.assertNotEqual(r.returncode, 0)
        self.assertFalse((self.root / 'flutter-input.json').exists())

    def test_invalid_public_destinations_reject_before_flutter(self):
        for value in ['http://public.org', 'https://user:password@public.org',
                      'https://example.com', 'https://sub.example.org',
                      'https://localhost', 'https://private.test', 'https://127.0.0.1',
                      'https://public.org/\nsecret']:
            with self.subTest(value=value):
                r = self.wrapper('prod', support_url=value)
                self.assertNotEqual(r.returncode, 0)
                self.assertFalse((self.root / 'flutter-input.json').exists())
        for value in ['name', 'x@example.com', 'a@@public.org', '.a@public.org',
                      'a..b@public.org', 'a@local', 'x@domain.invalid']:
            r = self.wrapper('prod', feedback_email=value)
            self.assertNotEqual(r.returncode, 0)
            self.assertFalse((self.root / 'flutter-input.json').exists())

    def test_explicit_beta_ads_passes_test_mode_and_platform_sample_app_to_both_layers(self):
        r = self.wrapper('prod', ad_mode='test')
        self.assertEqual(r.returncode, 0, r.stderr)
        sent = json.loads((self.root / 'flutter-input.json').read_text())
        self.assertEqual(sent['defines']['POURLUNE_AD_MODE'], 'test')
        self.assertEqual(sent['defines']['POURLUNE_AD_APP_ID'],
                         'ca-app-pub-3940256099942544~1458002511')
        self.assertIn('POURLUNE_ADMOB_APP_ID = ca-app-pub-3940256099942544~1458002511',
                      sent['xcconfig'])
        self.assertIn('--target=lib/main.dart', sent['argv'])

    def test_destination_or_ads_defines_cannot_bypass_owned_selection(self):
        for name in ['POURLUNE_SUPPORT_URL', 'POURLUNE_PRIVACY_URL',
                     'POURLUNE_FEEDBACK_EMAIL', 'POURLUNE_AD_MODE']:
            r = self.wrapper('prod', ['build', 'ios', f'--dart-define={name}=bypass'])
            self.assertNotEqual(r.returncode, 0)
            self.assertFalse((self.root / 'flutter-input.json').exists())


if __name__ == "__main__":
    unittest.main()
