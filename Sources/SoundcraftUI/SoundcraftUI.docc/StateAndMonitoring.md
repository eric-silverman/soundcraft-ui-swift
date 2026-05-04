# State And Monitoring

## Mixer state

``MixerStore`` accumulates incoming `SETD` and `SETS` messages into a flat dictionary keyed by the mixer protocol paths.

```swift
mixer.store.state
    .sink { state in
        let name = state["i.0.name"] as? String
        let mute = state["i.0.mute"] as? Int
        print(name as Any, mute as Any)
    }
    .store(in: &cancellables)
```

Typed accessors are available through:

- `select(path:default:)`
- `select(path:)`
- additional store helpers such as `masterValue`, `panValue(...)`, and `volumeBusValue(...)`

Examples:

```swift
mixer.store.masterValue
mixer.store.panValue(channelType: .input, channel: 1, busType: .master)
mixer.store.volumeBusValue(busName: "solovol")
```

## State key conventions

The raw protocol and store are 0-indexed.

| Key pattern | Meaning |
| --- | --- |
| `i.{n}.mix` | Input channel fader on the master bus |
| `i.{n}.mute` | Input channel mute |
| `i.{n}.solo` | Input channel solo |
| `i.{n}.aux.{a}.value` | Aux send level |
| `i.{n}.fx.{f}.value` | FX send level |
| `f.{n}.bpm` | FX bus BPM |
| `hw.{n}.gain` | Hardware gain |
| `m.mix` | Master fader |
| `m.pan` | Master pan |

## VU metering

Use ``VUProcessor`` for parsed binary meter data.

```swift
mixer.vuProcessor.vuData
    .sink { data in
        for (index, channel) in data.input.enumerated() {
            print("CH \\(index + 1):", channel.vuPre, channel.vuPostFader)
        }
    }
    .store(in: &cancellables)
```

Per-channel publishers:

```swift
mixer.vuProcessor.input(1)
mixer.vuProcessor.aux(1)
mixer.vuProcessor.fx(1)
mixer.vuProcessor.master()
```

## RTA

Use ``RTAProcessor`` for real-time analyzer frames.

```swift
mixer.rtaProcessor.subscribeChannel(path: "m")

mixer.rtaProcessor.rtaFrame
    .sink { frame in
        print(frame.bins)
    }
    .store(in: &cancellables)
```

Call `unsubscribe()` when the stream is no longer needed.

## Volume buses

Use `volume` for solo and headphone monitor levels.

```swift
mixer.volume.solo.setFaderLevel(0.8)
mixer.volume.headphone(1).setFaderLevel(0.7)
```

``VolumeBus`` supports the same relative and animated fade helpers as the channel facades.
