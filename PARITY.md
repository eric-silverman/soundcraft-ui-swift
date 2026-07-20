# Parity with `fmalcher/soundcraft-ui`

This Swift package is a port of the TypeScript library [`fmalcher/soundcraft-ui`](https://github.com/fmalcher/soundcraft-ui). This document tracks which upstream files have a Swift counterpart and when they were last reconciled.

**Upstream baseline:** [`93db985`](https://github.com/fmalcher/soundcraft-ui/commit/93db9850b91df3a6690534abc622d44fe01b9c9b) (2026-07-20)

When upstream changes, the `parity-watch` workflow opens an issue listing the upstream files that have moved. Reconcile, then update the SHA above and any affected status notes below.

## How to reconcile

1. `git -C /tmp clone --depth 50 https://github.com/fmalcher/soundcraft-ui` (or fetch)
2. `git log --oneline 9cb0ba5..HEAD -- packages/mixer-connection/src/lib/` to see what changed
3. Port the changes into the matching Swift file
4. Update this file's baseline SHA and any affected status notes if the change touched them
5. Commit with message `Sync parity to <new-sha>`

## File matrix

### Core

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/soundcraft-ui.ts` | `Sources/SoundcraftUI/SoundcraftUI.swift` | synced |
| `lib/mixer-connection.ts` | `Sources/SoundcraftUI/Connection/MixerConnection.swift` | synced |
| `lib/types.ts` | `Sources/SoundcraftUI/Types.swift` | synced |
| `lib/transitions.ts` | `Sources/SoundcraftUI/Utils/Transitions.swift` | synced |
| `lib/utils.ts` | `Sources/SoundcraftUI/Utils/Utilities.swift` | synced |
| `lib/type-guards.ts` | (inlined into Swift type system) | n/a |
| `lib/device-capabilities.ts` | `Sources/SoundcraftUI/DeviceCapabilities.swift` | synced |

### State

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/state/mixer-store.ts` | `Sources/SoundcraftUI/State/MixerStore.swift` | synced |
| `lib/state/object-store.ts` | `Sources/SoundcraftUI/State/ObjectStore.swift` | synced |
| `lib/state/state-selectors.ts` | `Sources/SoundcraftUI/State/StateSelectors.swift` | synced |
| `lib/state/resource-lists.ts` | `Sources/SoundcraftUI/State/ResourceLists.swift` | synced |
| `lib/state/mixer-state.models.ts` | (Swift types in `Types.swift`) | synced |

### Facade — buses

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/master-bus.ts` | `Sources/SoundcraftUI/Facade/MasterBus.swift` | synced |
| `lib/facade/aux-bus.ts` | `Sources/SoundcraftUI/Facade/AuxBus.swift` | synced |
| `lib/facade/fx-bus.ts` | `Sources/SoundcraftUI/Facade/FxBus.swift` | synced |
| `lib/facade/volume-bus.ts` | `Sources/SoundcraftUI/Facade/VolumeBus.swift` | synced |

### Facade — channels

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/channel.ts` | `Sources/SoundcraftUI/Facade/Channel.swift` | synced |
| `lib/facade/master-channel.ts` | `Sources/SoundcraftUI/Facade/MasterChannel.swift` | synced |
| `lib/facade/send-channel.ts` | `Sources/SoundcraftUI/Facade/SendChannel.swift` | synced |
| `lib/facade/aux-channel.ts` | `Sources/SoundcraftUI/Facade/AuxChannel.swift` | synced |
| `lib/facade/fx-channel.ts` | `Sources/SoundcraftUI/Facade/FxChannel.swift` | synced |
| `lib/facade/delayable-master-channel.ts` | `Sources/SoundcraftUI/Facade/DelayableMasterChannel.swift` | synced |
| `lib/facade/hw-channel.ts` | `Sources/SoundcraftUI/Facade/HwChannel.swift` | synced |
| `lib/facade/interfaces.ts` | `Sources/SoundcraftUI/Facade/Protocols.swift` | synced |
| `lib/facade/channel-id.ts` | `Sources/SoundcraftUI/Utils/Utilities.swift` (channel-id constructors) | synced |

### Facade — matrix buses (Ui24R)

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/mtx-bus.ts` | `Sources/SoundcraftUI/Facade/MtxBus.swift` | synced |
| `lib/facade/mtx-channel.ts` | `Sources/SoundcraftUI/Facade/MtxChannel.swift` | synced |
| `lib/facade/mtx-bus-channel.ts` | `Sources/SoundcraftUI/Facade/MtxBusChannel.swift` | synced |
| `lib/facade/mtx-master-channel.ts` | `Sources/SoundcraftUI/Facade/MtxMasterChannel.swift` | synced |
| `lib/facade/matrix-utils.ts` | `Sources/SoundcraftUI/Facade/MatrixUtils.swift` | synced |
| `lib/facade/object-store-ids.ts` | `Sources/SoundcraftUI/State/ObjectStore.swift` (store-id builders) | synced |

### Facade — features

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/player.ts` | `Sources/SoundcraftUI/Facade/Player.swift` | synced |
| `lib/facade/dual-track-recorder.ts` | `Sources/SoundcraftUI/Facade/DualTrackRecorder.swift` | synced |
| `lib/facade/multi-track-recorder.ts` | `Sources/SoundcraftUI/Facade/MultiTrackRecorder.swift` | synced |
| `lib/facade/show-controller.ts` | `Sources/SoundcraftUI/Facade/ShowController.swift` | synced |
| `lib/facade/automix-controller.ts` | `Sources/SoundcraftUI/Facade/AutomixController.swift` | synced |
| `lib/facade/mute-group.ts` | `Sources/SoundcraftUI/Facade/MuteGroup.swift` | synced |
| `lib/facade/channel-sync.ts` | `Sources/SoundcraftUI/Facade/ChannelSync.swift` | synced |
| `lib/facade/device-info.ts` | `Sources/SoundcraftUI/Facade/DeviceInfo.swift` | synced |

### VU

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/vu/vu-processor.ts` | `Sources/SoundcraftUI/VU/VUProcessor.swift` | synced |
| `lib/vu/vu.types.ts` | `Sources/SoundcraftUI/VU/VUTypes.swift` | synced |
| `lib/vu/vu.utils.ts` | `Sources/SoundcraftUI/VU/VUProcessor.swift` | synced |

### Utils

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/utils/bitmask.ts` | `Sources/SoundcraftUI/Utils/Bitmask.swift` | synced |
| `lib/utils/channel-sync-mapping.ts` | `Sources/SoundcraftUI/Facade/ChannelSync.swift` | synced |
| `lib/utils/state-utils.ts` | `Sources/SoundcraftUI/State/StateSelectors.swift`, `Sources/SoundcraftUI/Utils/Utilities.swift` | synced |
| `lib/utils/async-helpers.ts` | (Swift uses async/await natively) | n/a |
| `lib/utils/transitions/easings.ts` | `Sources/SoundcraftUI/Types.swift` (Easing enum) | synced |
| `lib/utils/value-converters/value-converters.ts` | `Sources/SoundcraftUI/Utils/ValueConverters.swift` | synced |
| `lib/utils/value-converters/benchmarks-calculations/*` | `Sources/SoundcraftUI/Utils/DBLookupTable.swift` | synced |
| `lib/utils/mock-websocket.ts` | `Tests/SoundcraftUITests/Mocks/MockWebSocketTransport.swift` | synced |

## Swift-only additions

Features present in the Swift port but not in the upstream TS library. These go beyond TS parity — upstream changes do not affect them.

| Swift type | Notes |
|---|---|
| `ParametricEQ` | 5-band + HPF/LPF — not exposed by TS facade |
| `GraphicEQ` | 31-band master/aux EQ — not exposed by TS facade |
| `Dynamics` | Compressor controls — not exposed by TS facade |
| `Gate` | Noise gate — not exposed by TS facade |
| `Deesser` | De-esser (input channels) — not exposed by TS facade |
| `Digitech` | Amp modeler (input channels) — not exposed by TS facade |
| `GlobalSettings` | AFS, footswitch, MTK format, hardware routing — not exposed by TS facade |
| `RTAProcessor` | Real-time analyzer — not exposed by TS facade |

## Intentional API deltas

Idiomatic Swift naming differences from the TS API.

| TS | Swift | Reason |
|---|---|---|
| `mute()` / `unmute()` | `enableMute()` / `disableMute()` | avoids collision with `mute` property |
| `dim()` / `undim()` | `enableDim()` / `disableDim()` | same pattern |
| `name$` (Observable) | `name` (Combine `AnyPublisher`) | Combine convention drops `$` |
| `Promise<void>` | `async` / sync as appropriate | native async |
| `conn.setd/setdBool/sets` | `conn.setd(_:_:)` / `conn.setdBool(_:_:)` / `conn.sets(_:_:)` | Swift argument labels |

On/off state matches upstream `93db985`: mute/solo/dim/phantom/post/postProc/shuffle/soundcheck/recording/busy/automix/mute-group and multitrack-selection publishers emit `Bool` and their setters accept `Bool`. `SETD` still keeps numeric values while `SETS` keeps strings (so numeric-looking names like `0001` are preserved).

## Test coverage status

At baseline `93db985`, the previously listed parity coverage gaps remain covered by Swift tests. Current coverage includes:

- facade behavior for `aux-channel`, `volume-bus`, `automix-controller`, `mute-group`, `device-info`, `fx-bus`, `delayable-master-channel`, `master-channel`, `master-bus`, `fx-channel`, and `hw-channel`
- state and connection coverage for `state-selectors`, `object-store`, outbound message streams, `mixer-connection`, singleton reuse, and top-level `soundcraft-ui` wiring
- matrix (MTX) bus routing, matrix source PRE/POST PROC, aux↔matrix switching and shared instance caching, matrix-aware default channel names, and `SETS` string preservation
- per-client resource lists: `Player` playlists/tracks and `ShowController` shows/snapshots/cues (fetched on connect)
- Swift-only coverage for `ParametricEQ`, `GraphicEQ`, `Dynamics`, `Gate`, `Deesser`, `Digitech`, and `GlobalSettings`
