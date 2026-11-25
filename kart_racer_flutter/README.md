# kart_racer_flutter

The Flutter game client for Kart Racer, an original 3D arcade kart racer. Part of the `kart_racer` Serverpod workspace (see `APP.md` at the repository root for architecture and milestones).

## Pinned versions (verified 2026-11-25)

| Component  | Version                                |
| ---------- | -------------------------------------- |
| Flutter    | 3.50.1 stable                          |
| Dart       | 3.14.0                                 |
| Serverpod  | 4.1.2 (exact, all packages)            |
| flutter_scene | 0.24.6 (exact pin)                  |

Global `serverpod` CLI: serverpod_cli 4.1.2 (matches the project packages).

Test devices: macOS desktop (Apple silicon), Android phone (Pixel 6).

Do not upgrade Flutter, Serverpod, or flutter_scene without asking the developer (APP.md hard rule 8).

Known mismatch: CI (`.github/workflows/`) pins Flutter `3.44.4`; the development machine runs `3.50.1`.

## Run commands

This repository is a Dart workspace. Run `flutter pub get` once at the repository root:

    cd kart_racer
    flutter pub get

### 1. Start the server

The game connects to the server during startup, so start the server first.

    cd kart_racer_server
    serverpod runner start

The command returns when the server is up and leaves it running. Attach to a runner that is already running with:

    serverpod start

Stop the server with `Q`.

### 2. Start the game

macOS desktop. Flutter GPU is enabled by `FLTEnableFlutterGPU` in `macos/Runner/Info.plist`. No extra run flags are needed.

    cd kart_racer_flutter
    flutter run -d macos

Android (Pixel 6 with USB debugging on):

    cd kart_racer_flutter
    flutter run

Use `flutter devices` if more than one device is connected. The app is locked to landscape on phones and tablets.

### Tests

    cd kart_racer_server
    dart test
