import Foundation

/// Represents an AUX bus with channel factories
public final class AuxBus {
    let conn: MixerConnection
    let store: MixerStore
    let bus: Int

    init(conn: MixerConnection, store: MixerStore, bus: Int) {
        self.conn = conn
        self.store = store
        self.bus = bus
    }

    static func resolve(conn: MixerConnection, store: MixerStore, bus: Int) -> AuxBus {
        let storeId = "auxbus\(bus)"
        if let cached: AuxBus = store.objectStore.get(storeId) {
            return cached
        }
        let instance = AuxBus(conn: conn, store: store, bus: bus)
        store.objectStore.set(storeId, instance)
        return instance
    }

    public func input(_ channel: Int) -> AuxChannel {
        AuxChannel.resolve(conn: conn, store: store, channelType: .input, channel: channel, bus: bus)
    }

    public func line(_ channel: Int) -> AuxChannel {
        AuxChannel.resolve(conn: conn, store: store, channelType: .line, channel: channel, bus: bus)
    }

    public func player(_ channel: Int) -> AuxChannel {
        AuxChannel.resolve(conn: conn, store: store, channelType: .player, channel: channel, bus: bus)
    }

    public func fx(_ channel: Int) -> AuxChannel {
        AuxChannel.resolve(conn: conn, store: store, channelType: .fx, channel: channel, bus: bus)
    }
}
