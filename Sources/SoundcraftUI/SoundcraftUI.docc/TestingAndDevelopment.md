# Testing And Development

## Mock transport

Use `MockWebSocketTransport` in tests to avoid a real mixer connection.

```swift
import XCTest
@testable import SoundcraftUI

let transport = MockWebSocketTransport()
let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
mixer.connect()

transport.simulateSetd(path: "i.0.mix", value: "0.75")

mixer.master.input(1).setFaderLevel(0.5)
XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.mix^0.5"))
```

Useful helpers on the mock transport include:

- `sentMessages`
- `sentCommands`
- `simulateInbound(_:)`
- `simulateSetd(path:value:)`
- `simulateOpen()`
- `simulateClose()`
- `simulateError(_:)`

## Running tests

```bash
swift test
```

If a moved checkout leaves stale cache paths inside local build artifacts, re-run with a clean scratch path:

```bash
swift test --scratch-path /tmp/soundcraft-ui-swift-build
```

## Building documentation

Generate the static DocC site locally with:

```bash
bash scripts/build-docc-site.sh
```

The script:

1. builds the package with symbol graph emission enabled
2. converts the `SoundcraftUI.docc` catalog with `docc convert`
3. transforms the output for static hosting under the repository base path

## Package architecture

The package is organized around a small set of layers:

- ``SoundcraftUI``: top-level facade and feature factories
- ``MixerConnection``: WebSocket transport, framing, status, reconnect logic
- ``MixerStore``: flat reactive state dictionary and sync-state store
- facade types such as ``MasterBus``, ``Channel``, ``HwChannel``, and ``VolumeBus``
- monitoring processors such as ``VUProcessor`` and ``RTAProcessor``

## Upstream parity

The repo tracks parity with the upstream TypeScript implementation in `PARITY.md`. When parity-sensitive behavior changes, update:

- the affected Swift facade or utility
- the matching tests
- the parity documentation and baseline SHA when appropriate
