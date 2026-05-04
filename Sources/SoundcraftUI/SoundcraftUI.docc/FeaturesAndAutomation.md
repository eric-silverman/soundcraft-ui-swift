# Features And Automation

## Player

`player` exposes the mixer media player.

```swift
mixer.player.play()
mixer.player.pause()
mixer.player.stop()
mixer.player.next()
mixer.player.prev()
mixer.player.loadPlaylist("My Set")
mixer.player.loadTrack(playlist: "My Set", track: "Song.mp3")
```

Published state includes:

- `state`
- `playlist`
- `track`
- `length`
- `elapsedTime`
- `remainingTime`
- `shuffle`

## Recording

Two-track USB recording is available through ``DualTrackRecorder``:

```swift
mixer.recorderDualTrack.recordToggle()
mixer.recorderDualTrack.recordStart()
mixer.recorderDualTrack.recordStop()
```

UI24R multitrack control is available through ``MultiTrackRecorder``:

```swift
mixer.recorderMultiTrack.play()
mixer.recorderMultiTrack.pause()
mixer.recorderMultiTrack.stop()
mixer.recorderMultiTrack.recordStart()
mixer.recorderMultiTrack.toggleSoundcheck()
mixer.recorderMultiTrack.renameSession("Session Name")
```

## Shows, snapshots, and cues

Use ``ShowController`` to load and save shows and cue data.

```swift
mixer.shows.loadShow("MyShow")
mixer.shows.loadSnapshot(show: "MyShow", snapshot: "Snap1")
mixer.shows.saveCue(show: "MyShow", cue: "Intro")
mixer.shows.updateCurrentSnapshot()
```

## Automix

Global automix state is available through ``AutomixController``:

```swift
mixer.automix.setResponseTimeMs(500)
mixer.automix.groups.a.enable()
mixer.automix.groups.b.toggle()
```

Channel assignment happens through ``MasterChannel``:

```swift
mixer.master.input(1).automixAssignGroup(.a)
mixer.master.input(2).automixAssignGroup(.b)
mixer.master.input(3).automixRemove()
```

## Mute groups

Use ``MuteGroup`` to control shared mute masks.

```swift
let group = mixer.muteGroup(.group(1))

group.mute()
group.unmute()
group.toggle()

mixer.clearMuteGroups()
```

## Channel sync

``ChannelSync`` lets multiple clients share the currently selected channel index on the same network.

```swift
mixer.channelSync.selectChannelIndex(2)
mixer.channelSync.selectChannel(type: .input, num: 3)
mixer.channelSync.selectMaster()

mixer.channelSync.getSelectedChannel()
    .sink { channel in
        channel?.setFaderLevel(0.8)
    }
    .store(in: &cancellables)
```

## Device info and capabilities

Use ``DeviceInfo`` to inspect model and firmware state.

```swift
mixer.deviceInfo.model
mixer.deviceInfo.capabilities
mixer.deviceInfo.firmware
```

Resolve static capability limits with ``DeviceCapabilities`` when you need to adapt UI or channel availability.
