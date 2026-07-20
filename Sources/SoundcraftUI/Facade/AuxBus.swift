import Combine
import Foundation

/// Represents an AUX bus with channel factories
public final class AuxBus {
    let conn: MixerConnection
    let store: MixerStore
    let bus: Int

    /// Whether this AUX bus is currently configured as a matrix bus (Ui24R only).
    /// When `true`, this slot is a matrix and should be controlled through `mixer.mtx(n)` instead.
    public lazy var isMatrix$: AnyPublisher<Bool, Never> = {
        store.matrix(bus: bus)
    }()

    init(conn: MixerConnection, store: MixerStore, bus: Int) {
        self.conn = conn
        self.store = store
        self.bus = bus
    }

    static func resolve(conn: MixerConnection, store: MixerStore, bus: Int) -> AuxBus {
        store.objectStore.getOrCreate(auxBusStoreId(bus)) {
            AuxBus(conn: conn, store: store, bus: bus)
        }
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

    /// Switch this AUX bus to a matrix bus (Ui24R only).
    /// When this bus is stereo-linked, the linked neighbour is switched as well.
    /// - Returns: the matrix bus (`MtxBus`) for the same slot
    @discardableResult
    public func switchToMatrix() -> MtxBus {
        setMatrixMode(conn: conn, store: store, bus: bus, value: true)
        return MtxBus.resolve(conn: conn, store: store, bus: bus)
    }
}
