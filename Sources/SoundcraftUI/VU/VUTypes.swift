import Foundation

/// VU data for input/player/line channels (mono with pre-fader)
public struct InputChannelVU: Sendable {
    public let vuPre: Double
    public let vuPost: Double
    public let vuPostFader: Double
    /// Level into the dynamics section (byte 3; the web UI's dynamics/gate editor "IN" meter).
    public let dynamicsIn: Double
    /// Level out of the dynamics section (byte 4; the editor's "OUT" meter).
    public let dynamicsOut: Double
    /// Compressor gain reduction, 0 = none, 1 = 20 dB or more (byte 5, low 7 bits) —
    /// the same scale as the web UI's GR meter.
    public let grFraction: Double
    /// Gate state (byte 5, top bit). `false` = gate closed; the web UI draws a red ✕.
    public let gateOpen: Bool

    /// 0 when the gate is open, 1 when it's closed.
    @available(*, deprecated, message: "Use gateOpen. This was read from byte 4, which is the dynamics output level.")
    public var gateGRFraction: Double { gateOpen ? 0 : 1 }
}

/// VU data for AUX channels (mono, post only)
public struct AuxChannelVU: Sendable {
    public let vuPost: Double
    public let vuPostFader: Double
    /// Compressor gain reduction, 0 = none, 1 = 20 dB or more (byte 4, low 7 bits).
    public let grFraction: Double
    /// Gate state (byte 4, top bit).
    public let gateOpen: Bool
}

/// VU data for master channels (mono, post only)
public struct MasterVU: Sendable {
    public let vuPost: Double
    public let vuPostFader: Double
    /// Compressor gain reduction, 0 = none, 1 = 20 dB or more (byte 4, low 7 bits).
    public let grFraction: Double
    /// Gate state (byte 4, top bit).
    public let gateOpen: Bool
}

/// VU data for stereo channels (FX, sub groups)
public struct StereoVU: Sendable {
    public let vuPostL: Double
    public let vuPostR: Double
    public let vuPostFaderL: Double
    public let vuPostFaderR: Double
    /// Compressor gain reduction, 0 = none, 1 = 20 dB or more. FX and sub groups
    /// send one value for both sides (byte 6); the stereo master sends one per side.
    public let grFractionL: Double
    public let grFractionR: Double
    /// Gate state (FX/sub: byte 6 top bit, shared by both sides).
    public let gateOpenL: Bool
    public let gateOpenR: Bool
}

/// Complete VU data for all channel types
public struct VUData: Sendable {
    public let input: [InputChannelVU]
    public let player: [InputChannelVU]
    public let sub: [StereoVU]
    public let fx: [StereoVU]
    public let aux: [AuxChannelVU]
    public let master: [MasterVU]
    public let line: [InputChannelVU]

    /// Stereo master VU derived from the two master channels
    public var stereoMaster: StereoVU? {
        guard master.count >= 2 else { return nil }
        return StereoVU(
            vuPostL: master[0].vuPost,
            vuPostR: master[1].vuPost,
            vuPostFaderL: master[0].vuPostFader,
            vuPostFaderR: master[1].vuPostFader,
            grFractionL: master[0].grFraction,
            grFractionR: master[1].grFraction,
            gateOpenL: master[0].gateOpen,
            gateOpenR: master[1].gateOpen
        )
    }
}
