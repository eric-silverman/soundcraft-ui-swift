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
}
