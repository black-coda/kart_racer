# Changelog

## 2026-11-23 — M0 step 3: flutter_scene
- Added `flutter_scene` 0.24.4 (exact pin) to `kart_racer_flutter`; ran `dart run flutter_scene:init` (hook/build.dart + `flutter_scene_generated/` asset entry). Declined optional agent-skills install.
- Decision: pin exact version per APP.md hard rule 8; recorded pins and test devices (macOS, Pixel 6) in APP.md status tracker.

## 2026-11-23 — M0 step 4: Flutter GPU enabled (macOS)
- Developer already added `FLTEnableFlutterGPU` to `macos/Runner/Info.plist`; verified present in source and built app bundle. No `--enable-impeller` needed (README: default on native since Flutter 3.47).

## 2026-11-23 — M0 step 5: built-in cube renders on macOS
- Added `lib/game/rendering/cube_view.dart` (only file with flutter_scene imports); `main.dart` home now shows it. Built-in `CuboidGeometry` + `PhysicallyBasedMaterial`, no assets. Analyzer + format clean; added `vector_math` dep and used `material_ui` import per project convention.
- Verified live: `flutter run -d macos --debug` logs `pipeline build took ... for PhysicallyBasedMaterial on CuboidGeometry`; screenshot shows the lit cube in the `kart_racer` window.
