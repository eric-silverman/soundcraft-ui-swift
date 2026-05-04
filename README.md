# SoundcraftUI

Swift package for controlling Soundcraft UI series mixers (UI12, UI16, UI24R) over WebSocket. Native port of the [soundcraft-ui-connection](https://github.com/fmalcher/soundcraft-ui) TypeScript library.

Supports iOS 16+ and macOS 13+. Uses Combine for reactive state and URLSessionWebSocketTask for transport.

## Installation

Add as a local SPM dependency:

```swift
// Package.swift
dependencies: [
    .package(path: "../SoundcraftUI"),
]
```

Or in xcodegen `project.yml`:

```yaml
packages:
  SoundcraftUI:
    path: ../SoundcraftUI
```

## Quick Start

```swift
import SoundcraftUI

let mixer = SoundcraftUI(ip: "192.168.1.123")
mixer.connect()

// Subscribe to connection status
mixer.status
    .sink { status in print("Status: \(status)") }
    .store(in: &cancellables)

// Control a channel
mixer.master.input(1).setFaderLevel(0.75)
mixer.master.input(1).enableMute()

// Subscribe to state
mixer.store.state
    .sink { state in
        let fader = state["i.0.mix"] as? Double
    }
    .store(in: &cancellables)
```

## Connection

```swift
let mixer = SoundcraftUI(ip: "192.168.1.123")
mixer.connect()       // Connect via WebSocket on port 80
mixer.disconnect()    // Close connection
mixer.reconnect()     // Disconnect, wait 1s, reconnect
```

### Connection Status

Subscribe to `mixer.status` for real-time connection state:

```swift
mixer.status
    .sink { status in ... }
    .store(in: &cancellables)
```

`ConnectionStatus` cases:

| Case | Raw Value | Meaning |
|------|-----------|---------|
| `.opening` | `"OPENING"` | WebSocket connecting |
| `.open` | `"OPEN"` | Connected and ready |
| `.close` | `"CLOSE"` | Disconnected |
| `.closing` | `"CLOSING"` | Disconnect in progress |
| `.error` | `"ERROR"` | Connection error |
| `.reconnecting` | `"RECONNECTING"` | Auto-reconnecting (2s delay) |

## Master Bus

Access via `mixer.master`. Controls the main stereo output.

### Master Output

```swift
mixer.master.faderLevel          // AnyPublisher<Double, Never> (0..1)
mixer.master.faderLevelDB        // AnyPublisher<Double, Never>
mixer.master.pan                 // AnyPublisher<Double, Never> (0..1)
mixer.master.dim$                // AnyPublisher<Int, Never> (0 or 1)
mixer.master.delayL              // AnyPublisher<Double, Never> (ms)
mixer.master.delayR              // AnyPublisher<Double, Never> (ms)

mixer.master.setFaderLevel(0.75)
mixer.master.setFaderLevelDB(-6.0)
mixer.master.changeFaderLevel(0.1)      // relative linear offset
mixer.master.changeFaderLevelDB(-1.0)   // relative dB offset
mixer.master.setPan(0.5)                // center
mixer.master.enableDim()
mixer.master.disableDim()
mixer.master.setDelayL(10.0)            // ms
mixer.master.setDelayR(10.0)
```

### Master Bus Channels

```swift
mixer.master.input(1)    // → DelayableMasterChannel (1-indexed)
mixer.master.line(1)     // → DelayableMasterChannel
mixer.master.player(1)   // → MasterChannel
mixer.master.aux(1)      // → DelayableMasterChannel
mixer.master.fx(1)       // → MasterChannel
mixer.master.sub(1)      // → MasterChannel
mixer.master.vca(1)      // → MasterChannel
```

## AUX Bus

Access via `mixer.aux(n)` where n is 1-indexed (1–10 on UI24R).

```swift
let aux1 = mixer.aux(1)
aux1.input(1).setFaderLevel(0.5)
aux1.input(1).postMode()         // post-fader send routing
aux1.input(1).preMode()          // pre-fader send routing
aux1.input(1).postProc()         // post-DSP send (after channel processing)
aux1.input(1).preProc()          // pre-DSP send (before channel processing)
aux1.input(1).setPan(0.5)
```

### AUX Bus Channels

```swift
mixer.aux(1).input(1)    // → AuxChannel
mixer.aux(1).line(1)     // → AuxChannel
mixer.aux(1).player(1)   // → AuxChannel
mixer.aux(1).fx(1)       // → AuxChannel
```

`AuxChannel` supports fader, mute, name, pan, pre/post routing, and pre/post DSP.

## FX Bus

Access via `mixer.fx(n)` where n is 1-indexed (1–4).

```swift
let fx1 = mixer.fx(1)
fx1.fxType                       // AnyPublisher<FxType, Never>
fx1.bpm                          // AnyPublisher<Int, Never>
fx1.setBpm(120)
fx1.setParam(1, value: 0.5)     // params 1-6, value 0-1
fx1.getParam(1)                  // AnyPublisher<Double, Never>

fx1.input(1).setFaderLevel(0.3) // FX send level
fx1.line(1).setFaderLevel(0.3)
fx1.player(1).setFaderLevel(0.3)
fx1.sub(1).setFaderLevel(0.3)
```

`FxType` cases: `.reverb`, `.delay`, `.chorus`, `.room`, `.none`

## Hardware Channels

Access via `mixer.hw(n)` where n is 1-indexed.

```swift
let hw1 = mixer.hw(1)
hw1.gain                 // AnyPublisher<Double, Never> (0..1)
hw1.gainDB               // AnyPublisher<Double, Never>
hw1.phantom              // AnyPublisher<Int, Never> (0 or 1)

hw1.setGain(0.6)
hw1.changeGain(0.1)      // relative linear offset
hw1.setGainDB(20.0)
hw1.changeGainDB(3.0)    // relative dB offset
hw1.phantomOn()
hw1.phantomOff()
hw1.togglePhantom()
```

Gain range: -6 to +57 dB (UI24), -40 to +50 dB (UI12/UI16).

## Channel Control

All channel types share these core controls:

### Fader

```swift
channel.faderLevel              // AnyPublisher<Double, Never> (0..1)
channel.faderLevelDB            // AnyPublisher<Double, Never>

channel.setFaderLevel(0.75)
channel.setFaderLevelDB(-6.0)
channel.changeFaderLevel(0.1)   // relative linear offset
channel.changeFaderLevelDB(-1.0)

// Animated transitions
channel.fadeTo(0.75, fadeTime: 2.0)                          // linear
channel.fadeTo(0.75, fadeTime: 2.0, easing: .easeInOut)      // with easing
channel.fadeToDB(-6.0, fadeTime: 2.0)
```

`Easing` options: `.linear`, `.easeIn`, `.easeOut`, `.easeInOut`

### Mute

```swift
channel.mute$                   // AnyPublisher<Int, Never> (0 or 1)

channel.enableMute()
channel.disableMute()
channel.toggleMute()
channel.setMute(1)              // raw value
```

### Solo (master bus channels only)

```swift
masterChannel.solo$             // AnyPublisher<Int, Never>

masterChannel.enableSolo()
masterChannel.disableSolo()
masterChannel.toggleSolo()
```

### Pan (master and aux channels)

```swift
pannableChannel.pan             // AnyPublisher<Double, Never> (0..1)

pannableChannel.setPan(0.5)     // center
pannableChannel.changePan(0.1)  // relative offset
```

### Name

```swift
channel.name                    // AnyPublisher<String, Never>
channel.setName("Kick")
```

### Delay (DelayableMasterChannel only)

```swift
delayableChannel.delay          // AnyPublisher<Double, Never> (ms)

delayableChannel.setDelay(5.0)
delayableChannel.changeDelay(1.0)
```

Max delay: 250ms for input/line, 500ms for aux returns.

### Automix (MasterChannel only)

```swift
masterChannel.automixGroup      // AnyPublisher<AutomixGroupID?, Never> (.a, .b, or nil)
masterChannel.automixWeight     // AnyPublisher<Double, Never> (0..1)
masterChannel.automixWeightDB   // AnyPublisher<Double, Never> (-12..+12 dB)

masterChannel.automixAssignGroup(.a)
masterChannel.automixAssignGroup(.b)
masterChannel.automixRemove()
masterChannel.automixSetWeight(0.75)
masterChannel.automixSetWeightDB(6.0)
masterChannel.automixChangeWeightDB(1.0)
```

### Multitrack Selection (MasterChannel only)

```swift
masterChannel.multiTrackSelected    // AnyPublisher<Int, Never> (0 or 1)

masterChannel.multiTrackSelect()
masterChannel.multiTrackUnselect()
masterChannel.multiTrackToggle()
```

## State Store

`mixer.store` holds the complete mixer state as a flat dictionary.

### Full State

```swift
mixer.store.state               // CurrentValueSubject<[String: Any], Never>

mixer.store.state
    .sink { state in
        let fader = state["i.0.mix"] as? Double
        let name = state["i.0.name"] as? String
        let mute = state["i.0.mute"] as? Int
    }
    .store(in: &cancellables)
```

### Typed Selectors

```swift
// With default value
mixer.store.select(path: "i.0.mix", default: 0.0)
    // → AnyPublisher<Double, Never>

// Optional (nil if missing)
mixer.store.select(path: "i.0.name")
    // → AnyPublisher<String?, Never>
```

### State Key Format

| Key Pattern | Meaning |
|-------------|---------|
| `i.{n}.mix` | Input channel fader (master bus) |
| `i.{n}.mute` | Input channel mute |
| `i.{n}.solo` | Input channel solo |
| `i.{n}.name` | Input channel name |
| `i.{n}.pan` | Input channel pan |
| `i.{n}.aux.{a}.value` | Input channel aux send level |
| `a.{n}.name` | Aux bus name |
| `hw.{n}.gain` | Hardware channel gain |
| `hw.{n}.ph` | Hardware phantom power |
| `f.{n}.type` | FX bus type |
| `m.mix` | Master fader |
| `m.pan` | Master pan |

All indices are 0-based in state keys. Channel API methods are 1-indexed.

## VU Meters

`mixer.vuProcessor` parses binary VU data at 60fps.

### Bulk Data

```swift
mixer.vuProcessor.vuData        // AnyPublisher<VUData, Never>

mixer.vuProcessor.vuData
    .sink { data in
        for (i, vu) in data.input.enumerated() {
            print("CH \(i+1): pre=\(vu.vuPre) post=\(vu.vuPostFader)")
        }
    }
    .store(in: &cancellables)
```

### Per-Channel Publishers

```swift
mixer.vuProcessor.input(1)      // AnyPublisher<InputChannelVU, Never>
mixer.vuProcessor.aux(1)        // AnyPublisher<AuxChannelVU, Never>
mixer.vuProcessor.fx(1)         // AnyPublisher<StereoVU, Never>
mixer.vuProcessor.master()      // AnyPublisher<StereoVU, Never>
```

### VU Types

```swift
struct InputChannelVU {
    let vuPre: Double           // pre-fader level (0..1)
    let vuPost: Double          // post-EQ level
    let vuPostFader: Double     // post-fader level
}

struct AuxChannelVU {
    let vuPost: Double
    let vuPostFader: Double
}

struct StereoVU {
    let vuPostL: Double
    let vuPostR: Double
    let vuPostFaderL: Double
    let vuPostFaderR: Double
}
```

## RTA (Real-Time Analyser)

`mixer.rtaProcessor` parses binary RTA spectrum data.

```swift
mixer.rtaProcessor.rtaData      // AnyPublisher<RTAFrame, Never>
mixer.rtaProcessor.subscribe()  // Start receiving RTA data
mixer.rtaProcessor.unsubscribe()

mixer.rtaProcessor.rtaData
    .sink { frame in
        for (i, level) in frame.bins.enumerated() {
            print("Band \(i): \(level)")
        }
    }
    .store(in: &cancellables)
```

## Volume Buses

Access solo and headphone monitor volumes via `mixer.volume`.

```swift
mixer.volume.solo.setFaderLevel(0.8)     // Solo bus level
mixer.volume.solo.faderLevel             // AnyPublisher<Double, Never>
mixer.volume.solo.faderLevelDB           // AnyPublisher<Double, Never>

mixer.volume.headphone(1).setFaderLevel(0.7)   // Headphone bus 1
mixer.volume.headphone(1).faderLevel
```

`VolumeBus` supports `setFaderLevel`, `setFaderLevelDB`, `changeFaderLevel`, `changeFaderLevelDB`, `fadeTo`, and `fadeToDB`.

## Player

Media player control via `mixer.player`.

```swift
mixer.player.state              // AnyPublisher<PlayerState, Never>
mixer.player.playlist           // AnyPublisher<String, Never>
mixer.player.track              // AnyPublisher<String, Never>
mixer.player.length             // AnyPublisher<Double, Never> (seconds)
mixer.player.elapsedTime        // AnyPublisher<Int, Never> (seconds)
mixer.player.remainingTime      // AnyPublisher<Int, Never> (seconds)
mixer.player.shuffle            // AnyPublisher<Int, Never> (0 or 1)

mixer.player.play()
mixer.player.pause()
mixer.player.stop()
mixer.player.next()
mixer.player.prev()
mixer.player.loadPlaylist("My Set")
mixer.player.loadTrack(playlist: "My Set", track: "Song.mp3")
mixer.player.setShuffle(1)
mixer.player.toggleShuffle()
mixer.player.setManual()
mixer.player.setAuto()
```

`PlayerState` cases: `.stopped`, `.playing`, `.paused`

## Recording

### Dual-Track Recorder

Two-track USB recording via `mixer.recorderDualTrack`.

```swift
mixer.recorderDualTrack.recording   // AnyPublisher<Int, Never> (0 or 1)
mixer.recorderDualTrack.busy        // AnyPublisher<Int, Never> (0 or 1)

mixer.recorderDualTrack.recordToggle()
mixer.recorderDualTrack.recordStart()
mixer.recorderDualTrack.recordStop()
```

### Multitrack Recorder (UI24R only)

```swift
mixer.recorderMultiTrack.state          // AnyPublisher<MtkState, Never>
mixer.recorderMultiTrack.session        // AnyPublisher<String, Never>
mixer.recorderMultiTrack.length         // AnyPublisher<Double, Never> (seconds)
mixer.recorderMultiTrack.elapsedTime    // AnyPublisher<Int, Never> (seconds)
mixer.recorderMultiTrack.remainingTime  // AnyPublisher<Int, Never> (seconds)
mixer.recorderMultiTrack.recording      // AnyPublisher<Int, Never> (0 or 1)
mixer.recorderMultiTrack.busy           // AnyPublisher<Int, Never> (0 or 1)
mixer.recorderMultiTrack.recordingTime  // AnyPublisher<Int, Never> (seconds elapsed recording)
mixer.recorderMultiTrack.soundcheck     // AnyPublisher<Int, Never> (0 or 1)

mixer.recorderMultiTrack.play()
mixer.recorderMultiTrack.pause()
mixer.recorderMultiTrack.stop()
mixer.recorderMultiTrack.recordToggle()
mixer.recorderMultiTrack.recordStart()
mixer.recorderMultiTrack.recordStop()
mixer.recorderMultiTrack.activateSoundcheck()
mixer.recorderMultiTrack.deactivateSoundcheck()
mixer.recorderMultiTrack.toggleSoundcheck()
mixer.recorderMultiTrack.renameSession("Session Name")
```

`MtkState` cases: `.stopped`, `.paused`, `.playing`

## Shows, Snapshots & Cues

```swift
mixer.shows.currentShow         // AnyPublisher<String, Never>
mixer.shows.currentSnapshot     // AnyPublisher<String, Never>
mixer.shows.currentCue          // AnyPublisher<String, Never>

mixer.shows.loadShow("MyShow")
mixer.shows.loadSnapshot(show: "MyShow", snapshot: "Snap1")
mixer.shows.loadCue(show: "MyShow", cue: "Intro")
mixer.shows.saveSnapshot(show: "MyShow", snapshot: "Snap1")
mixer.shows.saveCue(show: "MyShow", cue: "Intro")
mixer.shows.updateCurrentSnapshot()    // Save over the currently loaded snapshot
mixer.shows.updateCurrentCue()         // Save over the currently loaded cue
mixer.shows.exportJSON()               // Export show to USB (V3 firmware)
mixer.shows.importJSON(path: "show.json")
```

## Automix

```swift
mixer.automix.responseTime      // AnyPublisher<Double, Never> (0..1)
mixer.automix.responseTimeMs    // AnyPublisher<Int, Never> (20..4000 ms)

mixer.automix.setResponseTime(0.5)
mixer.automix.setResponseTimeMs(500)

// Per-group control
mixer.automix.groups.a.state    // AnyPublisher<Int, Never> (0 or 1)
mixer.automix.groups.a.enable()
mixer.automix.groups.a.disable()
mixer.automix.groups.a.toggle()

mixer.automix.groups.b.enable()
```

Assign channels to automix groups via `MasterChannel`:

```swift
mixer.master.input(1).automixAssignGroup(.a)
mixer.master.input(2).automixAssignGroup(.b)
mixer.master.input(3).automixRemove()
```

## Mute Groups

```swift
mixer.muteGroup(.group(1))      // MuteGroup (groups 1-6)
mixer.muteGroup(.all)           // All mute
mixer.muteGroup(.fx)            // FX mute

let mg = mixer.muteGroup(.group(1))
mg.state                        // AnyPublisher<Int, Never> (0 or 1)
mg.mute()
mg.unmute()
mg.toggle()

mixer.clearMuteGroups()         // Unmute all groups
```

## Channel Sync

Synchronize channel selection across multiple clients on the same network.

```swift
// Send selection
mixer.channelSync.selectChannelIndex(2)
mixer.channelSync.selectChannel(type: .input, num: 3)
mixer.channelSync.selectMaster()

// Receive selection — index only
mixer.channelSync.getSelectedChannelIndex()
    .sink { index in print("Selected index: \(index)") }
    .store(in: &cancellables)

// Receive selection — resolved channel object (nil when master is selected)
mixer.channelSync.getSelectedChannel()
    .sink { channel in
        channel?.setFaderLevel(0.8)
    }
    .store(in: &cancellables)

// Custom sync ID for multiple independent selection groups
mixer.channelSync.selectChannelIndex(5, syncId: "PANEL_B")
mixer.channelSync.getSelectedChannel(syncId: "PANEL_B")
    .sink { ... }
    .store(in: &cancellables)
```

## Device Info

```swift
mixer.deviceInfo.model          // AnyPublisher<MixerModel?, Never>
mixer.deviceInfo.capabilities   // AnyPublisher<DeviceCapabilities?, Never>
mixer.deviceInfo.firmware       // AnyPublisher<String?, Never>
```

### MixerModel

Cases: `.ui12`, `.ui16`, `.ui24`

### DeviceCapabilities

```swift
let caps = DeviceCapabilities.forModel(.ui24)
caps.input      // 24
caps.line       // 2
caps.player     // 2
caps.fx         // 4
caps.sub        // 6
caps.aux        // 10
caps.vca        // 6
caps.multitrack // true
caps.masterDim  // true
```

| Capability | UI12 | UI16 | UI24 |
|------------|------|------|------|
| Inputs | 8 | 12 | 24 |
| Lines | 2 | 2 | 2 |
| Players | 2 | 2 | 2 |
| FX | 4 | 4 | 4 |
| Subs | 4 | 4 | 6 |
| Aux | 4 | 6 | 10 |
| VCA | 0 | 0 | 6 |
| Multitrack | No | No | Yes |
| Master Dim | No | No | Yes |

## Testing

Use `MockWebSocketTransport` to test without a real mixer connection:

```swift
import XCTest
@testable import SoundcraftUI

let transport = MockWebSocketTransport()
let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
mixer.connect()

// Simulate inbound state
transport.simulateSetd(path: "i.0.mix", value: "0.75")

// Verify outbound commands
mixer.master.input(1).setFaderLevel(0.5)
XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.mix^0.5"))
```

### MockWebSocketTransport API

```swift
transport.sentMessages          // [String] — all raw sent messages
transport.sentCommands          // [String] — sent messages without 3::: framing
transport.connectCalled         // Bool
transport.disconnectCalled      // Bool
transport.simulateInbound(_:)   // Simulate receiving a raw message
transport.simulateSetd(path:value:)  // Simulate receiving SETD^path^value
```

### Running Tests

```bash
cd SoundcraftUI
swift test
```

84 tests covering message protocol parsing, state management, VU processing, value conversion, and channel control.

## Architecture

| Component | Purpose |
|-----------|---------|
| `SoundcraftUI` | Main facade — connection, bus/channel factories |
| `MixerConnection` | WebSocket transport with auto-reconnect |
| `MixerStore` | Reactive state dictionary (`CurrentValueSubject<[String: Any], Never>`) |
| `MasterBus` / `AuxBus` / `FxBus` | Bus-specific channel access |
| `Channel` / `MasterChannel` / `AuxChannel` | Per-channel control + publishers |
| `DelayableMasterChannel` | Master bus channel with delay control |
| `HwChannel` | Hardware gain and phantom power |
| `VolumeBus` | Solo and headphone monitor volume |
| `VUProcessor` | Binary VU meter data parsing at 60fps |
| `RTAProcessor` | Binary RTA spectrum data parsing |
| `DeviceInfo` | Model detection and capabilities |
| `ShowController` | Shows, snapshots, and cues |
| `AutomixController` | Automix group state and response time |
| `ChannelSync` | Cross-client channel selection sync |
| `DualTrackRecorder` | Two-track USB recording |
| `MultiTrackRecorder` | Multitrack USB recording (UI24R) |
| `GlobalSettings` | AFS, solo mode, clock, hardware routing |
