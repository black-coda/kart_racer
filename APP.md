# AGENTS.md: Kart Racer (working title)
 
An original 3D arcade kart racer with online multiplayer. Flutter client, Flutter Scene renderer, Serverpod backend, custom arcade physics in a shared pure-Dart core package.
 
Read this whole file before doing anything. Re-read the "Working protocol" and "Hard rules" sections at the start of every session.
 
---
 
## 0. Status tracker
 
Update this list at the end of every completed step. Do not start a milestone until the one before it is checked and the developer has confirmed.
 
- [ ] M0: Feasibility spike (renderer on macOS/desktop and a real Android phone)
- [ ] M1: Core package (headless simulation, tests)
- [ ] M2: Network spike (can Serverpod host race rooms?)
- [ ] M3: Single-player prototype (playable lap with bots)
- [ ] M4: Multiplayer race
- [ ] M5: Persistence and meta-game
- [ ] M6: Game feel, content, extra platforms
Current pinned versions (fill in during M0, then do not change without asking):
 
- Flutter: 3.50.1 stable (Dart 3.14.0)
- Serverpod: 4.1.2
- flutter_scene: 0.24.4 (exact)
- Test devices: macOS desktop (Apple silicon); Android phone: Pixel 6
---
 
## 1. Project summary
 
- Genre: arcade kart racing, short races (2 to 3 minutes), easy to pick up, drift and boost as skill options, simple items that create comebacks.
- Inspiration: the feel and scope of Beach Buggy Racing. This is a legal and creative boundary, see Hard rule 1.
- Platforms: develop on desktop plus one Android phone first. iOS, Windows and Linux come in M6.
- Multiplayer: online, server-validated, with client prediction and interpolation.
### The primary engineering goal
 
Rendering, vehicle physics, race simulation and networking must stay decoupled. We must be able to replace the renderer or the physics without rewriting the multiplayer backend, and the reverse.
 
---
 
## 2. Working protocol (how to work with this developer)
 
The developer is strong in Flutter (including Riverpod and GoRouter). Assume that knowledge. Do not assume knowledge of 3D rendering, game loops, game networking, or Serverpod.
 
1. **Concept first, code second.** Before writing code for a step, explain the idea in plain language: what it is, why it exists, how it fits the architecture. Use plain text. Do not use diagrams, ASCII art or flowcharts unless asked.
2. **Go slowly.** One small step at a time. After each step, stop, say what you did and how to run or test it, and wait for the developer before continuing.
3. **Do not generate the whole app.** Never create more files than the current step needs.
4. **Fixes must be fully reflected in code.** If you say you fixed something, the delivered code must contain the fix. Re-read the final file before reporting.
5. **Run it.** Every step ends with the developer or you running a concrete command and seeing a concrete result. Report real output, never guessed output.
6. **Say when you are unsure.** Flutter Scene is pre-1.0 and Serverpod 4 is recent. Package APIs and CLI commands in this file may be out of date. Where this file says VERIFY, check the package's current documentation or `--help` output before relying on it, and tell the developer what you found.
7. **No unnecessary abstractions.** Add an interface only where this file says a layer boundary exists, or where two real implementations exist.
8. **Keep a short changelog.** At the end of each step append a line to `CHANGELOG.md`: date, step, what changed, any decision made.
---
 
## 3. Hard rules
 
1. **Original work only.** Do not copy, extract, trace or imitate specific assets, names, characters, kart designs, track layouts, music, logos or code from Beach Buggy Racing or any other game. Genre mechanics (drifting, boosts, item types) are fine. Give the game its own name, look and tracks.
2. **Dependency direction is one-way.** See section 4. A violation is a bug even if the code runs.
3. **The core package never imports Flutter, Serverpod, or Flutter Scene.** Its only runtime dependency is `vector_math` (plus dev dependencies for tests).
4. **Simulation is deterministic and fixed-step.** See section 5.
5. **Simulation never reads real time or randomness directly.** No `DateTime.now()`, `Stopwatch`, `Random()` without a seed passed in.
6. **Gameplay data never comes from visual meshes.** Collision, checkpoints and the racing line come from explicit track data.
7. **Do not send 3D models or scene graphs over the network.** Only compact game state and inputs.
8. **Pin versions.** Do not upgrade Flutter, Serverpod or flutter_scene without asking.
9. **Track asset licenses.** Every third-party asset added gets a line in `assets/LICENSES.md`: source URL, license, author, attribution text if required. Do not add an asset whose license you cannot confirm.
10. **Do not touch generated code by hand.** The Serverpod client package and generated protocol files are produced by `serverpod generate`.
11. **Never put secrets in the repo.** Serverpod's password files stay out of version control.
---
 
