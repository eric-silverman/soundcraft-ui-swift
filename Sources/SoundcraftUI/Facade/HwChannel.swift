import Combine
import Foundation

/// Represents a hardware input on the mixer (gain, phantom power)
public final class HwChannel {
    let conn: MixerConnection
    let store: MixerStore
    private let deviceInfo: DeviceInfo
    let channel: Int
    private var cancellables = Set<AnyCancellable>()

    /// Full channel ID (changes based on model: "hw.N" for ui24, "i.N" for ui12/16)
    private var fullChannelId: String

    /// Phantom power state (0 or 1)
    public lazy var phantom: AnyPublisher<Int, Never> = {
        deviceInfo.model
            .compactMap { $0 }
            .flatMap { [store, channel] model -> AnyPublisher<Int, Never> in
                let key = model == .ui24 ? "hw" : "i"
                return store.phantom(channel: channel, key: key)
            }
            .eraseToAnyPublisher()
    }()

    /// Linear gain level (0..1)
    public lazy var gain: AnyPublisher<Double, Never> = {
        deviceInfo.model
            .compactMap { $0 }
            .flatMap { [store, channel] model -> AnyPublisher<Double, Never> in
                let key = model == .ui24 ? "hw" : "i"
                return store.gain(channel: channel, key: key)
            }
            .eraseToAnyPublisher()
    }()

    /// Gain in dB (ui24: -6..57, ui12/16: -40..50)
    public lazy var gainDB: AnyPublisher<Double, Never> = {
        deviceInfo.model
            .compactMap { $0 }
            .flatMap { [weak self] model -> AnyPublisher<Double, Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                let (lower, upper): (Double, Double) = model == .ui24 ? (-6, 57) : (-40, 50)
                return self.gain
                    .map { linearMappingValueToRange($0, lowerBound: lower, upperBound: upper) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }()

    init(conn: MixerConnection, store: MixerStore, deviceInfo: DeviceInfo, channel: Int) {
        self.conn = conn
        self.store = store
        self.deviceInfo = deviceInfo
        self.channel = channel
        self.fullChannelId = "hw.\(channel - 1)"

        // Update fullChannelId based on model
        deviceInfo.model
            .compactMap { $0 }
            .sink { [weak self] model in
                guard let self else { return }
                self.fullChannelId = model == .ui24 ? "hw.\(channel - 1)" : "i.\(channel - 1)"
            }
            .store(in: &cancellables)
    }

    static func resolve(conn: MixerConnection, store: MixerStore,
                        deviceInfo: DeviceInfo, channel: Int) -> HwChannel {
        let storeId = "hw\(channel)"
        if let cached: HwChannel = store.objectStore.get(storeId) {
            return cached
        }
        let instance = HwChannel(conn: conn, store: store, deviceInfo: deviceInfo, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Phantom

    public func setPhantom(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).phantom^\(value)")
    }

    public func phantomOn() { setPhantom(1) }
    public func phantomOff() { setPhantom(0) }

    public func togglePhantom() {
        phantom.first()
            .sink { [weak self] v in self?.setPhantom(v ^ 1) }
            .store(in: &cancellables)
    }

    // MARK: - Gain

    public func setGain(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^\(fullChannelId).gain^\(clamped)")
    }

    public func changeGain(_ offset: Double) {
        gain.first()
            .sink { [weak self] v in self?.setGain(v + offset) }
            .store(in: &cancellables)
    }

    public func setGainDB(_ dbValue: Double) {
        let model = deviceInfo.currentModel
        let (lower, upper): (Double, Double) = model == .ui24 ? (-6, 57) : (-40, 50)
        setGain(linearMappingRangeToValue(dbValue, lowerBound: lower, upperBound: upper))
    }

    public func changeGainDB(_ offsetDB: Double) {
        gainDB.first()
            .sink { [weak self] v in self?.setGainDB(v + offsetDB) }
            .store(in: &cancellables)
    }
}
