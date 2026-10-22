"""Invoke Flutter with one validated local Firebase selection, without file swaps."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from firebase_config import ConfigError, NATIVE_IDS, REGISTRY, ROOT, inspect_config, require


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", choices=["none", "dev", "prod"], required=True)
    parser.add_argument("--platform", choices=["ios", "android"], required=True)
    parser.add_argument("--config-dir", type=Path, default=ROOT / "app/config/firebase")
    parser.add_argument("--registry", type=Path, default=REGISTRY)
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--upload-symbols", action="store_true")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        command = args.command[1:] if args.command[:1] == ["--"] else args.command
        require(bool(command) and command[0] in {"build", "run", "test"}, "invalid_flutter_command")
        require(not any("POURLUNE_FIREBASE_" in a or a.startswith("--dart-define-from-file")
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
        if command[0] == "build":
            require(len(command) > 1 and command[1] in (
                {"ios"} if args.platform == "ios" else {"apk", "appbundle"}
            ), "flutter_platform_mismatch")
        require(not args.upload_symbols or (args.environment == "dev" and args.platform == "ios"),
                "symbol_upload_is_development_ios_only")
        config = None if args.environment == "none" else inspect_config(
            args.config_dir, args.environment, args.platform, args.registry
        )
        definitions = {"POURLUNE_FIREBASE_ENV": args.environment,
                       "POURLUNE_FIREBASE_NATIVE_READY": "false" if config is None else "true",
                       "POURLUNE_AD_MODE": "disabled"}
        if config:
            definitions["POURLUNE_FIREBASE_OPTIONS"] = json.dumps(config["options"], separators=(",", ":"))
        with tempfile.TemporaryDirectory(prefix="pourlune-firebase-") as temp:
            temp = Path(temp)
            define_file = temp / "defines.json"
            define_file.write_text(json.dumps(definitions))
            define_file.chmod(0o600)
            inputs = temp / "config-inputs.xcfilelist"
            inputs.write_text("" if config is None else "\n".join([
                str(config["native_path"]), str(config["options_path"]), str(args.registry.resolve())
            ]) + "\n")
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
                     f"POURLUNE_FIREBASE_CONFIG_DIR = {args.config_dir.resolve()}",
                     f"POURLUNE_FIREBASE_REGISTRY = {args.registry.resolve()}",
                     f"POURLUNE_FIREBASE_INPUTS = {inputs}",
                     f"POURLUNE_FIREBASE_SYMBOL_INPUTS = {symbol_inputs}",
                     f"POURLUNE_FIREBASE_UPLOAD_SYMBOLS = {'YES' if args.upload_symbols else 'NO'}"]
            if config:
                lines.extend([f"PRODUCT_BUNDLE_IDENTIFIER = {config['native_id']}",
                              "DEBUG_INFORMATION_FORMAT = dwarf-with-dsym",
                              "ENABLE_DEBUG_DYLIB = NO"])
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
            })
            result = subprocess.run(
                [args.flutter, *command, f"--dart-define-from-file={define_file}"],
                cwd=ROOT / "app", env=environment, capture_output=True, text=True, errors="replace",
            )
            # Flutter/Xcode can echo their environment on failure. Redact both
            # the client value and its complete encoded Dart definition.
            log = result.stdout + result.stderr
            if config:
                for value in [config["options"]["apiKey"],
                              base64.b64encode(("POURLUNE_FIREBASE_OPTIONS=" +
                                  definitions["POURLUNE_FIREBASE_OPTIONS"]).encode()).decode()]:
                    log = log.replace(value, "[CLIENT_CONFIG_REDACTED]")
            print(log, end="")
            return result.returncode
    except ConfigError as error:
        print(json.dumps({"ok": False, "code": str(error)}), file=sys.stderr)
        return 1
    except OSError:
        print(json.dumps({"ok": False, "code": "build_selection_io_error"}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
