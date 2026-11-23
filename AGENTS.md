# Flutter & Serverpod project

Kart Racer: an original 3D arcade kart racer with online multiplayer. Flutter client, Flutter Scene renderer, Serverpod backend, custom arcade physics in a shared pure-Dart core package.

Game design, architecture, milestones, hard rules, and the working protocol live in `APP.md`. Read it before game work; this file does not duplicate it.

## Current state

Still the Serverpod starter (greetings endpoint, sign-in screens). Game packages and zones (`kart_racer_core`, `game/*`) do not exist yet. Follow APP.md milestones in order; do not start a milestone until the previous one is checked and the developer has confirmed.

## Working protocol (from APP.md — full text there)

- Concept first: explain the idea in plain language before writing code for a step.
- One small step at a time. After each step, stop, say what you did and how to run/test it, and wait for the developer.
- Do not generate the whole app. Never create more files than the current step needs.
- Every step ends with a concrete command and real output — never guessed output.
- Say when you are unsure. Package APIs may be out of date; verify before relying on them.
- Append a line to `CHANGELOG.md` at the end of each step (file may not exist yet — create it).
- No unnecessary abstractions; comments explain why, not what.

## Hard rules that constrain every code change (from APP.md — full text there)

- **Dependency direction is one-way.** `kart_racer_core` (pure Dart, only `vector_math`) → `kart_racer_server` (may import core, never Flutter) → `kart_racer_client` (generated, never edited) → `kart_racer_flutter` (may import core, client, Flutter, Flutter Scene). Inside the Flutter app: `game/simulation_host` (fixed-step core loop), `game/rendering` (**read-only**; all Flutter Scene imports live here only), `game/networking` (Serverpod client ↔ core types), `features/*` (Riverpod UI). A violation is a bug even if the code runs.
- **Simulation is deterministic and fixed-step.** Pure `step(state, input)`; constant `dt`; no `DateTime.now()`, `Stopwatch`, or unseeded `Random()`. Server is source of truth; reconciliation tolerates tiny cross-arch float error.
- **Do not send 3D models or scene graphs over the network.** Only compact game state and inputs.
- **Pin versions.** Do not upgrade Flutter, Serverpod, or flutter_scene without asking.
- **Never put secrets in the repo.** Serverpod password files stay out of version control.
- **Original work only.** No assets/names/tracks from commercial games. Every third-party asset gets a line in `assets/LICENSES.md`.
- **Gameplay data never comes from visual meshes.** Collision, checkpoints, racing line come from explicit track data.

## Versions (trust pubspec/CI)

- Flutter: `^3.44.4` (CI pins `3.44.4`)
- Serverpod: `4.1.2` (exact, all packages)
- Dart SDK: `^3.12.2`
- APP.md's status tracker lists Flutter 3.50.1 as aspirational — not confirmed in config; do not treat as pinned.

## Workspace layout

Root `pubspec.yaml` is a Dart workspace (`flutter pub get` at root):

- `kart_racer_server/` — Serverpod server; entry `lib/server.dart` (auth already set up: JWT + email IDP).
- `kart_racer_client/` — generated client package; never edit by hand.
- `kart_racer_flutter/` — the game app; entry `lib/main.dart`, driver entry `lib/driver.dart`.
- `kart_racer_core/` — planned pure-Dart simulation package (APP.md M1); does not exist yet.

## Serverpod runner and MCP

The server and Flutter app run under the Serverpod runner, a background process per server package. The user attaches to it with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then call `tail_runner_logs` to learn whether it is still starting or why it stopped. If nothing is running, start it with `serverpod runner start` in `kart_racer_server`, which returns once the server is up and leaves it running for the user to attach to. If it fails, fix the cause it reports (a build error, a port held by another process, Docker) instead of retrying; only a `serverpod runner start` your shell killed on a timeout is run again, since the runner keeps starting. Flutter apps declared with `auto_launch` launch once the user attaches; launch any app before that with the MCP tool `spawn_flutter_app`. Leave the runner running, and run `serverpod runner stop` only when asked.

While running, the runner watches for file changes to run incremental code generation and hot reload both the server and the Flutter app. `serverpod runner status` prints its state and the server addresses, which are not always the configured ports when another Serverpod runner on the machine holds them.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line for the tasks below. The `serverpod runner` commands are the exception: they manage the stack itself. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_runner_logs` to read the output of the runner itself (code generation, compilation, Docker, raw server output). The only tool that also works while the server is starting or after it stopped.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `kart_racer_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the MCP is not available or `serverpod runner start` cannot bring the server up, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; the runner applies pending migrations when it boots the server.

## Tests

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

CI (`.github/workflows/`) only analyzes, formats, and tests `kart_racer_server`:

- analyze: `dart analyze --fatal-infos` (in `kart_racer_server`)
- format: `dart format --set-exit-if-changed .` (in `kart_racer_server`)
- tests: `dart test` (in `kart_racer_server`)
- deploy: Serverpod Cloud on pushes to the `deploy` branch

Server analysis excludes `lib/src/generated/**` and the generated test tools. Formatter uses `trailing_commas: preserve` in both server and Flutter packages.

## Checklist after doing changes, in this order

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

## Driving the app with the Flutter driver

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `kart_racer_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.
