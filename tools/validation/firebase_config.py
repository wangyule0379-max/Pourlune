"""Cross-check local client files against public registration evidence.

Only public identity/hash summaries leave the CLI. Never print parser exceptions
or configuration contents, including the public client API key.
"""
import argparse
import base64
import binascii
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import sys
from xml.parsers.expat import ExpatError


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "docs/development/evidence/firebase-integration/registration.json"
NATIVE_IDS = {
    "dev": {"ios": "dev.pourlune.pourluneDev", "android": "dev.pourlune.pourlune_dev"},
    "prod": {"ios": "com.pourlune.app", "android": "com.pourlune.app"},
}
OPTION_KEYS = {
    "apiKey", "appId", "projectId", "messagingSenderId", "storageBucket", "iosBundleId",
}


class ConfigError(Exception):
    """A fixed diagnostic code, never a value from a client file."""


def require(condition, code):
    if not condition:
        raise ConfigError(code)


def read_json(path):
    try:
        data = json.loads(Path(path).read_text())
    except (OSError, ValueError, UnicodeError):
        raise ConfigError("missing_or_invalid_json") from None
    require(isinstance(data, dict), "expected_json_object")
    return data


def inspect_config(config_dir, environment, platform, registry_path=REGISTRY):
    require(environment in NATIVE_IDS and platform in {"ios", "android"}, "invalid_target")
    registry = read_json(registry_path)
    try:
        target = registry["environments"][environment]
        app = target["apps"][platform]
        project, number = target["project_id"], target["project_number"]
        app_id, native_id = app["app_id"], app["native_id"]
    except (KeyError, TypeError):
        raise ConfigError("registration_incomplete") from None
    require(isinstance(project, str) and bool(re.fullmatch(
        rf"pourlune-{environment}(?:-[a-z0-9-]+)?", project
    )), "foreign_project_registration")
    require(isinstance(number, str) and number.isdigit(), "invalid_project_number")
    require(native_id == NATIVE_IDS[environment][platform], "wrong_registered_native_id")
    require(isinstance(app_id, str) and bool(re.fullmatch(
        rf"1:{number}:{platform}:[A-Fa-f0-9]+", app_id
    )), "invalid_registered_app_id")
    folder = Path(config_dir) / environment / platform
    options_path = folder / "options.json"
    options = read_json(options_path)
    require(set(options) <= OPTION_KEYS, "unsupported_options_fields")
    for field in ["apiKey", "appId", "projectId", "messagingSenderId"]:
        require(isinstance(options.get(field), str) and bool(options[field]), "missing_options_field")
    require(bool(re.fullmatch(r"AIza[A-Za-z0-9_-]{35}", options["apiKey"])), "invalid_api_key_format")
    require(options["projectId"] == project and options["messagingSenderId"] == number
            and options["appId"] == app_id, "options_registration_mismatch")
    if platform == "ios":
        require(options.get("iosBundleId") == native_id, "options_bundle_mismatch")
        native_path = folder / "GoogleService-Info.plist"
        try:
            native = plistlib.loads(native_path.read_bytes())
        except (OSError, ValueError, TypeError, plistlib.InvalidFileException, ExpatError):
            raise ConfigError("missing_or_invalid_plist") from None
        require(isinstance(native, dict), "expected_plist_object")
        expected = {"PROJECT_ID": project, "GCM_SENDER_ID": number,
                    "GOOGLE_APP_ID": app_id, "BUNDLE_ID": native_id,
                    "API_KEY": options["apiKey"]}
        require(all(native.get(k) == v for k, v in expected.items()), "native_registration_mismatch")
        bucket = native.get("STORAGE_BUCKET")
    else:
        require("iosBundleId" not in options, "ios_options_on_android")
        native_path = folder / "google-services.json"
        native = read_json(native_path)
        try:
            project_info = native["project_info"]
            clients = [c for c in native["client"]
                       if c["client_info"]["android_client_info"]["package_name"] == native_id]
            require(len(clients) == 1, "native_package_mismatch")
            client = clients[0]
            require(project_info["project_id"] == project and
                    project_info["project_number"] == number and
                    client["client_info"]["mobilesdk_app_id"] == app_id,
                    "native_registration_mismatch")
            require(options["apiKey"] in [x["current_key"] for x in client["api_key"]],
                    "native_api_key_mismatch")
            bucket = project_info.get("storage_bucket")
        except (KeyError, TypeError):
            raise ConfigError("invalid_native_android_fields") from None
    if "storageBucket" in options:
        require(isinstance(options["storageBucket"], str) and
                options["storageBucket"] == bucket, "storage_bucket_mismatch")
    return {"environment": environment, "platform": platform,
            "project_id": project, "project_number": number,
            "app_id": app_id, "native_id": native_id,
            "native_path": native_path.resolve(), "options_path": options_path.resolve(),
            "options": options}


