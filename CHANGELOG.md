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

## 2026-11-25 — M1 step 1: kart_racer_core package created
- Created `kart_racer_core` with `dart create -t package`; added it to the root workspace with `resolution: workspace`; added `vector_math: ^2.4.4` as the only runtime dependency; SDK constraint ^3.12.2 to match the project. Removed the standalone lockfile from `dart create` (workspace owns resolution).
- Verified: root `flutter pub get` → Got dependencies!; `dart test` → All tests passed!; `dart analyze` → No issues found!; imports show only `test` (dev) and self — no Flutter/Serverpod (hard rule 3).

## 2026-11-25 — M1 step 2: vehicle data types
- Added `lib/src/vehicle/`: `VehicleInput` (throttle/steering/brake/drift), `VehicleState` (position/heading/speed/velocity/drifting/boosting), `VehicleParams` (acceleration, braking, topSpeed, turnRate, drag, grip, drift and boost values with placeholder defaults). Exported from `kart_racer_core.dart`; removed template `Awesome`/example scaffolding.
- Documented world conventions in code: Y-up, ground XZ, heading = yaw about +Y (0 → +Z, positive → +X), units m/s/rad. Speed signed (negative = reverse); velocity holds lateral component for drift.
- Verified: `dart analyze` clean, `dart format` clean, `dart test` → 5 tests passed.

## 2026-11-25 — M1 step 3: step() basic handling model
- Added `lib/src/vehicle/vehicle_step.dart`: pure `step(state, input, params, dt)` + `fixedDt = 1/30`. Model order: throttle vs drag (`speed += (throttle*acceleration - drag*speed)*dt`), brake toward zero (no reverse overshoot), top-speed clamp, steering scaled by signed `speed/topSpeed` (standstill → no turn; reverse flips), velocity from heading `(sin h, 0, cos h)*speed`, Euler position integrate on XZ.
- grip/drift/boost params intentionally unused until their milestones (APP.md: drift/boost after basic model tested).
- Added `test/vehicle_step_test.dart`: reaches-but-never-exceeds top speed (+Z straight run), steering at speed vs standstill, braking stops without reversing, no mutation of input state.
- Verified: `dart analyze` clean, `dart format` clean, `dart test` → 10 tests passed.

## 2026-11-25 — M1 step 4: TrackData + test track
- Added `lib/src/track/track_data.dart`: `TrackData` holds unmodifiable centerline/width/checkpoints/leftWall/rightWall lists + `halfWidth` getter; docs state the closed-loop convention (last point connects to first, never repeated).
- Added `lib/src/track/test_track.dart`: `buildTestTrack()` stadium (60 m straights, 15 m radius, 8 m width, 4 checkpoint gates at 0/25/50/75% of loop length). Wall loops offset from the centerline by half width using the right-of-travel normal `(-dz, 0, dx)`; left wall is its negation. Gates placed by cumulative segment length. Exported both from `kart_racer_core.dart`.
- Fixed: `Vector3.lerp` does not exist in vector_math 2.4.4 — gates interpolate component-wise.
- Fixed (root cause): the whole core package now imports `package:vector_math/vector_math_64.dart` instead of `vector_math.dart`. The default entrypoint is the **32-bit** implementation (`Float32List` storage) — track points were silently rounded to float32 (`-42.990379333496094` instead of `-42.99038105676658`), which failed the wall-distance test by ~1e-6. Same dependency, different library file; hard rule 3 unaffected. flutter_scene's `Node.position` stays 32-bit (rendering side converts components in M3).
- Added `test/track_test.dart`: closed loop ≥8 ground points, 8 m width, walls at exactly half width (1e-9 tolerance), 4 distinct ground gates, unmodifiable lists throw `UnsupportedError`.
- Verified: `dart analyze` clean, `dart format` clean, `dart test` → 15 tests passed.

## 2026-11-25 — M1 step 4 follow-up: kart_racer_core becomes its own git repo
- Developer created https://github.com/black-coda/kart_racer_core.git. Core is now standalone: removed `resolution: workspace` from its pubspec (root workspace no longer lists it — root `flutter pub get` / CI must not depend on a directory the root repo does not contain).
- Core verified standalone: `dart pub get` resolves its own graph; `dart analyze`/`dart format` clean; `dart test` → 15 tests passed. Initial commit `63d56a1` pushed to origin/main; package history lives in its own CHANGELOG.md.
- Root repo: recovered the M1 CHANGELOG entries and `kart_racer_flutter/.vscode/settings.json` from the earlier `81314ab` commit (which also held the core files and an accidental empty `.zshrc`); `kart_racer_core/` stays in `.gitignore`. AGENTS.md workspace/current-state sections updated.
