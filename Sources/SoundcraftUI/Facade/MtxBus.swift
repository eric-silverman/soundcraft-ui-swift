import Combine
import Foundation

/// Represents a matrix bus.
/// A matrix bus is an AUX bus that has been converted into a matrix.
/// Unlike a regular AUX bus, a matrix routes other buses (AUX buses, subgroups
/// and the master mix) to an AUX output. Matrix buses are only available on the Ui24R.
///
/// The matrix output (level, name, mute, solo, delay) is controlled like an AUX
/// output via `mixer.master.mtx(n)`.
public final class MtxBus {
    let conn: MixerConnection
    let store: MixerStore
    let bus: Int

    /// Whether this bus is currently configured as a matrix bus (Ui24R only)
    public lazy var isMatrix$: AnyPublisher<Bool, Never> = {
        store.matrix(bus: bus)
    }()

    init(conn: MixerConnection, store: MixerStore, bus: Int) {
        self.conn = conn
        self.store = store
        self.bus = bus
    }

    static func resolve(conn: MixerConnection, store: MixerStore, bus: Int) -> MtxBus {
        store.objectStore.getOrCreate(mtxBusStoreId(bus)) {
            MtxBus(conn: conn, store: store, bus: bus)
        }
    }

    /// Get an AUX bus as a source on the matrix
    /// - Parameter channel: AUX bus number
    public func aux(_ channel: Int) -> MtxBusChannel {
        MtxBusChannel.resolve(conn: conn, store: store, channelType: .aux, channel: channel, bus: bus)
    }

    /// Get a subgroup as a source on the matrix
    /// - Parameter channel: Subgroup number
    public func sub(_ channel: Int) -> MtxBusChannel {
        MtxBusChannel.resolve(conn: conn, store: store, channelType: .sub, channel: channel, bus: bus)
    }

    /// Get the master mix as a source on the matrix
    public func master() -> MtxMasterChannel {
        MtxMasterChannel.resolve(conn: conn, store: store, bus: bus)
    }

    /// Switch this matrix bus to a regular AUX bus (Ui24R only).
    /// When this bus is stereo-linked, the linked neighbour is switched as well.
    /// - Returns: the AUX bus (`AuxBus`) for the same slot
    @discardableResult
    public func switchToAux() -> AuxBus {
        setMatrixMode(conn: conn, store: store, bus: bus, value: false)
        return AuxBus.resolve(conn: conn, store: store, bus: bus)
    }
}
