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
apk = Path(sys.argv[sys.argv.index("--apk") + 1]).resolve() if "--apk" in sys.argv else root / "native/android/app/build/outputs/apk/debug/app-debug.apk"
app = Path(sys.argv[2]).resolve()
digest = lambda data: hashlib.sha256(data).hexdigest()
info = plistlib.loads((app / "Info.plist").read_bytes())
icon_raw = (root / "native/icon-manifest.json").read_bytes()
for item in json.loads(icon_raw)["files"]:
    assert digest((root.parent / item["source"]).read_bytes()) == item["sha256"]
    assert digest((root.parent / item["copy"]).read_bytes()) == item["sha256"]
assert info["CFBundleIcons"]["CFBundlePrimaryIcon"]["CFBundleIconName"] == "AppIcon"

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
minified_evidence = None
with zipfile.ZipFile(apk) as archive:
    if "--apk" in sys.argv:
        assert android("debuggable") == "false", "Minified QA must use the release manifest"
        mapping = (root / "native/android/app/build/outputs/mapping/release/mapping.txt").read_bytes()
        match = re.search(rb"^# pg_map_id: (.+)$", mapping, re.M)
        assert mapping.startswith(b"# compiler: R8") and match, "Missing R8 mapping"
        markers = []
        for name in archive.namelist():
            if re.fullmatch(r"classes[0-9]*[.]dex", name):
                markers.extend(json.loads(raw) for raw in re.findall(rb"~~R8(\{[^\0]*?\})", archive.read(name)))
        assert markers and all(m.get("compilation-mode") == "release" and m.get("pg-map-id") == match.group(1).decode() for m in markers), "DEX/R8 mapping mismatch"
        minified_evidence = {"mapping_sha256": digest(mapping), "mapping_id": match.group(1).decode(), "dex_markers": markers}

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
    "icon_source_manifest_sha256": digest(icon_raw),
    "reported_app_version": info["CFBundleShortVersionString"] + "+" + info["CFBundleVersion"],
    "sdk": manifest["sdk"], "ads": manifest.get("ads"), "nativeBridgeVersion": manifest.get("nativeBridgeVersion", 1), "stage": "developer self-test; not independent/native/store acceptance",
    "verified_web_files": {"android": len(manifest["files"]) - len(omitted), "ios": len(manifest["files"])},
    "android_only_omitted_nonruntime_metadata": omitted, "android_permissions": permissions,
    "android": {"minified_qa": "--apk" in sys.argv, "minified_evidence": minified_evidence, "path": str(destination / "glass-garden-qa.apk"), "bytes": apk.stat().st_size, "sha256": digest(apk.read_bytes())},
    "ios": {"path": str(destination / "GlassGarden.app"), "files": [
        {"path": str(p.relative_to(app)), "bytes": p.stat().st_size, "sha256": digest(p.read_bytes())}
        for p in sorted(app.rglob("*")) if p.is_file()
    ]},
}
raw = (json.dumps(record, indent=2) + "\n").encode()
(destination / "artifact-index.json").write_bytes(raw)
print(json.dumps({"directory": str(destination), "index_sha256": digest(raw), "apk_sha256": record["android"]["sha256"], "web_manifest_sha256": record["web_manifest_sha256"]}, indent=2))
