#!/bin/sh
set -eu
POURLUNE_REPO_ROOT="$SRCROOT/../.."
POURLUNE_PYTHON_BIN="${POURLUNE_PYTHON:-$POURLUNE_REPO_ROOT/.venv/bin/python}"
if [ ! -x "$POURLUNE_PYTHON_BIN" ]; then POURLUNE_PYTHON_BIN=python3; fi
if [ -n "${POURLUNE_ADMOB_REGISTRATION:-}" ]; then
  set -- --registration "$POURLUNE_ADMOB_REGISTRATION"
else
  set --
fi
"$POURLUNE_PYTHON_BIN" "$POURLUNE_REPO_ROOT/tools/validation/admob_config.py" \
  --platform ios --native-id "$PRODUCT_BUNDLE_IDENTIFIER" \
  --native-app-id "${POURLUNE_ADMOB_APP_ID:-ca-app-pub-3940256099942544~1458002511}" "$@"
"$POURLUNE_PYTHON_BIN" "$POURLUNE_REPO_ROOT/tools/validation/gamemunchies_config.py" \
  --platform ios --native-id "$PRODUCT_BUNDLE_IDENTIFIER"
"$POURLUNE_PYTHON_BIN" "$POURLUNE_REPO_ROOT/tools/validation/firebase_config.py" \
  --environment "${POURLUNE_FIREBASE_ENV:-none}" --platform ios \
  --config-dir "${POURLUNE_FIREBASE_CONFIG_DIR:-$SRCROOT/../config/firebase}" \
  --registry "${POURLUNE_FIREBASE_REGISTRY:-$POURLUNE_REPO_ROOT/docs/development/evidence/firebase-integration/registration.json}" \
  --check-build --native-id "$PRODUCT_BUNDLE_IDENTIFIER" \
  --stage-ios "$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
