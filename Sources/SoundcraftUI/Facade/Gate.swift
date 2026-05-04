import Combine
import Foundation

/// Represents a noise gate processor on a channel.
///
/// Protocol paths: `{ch}.gate.{param}` where param is one of:
///   depth, bypass, enabled, hold, release, attack, thresh, prmod
public final class Gate {
    private let conn: MixerConnection
    private let store: MixerStore
    private let basePath: String // e.g. "i.0.gate"

    init(conn: MixerConnection, store: MixerStore, channelType: ChannelType, channel: Int) {
        self.conn = conn
        self.store = store
        self.basePath = "\(channelType.rawValue).\(channel - 1).gate"
    }

    // MARK: - Publishers

    /// Gate enabled (0 or 1)
    public lazy var enabled: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).enabled", default: 0)
    }()

    /// Bypass (0 or 1)
    public lazy var bypass: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).bypass", default: 0)
    }()

    /// Threshold (0..1 normalized)
    public lazy var threshold: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).thresh", default: 0.5)
    }()

    /// Depth (0..1 normalized)
    public lazy var depth: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).depth", default: 0.5)
    }()

    /// Attack (0..1 normalized)
    public lazy var attack: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).attack", default: 0.5)
    }()

    /// Release (0..1 normalized)
    public lazy var release: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).release", default: 0.5)
    }()

    /// Hold (0..1 normalized)
    public lazy var hold: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).hold", default: 0.5)
    }()

    /// Sidechain pre-routing mode
    public lazy var prmod: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).prmod", default: 0)
    }()

    // MARK: - Setters

    public func setEnabled(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).enabled^\(value)")
    }

    public func enable() { setEnabled(1) }
    public func disable() { setEnabled(0) }

    public func setBypass(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).bypass^\(value)")
    }

    public func enableBypass() { setBypass(1) }
    public func disableBypass() { setBypass(0) }

    public func setThreshold(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).thresh^\(clamped)")
    }

    public func setDepth(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).depth^\(clamped)")
    }

    public func setAttack(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).attack^\(clamped)")
    }

    public func setRelease(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).release^\(clamped)")
    }

    public func setHold(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).hold^\(clamped)")
    }

    public func setPrmod(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).prmod^\(value)")
    }

    public func setSoftknee(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).softknee^\(value)")
    }

    public func enableSoftknee() { setSoftknee(1) }
    public func disableSoftknee() { setSoftknee(0) }
}
