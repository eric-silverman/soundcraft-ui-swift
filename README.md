# SoundcraftUI

Swift package for controlling Soundcraft UI series mixers (`UI12`, `UI16`, and `UI24R`) over WebSocket.

`SoundcraftUI` is a native Swift port of the TypeScript library [`fmalcher/soundcraft-ui`](https://github.com/fmalcher/soundcraft-ui). It targets iOS 16+ and macOS 13+, uses Combine for reactive state, and includes VU/RTA processors plus Swift-only DSP and global-settings facades.

## Documentation

- Published API and guide docs: [eric-silverman.github.io/soundcraft-ui-swift](https://eric-silverman.github.io/soundcraft-ui-swift/)
- Contributor guide: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Upstream parity tracking: [`PARITY.md`](PARITY.md)
- DocC source catalog: [`Sources/SoundcraftUI/SoundcraftUI.docc`](Sources/SoundcraftUI/SoundcraftUI.docc)

## Installation

Add the package as a local or remote Swift Package Manager dependency.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/eric-silverman/soundcraft-ui-swift.git", branch: "main"),
]
```

Or as a local dependency while developing:

```swift
dependencies: [
    .package(path: "../soundcraft-ui-swift"),
]
```

## Quick Start

```swift
import SoundcraftUI

let mixer = SoundcraftUI(ip: "192.168.1.123")
mixer.connect()

mixer.status
    .sink { status in
        print("Connection status:", status)
    }
    .store(in: &cancellables)

mixer.master.input(1).setFaderLevel(0.75)
mixer.master.input(1).enableMute()

mixer.store.state
    .sink { state in
        print(state["i.0.mix"] as Any)
    }
    .store(in: &cancellables)
```

## Highlights

- 1-indexed Swift facades for master, aux, FX, hardware, recorder, player, and show control
- Reactive state store via Combine publishers
- Per-channel and aggregate VU metering plus RTA parsing
- Swift-only facades for EQ, dynamics, gate, de-esser, Digitech, and global routing/settings
- Test-friendly transport abstraction with `MockWebSocketTransport`

## Development

Run the test suite:

```bash
swift test
```

Build the static DocC site locally:

```bash
bash scripts/build-docc-site.sh
```

The generated site is written to `.build/docc-site/site`.
