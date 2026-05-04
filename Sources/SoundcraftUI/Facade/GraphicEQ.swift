import Combine
import Foundation

/// Represents a 31-band graphic EQ on a master or AUX bus.
///
/// Master paths (stereo): `m.eq.peak.{l,r}.{0-30}`, `m.eq.hpf.{l,r}`, `m.eq.lpf.{l,r}`,
///                         `m.eq.linked`, `m.eq.bypass`
/// AUX paths (mono):      `a.{n}.eq.peak.{0-30}`, `a.{n}.eq.hpf`, `a.{n}.eq.lpf`,
///                         `a.{n}.eq.bypass`
public final class GraphicEQ {
    private let conn: MixerConnection
    private let store: MixerStore
    private let basePath: String // e.g. "m.eq" or "a.0.eq"
    private let isMaster: Bool

    /// Number of GEQ bands
    public static let bandCount = 31

    init(conn: MixerConnection, store: MixerStore, isMaster: Bool, auxBus: Int = 0) {
        self.conn = conn
        self.store = store
        self.isMaster = isMaster
        self.basePath = isMaster ? "m.eq" : "a.\(auxBus - 1).eq"
    }

    // MARK: - Bypass / Linked

    /// GEQ bypass (0 or 1)
    public lazy var bypass: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).bypass", default: 0)
    }()

    /// L/R linked (master only, 0 or 1)
    public lazy var linked: AnyPublisher<Int, Never> = {
        guard isMaster else { return Just(0).eraseToAnyPublisher() }
        return store.select(path: "\(basePath).linked", default: 1)
    }()

    public func setBypass(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).bypass^\(value)")
    }

    public func enableBypass() { setBypass(1) }
    public func disableBypass() { setBypass(0) }

    public func setLinked(_ value: Int) {
        guard isMaster else { return }
        conn.sendMessage("SETD^\(basePath).linked^\(value)")
    }

    // MARK: - Band Values (0-30)

    /// Get a GEQ band value (0..1 normalized, 0.5 = flat).
    /// For master, `side` is "l" or "r". For AUX, side is ignored.
    public func bandValue(_ band: Int, side: String = "l") -> AnyPublisher<Double, Never> {
        precondition(band >= 0 && band <= 30, "GEQ band must be 0-30")
        let path: String
        if isMaster {
            path = "\(basePath).peak.\(side).\(band)"
        } else {
            path = "\(basePath).peak.\(band)"
        }
        return store.select(path: path, default: 0.5)
    }

    /// Set a GEQ band value.
    public func setBandValue(_ band: Int, side: String = "l", value: Double) {
        precondition(band >= 0 && band <= 30, "GEQ band must be 0-30")
        let clamped = clamp(value, min: 0, max: 1)
        let path: String
        if isMaster {
            path = "\(basePath).peak.\(side).\(band)"
        } else {
            path = "\(basePath).peak.\(band)"
        }
        conn.sendMessage("SETD^\(path)^\(clamped)")
    }

    // MARK: - HPF / LPF

    /// HPF frequency for the given side (master) or mono (AUX). 0..1 normalized.
    public func hpf(side: String = "l") -> AnyPublisher<Double, Never> {
        let path = isMaster ? "\(basePath).hpf.\(side)" : "\(basePath).hpf"
        return store.select(path: path, default: 0.0)
    }

    /// LPF frequency for the given side (master) or mono (AUX). 0..1 normalized.
    public func lpf(side: String = "l") -> AnyPublisher<Double, Never> {
        let path = isMaster ? "\(basePath).lpf.\(side)" : "\(basePath).lpf"
        return store.select(path: path, default: 1.0)
    }

    public func setHpf(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        let path = isMaster ? "\(basePath).hpf.\(side)" : "\(basePath).hpf"
        conn.sendMessage("SETD^\(path)^\(clamped)")
    }

    public func setLpf(side: String = "l", value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        let path = isMaster ? "\(basePath).lpf.\(side)" : "\(basePath).lpf"
        conn.sendMessage("SETD^\(path)^\(clamped)")
    }
}
