import Combine
import Foundation

/// Represents a volume bus (solo or headphone volume)
public final class VolumeBus: FadeableChannel {
    private let conn: MixerConnection
    private let store: MixerStore
    private let busName: VolumeBusType
    private let busId: Int?
    private var cancellables = Set<AnyCancellable>()

    /// Bus name
    public let name: AnyPublisher<String, Never>

    /// Linear fader level (0..1)
    public lazy var faderLevel: AnyPublisher<Double, Never> = {
        store.volumeBusValue(busName: busName.rawValue, busId: busId.map { $0 - 1 })
    }()

    /// dB fader level
    public lazy var faderLevelDB: AnyPublisher<Double, Never> = {
        faderLevel.map { faderValueToDB($0) }.eraseToAnyPublisher()
    }()

    init(conn: MixerConnection, store: MixerStore, busName: VolumeBusType, busId: Int? = nil) {
        self.conn = conn
        self.store = store
        self.busName = busName
        self.busId = busId
        self.name = Just(getDefaultVolumeBusName(type: busName, id: busId ?? -1)).eraseToAnyPublisher()
    }

    static func resolve(conn: MixerConnection, store: MixerStore,
                        busName: VolumeBusType, busId: Int? = nil) -> VolumeBus {
        let storeId = "volume-\(busName.rawValue)\(busId ?? -1)"
        if let cached: VolumeBus = store.objectStore.get(storeId) {
            return cached
        }
        let instance = VolumeBus(conn: conn, store: store, busName: busName, busId: busId)
        store.objectStore.set(storeId, instance)
        return instance
    }

    public func setFaderLevel(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        let bus = busId.map { "\(busName.rawValue).\($0 - 1)" } ?? busName.rawValue
        conn.setd("settings.\(bus)", clamped)
    }

    public func setFaderLevelDB(_ dbValue: Double) {
        setFaderLevel(dBToFaderValue(dbValue))
    }

    public func changeFaderLevel(_ offset: Double) {
        faderLevel.first()
            .sink { [weak self] v in self?.setFaderLevel(v + offset) }
            .store(in: &cancellables)
    }

    public func changeFaderLevelDB(_ offsetDB: Double) {
        faderLevelDB.first()
            .sink { [weak self] v in self?.setFaderLevelDB(max(v, -100) + offsetDB) }
            .store(in: &cancellables)
    }

    public func fadeTo(_ targetValue: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        let target = clamp(targetValue, min: 0, max: 1)
        faderLevel.first()
            .flatMap { sourceValue in
                generateTransition(sourceValue: sourceValue, targetValue: target,
                                   fadeTime: fadeTime, easing: easing, fps: fps)
            }
            .sink { [weak self] value in
                self?.setFaderLevel(value)
            }
            .store(in: &cancellables)
    }

    public func fadeToDB(_ targetValueDB: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        fadeTo(dBToFaderValue(targetValueDB), fadeTime: fadeTime, easing: easing, fps: fps)
    }
}
