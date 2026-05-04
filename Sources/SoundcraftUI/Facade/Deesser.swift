import Combine
import Foundation

/// Represents a de-esser processor (input channels only).
///
/// Protocol paths: `i.{n}.deesser.{freq,enabled,ratio,threshold}`
public final class Deesser {
    private let conn: MixerConnection
    private let store: MixerStore
    private let basePath: String // e.g. "i.0.deesser"

    init(conn: MixerConnection, store: MixerStore, channel: Int) {
        self.conn = conn
        self.store = store
        self.basePath = "i.\(channel - 1).deesser"
    }

    // MARK: - Publishers

    /// De-esser enabled (0 or 1)
    public lazy var enabled: AnyPublisher<Int, Never> = {
        store.select(path: "\(basePath).enabled", default: 0)
    }()

    /// Frequency (0..1 normalized)
    public lazy var freq: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).freq", default: 0.5)
    }()

    /// Ratio (0..1 normalized)
    public lazy var ratio: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).ratio", default: 0.5)
    }()

    /// Threshold (0..1 normalized)
    public lazy var threshold: AnyPublisher<Double, Never> = {
        store.select(path: "\(basePath).threshold", default: 0.5)
    }()

    // MARK: - Setters

    public func setEnabled(_ value: Int) {
        conn.sendMessage("SETD^\(basePath).enabled^\(value)")
    }

    public func enable() { setEnabled(1) }
    public func disable() { setEnabled(0) }

    public func setFreq(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).freq^\(clamped)")
    }

    public func setRatio(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).ratio^\(clamped)")
    }

    public func setThreshold(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(basePath).threshold^\(clamped)")
    }
}
