"""Fail closed when the native service flag and frozen web notice disagree."""
import json
import os
from pathlib import Path

root = Path(__file__).resolve().parents[1]
stage = json.loads((root / "build/native/staged-web.json").read_text())
if stage.get("nativeBridgeVersion") != 2:
    raise SystemExit("Stage the matching migration/native-effects web bridge before building")
if "GARDEN_QA_SERVICES" in os.environ.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "").split():
    if stage.get("ads") != "official_test":
        raise SystemExit("Stage a verified SDK/test-ad candidate with the connected ad notice first")
