# Getting Started

## Create a mixer connection

Instantiate ``SoundcraftUI`` with the mixer IP address, then call `connect()`.

```swift
import SoundcraftUI

let mixer = SoundcraftUI(ip: "192.168.1.123")
mixer.connect()
```

The top-level facade owns:

- a ``MixerConnection`` for WebSocket transport
- a ``MixerStore`` for the accumulated state dictionary
- top-level feature facades such as ``MasterBus``, ``Player``, and ``AutomixController``

## Observe connection state

Subscribe to `status` for real-time connection updates.

```swift
mixer.status
    .sink { status in
        print("Status:", status)
    }
    .store(in: &cancellables)
```

Important ``ConnectionStatus`` values:

- `.opening`: socket connect in progress
- `.open`: connected and ready
- `.closing`: disconnect requested
- `.close`: disconnected
- `.error`: transport reported an error
- `.reconnecting`: automatic reconnect has been scheduled

## First control example

All bus and channel access is rooted at ``SoundcraftUI``.

```swift
let vocal = mixer.master.input(1)

vocal.setFaderLevel(0.75)
vocal.enableMute()
```

`input(1)` is the first input channel, not the zero-th. Internally, the state path becomes `i.0`.

## Observe state

The raw state store is available as `store.state`.

```swift
mixer.store.state
    .sink { state in
        let fader = state["i.0.mix"] as? Double
        let mute = state["i.0.mute"] as? Int
        print(fader as Any, mute as Any)
    }
    .store(in: &cancellables)
```

For focused reads, use typed selectors:

```swift
mixer.store.select(path: "i.0.mix", default: 0.0)
    .sink { level in
        print(level)
    }
    .store(in: &cancellables)
```

## Next steps

- <doc:MixerControl> for buses, sends, and hardware channels
- <doc:StateAndMonitoring> for selectors, VU, RTA, and monitoring paths
- <doc:FeaturesAndAutomation> for transport, recording, shows, automix, and synchronization
