import Foundation

/// Cache for facade objects to prevent duplicate instances.
/// This ensures the same channel/bus always returns the same object.
final class ObjectStore {
    private var store = [String: AnyObject]()

    func get<T: AnyObject>(_ id: String) -> T? {
        store[id] as? T
    }

    func set(_ id: String, _ value: AnyObject) {
        store[id] = value
    }

    /// Return the cached object for the given id, or create it (and cache it) with the factory.
    func getOrCreate<T: AnyObject>(_ id: String, _ factory: () -> T) -> T {
        if let existing: T = get(id) {
            return existing
        }
        let created = factory()
        set(id, created)
        return created
    }
}

/// Builders for the cache ids that must be shared between accessors, so that
/// `conn.aux(n)`/`mtx.switchToAux()` and `conn.mtx(n)`/`aux.switchToMatrix()`
/// resolve to the very same cached instance.

/// cache id for an `AuxBus`
func auxBusStoreId(_ bus: Int) -> String { "auxbus\(bus)" }

/// cache id for an `MtxBus`
func mtxBusStoreId(_ bus: Int) -> String { "mtxbus\(bus)" }
