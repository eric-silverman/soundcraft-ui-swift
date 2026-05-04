import Combine
import Foundation

/// Device model and capabilities information
public final class DeviceInfo {
    private let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Hardware model (ui12, ui16, ui24)
    public lazy var model: AnyPublisher<MixerModel?, Never> = {
        store.state
            .map { dict -> MixerModel? in
                guard let raw = dict["model"] as? String else { return nil }
                return MixerModel(rawValue: raw)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    /// Device capabilities based on model
    public lazy var capabilities: AnyPublisher<DeviceCapabilities?, Never> = {
        model.map { $0.map { DeviceCapabilities.forModel($0) } }.eraseToAnyPublisher()
    }()

    /// Firmware version
    public lazy var firmware: AnyPublisher<String?, Never> = {
        store.select(path: "firmware") as AnyPublisher<String?, Never>
    }()

    /// Current model (synchronous, may be nil before connection)
    public private(set) var currentModel: MixerModel?

    init(store: MixerStore) {
        self.store = store
        model.sink { [weak self] m in self?.currentModel = m }.store(in: &cancellables)
    }
}