## 4. Architecture
 
### Layers and allowed imports
 
Packages and what each may depend on:
 
- `kart_racer_core` (pure Dart): depends on nothing but `vector_math`.
- `kart_racer_server` (Serverpod): may import `kart_racer_core`. May not import Flutter or Flutter Scene.
- `kart_racer_client` (generated by Serverpod): never edited by hand.
- `kart_racer_flutter` (the game): may import `kart_racer_core`, `kart_racer_client`, Flutter and Flutter Scene.
Inside `kart_racer_flutter`, the code is split into four zones with one rule each:
 
- `game/simulation_host`: runs the core simulation on a fixed step. May use core. Does not know about Scene or the network.
- `game/rendering`: reads simulation state and updates Flutter Scene nodes. **Read-only.** It must never change simulation state. All Flutter Scene imports live here and nowhere else.
- `game/networking`: talks to the Serverpod client and maps network messages to and from core types. Does not import rendering.
- `features/*`: menus, lobby, HUD, garage. Use Riverpod for UI state. The game loop and simulation live outside the widget tree.
If swapping the renderer would require edits outside `game/rendering`, the boundary has been broken. Fix it.
 
### Workspace layout
 
```
kart_racer/
  AGENTS.md
  CHANGELOG.md
  kart_racer_core/            pure Dart simulation package (we create this)
  kart_racer_server/          generated by Serverpod, then extended
  kart_racer_client/          generated by Serverpod, do not edit
  kart_racer_flutter/         the game app
    lib/
      app/
      features/{home,garage,lobby,racing}/
      game/{simulation_host,rendering,input,camera,networking}/
    assets/
      LICENSES.md
      vehicles/ tracks/ environments/ effects/
```
 
### Core package contents (target)
 
```
kart_racer_core/lib/
  src/
    math/         small helpers on top of vector_math
    vehicle/      VehicleInput, VehicleState, VehicleParams, step function
    track/        TrackData, checkpoints, wall edges, surface zones, queries
    race/         RaceState, lap/checkpoint logic, results
    items/        added in M6, not before
  kart_racer_core.dart   public exports
```
 
### Network contract
 
- Message types that cross the network are defined in Serverpod's YAML protocol files on the server side, **not** reused from core types.
- A small mapping layer on each side converts between protocol messages and core types. This lets the simulation change without breaking the wire format and the reverse.
- Include a protocol version number in the join handshake from the start.
Minimum message set:
 
- `PlayerInput`: sequence number, tick, throttle, steering, brake, drift.
- `PlayerSnapshot`: player id, last processed input sequence, position, heading, velocity, lap, next checkpoint.
- `RaceSnapshot`: server tick, list of player snapshots.
- Race events: countdown, start, lap completed, finished, player left.
### Rates
 
- Simulation: 30 ticks per second on the server. The client may run the same step at the same rate and interpolate visually between ticks.
- Rendering: whatever the device achieves. Rendering never drives the simulation.
---
 
## 5. Determinism rules for the core package
 
Client prediction only works if client and server produce nearly identical results from identical inputs.
 
1. The simulation advances in fixed steps. `step` receives a constant `dt` constant, never a measured frame time.
2. `step(previousState, input, params, track)` is a pure function that returns a new state. No hidden mutable globals.
3. No wall-clock time, no unseeded randomness, no platform checks.
4. Iteration order must not depend on hash ordering. Use lists or sorted keys.
5. Be aware: trigonometric and similar math can differ in the last bits across CPU architectures and across web versus native. Therefore the server is always the source of truth, the client reconciles against it, and reconciliation must tolerate tiny error. Do not rely on bit-exact equality across devices.
6. Authoritative simulation targets the native Dart VM. Do not treat web builds as a determinism-safe target.
7. Every change to the vehicle step function must keep the determinism test passing (M1).
---
 
## 6. Milestones
 
Each milestone lists: goal, concepts to explain first, tasks, acceptance criteria, and what is out of scope. Do not skip the "concepts" part.
 
### M0: Feasibility spike
 
