# Parity with `fmalcher/soundcraft-ui`

This Swift package is a port of the TypeScript library [`fmalcher/soundcraft-ui`](https://github.com/fmalcher/soundcraft-ui). This document tracks which upstream files have a Swift counterpart and when they were last reconciled.

**Upstream baseline:** [`9cb0ba5`](https://github.com/fmalcher/soundcraft-ui/commit/9cb0ba503d4e9ceac2a235be6a8977bd8b33d5f6) (2026-05-03)

When upstream changes, the `parity-watch` workflow opens an issue listing the upstream files that have moved. Reconcile, then update the SHA above and the per-row notes below.

## How to reconcile

1. `git -C /tmp clone --depth 50 https://github.com/fmalcher/soundcraft-ui` (or fetch)
2. `git log --oneline 9cb0ba5..HEAD -- packages/mixer-connection/src/lib/` to see what changed
3. Port the changes into the matching Swift file
4. Update this file's baseline SHA and the row's "last synced" if the change touched it
5. Commit with message `Sync parity to <new-sha>`

## File matrix

### Core

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/soundcraft-ui.ts` | `Sources/SoundcraftUI/SoundcraftUI.swift` | synced |
| `lib/mixer-connection.ts` | `Sources/SoundcraftUI/Connection/MixerConnection.swift` | synced |
| `lib/types.ts` | `Sources/SoundcraftUI/Types.swift` | synced |
| `lib/transitions.ts` | `Sources/SoundcraftUI/Utils/Transitions.swift` (Easing enum) | synced |
| `lib/utils.ts` | `Sources/SoundcraftUI/Utils/` | synced |
| `lib/type-guards.ts` | (inlined into Swift type system) | n/a |
| `lib/device-capabilities.ts` | `Sources/SoundcraftUI/DeviceCapabilities.swift` | synced |

### State

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/state/mixer-store.ts` | `Sources/SoundcraftUI/State/MixerStore.swift` | synced |
| `lib/state/object-store.ts` | `Sources/SoundcraftUI/State/ObjectStore.swift` | synced |
| `lib/state/state-selectors.ts` | (folded into MixerStore methods) | synced |
| `lib/state/mixer-state.models.ts` | (Swift types in `Types.swift`) | synced |

### Facade — buses

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/master-bus.ts` | `Sources/SoundcraftUI/Buses/MasterBus.swift` | synced |
| `lib/facade/aux-bus.ts` | `Sources/SoundcraftUI/Buses/AuxBus.swift` | synced |
| `lib/facade/fx-bus.ts` | `Sources/SoundcraftUI/Buses/FxBus.swift` | synced |
| `lib/facade/volume-bus.ts` | `Sources/SoundcraftUI/Buses/VolumeBus.swift` | synced |

### Facade — channels

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/channel.ts` | `Sources/SoundcraftUI/Channels/Channel.swift` | synced |
| `lib/facade/master-channel.ts` | `Sources/SoundcraftUI/Channels/MasterChannel.swift` | synced |
| `lib/facade/send-channel.ts` | `Sources/SoundcraftUI/Channels/SendChannel.swift` | synced |
| `lib/facade/aux-channel.ts` | `Sources/SoundcraftUI/Channels/AuxChannel.swift` | synced |
| `lib/facade/fx-channel.ts` | `Sources/SoundcraftUI/Channels/FxChannel.swift` | synced |
| `lib/facade/delayable-master-channel.ts` | `Sources/SoundcraftUI/Channels/DelayableMasterChannel.swift` | synced |
| `lib/facade/hw-channel.ts` | `Sources/SoundcraftUI/Channels/HwChannel.swift` | synced |
| `lib/facade/interfaces.ts` | `Sources/SoundcraftUI/Protocols.swift` | synced |

### Facade — features

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/facade/player.ts` | `Sources/SoundcraftUI/Player.swift` | synced |
| `lib/facade/dual-track-recorder.ts` | `Sources/SoundcraftUI/DualTrackRecorder.swift` | synced |
| `lib/facade/multi-track-recorder.ts` | `Sources/SoundcraftUI/MultiTrackRecorder.swift` | synced |
| `lib/facade/show-controller.ts` | `Sources/SoundcraftUI/ShowController.swift` | synced |
| `lib/facade/automix-controller.ts` | `Sources/SoundcraftUI/AutomixController.swift` | synced |
| `lib/facade/mute-group.ts` | `Sources/SoundcraftUI/MuteGroup.swift` | synced |
| `lib/facade/channel-sync.ts` | `Sources/SoundcraftUI/ChannelSync.swift` | synced |
| `lib/facade/device-info.ts` | `Sources/SoundcraftUI/DeviceInfo.swift` | synced |

### VU

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/vu/vu-processor.ts` | `Sources/SoundcraftUI/VU/VUProcessor.swift` | synced |
| `lib/vu/vu.types.ts` | `Sources/SoundcraftUI/VU/VUTypes.swift` | synced |
| `lib/vu/vu.utils.ts` | (folded into VUProcessor) | synced |

### Utils

| Upstream file | Swift file | Status |
|---|---|---|
| `lib/utils/bitmask.ts` | `Sources/SoundcraftUI/Utils/Bitmask.swift` | synced |
| `lib/utils/channel-sync-mapping.ts` | `Sources/SoundcraftUI/Utils/ChannelSyncMapping.swift` | synced |
| `lib/utils/state-utils.ts` | `Sources/SoundcraftUI/Utils/` | synced |
| `lib/utils/async-helpers.ts` | (Swift uses async/await natively) | n/a |
| `lib/utils/transitions/easings.ts` | `Sources/SoundcraftUI/Utils/Easings.swift` | synced |
| `lib/utils/value-converters/value-converters.ts` | `Sources/SoundcraftUI/Utils/ValueConverters.swift` | synced |
| `lib/utils/value-converters/benchmarks-calculations/*` | `Sources/SoundcraftUI/Utils/` | synced |
| `lib/utils/mock-websocket.ts` | `Tests/SoundcraftUITests/MockWebSocketTransport.swift` | synced |

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

## Known test gaps vs upstream

Upstream has ~35 spec files; Swift port has 7. Subsystems with TS specs but no Swift tests:

- `aux-channel.spec.ts`, `volume-bus.spec.ts`
- `automix-controller.spec.ts`, `mute-group.spec.ts` (state behavior)
- `device-info.spec.ts`
- `fx-bus.spec.ts` (type, bypass, stereo controls — only BPM/params tested)
- `delayable-master-channel.spec.ts`, `master-channel.spec.ts` (full coverage)
- `master-bus.spec.ts`, `fx-channel.spec.ts`, `hw-channel.spec.ts` (full coverage)
- `state-selectors.spec.ts`, `object-store.spec.ts`
- `channel-singletons.spec.ts`, `outbound-messages.spec.ts`
- `mixer-connection.spec.ts`, `soundcraft-ui.spec.ts`

Native Swift-only tests still needed for: `ParametricEQ`, `GraphicEQ`, `Dynamics`, `Gate`, `Deesser`, `Digitech`, `GlobalSettings`.
