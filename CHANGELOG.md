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

## 2026-11-24 — M0: guide.html created
- Created `guide.html` (repo root): self-contained milestone report page in ASD-STE100 Simplified Technical English; seeded with M0 progress report (steps 1–7 status, real verification output from prior steps), M1–M6 placeholders.
- Recorded standing rule: after each milestone, write its detailed STE report in `guide.html` (APP.md working protocol item 9; AGENTS.md protocol bullet).

## 2026-11-24 — M0 step: landscape lock for mobile
- Developer confirmed the cube and both GLB karts render on the Pixel 6; skipped the frame-rate test by decision. The only issue was screen orientation (portrait).
- Added `SystemChrome.setPreferredOrientations` (landscapeLeft/landscapeRight) in `main()` before `runApp()` so the first frame is landscape. Analyzer warning about `_logFps` is pre-existing (call still commented out); format clean.
- Updated guide.html M0: phone render marked done, FPS test marked skipped, landscape fix recorded.

## 2026-11-24 — M0 step: README with pinned versions and run commands
- Rewrote `kart_racer_flutter/README.md`: verified pins (Flutter 3.50.1, Dart 3.14.0, Serverpod 4.1.2, flutter_scene 0.24.4), run commands (serverpod runner start, flutter run -d macos, flutter run on Pixel 6, dart test), landscape note, known CI/Flutter version mismatch (CI 3.44.4).
- guide.html M0: README acceptance criterion marked done; only landscape confirmation and status-tracker check-off remain.
- Checked latest package versions: Serverpod 4.1.2 is already latest; flutter_scene 0.24.6 exists (pin is 0.24.4); global serverpod_cli is 4.1.1 vs project 4.1.2.

## 2026-11-25 — M0 step: minimal package upgrade (approved)
- Upgraded flutter_scene 0.24.4 → 0.24.6 (exact pin) and activated global serverpod_cli 4.1.2 to match project packages. Serverpod packages were already latest (4.1.2).
- Verified: `flutter pub get` resolved; `dart analyze` and `dart format` clean; fresh `flutter run -d macos` built and ran — kart renders, log has no errors (screenshot at /tmp/kart_m0_verify.png).
- Finding: only one kart visible in frame after upgrade. Root cause is framing, not the upgrade — models_view.dart camera/positions were committed 2026-11-24 01:38 (after the Nov 23 both-karts check); type-2 at y=0 projects above the top edge. 0.24.5/0.24.6 changelogs only fix cutout-material depth builds; our karts use lit PBR.
- README and guide.html updated to flutter_scene 0.24.6. Developer to decide on camera framing fix.
