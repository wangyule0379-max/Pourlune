"""Invoke Flutter with one validated local Firebase selection, without file swaps."""
import argparse
import base64
from contextlib import ExitStack
import json
import os
import plistlib
from pathlib import Path
import subprocess
import sys
import tempfile

from firebase_config import ConfigError, NATIVE_IDS, REGISTRY, ROOT, inspect_config, require
from ios_signing import ProfileError, inspect_profile
from public_destinations import DestinationError, add_destination_arguments, validate_destinations
from admob_config import AdConfigError, add_arguments as add_ad_arguments, selection as ad_selection
from build_version import BuildError, display_definitions
from ios_release_plugins import release_plugins, verify_no_test_plugin
from ios_privacy_manifests import inspect_app as inspect_privacy_manifests


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", choices=["none", "dev", "prod"], required=True)
    parser.add_argument("--platform", choices=["ios", "android"], required=True)
    parser.add_argument("--config-dir", type=Path, default=ROOT / "app/config/firebase")
    parser.add_argument("--registry", type=Path, default=REGISTRY)
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--upload-symbols", action="store_true")
    parser.add_argument("--ios-profile", type=Path,
                        help="Existing Pourlune App Store profile, for local IPA export only")
    parser.add_argument("--ios-output", type=Path)
    add_destination_arguments(parser)
    add_ad_arguments(parser)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        destinations = validate_destinations(args.support_url, args.privacy_url, args.feedback_email)
        command = args.command[1:] if args.command[:1] == ["--"] else args.command
        require(bool(command) and command[0] in {"build", "run", "test"}, "invalid_flutter_command")
        require(not any(any(name in a for name in (
                        "POURLUNE_FIREBASE_", "POURLUNE_SUPPORT_URL", "POURLUNE_PRIVACY_URL",
                        "POURLUNE_FEEDBACK_EMAIL", "POURLUNE_AD", "POURLUNE_INTERSTITIAL",
                        "POURLUNE_REWARDED", "POURLUNE_VERSION_NAME", "POURLUNE_VERSION_CODE"))
                        or a.startswith("--dart-define-from-file")
                        for a in command), "caller_cannot_override_firebase_selection")
        if args.environment == "prod":
            require(command[0] == "build", "production_is_compile_only")
            index = 2
            while index < len(command):
                item = command[index]
                if item in {"-t", "--target"}:
                    require(index + 1 < len(command) and command[index + 1] == "lib/main.dart",
                            "production_default_entrypoint_only")
                    index += 2
                    continue
                if item.startswith("-t") and not item.startswith("--"):
                    require(item == "-tlib/main.dart", "production_default_entrypoint_only")
                elif item.startswith("--target="):
                    require(item == "--target=lib/main.dart", "production_default_entrypoint_only")
                else:
                    # Prod accepts non-target option values inline (--flag=value),
                    # avoiding an incomplete imitation of Flutter's full parser.
                    require(item != "--" and (item.startswith("-") or item == "lib/main.dart"),
                            "production_default_entrypoint_only")
                index += 1
            # Flutter also supports positional/combined short arguments. Pin its
            # final parsed target explicitly, even when a caller uses short flags.
            command = [*command, "--target=lib/main.dart"]
        exporting_ipa = command[:2] == ["build", "ipa"]
        require(bool(args.ios_profile) == exporting_ipa, "ipa_requires_existing_profile")
        require(bool(args.ios_output) == exporting_ipa, "ipa_requires_new_export_output")
        if exporting_ipa:
            require(args.environment == "prod" and args.platform == "ios",
                    "ipa_requires_production_ios")
            require(all(item in {"--release", "--no-pub", "--target=lib/main.dart"}
                        or item.startswith(("--build-name=", "--build-number="))
                        for item in command[2:]), "ipa_options_are_local_export_only")
            require(args.ios_output.resolve().is_relative_to((ROOT / 'build').resolve())
                    and not args.ios_output.exists(), "ipa_output_must_be_new_build_subdirectory")
        if command[0] == "build":
            require(len(command) > 1 and command[1] in (
                {"ios", "ipa"} if args.platform == "ios" else {"apk", "appbundle"}
            ), "flutter_platform_mismatch")
        require(not args.upload_symbols or (args.environment == "dev" and args.platform == "ios"),
                "symbol_upload_is_development_ios_only")
        config = None if args.environment == "none" else inspect_config(
            args.config_dir, args.environment, args.platform, args.registry
        )
        profile = inspect_profile(args.ios_profile) if args.ios_profile else None
        ads = ad_selection(args.ad_mode, args.platform,
                           NATIVE_IDS['prod' if args.environment == 'prod' else 'dev'][args.platform],
                           args.admob_registration)
        definitions = {"POURLUNE_FIREBASE_ENV": args.environment,
                       "POURLUNE_FIREBASE_NATIVE_READY": "false" if config is None else "true",
                       "POURLUNE_AD_MODE": args.ad_mode,
                       "POURLUNE_AD_APP_ID": ads['app_id'],
                       "POURLUNE_AD_PLATFORM": args.platform,
                       "POURLUNE_AD_NATIVE_ID": ads['native_id']}
        definitions.update(display_definitions((ROOT / 'app/pubspec.yaml').read_text(), command))
        definitions.update({'POURLUNE_' + name.upper(): value
                            for name, value in destinations.items() if name != 'ready'})
        if config:
            definitions["POURLUNE_FIREBASE_OPTIONS"] = json.dumps(config["options"], separators=(",", ":"))
        with tempfile.TemporaryDirectory(prefix="pourlune-firebase-") as temp:
            temp = Path(temp)
            define_file = temp / "defines.json"
            define_file.write_text(json.dumps(definitions))
            define_file.chmod(0o600)
            inputs = temp / "config-inputs.xcfilelist"
            input_paths = [] if config is None else [
                str(config["native_path"]), str(config["options_path"]), str(args.registry.resolve())
            ]
            if args.admob_registration:
                input_paths.append(str(args.admob_registration.resolve()))
            inputs.write_text("\n".join(input_paths) + ("\n" if input_paths else ""))
            symbol_inputs = temp / "symbol-inputs.xcfilelist"
            symbol_inputs.write_text("" if not args.upload_symbols else "\n".join([
                "$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)",
                "$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)/Contents/Resources/DWARF/$(PRODUCT_NAME)",
                "$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)/Contents/Info.plist",
                "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)",
            ]) + "\n")
            xcconfig = temp / "selection.xcconfig"
            lines = [f"POURLUNE_FIREBASE_ENV = {args.environment}",
                     f"POURLUNE_ADMOB_APP_ID = {ads['app_id']}",
                     f"POURLUNE_ADMOB_REGISTRATION = {args.admob_registration.resolve() if args.admob_registration else ''}",
                     f"POURLUNE_DISPLAY_NAME = {'Pourlune' if args.environment == 'prod' else 'Pourlune Dev'}",
                     f"POURLUNE_FIREBASE_CONFIG_DIR = {args.config_dir.resolve()}",
                     f"POURLUNE_FIREBASE_REGISTRY = {args.registry.resolve()}",
                     f"POURLUNE_FIREBASE_INPUTS = {inputs}",
                     f"POURLUNE_FIREBASE_SYMBOL_INPUTS = {symbol_inputs}",
                     f"POURLUNE_FIREBASE_UPLOAD_SYMBOLS = {'YES' if args.upload_symbols else 'NO'}"]
            if config:
                lines.extend([f"POURLUNE_BUNDLE_IDENTIFIER = {config['native_id']}",
                              "DEBUG_INFORMATION_FORMAT = dwarf-with-dsym",
                              "ENABLE_DEBUG_DYLIB = NO"])
            if profile:
                lines.extend(["POURLUNE_CODE_SIGN_STYLE = Manual",
                              f"POURLUNE_CODE_SIGN_IDENTITY = {profile['certificate_sha1']}",
                              f"POURLUNE_PROVISIONING_PROFILE = {profile['uuid']}"])
                export = temp / "export.plist"
                export.write_bytes(plistlib.dumps({
                    "method": "app-store-connect", "destination": "export",
                    "signingStyle": "manual", "teamID": profile["team"],
                    "signingCertificate": profile["certificate_sha1"],
                    "provisioningProfiles": {profile["bundle"]: profile["uuid"]},
                    "uploadSymbols": False, "manageAppVersionAndBuildNumber": False,
                }))
            xcconfig.write_text("\n".join(lines) + "\n")
            environment = dict(os.environ)
            environment.pop("DART_DEFINES", None)
            environment.update({
                "FIREBASE_ANALYTICS_WITHOUT_ADID": "1",
                "POURLUNE_PYTHON": sys.executable,
                "XCODE_XCCONFIG_FILE": str(xcconfig),
                "ORG_GRADLE_PROJECT_POURLUNE_FIREBASE_ENV": args.environment,
                "ORG_GRADLE_PROJECT_POURLUNE_FIREBASE_CONFIG_DIR": str(args.config_dir.resolve()),
                "ORG_GRADLE_PROJECT_POURLUNE_FIREBASE_REGISTRY": str(args.registry.resolve()),
                "ORG_GRADLE_PROJECT_POURLUNE_ADMOB_APP_ID": ads['app_id'],
                "ORG_GRADLE_PROJECT_POURLUNE_ADMOB_REGISTRATION": str(args.admob_registration.resolve()) if args.admob_registration else '',
            })
            # Flutter's signed IPA path unconditionally adds provisioning-update
            # flags. Prepare unsigned, then archive/export with the verified
            # existing manual identity; never allow Xcode to create signing assets.
            flutter_command = command
            if profile:
                flutter_command = ["build", "ios", *command[2:], "--no-codesign"]
            commands = [[args.flutter, *flutter_command,
                         f"--dart-define-from-file={define_file}"]]
            if profile:
                output = args.ios_output.resolve()
                output.mkdir(parents=True)
                archive = output / "Runner.xcarchive"
                commands.extend([
                    ["xcodebuild", "-workspace", "ios/Runner.xcworkspace", "-scheme", "Runner",
                     "-configuration", "Release", "-destination", "generic/platform=iOS",
                     "-disableAutomaticPackageResolution", "-onlyUsePackageVersionsFromResolvedFile",
                     "-archivePath", str(archive), "POURLUNE_REPAIR_PRIVACY_MANIFESTS=1", "archive"],
                    ["xcodebuild", "-exportArchive", "-archivePath", str(archive),
                     "-exportOptionsPlist", str(export), "-exportPath", str(output / "ipa")],
                ])
            logs = []
            with ExitStack() as generated_inputs:
                for index, invocation in enumerate(commands):
                    if profile and index == 1:
                        evidence = generated_inputs.enter_context(release_plugins(ROOT / 'app'))
                        (output / 'release-plugins.json').write_text(json.dumps(evidence, indent=2) + '\n')
                    result = subprocess.run(
                        invocation, cwd=ROOT / "app", env=environment,
                        capture_output=True, text=True, errors="replace",
                    )
                    logs.append(result.stdout + result.stderr)
                    if result.returncode:
                        break
                    if profile and index == 1:
                        verify_no_test_plugin(archive / 'Products/Applications/Runner.app/Runner')
                        privacy = inspect_privacy_manifests(archive / 'Products/Applications/Runner.app')
                        (output / 'privacy-manifests.json').write_text(json.dumps(privacy, indent=2) + '\n')
            # Flutter/Xcode can echo their environment on failure. Redact both
            # the client value and its complete encoded Dart definition.
            log = "\n".join(logs)
            if config:
                for value in [config["options"]["apiKey"],
                              base64.b64encode(("POURLUNE_FIREBASE_OPTIONS=" +
                                  definitions["POURLUNE_FIREBASE_OPTIONS"]).encode()).decode()]:
                    log = log.replace(value, "[CLIENT_CONFIG_REDACTED]")
            print(log, end="")
            return result.returncode
    except (ConfigError, ProfileError, DestinationError, AdConfigError, BuildError) as error:
        print(json.dumps({"ok": False, "code": str(error)}), file=sys.stderr)
        return 1
    except OSError:
        print(json.dumps({"ok": False, "code": "build_selection_io_error"}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
