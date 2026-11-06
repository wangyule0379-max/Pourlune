"""Fail closed when the native service flag and frozen web notice disagree."""
import json
import os
from pathlib import Path

if "GARDEN_QA_SERVICES" in os.environ.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "").split():
    root = Path(__file__).resolve().parents[1]
    stage = json.loads((root / "build/native/staged-web.json").read_text())
    if stage.get("ads") != "official_test":
        raise SystemExit("Stage a verified SDK/test-ad candidate with the connected ad notice first")
