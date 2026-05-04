import Combine
import Foundation

/// Additional properties for FX buses/returns.
extension FxBus {

    /// FX bus bypass (0 or 1)
    public func bypass() -> AnyPublisher<Int, Never> {
        store.select(path: "f.\(bus - 1).bypass", default: 0)
    }

    /// Stereo mix for FX return (0..1)
    public func stereoMix() -> AnyPublisher<Double, Never> {
        store.select(path: "f.\(bus - 1).smix", default: 0.5)
    }

    /// Stereo pan for FX return (0..1)
    public func stereoPan() -> AnyPublisher<Double, Never> {
        store.select(path: "f.\(bus - 1).span", default: 0.5)
    }

    public func setBypass(_ value: Int) {
        conn.sendMessage("SETD^f.\(bus - 1).bypass^\(value)")
    }

    public func setStereoMix(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^f.\(bus - 1).smix^\(clamped)")
    }

    public func setStereoPan(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^f.\(bus - 1).span^\(clamped)")
    }

    /// Mute the FX bus return (1 = muted, 0 = unmuted)
    public func setMute(_ value: Int) {
        conn.sendMessage("SETD^f.\(bus - 1).mute^\(value)")
    }

    public func enableMute()  { setMute(1) }
    public func disableMute() { setMute(0) }
}
