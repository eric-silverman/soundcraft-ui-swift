import Combine
import Foundation

/// Represents a compressor/dynamics processor on a channel.
///
/// Channel paths: `{ch}.dyn.{param}` where param is one of:
///   ratio, gain, threshold, bypass, outgain, release, attack,
///   softknee, prmod, prname, hold, autogain
///
/// Master paths: `m.dyn.{l,r}.{param}` (stereo), `m.dyn.linked`, `m.dyn.bypass`
public final class Dynamics {
    private let conn: MixerConnection
    private let store: MixerStore
    private let basePath: String // e.g. "i.0.dyn" or "m.dyn"
    private let isMaster: Bool

    init(conn: MixerConnection, store: MixerStore, channelType: ChannelType, channel: Int) {
        self.conn = conn
        self.store = store
        self.basePath = "\(channelType.rawValue).\(channel - 1).dyn"
        self.isMaster = false
    }

    init(conn: MixerConnection, store: MixerStore, isMaster: Bool) {
        self.conn = conn
        self.store = store
        self.basePath = "m.dyn"
        self.isMaster = true
    }

    // MARK: - Channel Dynamics Publishers

    /// Threshold (0..1 normalized)
    public func threshold(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("threshold", side: side), default: 0.5)
    }

    /// Ratio (0..1 normalized)
    public func ratio(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("ratio", side: side), default: 0.5)
    }

    /// Attack (0..1 normalized)
    public func attack(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("attack", side: side), default: 0.5)
    }

    /// Release (0..1 normalized)
    public func release(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("release", side: side), default: 0.5)
    }

    /// Gain / makeup gain (0..1 normalized)
    public func gain(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("gain", side: side), default: 0.5)
    }

    /// Output gain (0..1 normalized)
    public func outgain(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("outgain", side: side), default: 0.5)
    }

    /// Hold (0..1 normalized)
    public func hold(side: String = "l") -> AnyPublisher<Double, Never> {
        store.select(path: paramPath("hold", side: side), default: 0.5)
    }

    /// Soft knee (0 or 1)
    public func softknee(side: String = "l") -> AnyPublisher<Int, Never> {
        store.select(path: paramPath("softknee", side: side), default: 0)
    }

    /// Auto gain (0 or 1)
    public func autogain(side: String = "l") -> AnyPublisher<Int, Never> {
        store.select(path: paramPath("autogain", side: side), default: 0)
    }

    /// Bypass (0 or 1)
    public lazy var bypass: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).bypass", default: 0)
    }()

    /// Sidechain pre-routing mode (channel dynamics only)
    public lazy var prmod: AnyPublisher<Int, Never> = {
        guard !isMaster else { return Just(0).eraseToAnyPublisher() }
        return store.select(path: "\(basePath).prmod", default: 0)
    }()

    /// Sidechain source name (channel dynamics only)
    public lazy var prname: AnyPublisher<String, Never> = {
        guard !isMaster else { return Just("").eraseToAnyPublisher() }
        return store.select(path: "\(basePath).prname", default: "")
    }()

    /// L/R linked (master only, 0 or 1)
    public lazy var linked: AnyPublisher<Int, Never> = {
        guard isMaster else { return Just(0).eraseToAnyPublisher() }
        return store.select(path: "\(basePath).linked", default: 1)
    }()

    // MARK: - Setters

    public func setThreshold(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("threshold", side: side))^\(clamped)")
    }

    public func setRatio(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("ratio", side: side))^\(clamped)")
    }

    public func setAttack(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("attack", side: side))^\(clamped)")
    }

    public func setRelease(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("release", side: side))^\(clamped)")
    }

    public func setGain(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("gain", side: side))^\(clamped)")
    }

    public func setOutgain(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("outgain", side: side))^\(clamped)")
    }

    public func setHold(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(paramPath("hold", side: side))^\(clamped)")
    }

    public func setSoftknee(side: String = "l", value: Int) {
        conn.sendMessage("SETD^\(paramPath("softknee", side: side))^\(value)")
    }

    public func setAutogain(side: String = "l", value: Int) {
        conn.sendMessage("SETD^\(paramPath("autogain", side: side))^\(value)")
    }

    public func setBypass(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).bypass^\(value)")
    }

    public func enableBypass() { setBypass(1) }
    public func disableBypass() { setBypass(0) }

    public func setPrmod(_ value: Int) {
        guard !isMaster else { return }
        conn.sendMessage("SETD^\(basePath).prmod^\(value)")
    }

    public func setLinked(_ value: Int) {
        guard isMaster else { return }
        conn.sendMessage("SETD^\(basePath).linked^\(value)")
    }

    // MARK: - Path Helper

    private func paramPath(_ param: String, side: String) -> String {
        if isMaster {
            return "\(basePath).\(side).\(param)"
        }
        return "\(basePath).\(param)"
    }
}
