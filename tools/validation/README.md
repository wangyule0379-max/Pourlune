# B05 validation utilities

`b05_lifecycle.py` uses Python's standard library and macOS `xcrun simctl`. Run from the project root with `.venv/bin/python` (Python3.11+). It requires the standalone **QA entrypoint already installed**; it never installs an app or operates on the ordinary development identity. It is not a production app interface or a Firebase/AdMob transport.

1. Create an external Xcode override containing `PRODUCT_BUNDLE_IDENTIFIER = dev.pourlune.b05Validation`, for example `/tmp/pourlune-b05.xcconfig`. Do not modify production project identity.
2. From `app/`:

   ```sh
   XCODE_XCCONFIG_FILE=/tmp/pourlune-b05.xcconfig FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --simulator --debug -t integration_test/b05_lifecycle_app.dart
   xcrun simctl install <simulator-id> build/ios/iphonesimulator/Runner.app
   ```

3. From the project root:

   ```sh
   .venv/bin/python tools/validation/b05_lifecycle.py --device <simulator-id> --out docs/development/evidence/B05/lifecycle-repeat
   ```

The QA entrypoint deletes only `b05_lifecycle.sqlite` when an explicit prepare command resets its QA state. The runner pins the QA bundle, checks the PID's executable path, and uses SIGKILL at seven save/reveal boundaries plus an active900ms animation. Every launch asserts the same container and executable. It checks exact snapshots, both-slot preservation, SQL integrity/schema5, one receipt/award, an observed active SceneArt reveal followed by interruption/re-entry/acknowledgment/another cold launch without repeat, controlled saved/unconfirmed/uncommitted reward outcomes, and10 move/undo/immediate hint-cancel cycles. Receipt barriers block only this test binary for30s so the host can kill an actually open transaction; they are not production delays. No mocked database is used. The ordinary `dev.pourlune.pourluneDev` app and `b04_review_r2.sqlite` are outside its scope.

The Python runner copies JSON/PNG evidence and command results. Choose a fresh --out directory for every run; a previous successful JSON in a reused directory is historical and cannot certify a new failed run. Final success requires the current command exit0 and current B05_LIFECYCLE_PASS marker. Do not run with `python -O`: assertions are acceptance checks. Screenshots produced immediately after a kill may depict the last completed capture; authoritative restore assertions are JSON/SQL, and later `inspect` creates a new render capture. The native integration runner can uninstall its own QA app at teardown; copy its evidence before the end. This is why the bundle override matters.

`app/integration_test/b05_candidate_test.dart` is the separate actual Flutter/sqflite five-flow/short-screen suite. It uses formal bundled60+30 puzzles, explicitly seeded prior progress and controlled ad callbacks. Run with the same QA identity override, then copy `Documents/b05-candidate-evidence/` before teardown. Its12 branch is transaction-failure/Retry; the standalone lifecycle runner supplies actual process-death coverage. Never label either controlled callback test as a real SDK ad reward.

Focused regression: add `--reveal-only` to run just the reveal interruption/acknowledgment chain; it writes reveal-only.json and B05_REVEAL_ONLY_PASS, never the full lifecycle success marker. The final B05 run uses the complete matrix.
