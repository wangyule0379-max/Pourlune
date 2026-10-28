#!/bin/sh
set -eu

# Only the manual archive command opts in. Simulator/debug builds are untouched.
[ "${POURLUNE_REPAIR_PRIVACY_MANIFESTS:-0}" = "1" ] || exit 0
: "${POURLUNE_PYTHON:?Manual archive must select the project Python runtime}"
exec "$POURLUNE_PYTHON" "$SRCROOT/../../tools/validation/ios_privacy_manifests.py" \
  --app "$TARGET_BUILD_DIR/$WRAPPER_NAME" --repair-build-product
