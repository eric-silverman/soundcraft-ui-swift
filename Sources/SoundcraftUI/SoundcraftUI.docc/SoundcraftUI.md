# ``SoundcraftUI``

Control Soundcraft UI series mixers from Swift on iOS and macOS.

## Overview

Use ``SoundcraftUI`` to connect to a mixer, observe its state via Combine, and control buses, channels, recorders, transport, and monitoring features from Swift code.

The package exposes:

- bus and channel facades such as ``MasterBus``, ``AuxBus``, ``FxBus``, and ``HwChannel``
- a reactive state model through ``MixerStore``
- meter and analyzer streams through ``VUProcessor`` and ``RTAProcessor``
- Swift-only DSP and settings facades such as ``ParametricEQ``, ``GraphicEQ``, ``Dynamics``, and ``GlobalSettings``

Channel- and bus-selection APIs are 1-indexed for ergonomic use in app code. Raw state keys inside ``MixerStore`` remain 0-indexed to match the mixer protocol.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:MixerControl>
- <doc:StateAndMonitoring>
- <doc:FeaturesAndAutomation>

### Development

- <doc:TestingAndDevelopment>
