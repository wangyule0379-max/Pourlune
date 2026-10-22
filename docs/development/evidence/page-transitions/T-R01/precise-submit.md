# R01 precise submission sources

Base HEAD `46e3d67aec10118cac36e210853ea57298376cfc`. Full list and SHA: precise-submit-manifest.json (55 files). Bundle: `build/page-transitions-r01-candidates/precise-submit-files.zip` SHA256 `ee9765b8052849c649e7864ce6b627183fe47052918ed22e47b74a7d7b6f9d04`. This is submission material, not a new build. The original 349-file source freeze and built candidates remain unchanged. No staging, commit or push performed. Text changes: head-product-text.patch; PNG content must come from the ZIP.

## Required M prerequisites

The 8cb/R01 runtime includes M changes absent from HEAD. main.dart retains M startup concurrency protection and local Home image predecode; R01 changes only its shell/background. knitArtImage and warmScene are direct dependencies of that main. game_controller changes only visual motion duration by poured units. board_page must be the frozen Flutter M board (arrival/press/pour), never the current root full-Flame version. collection_pages uses shared success timing; service_views uses showKnitDialog. The M tests and separate QA entrypoints preserve that tested baseline. motion/game_screen/navigation/pourlune_app contain shared M and T presentation changes.

Keep the newer HEAD b04_hint_events_test.dart and b05_accessibility_test.dart. The freeze contains their pre-repair versions, which must not be restored. Root motion_test/system_motion_test full-board adaptations are absent from this candidate difference and excluded. Core/storage/SDK service implementation has no candidate difference from HEAD. Dependency changes are only animations3.0.0 and material_ui1.8.0/cupertino_ui1.1.4; existing Flame pin remains.

## Complete include list


M + T shared presentation:

- `app/lib/presentation/game_screen.dart`
- `app/lib/presentation/motion.dart`
- `app/lib/presentation/navigation_pages.dart`
- `app/lib/presentation/pourlune_app.dart`

M prerequisite:

- `app/integration_test/motion_polish_app.dart`
- `app/integration_test/motion_route_app.dart`
- `app/lib/application/game_controller.dart`
- `app/lib/main.dart`
- `app/lib/presentation/board_page.dart`
- `app/lib/presentation/collection_pages.dart`
- `app/lib/presentation/knit_components.dart`
- `app/lib/presentation/scene_art.dart`
- `app/lib/presentation/service_views.dart`
- `app/test/motion_arrival_test.dart`
- `app/test/motion_polish_test.dart`
- `app/test/motion_primitives_test.dart`
- `app/test/startup_motion_test.dart`

R01 startup:

- `app/android/app/src/main/kotlin/dev/pourlune/pourlune_dev/MainActivity.kt`
- `app/android/app/src/main/res/drawable-hdpi/startup_icon.png`
- `app/android/app/src/main/res/drawable-hdpi/startup_wordmark.png`
- `app/android/app/src/main/res/drawable-mdpi/startup_icon.png`
- `app/android/app/src/main/res/drawable-mdpi/startup_wordmark.png`
- `app/android/app/src/main/res/drawable-v21/launch_background.xml`
- `app/android/app/src/main/res/drawable-xhdpi/startup_icon.png`
- `app/android/app/src/main/res/drawable-xhdpi/startup_wordmark.png`
- `app/android/app/src/main/res/drawable-xxhdpi/startup_icon.png`
- `app/android/app/src/main/res/drawable-xxhdpi/startup_wordmark.png`
- `app/android/app/src/main/res/drawable-xxxhdpi/startup_icon.png`
- `app/android/app/src/main/res/drawable-xxxhdpi/startup_wordmark.png`
- `app/android/app/src/main/res/drawable/launch_background.xml`
- `app/android/app/src/main/res/values-night-v31/styles.xml`
- `app/android/app/src/main/res/values-night/styles.xml`
- `app/android/app/src/main/res/values-v31/styles.xml`
- `app/android/app/src/main/res/values/colors.xml`
- `app/android/app/src/main/res/values/styles.xml`
- `app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`
- `app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`
- `app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`
- `app/ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `app/ios/Runner/Base.lproj/Main.storyboard`
- `app/lib/presentation/startup_view.dart`
- `app/test/startup_shell_test.dart`

R01 tools/docs/manifest:

- `docs/design/production-candidates/runtime/manifest.json`
- `docs/design/production-candidates/runtime/ui/manifest.json`
- `tools/assets/README.md`
- `tools/assets/startup_assets.py`
- `tools/assets/test_startup_native.py`
- `tools/validation/startup_capture.py`
- `tools/validation/startup_frame_check.py`
- `tools/validation/startup_frames.swift`

T dependency/test/QA:

- `app/README.md`
- `app/integration_test/page_transitions_app.dart`
- `app/pubspec.lock`
- `app/pubspec.yaml`
- `app/test/page_transitions_test.dart`

## Exclusions and integration notes

Do not include QA applicationId/Manifest overlays, temporary xcconfig, binaries/private config, full-Flame board/sample capacity work/support, tracking/plans or independent review documents. Production Gradle/Manifest stay at HEAD. The root page_transitions_test specific wait adaptation belongs to the original developer; the frozen test in this bundle is provenance only and must not overwrite their in-progress root work.

The two manifest corrections are from physical copies inside R01, with full recursive equality outside geometry source SHA metadata. check_manifest(candidate) passes for both, and root manifests remain unchanged. See manifest-correction-check.json and manifest-corrections.patch. The app README is frozen documentation plus the R01 section, excluding later full-board text; tools/assets/README documents density packaging. Delivery/evidence files should be selected separately from page-transitions.md and T-R01; do not stage unrelated owner documents.
