import Combine
import Foundation

/// Represents an FX bus with type, BPM, parameters, and channel factories
public final class FxBus {
    let conn: MixerConnection
    let store: MixerStore
    let bus: Int

    /// FX type (Reverb, Delay, Chorus, Room, None)
    public lazy var fxType: AnyPublisher<FxType, Never> = {
        store.fxType(bus: bus)
            .map { FxType(rawValue: $0) ?? .none }
            .eraseToAnyPublisher()
    }()

    /// BPM value
    public lazy var bpm: AnyPublisher<Int, Never> = {
        store.fxBpm(bus: bus)
    }()

    init(conn: MixerConnection, store: MixerStore, bus: Int) {
        self.conn = conn
        self.store = store
        self.bus = bus
    }

    static func resolve(conn: MixerConnection, store: MixerStore, bus: Int) -> FxBus {
        let storeId = "fxbus\(bus)"
        if let cached: FxBus = store.objectStore.get(storeId) {
            return cached
        }
        let instance = FxBus(conn: conn, store: store, bus: bus)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Channel Factories

    public func input(_ channel: Int) -> FxChannel {
        FxChannel.resolve(conn: conn, store: store, channelType: .input, channel: channel, bus: bus)
    }

    public func line(_ channel: Int) -> FxChannel {
        FxChannel.resolve(conn: conn, store: store, channelType: .line, channel: channel, bus: bus)
    }

    public func player(_ channel: Int) -> FxChannel {
        FxChannel.resolve(conn: conn, store: store, channelType: .player, channel: channel, bus: bus)
    }

    public func sub(_ channel: Int) -> FxChannel {
        FxChannel.resolve(conn: conn, store: store, channelType: .sub, channel: channel, bus: bus)
    }

    // MARK: - FX Type

    public func setFxType(_ type: FxType) {
        conn.sendMessage("SETD^f.\(bus - 1).fxtype^\(type.rawValue)")
    }

    // MARK: - BPM

    public func setBpm(_ value: Int) {
        let clamped = clamp(value, min: 20, max: 400)
        conn.sendMessage("SETD^f.\(bus - 1).bpm^\(clamped)")
    }

    // MARK: - FX Parameters (1-6)

    public func getParam(_ param: Int) -> AnyPublisher<Double, Never> {
        precondition(param >= 1 && param <= 6, "FX Parameter must be between 1 and 6")
        let path = "f.\(bus - 1).par\(param)"
        return store.select(path: path, default: 0.0)
    }

    public func setParam(_ param: Int, value: Double) {
        precondition(param >= 1 && param <= 6, "FX Parameter must be between 1 and 6")
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^f.\(bus - 1).par\(param)^\(clamped)")
    }
}
