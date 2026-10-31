# SDK 0.2 Android diagnostic — partial, 2026-10-28

On `Pourlune_GM_QA_20261028` (emulator-5554), Android Studio installed the QA APK with clear app storage unchecked. Its initial screen showed the offline first-process phase, two queued events, statistics enabled, and config version 1. The first process evidence was exported to ignored `build/gamemunchies-020/android-device-private/first-process/` before stopping it. The QA APK SHA-256 was `f120d0c9620953badde41e0262660f94d18565e3f099c11999ba53bba3a0ad2a`.

A subsequent Android Studio no-deploy launch attempt timed out waiting for the existing application process; UI clicks on the Android device view were not delivered to the emulator. Same-install recovery, acknowledgement/retry, advertising, privacy withdrawal, cooldown and backend filter checks remain unverified on Android. No ordinary-entry candidate was installed as a substitute. Screenshots show the first offline state.

Follow-up: Android Studio Device Manager stopped only Pourlune GM QA 20261028 and ran its Cold Boot action without wipe. It returned to the home screen on emulator-5554. The detached Running Devices window remains outside the computer-control hit-test region: a swipe returned a window-not-found error and the Dock control reported off-screen, so the existing app could not be opened through that window. The original installed data and first-process export remain in place; no reinstall or wipe was used. Same-install recovery and remaining Android checks are still unverified.

A subsequent window-layout attempt through Android Studio's Window/Active Tool Window menu did not produce an accessible docked device view; the detached view remains inaccessible for input. No global display settings or app data were changed. Recovery remains unverified.
