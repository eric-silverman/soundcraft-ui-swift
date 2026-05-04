import Combine
import Foundation

/// DSP processor accessors for AUX buses.
extension AuxBus {

    // MARK: - Graphic EQ

    /// 31-band graphic EQ for this AUX bus (mono)
    public func graphicEQ() -> GraphicEQ {
        let storeId = "geq_aux\(bus)"
        if let cached: GraphicEQ = store.objectStore.get(storeId) {
            return cached
        }
        let instance = GraphicEQ(conn: conn, store: store, isMaster: false, auxBus: bus)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - AFS (Automatic Feedback Suppression)

    /// AUX AFS enabled (0 or 1)
    public var afsEnabled: AnyPublisher<Int, Never> {
        store.select(path: "a.\(bus - 1).afs.enabled", default: 0)
    }

    public func setAfsEnabled(_ value: Int) {
        conn.sendMessage("SETD^a.\(bus - 1).afs.enabled^\(value)")
    }
}
