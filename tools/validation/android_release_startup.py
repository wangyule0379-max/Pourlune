"""Check packaged DEX reflection constructors required before Flutter starts.

This is a package regression check, not an Android runtime test. It uses the
existing Android SDK apkanalyzer; it never installs or edits the supplied APK/AAB.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


REFLECTED_CLASSES = (
    "androidx.work.impl.WorkDatabase_Impl",
    "androidx.work.OverwritingInputMerger",
    "androidx.work.ArrayCreatingInputMerger",
)


def inspect_package(archive: Path, apkanalyzer: str) -> list[dict]:
    with tempfile.TemporaryDirectory(prefix="pourlune-dex-inspect-") as temp:
        view = archive
        with zipfile.ZipFile(archive) as source:
            if archive.suffix == ".aab":
                # apkanalyzer reads root DEX entries. This temporary DEX-only
                # view is never signed, installed, or presented as an APK build.
                dex = [n for n in source.namelist()
                       if n.startswith("base/dex/") and n.endswith(".dex")]
                if not dex or len({Path(n).name for n in dex}) != len(dex):
                    raise ValueError("Missing or ambiguous base DEX entries")
                view = Path(temp) / "dex-inspection-only.apk"
                with zipfile.ZipFile(view, "w") as output:
                    for name in dex:
                        output.writestr(Path(name).name, source.read(name))
            elif archive.suffix != ".apk":
                raise ValueError("An APK or AAB is required")

        checks = []
        for name in REFLECTED_CLASSES:
            result = subprocess.run(
                [apkanalyzer, "dex", "code", "--class", name, str(view)],
                capture_output=True, text=True, timeout=60,
            )
            if result.returncode:
                raise ValueError("apkanalyzer could not inspect packaged DEX")
            descriptor = "L" + name.replace(".", "/") + ";"
            headers = [line for line in result.stdout.splitlines()
                       if line.startswith(".class ")]
            constructors = [line.split() for line in result.stdout.splitlines()
                            if line.startswith(".method ")]
            checks.append({
                "class": name,
                "class_present": any(descriptor in line for line in headers),
                "public_noarg_constructor": any(
                    parts[-1] == "<init>()V" and "public" in parts[1:-1]
                    and "constructor" in parts[1:-1]
                    for parts in constructors
                ),
            })
        return checks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    parser.add_argument(
        "--apkanalyzer",
        default=shutil.which("apkanalyzer") or (
            str(Path(sdk) / "cmdline-tools/latest/bin/apkanalyzer") if sdk else None
        ),
    )
    args = parser.parse_args()
    if not args.apkanalyzer:
        parser.error("Provide the existing SDK apkanalyzer with --apkanalyzer")
    try:
        checks = inspect_package(args.archive, args.apkanalyzer)
    except (OSError, ValueError, zipfile.BadZipFile, subprocess.TimeoutExpired) as exc:
        print(json.dumps({"passed": False, "error": str(exc)}))
        return 2
    passed = all(c["class_present"] and c["public_noarg_constructor"]
                 for c in checks)
    print(json.dumps({"passed": passed, "reflection_constructors": checks}, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
