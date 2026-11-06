"""Fail closed when service flags, app identity and frozen web payload disagree."""
import json
import os
from pathlib import Path

root = Path(__file__).resolve().parents[1]
stage = json.loads((root / "build/native/staged-web.json").read_text())
flags = os.environ.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "").split()
qa = "GARDEN_QA_SERVICES" in flags
production = "GARDEN_PRODUCTION_SERVICES" in flags
if qa and production:
    raise SystemExit("Choose one explicit service environment")
if stage.get("nativeBridgeVersion") != 5:
    raise SystemExit("Stage the matching environment/migration web bridge before building")
identity = "com.pourlune.app" if production else "dev.pourlune.glassgarden.localqa"
if stage.get("identity") != identity or stage.get("serviceTarget") != ("production" if production else "test"):
    raise SystemExit("Staged service environment/identity mismatch")
if os.environ.get("PRODUCT_BUNDLE_IDENTIFIER") != identity:
    raise SystemExit("Actual app identity does not match the staged environment")
if production and (os.environ.get("CONFIGURATION") != "Release" or os.environ.get("GARDEN_APP_DISPLAY_NAME") != "Pourlune"):
    raise SystemExit("Production requires Release and the existing Pourlune display name")
if qa or production:
    if stage.get("ads") != "official_test":
        raise SystemExit("Stage a verified SDK/test-ad candidate with the connected ad notice first")

if production and (os.environ.get("MARKETING_VERSION") != stage.get("version") or os.environ.get("CURRENT_PROJECT_VERSION") != stage.get("buildNumber")):
    raise SystemExit("Production version/build must match the explicit store-verified stage")
