import Foundation

/// VU data for input/player/line channels (mono with pre-fader)
public struct InputChannelVU: Sendable {
    public let vuPre: Double
    public let vuPost: Double
    public let vuPostFader: Double
    /// Compressor/dynamics gain reduction fraction (0 = no reduction, 1 = full). Sourced from byte[3].
    public let grFraction: Double
    /// Gate gain reduction fraction (0 = gate open, >0 = gate attenuating). Sourced from byte[4].
    /// May be 0 on firmware versions that don't populate this byte.
    public let gateGRFraction: Double
}

/// VU data for AUX channels (mono, post only)
public struct AuxChannelVU: Sendable {
    public let vuPost: Double
    public let vuPostFader: Double
    /// Gain reduction fraction (0 = no reduction, 1 = full reduction). Sourced from byte[2].
    public let grFraction: Double
}

/// VU data for master channels (mono, post only)
public struct MasterVU: Sendable {
    public let vuPost: Double
    public let vuPostFader: Double
    /// Gain reduction fraction. Sourced from byte[2].
    public let grFraction: Double
}

/// VU data for stereo channels (FX, sub groups)
public struct StereoVU: Sendable {
    public let vuPostL: Double
    public let vuPostR: Double
    public let vuPostFaderL: Double
    public let vuPostFaderR: Double
    /// Gain reduction fraction, left channel. Sourced from byte[4].
    public let grFractionL: Double
    /// Gain reduction fraction, right channel. Sourced from byte[5].
    public let grFractionR: Double
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
            grFractionR: master[1].grFraction
        )
    }
}