def public_summary(config):
    result = {k: config[k] for k in ["environment", "platform", "project_id",
                                    "project_number", "app_id", "native_id"]}
    result["ok"] = True
    result["files"] = [
        {"name": config[k].name, "sha256": hashlib.sha256(config[k].read_bytes()).hexdigest()}
        for k in ["native_path", "options_path"]
    ]
    return result


def check_build(config_dir, environment, platform, native_id, encoded, registry_path=REGISTRY):
    definitions = {}
    try:
        for part in encoded.split(",") if encoded else []:
            key, value = base64.b64decode(part, validate=True).decode().split("=", 1)
            if key.startswith("POURLUNE_FIREBASE_"):
                require(key not in definitions, "duplicate_firebase_define")
                require(key in {"POURLUNE_FIREBASE_ENV", "POURLUNE_FIREBASE_OPTIONS",
                                "POURLUNE_FIREBASE_NATIVE_READY"}, "unknown_firebase_define")
                definitions[key] = value
    except (ValueError, UnicodeError, binascii.Error):
        raise ConfigError("invalid_dart_defines") from None
    if environment == "none":
        require(definitions.get("POURLUNE_FIREBASE_ENV", "none") == "none" and
                definitions.get("POURLUNE_FIREBASE_NATIVE_READY", "false") == "false" and
                not definitions.get("POURLUNE_FIREBASE_OPTIONS"), "firebase_without_native_selection")
        return {"ok": True, "environment": "none", "platform": platform,
                "native_id": native_id, "firebase": "disabled"}, None
    config = inspect_config(config_dir, environment, platform, registry_path)
    require(native_id == config["native_id"], "build_native_id_mismatch")
    require(definitions.get("POURLUNE_FIREBASE_ENV") == environment and
            definitions.get("POURLUNE_FIREBASE_NATIVE_READY") == "true", "build_selection_mismatch")
    try:
        options = json.loads(definitions.get("POURLUNE_FIREBASE_OPTIONS", ""))
    except ValueError:
        raise ConfigError("invalid_build_options") from None
    require(options == config["options"], "build_options_mismatch")
    return public_summary(config), config


def stage_ios(target, public, config):
    """Copy only after validation; offline builds remove a previous SDK plist."""
    target = Path(target)
    require(target.name.endswith(".app"), "invalid_ios_product_directory")
    target.mkdir(parents=True, exist_ok=True)
    native = target / "GoogleService-Info.plist"
    if config is None:
        native.unlink(missing_ok=True)
    else:
        shutil.copyfile(config["native_path"], native)
    (target / ".pourlune-firebase.json").write_text(json.dumps(public, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", choices=["dev", "prod", "none"], required=True)
    parser.add_argument("--platform", choices=["ios", "android"], required=True)
    parser.add_argument("--config-dir", type=Path, required=True)
    parser.add_argument("--registry", type=Path, default=REGISTRY)
    parser.add_argument("--check-build", action="store_true")
    parser.add_argument("--native-id", default="")
    parser.add_argument("--stage-ios", type=Path)
    args = parser.parse_args()
    try:
        if args.check_build:
            require(bool(args.native_id), "missing_build_native_id")
            public, config = check_build(args.config_dir, args.environment, args.platform,
                                         args.native_id, os.environ.get("DART_DEFINES", ""), args.registry)
            if args.stage_ios:
                require(args.platform == "ios", "invalid_stage_platform")
                stage_ios(args.stage_ios, public, config)
        else:
            require(not args.stage_ios, "stage_requires_build_check")
            config = inspect_config(args.config_dir, args.environment, args.platform, args.registry)
            public = public_summary(config)
        print(json.dumps(public, indent=2))
        return 0
    except ConfigError as error:
        print(json.dumps({"ok": False, "code": str(error)}), file=sys.stderr)
        return 1
    except OSError:
        print(json.dumps({"ok": False, "code": "configuration_io_error"}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
