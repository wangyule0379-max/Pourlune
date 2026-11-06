"""Freeze already-built, independent QA artifacts. Never installs or signs."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
tag = sys.argv[1]
if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,63}", tag):
    raise SystemExit("Supply a new frozen web candidate name")
web = root / "build" / tag
raw_manifest = (web / "artifact-manifest.json").read_bytes()
manifest = json.loads(raw_manifest)
apk = root / "native/android/app/build/outputs/apk/debug/app-debug.apk"
app = Path(sys.argv[2]).resolve()
digest = lambda data: hashlib.sha256(data).hexdigest()
info = plistlib.loads((app / "Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "dev.pourlune.glassgarden.localqa"
sdk = Path(os.environ.get("ANDROID_SDK_ROOT", os.environ.get("ANDROID_HOME", str(Path.home() / "Library/Android/sdk"))))
analyzer = sdk / "cmdline-tools/latest/bin/apkanalyzer"
def android(field):
    return subprocess.check_output([str(analyzer), "manifest", field, str(apk)], text=True).strip()
assert android("application-id") == info["CFBundleIdentifier"]
assert android("version-code") == info["CFBundleVersion"]
permissions = android("permissions").splitlines()
assert not set(permissions) & {"com.google.android.gms.permission.AD_ID", "android.permission.ACCESS_ADSERVICES_AD_ID"}
if manifest.get("ads"):
    assert (app / "Frameworks/GoogleMobileAds.framework/GoogleMobileAds").is_file()
    assert (app / "Frameworks/UserMessagingPlatform.framework/UserMessagingPlatform").is_file()
    assert info["GADApplicationIdentifier"] == "ca-app-pub-3940256099942544~1458002511"
omitted = ["web/game/vendor/cocos/.gitignore"]
with zipfile.ZipFile(apk) as archive:
    if manifest.get("nativeBridgeVersion", 1) >= 3:
        # BuildConfig constants are folded into the native bridge string. Catch
        # a stale SDK version dimension even when manifest versionCode is right.
        version = info["CFBundleShortVersionString"] + "+" + info["CFBundleVersion"]
        assert any(version.encode() in archive.read(name) for name in archive.namelist() if re.fullmatch(r"classes[0-9]*\.dex", name)), "Native SDK appVersion does not match the installed build"
    if manifest.get("nativeBridgeVersion", 1) >= 2:
        assert archive.getinfo("assets/web/media/dream-culture.mp3").compress_type == zipfile.ZIP_STORED, "Native AssetFileDescriptor requires stored MP3"
    for item in manifest["files"]:
        source = (web / item["path"]).read_bytes()
        assert len(source) == item["bytes"] and digest(source) == item["sha256"]
        assert (app / "Web" / item["path"][4:]).read_bytes() == source, item["path"]
        if item["path"] not in omitted:
            assert archive.read("assets/" + item["path"]) == source, item["path"]
native_tag = sys.argv[3] if len(sys.argv) > 3 else tag
assert re.fullmatch(r"[a-z0-9][a-z0-9-]{0,63}", native_tag)
destination = root / "build/native-candidates" / native_tag
destination.mkdir()  # Existing candidates are immutable.
shutil.copy2(apk, destination / "glass-garden-qa.apk")
shutil.copytree(app, destination / "GlassGarden.app")
record = {
    "web_candidate": tag, "native_candidate": native_tag, "web_manifest_sha256": digest(raw_manifest),
    "identity": info["CFBundleIdentifier"], "version": info["CFBundleShortVersionString"] + "(" + info["CFBundleVersion"] + ")",
    "reported_app_version": info["CFBundleShortVersionString"] + "+" + info["CFBundleVersion"],
    "sdk": manifest["sdk"], "ads": manifest.get("ads"), "nativeBridgeVersion": manifest.get("nativeBridgeVersion", 1), "stage": "developer self-test; not independent/native/store acceptance",
    "verified_web_files": {"android": len(manifest["files"]) - len(omitted), "ios": len(manifest["files"])},
    "android_only_omitted_nonruntime_metadata": omitted, "android_permissions": permissions,
    "android": {"path": str(destination / "glass-garden-qa.apk"), "bytes": apk.stat().st_size, "sha256": digest(apk.read_bytes())},
    "ios": {"path": str(destination / "GlassGarden.app"), "files": [
        {"path": str(p.relative_to(app)), "bytes": p.stat().st_size, "sha256": digest(p.read_bytes())}
        for p in sorted(app.rglob("*")) if p.is_file()
    ]},
}
raw = (json.dumps(record, indent=2) + "\n").encode()
(destination / "artifact-index.json").write_bytes(raw)
print(json.dumps({"directory": str(destination), "index_sha256": digest(raw), "apk_sha256": record["android"]["sha256"], "web_manifest_sha256": record["web_manifest_sha256"]}, indent=2))
