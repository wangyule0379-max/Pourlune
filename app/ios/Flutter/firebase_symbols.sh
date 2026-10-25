#!/bin/sh
set -eu
POURLUNE_REPO_ROOT="$SRCROOT/../.."
POURLUNE_PYTHON_BIN="${POURLUNE_PYTHON:-$POURLUNE_REPO_ROOT/.venv/bin/python}"
if [ ! -x "$POURLUNE_PYTHON_BIN" ]; then POURLUNE_PYTHON_BIN=python3; fi
"$POURLUNE_PYTHON_BIN" "$POURLUNE_REPO_ROOT/tools/validation/firebase_symbols.py"
