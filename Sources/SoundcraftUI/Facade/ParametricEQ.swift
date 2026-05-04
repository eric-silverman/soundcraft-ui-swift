import Combine
import Foundation

/// Represents a 5-band parametric EQ on a channel (input, line, player, sub, FX return).
///
/// Protocol paths:
/// - Band parameters: `{ch}.eq.b{1-5}.{gain,q,freq}` (all 0..1 normalized)
/// - HPF: `{ch}.eq.hpf.slope`, `{ch}.eq.hpf.freq`
/// - LPF: `{ch}.eq.lpf.slope`, `{ch}.eq.lpf.freq`
/// - Bypass: `{ch}.eq.bypass` (0/1)
/// - Easy mode: `{ch}.eq.easy` (0/1, simplified 3-band)
public final class ParametricEQ {
    private let conn: MixerConnection
    private let store: MixerStore
    private let basePath: String // e.g. "i.0.eq"

    init(conn: MixerConnection, store: MixerStore, channelType: ChannelType, channel: Int) {
        self.conn = conn
        self.store = store
        self.basePath = "\(channelType.rawValue).\(channel - 1).eq"
    }

    // MARK: - Global EQ State

    /// EQ bypass (0 or 1)
    public lazy var bypass: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).bypass", default: 0)
    }()

    /// Easy mode (0 or 1) — simplified 3-band view
    public lazy var easyMode: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).easy", default: 0)
    }()

    public func setBypass(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).bypass^\(value)")
    }

    public func enableBypass() { setBypass(1) }
    public func disableBypass() { setBypass(0) }

    public func setEasyMode(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).easy^\(value)")
    }

    // MARK: - Band Parameters (1-5)

    /// Get band gain (0..1 normalized, 0.5 = 0dB)
    public func bandGain(_ band: Int) -> AnyPublisher<Double, Never> {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        return store.select(path: "\(basePath).b\(band).gain", default: 0.5)
    }

    /// Get band frequency (0..1 normalized)
    public func bandFreq(_ band: Int) -> AnyPublisher<Double, Never> {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        return store.select(path: "\(basePath).b\(band).freq", default: 0.5)
    }

    /// Get band Q factor (0..1 normalized)
    public func bandQ(_ band: Int) -> AnyPublisher<Double, Never> {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        return store.select(path: "\(basePath).b\(band).q", default: 0.5)
    }

    /// Set band gain
    public func setBandGain(_ band: Int, value: Double) {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).b\(band).gain^\(clamped)")
    }

    /// Set band frequency
    public func setBandFreq(_ band: Int, value: Double) {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).b\(band).freq^\(clamped)")
    }

    /// Set band Q factor
    public func setBandQ(_ band: Int, value: Double) {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).b\(band).q^\(clamped)")
    }

    /// Set band enabled (1 = on, 0 = off)
    public func setBandEnabled(_ band: Int, value: Int) {
        precondition(band >= 1 && band <= 5, "EQ band must be 1-5")
        conn.sendMessage("SETD^\(basePath).b\(band).on^\(value)")
    }

    // MARK: - High-Pass Filter

    /// HPF slope (0 = off, 1-4 = 6/12/18/24 dB/oct)
    public lazy var hpfSlope: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).hpf.slope", default: 0)
    }()

    /// HPF frequency (0..1 normalized)
    public lazy var hpfFreq: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).hpf.freq", default: 0.0)
    }()

    public func setHpfSlope(_ value: Int) {
        let clamped = clamp(value, min: 0, max: 4)
        conn.sendMessage("SETD^\(basePath).hpf.slope^\(clamped)")
    }

    public func setHpfFreq(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).hpf.freq^\(clamped)")
    }

    // MARK: - Low-Pass Filter

    /// LPF slope (0 = off, 1-4 = 6/12/18/24 dB/oct)
    public lazy var lpfSlope: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).lpf.slope", default: 0)
    }()

    /// LPF frequency (0..1 normalized)
    public lazy var lpfFreq: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).lpf.freq", default: 1.0)
    }()

    public func setLpfSlope(_ value: Int) {
        let clamped = clamp(value, min: 0, max: 4)
        conn.sendMessage("SETD^\(basePath).lpf.slope^\(clamped)")
    }

    public func setLpfFreq(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).lpf.freq^\(clamped)")
    }
}
