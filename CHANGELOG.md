# Changelog

## 2026-11-23 — M0 step 3: flutter_scene
- Added `flutter_scene` 0.24.4 (exact pin) to `kart_racer_flutter`; ran `dart run flutter_scene:init` (hook/build.dart + `flutter_scene_generated/` asset entry). Declined optional agent-skills install.
- Decision: pin exact version per APP.md hard rule 8; recorded pins and test devices (macOS, Pixel 6) in APP.md status tracker.

## 2026-11-23 — M0 step 4: Flutter GPU enabled (macOS)
- Developer already added `FLTEnableFlutterGPU` to `macos/Runner/Info.plist`; verified present in source and built app bundle. No `--enable-impeller` needed (README: default on native since Flutter 3.47).

## 2026-11-23 — M0 step 5: built-in cube renders on macOS
- Added `lib/game/rendering/cube_view.dart` (only file with flutter_scene imports); `main.dart` home now shows it. Built-in `CuboidGeometry` + `PhysicallyBasedMaterial`, no assets. Analyzer + format clean; added `vector_math` dep and used `material_ui` import per project convention.
- Verified live: `flutter run -d macos --debug` logs `pipeline build took ... for PhysicallyBasedMaterial on CuboidGeometry`; screenshot shows the lit cube in the `kart_racer` window.

## 2026-11-23 — M0 step 6: both GLB karts load and spin on macOS
- Registered `assets/3d/` in pubspec; added `lib/game/rendering/models_view.dart` (Scene imports only under game/rendering); home switched to it. `loadScene` for type-1.glb (HotRod) and type-2.glb (Toy Car), side by side, slow Y spin via `SceneView.onTick`. Build hook emitted `scene.type-*.fsceneb`.
- Verified live: two frames show both karts upright (Y-up, wheels on ground), authored scale (no rescale), rotating; analyzer + format clean. Authored bounds: type-1 ≈0.9×0.54×1.4 m, type-2 ≈1.19×0.28×0.49 m.
