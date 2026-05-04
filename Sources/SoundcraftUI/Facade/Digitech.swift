import Combine
import Foundation

/// Represents a Digitech amp modeler (input channels only).
///
/// Protocol paths: `i.{n}.digitech.{bass,level,gain,treble,mid,enabled,amp,cab}`
public final class Digitech {
    private let conn: MixerConnection
    private let store: MixerStore
    private let basePath: String // e.g. "i.0.digitech"

    init(conn: MixerConnection, store: MixerStore, channel: Int) {
        self.conn = conn
        self.store = store
        self.basePath = "i.\(channel - 1).digitech"
    }

    // MARK: - Publishers

    /// Digitech enabled (0 or 1)
    public lazy var enabled: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).enabled", default: 0)
    }()

    /// Amp model index
    public lazy var amp: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).amp", default: 0)
    }()

    /// Cabinet model index
    public lazy var cab: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).cab", default: 0)
    }()

    /// Gain (0..1 normalized)
    public lazy var gain: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).gain", default: 0.5)
    }()

    /// Level (0..1 normalized)
    public lazy var level: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).level", default: 0.5)
    }()

    /// Bass (0..1 normalized)
    public lazy var bass: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).bass", default: 0.5)
    }()

    /// Mid (0..1 normalized)
    public lazy var mid: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).mid", default: 0.5)
    }()

    /// Treble (0..1 normalized)
    public lazy var treble: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).treble", default: 0.5)
    }()

    // MARK: - Setters

    public func setEnabled(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).enabled^\(value)")
    }

    public func enable() { setEnabled(1) }
    public func disable() { setEnabled(0) }

    public func setAmp(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).amp^\(value)")
    }

    public func setCab(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).cab^\(value)")
    }

    public func setGain(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).gain^\(clamped)")
    }

    public func setLevel(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).level^\(clamped)")
    }

    public func setBass(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).bass^\(clamped)")
    }

    public func setMid(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).mid^\(clamped)")
    }

    public func setTreble(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).treble^\(clamped)")
    }
}
