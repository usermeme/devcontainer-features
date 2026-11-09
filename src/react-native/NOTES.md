## Motivation

iOS Simulators cannot run inside a Linux Docker container (they require Apple's Darwin kernel, Metal, and Xcode frameworks). Android Emulators inside Docker on macOS lack hardware acceleration (KVM).

This feature bridges your devcontainer to the **iOS Simulators** and **Android Emulators** running natively with hardware acceleration on your host machine, providing a unified agent-friendly CLI (`sim`) to inspect, tap, type, and capture screens.

## Host requirements

### 1. iOS Simulator Support (macOS Host)
Install Meta's `idb-companion` on your macOS host:

```bash
brew tap meta/fb
brew install meta/fb/idb-companion
```

Run `idb_companion` listening on port `10882`:
```bash
idb_companion --port 10882
```

*(Tip: Automate this before container start in `.devcontainer/devcontainer.json`)*:
```json
"initializeCommand": "idb_companion --port 10882 &"
```

### 2. Android Emulator Support
Start your Android Emulator or connect a device on the host, and ensure the host's ADB server listens on all interfaces:
```bash
adb -a -P 5037 nodaemon server
```

### 3. Forward Metro Bundler Port
In your project's `.devcontainer/devcontainer.json`, forward port 8081:
```json
"forwardPorts": [8081]
```
The iOS Simulator and Android Emulator on your host connect to `http://localhost:8081`, which routes directly into the devcontainer's Metro packager.

## How it works

- **Unified CLI (`sim` / `mobile-sim`)**: An agent-friendly command-line tool that auto-detects active iOS or Android devices and runs automation actions.
- **`idb` (iOS Development Bridge)**: Meta's client installed in `/usr/local/lib/idb/venv` with preconfigured `IDB_COMPANION=host.docker.internal:10882`.
- **`adb` (Android Debug Bridge)**: Preconfigured with `ADB_SERVER_SOCKET=tcp:host.docker.internal:5037` to talk to host emulators.
- **Watchman**: File-watching service required by React Native Metro packager.

## Agent Simulator CLI (`sim`)

Agents (Hermes, Antigravity, OpenCode, Claude Code) can control the host simulator with simple commands:

```bash
# Check device connections
sim devices
sim bridge-status

# Visual inspection (save screenshot for vision models)
sim screenshot screen.png

# Accessibility inspection (DOM-like UI hierarchy with coordinates)
sim ui

# Touch, text, and gestures
sim tap 200 450
sim text "user@example.com"
sim key HOME
sim swipe 200 600 200 100

# App lifecycle
sim launch com.example.myapp
sim install ./ios/build/MyApp.app
```