**Goal.** Prove the renderer works on the developer's desktop and on a real Android phone before building anything that depends on it.
 
**Concepts to explain first.**
 
- What a GPU does with triangles, and why a 3D object needs a camera, lights and materials.
- The chain: Flutter Scene builds the scene, Flutter GPU is the low-level door, Impeller talks to the graphics API (Metal, Vulkan, etc.).
- Why Flutter GPU must be enabled explicitly, and why a pre-1.0 package needs pinned versions.
- What a GLB file is: one file with a model's shape, textures, materials and optional animation.
**Tasks.**
 
1. Create the Serverpod workspace if it does not exist: `serverpod create kart_racer` (interactive, accept defaults, choose the developer's editor or agent). VERIFY that `kart_racer_server`, `kart_racer_client` and `kart_racer_flutter` were created. Show the developer the folder listing and do not modify anything until they confirm.
2. Run the generated starter server and app once to confirm client and server connect. VERIFY the current start command (`serverpod start` is expected for Serverpod 4; older versions used `docker compose up` and `dart bin/main.dart --apply-migrations`). Report what actually worked.
3. In `kart_racer_flutter`: `flutter pub add flutter_scene`, then `dart run flutter_scene:init`. VERIFY against the package's current README. The init step is expected to add a build hook and an asset directory entry to `pubspec.yaml`.
4. Enable Flutter GPU. For development, run with `--enable-flutter-gpu` (and `--enable-impeller` if the package README still asks for it). For desktop shipping builds, the package docs describe a one-line setting in the platform runner files. VERIFY and apply only for platforms being tested.
5. Render the package's built-in cube first (no asset pipeline needed). Then load one free GLB kart or a simple placeholder model and display it, slowly rotating.
6. Measure frame rate with Flutter's performance overlay on desktop and on the Android phone, in release or profile mode (not debug).
7. Record pinned versions in the status tracker.
**Acceptance criteria.**
 
- A cube and then a GLB model render on desktop and on the Android phone.
- Frame rate on the phone is stable. Record the number and the device.
- Pinned versions and the exact run commands are written into `README.md` in `kart_racer_flutter`.
**Out of scope.** Gameplay, input, tracks, networking, custom assets.
 
**If it fails.** Stop and report the exact error, the package version and the device. Do not work around it by switching engines without asking.
 
---
 
### M1: Core package (headless simulation)
 
**Goal.** A pure-Dart simulation that can drive a kart around a track and count a lap with no graphics and no network.
 
**Concepts to explain first.**
 
- Fixed time step versus variable frame time, and why determinism depends on it.
- Why a kart is modeled as a position, heading, speed and grip values rather than a rigid-body physics object (arcade handling is designed, not simulated).
- State, input and step function: `nextState = step(state, input)`.
- How tracks are represented as data: a centerline curve, track width, checkpoint gates, wall edges and surface zones.
**Tasks.**
 
1. Create the package: `dart create -t package kart_racer_core` inside `kart_racer/`. Add `vector_math` as the only runtime dependency.
2. Define `VehicleInput` (throttle, steering, brake, drift), `VehicleState` (position, heading, speed, velocity, drift and boost state), and `VehicleParams` (acceleration, top speed, turn rate, grip, drift behavior, boost values). Start simple: movement on a flat plane.
3. Implement `step` with a first handling model: acceleration, braking, drag, speed-dependent steering. Explain each parameter to the developer. Drift and boost can be added after the basic model is tested.
4. Define `TrackData` and a hand-written test track as plain Dart data: centerline points, width, ordered checkpoint gates, wall edges.
5. Implement track queries: nearest point on the centerline, signed distance from center, whether a kart is inside the track.
6. Implement wall collision as a simple response (clamp position and reduce speed). No kart-to-kart collisions yet.
7. Implement checkpoint and lap logic in `RaceState`: checkpoints must be crossed in order, a lap counts only after all checkpoints.
8. Write tests (see below).
**Tests (required).**
 
- Straight-line acceleration reaches but does not exceed top speed.
- Steering at speed changes heading, steering at standstill does not.
- Driving a scripted input sequence completes one lap and the lap count is 1.
- Skipping a checkpoint prevents the lap from counting.
- **Determinism test:** run the same input log twice and require identical final state. Also run it as a golden test that compares against a saved result.
- Wall collision keeps the kart on the track.
**Acceptance criteria.** `dart test` passes in `kart_racer_core`. A headless script prints a lap time for a scripted run. The package has no Flutter or Serverpod imports (check `pubspec.yaml` and imports).
 
**Out of scope.** Rendering, UI, items, other karts, networking.
 
---
 
### M2: Network spike
 
**Goal.** Decide, with measurements, whether Serverpod can host real-time race rooms or whether race simulation should run in a separate Dart process.
 
**Concepts to explain first.**
 
- Client-server architecture for games: client sends inputs, server decides, server broadcasts snapshots.
- WebSockets run over TCP, so one delayed packet delays those behind it. Why that matters for racing.
- Latency (delay), jitter (variation in delay), and tick rate.
- How Serverpod models real-time communication. VERIFY in current docs (streaming endpoint methods and session handling in Serverpod 4).
**Tasks.**
 
1. Add a server-side room object that ticks at 30 Hz using a timer, holding a list of players.
2. Define the minimal protocol messages from section 4 in Serverpod YAML and run `serverpod generate`.
3. Create a streaming endpoint where a client sends `PlayerInput` and receives `RaceSnapshot`. Use a **fake simulation** at this stage (for example, integrate a value) so this stage measures only networking.
4. Build a small test client (command-line Dart script or a debug screen) that connects two clients and logs round-trip time and snapshot arrival intervals.
5. Run with simulated bad networks if possible (added latency and packet delay) and record results.
6. Test with the server on the developer's machine and, if possible, on a remote host.
**Acceptance criteria.** A short written report in `docs/m2-network-report.md` with: measured latency and jitter, whether a 30 Hz loop kept its timing under load (for example 8 simulated players in one room), and a recommendation: keep rooms in Serverpod, or move race simulation to a separate Dart process that uses `kart_racer_core`. Wait for the developer's decision before building on it.
 
**Out of scope.** The real vehicle simulation, prediction, matchmaking, persistence.
 
---
 
### M3: Single-player prototype
 
**Goal.** A kart game you would enjoy repeating, running locally with bots, using the real core simulation.
 
**Concepts to explain first.**
 
- The game loop: an accumulator that runs zero or more fixed simulation steps per rendered frame.
- Interpolation: drawing a state between two simulation ticks so motion looks smooth at any frame rate.
- Why rendering is read-only and how the renderer adapter maps `VehicleState` to a scene node.
- Camera follow behavior: smoothing, look-ahead and field-of-view changes with speed.
**Tasks.**
 
1. `game/simulation_host`: a fixed-step loop driven by a `Ticker`, with an accumulator and a cap on catch-up steps to avoid spiral-of-death.
2. `game/input`: keyboard input for desktop and on-screen touch controls for mobile, both producing `VehicleInput`. Input source is swappable.
3. `game/rendering`: renderer adapter that creates the scene, places the kart model (placeholder box first), places the track visuals, and each frame sets node transforms from interpolated state. Keep all Flutter Scene imports in this folder.
4. `game/camera`: third-person chase camera.
5. Visual track: a simple track mesh (placeholder or free asset) that matches the hand-written `TrackData`. If they do not match, fix the data, not the physics.
6. HUD: speed, lap, position and timer, using Riverpod providers fed from the simulation host.
7. Bots: simple controllers that follow the centerline and produce `VehicleInput` through the same core step function. A race with 3 to 5 bots.
8. Tuning pass with the developer: adjust `VehicleParams` until it feels good. This is the most important task in the milestone.
**Acceptance criteria.** A full lap and a full multi-lap race against bots on desktop and on the Android phone at stable frame rate. The renderer can be disabled (headless mode) and the simulation still runs. A grep shows no Flutter Scene imports outside `game/rendering`.
 
**Out of scope.** Items, online play, custom art, audio.
 
---
 
### M4: Multiplayer race
 
**Goal.** Two real devices finish a race together on a poor connection.
 
**Concepts to explain first.**
 
- Authoritative server versus trusting the client.
- Client-side prediction: the client applies its own input immediately and replays unacknowledged inputs after a server correction (reconciliation).
- Interpolation of other players: render them about 100 ms in the past between two server snapshots.
- Why kart-to-kart bumps are soft effects in the first version.
- Clock and tick synchronization.
**Tasks.**
 
1. Implement the real room: join with protocol version check, lobby state, ready-up, countdown, start, finish, results. Room logic uses `kart_racer_core` (or runs in the separate process if M2 decided that).
2. Server tick loop: collect latest input per player (buffered by sequence), step the simulation, broadcast `RaceSnapshot`.
3. Server validation: speed limits, checkpoint order, on-track checks. Correct a client only when it diverges beyond a tolerance.
4. Client prediction and reconciliation for the local kart in `game/networking`.
5. Interpolation buffer for remote karts.
6. Handle disconnects and late joiners: mark a disconnected player, let the race continue.
7. Soft kart-to-kart interaction: small push or slowdown applied on the server, not a shared hard collision.
8. Test with simulated latency and packet delay. Record results in `docs/m4-test-notes.md`.
**Acceptance criteria.** Two devices complete a multi-lap race. Remote karts move smoothly. The local kart does not visibly snap under normal conditions. Results are consistent on both screens. Protocol version mismatch is rejected cleanly.
 
**Out of scope.** Rankings, matchmaking by skill, items, anti-cheat beyond basic validation.
 
---
 
### M5: Persistence and meta-game
 
**Goal.** Accounts, history and a reason to come back.
 
**Concepts to explain first.**
 
- What belongs in the database (profiles, results, rankings) versus in-memory room state (the live race).
- Serverpod models and migrations: YAML defines tables, `serverpod generate` and `serverpod create-migration` produce SQL. VERIFY current migration commands.
- Authentication in Serverpod. VERIFY the current auth module and how it differs in Serverpod 4.
**Tasks.**
 
1. Authentication (guest and one real method to start).
2. Player profile model: display name, selected kart, stats.
3. Race result model: race id, players, finish order and times, track id, timestamp.
4. Save results when a race ends. Never trust client-reported results.
5. Simple ranking or leaderboard endpoint and a screen to show it.
6. Kart selection screen (`features/garage`) using free or placeholder models.
7. Reconnect to a race in progress if feasible.
**Acceptance criteria.** Profiles and race history persist across server restarts. Results are written by the server only. Migrations apply cleanly on a fresh database.
 
---
 
### M6: Game feel, content and platforms
 
**Goal.** Make it feel like a finished game and run on more platforms.
 
Possible tasks, to be prioritized with the developer, one at a time:
 
- Items and boosts (add `core/items/`, keep them deterministic and server-validated).
- Drift refinement, effects (dust, boost flames), audio.
- More tracks and a track selection screen. Custom Blender models for the karts and one hero track.
- Menu polish and onboarding.
- Additional platforms: iOS, Windows, Linux. Each needs the Flutter GPU enable step for that platform (VERIFY), and a performance check.
- Performance pass on low-end Android: triangle budget, draw calls, texture sizes.
---
 
## 7. Assets
 
- Start with placeholders (boxes, flat ribbons). Do not block gameplay work on art.
- Prefer permissive sources (for example CC0 packs). Record every asset in `assets/LICENSES.md` (Hard rule 9).
- Conventions to apply to every model: 1 unit = 1 meter, Y up, the kart faces forward along one fixed axis (decide in M0 and write it down here).
- Polygon budget (starting point, adjust after M0 measurements): karts in the low thousands of triangles, tracks built from modular pieces.
- Textures: keep them small and compressed for mobile.
- Never extract or reuse assets from commercial games.
---
 
## 8. Testing and quality
 
- `kart_racer_core`: unit tests and the determinism golden test run on every change to simulation code.
- Run `dart analyze` and `dart format` before reporting a step as done. Fix all warnings you introduce.
- Server: use Serverpod's test tooling where available. VERIFY how tests are run in Serverpod 4.
- Keep each file focused. Prefer small files with clear names over large ones.
- Comments explain why, not what.
---
 
## 9. Definition of done (every step)
 
A step is done only when all of these are true:
 
1. The concept was explained before the code.
2. The code runs, and you ran it or told the developer exactly what to run and what to expect.
3. Tests relevant to the step pass.
4. `dart analyze` is clean for touched packages.
5. No Hard rule is violated (check dependency direction and imports).
6. `CHANGELOG.md` and the status tracker are updated.
7. You stopped and asked the developer before starting the next step.
---
 
## 10. Open decisions (ask the developer, do not decide silently)
 
- Final game name and visual identity.
- Whether race rooms live in Serverpod or a separate Dart process (decided at the end of M2).
- Simulation rate beyond 30 Hz for local play.
- Which authentication methods to support in M5.
- Which items to include in M6.
 