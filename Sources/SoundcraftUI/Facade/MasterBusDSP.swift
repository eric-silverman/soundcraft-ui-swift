import Combine
import Foundation

/// DSP processor accessors for the master bus.
extension MasterBus {

    // MARK: - Graphic EQ

    /// 31-band graphic EQ for the master bus (stereo L/R)
    public func graphicEQ() -> GraphicEQ {
        let storeId = "geq_master"
        if let cached: GraphicEQ = store.objectStore.get(storeId) {
            return cached
        }
        let instance = GraphicEQ(conn: conn, store: store, isMaster: true)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Dynamics (Compressor)

    /// Master bus compressor/dynamics (stereo L/R with linked option)
    public func dynamics() -> Dynamics {
        let storeId = "dyn_master"
        if let cached: Dynamics = store.objectStore.get(storeId) {
            return cached
        }
        let instance = Dynamics(conn: conn, store: store, isMaster: true)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Master L/R Phase Invert

    /// Left channel phase invert (0 or 1)
    public var invertL: AnyPublisher<Int, Never> {
        store.select(path: "m.l.invert", default: 0)
    }

    /// Right channel phase invert (0 or 1)
    public var invertR: AnyPublisher<Int, Never> {
        store.select(path: "m.r.invert", default: 0)
    }

    public func setInvertL(_ value: Int) {
        conn.sendMessage("SETD^m.l.invert^\(value)")
    }

    public func setInvertR(_ value: Int) {
        conn.sendMessage("SETD^m.r.invert^\(value)")
    }

    // MARK: - AFS (Automatic Feedback Suppression)

    /// Master AFS enabled (0 or 1)
    public var afsEnabled: AnyPublisher<Int, Never> {
        store.select(path: "m.afs.enabled", default: 0)
    }

    public func setAfsEnabled(_ value: Int) {
        conn.sendMessage("SETD^m.afs.enabled^\(value)")
    }
}
