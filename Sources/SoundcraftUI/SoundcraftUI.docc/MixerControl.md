# Mixer Control

## Bus access

The top-level ``SoundcraftUI`` facade exposes the mixer as a set of typed buses.

```swift
let master = mixer.master
let aux1 = mixer.aux(1)
let fx1 = mixer.fx(1)
let hw1 = mixer.hw(1)
```

## Master bus

Use ``MasterBus`` for the main stereo output and for master-bus channel access.

```swift
master.setFaderLevel(0.75)
master.setFaderLevelDB(-6.0)
master.setPan(0.5)
master.enableDim()
master.setDelayL(10.0)
master.setDelayR(10.0)
```

Master bus channel factories:

```swift
master.input(1)   // DelayableMasterChannel
master.line(1)    // DelayableMasterChannel
master.player(1)  // MasterChannel
master.aux(1)     // DelayableMasterChannel
master.fx(1)      // MasterChannel
master.sub(1)     // MasterChannel
master.vca(1)     // MasterChannel
```

## Aux sends

Use ``AuxBus`` for monitor mixes and auxiliary sends.

```swift
let auxChannel = mixer.aux(1).input(1)

auxChannel.setFaderLevel(0.5)
auxChannel.postMode()
auxChannel.preMode()
auxChannel.postProc()
auxChannel.preProc()
auxChannel.setPan(0.5)
```

``AuxChannel`` layers aux-specific routing controls on top of the common channel API.

## FX sends and FX buses

Use ``FxBus`` for processor configuration and FX send access.

```swift
let fx = mixer.fx(1)

fx.setFxType(.delay)
fx.setBpm(120)
fx.setParam(1, value: 0.5)

fx.input(1).setFaderLevel(0.3)
fx.player(1).setFaderLevel(0.3)
```

## Hardware channels

Use ``HwChannel`` for preamp gain and phantom power.

```swift
let hw = mixer.hw(1)

hw.setGain(0.6)
hw.setGainDB(20.0)
hw.phantomOn()
```

Gain ranges differ by mixer family:

- UI24: `-6 ... +57 dB`
- UI12/UI16: `-40 ... +50 dB`

## Shared channel controls

All channel types inherit the common ``Channel`` controls:

```swift
channel.setFaderLevel(0.75)
channel.setFaderLevelDB(-6.0)
channel.changeFaderLevel(0.1)
channel.fadeTo(0.5, fadeTime: 2.0, easing: .easeInOut)

channel.enableMute()
channel.disableMute()
channel.toggleMute()

channel.setName("Kick")
```

Additional channel-specialized controls include:

- ``MasterChannel``: solo, automix assignment/weight, multitrack selection
- ``DelayableMasterChannel``: delay in milliseconds
- ``SendChannel``: pre/post send routing
- ``AuxChannel``: post/pre DSP send placement and aux send pan

## Swift-only DSP facades

The Swift port exposes DSP and global controls that are not part of the upstream TypeScript facade:

- `eq()`, `dynamics()`, and `gate()` on channels
- `graphicEQ()` and `dynamics()` on the master bus
- `graphicEQ()` on aux buses
- `deesser()` and `digitech()` on supported master channels
- `settings` on ``SoundcraftUI``

See <doc:FeaturesAndAutomation> for the higher-level feature controllers and system state surfaces.
