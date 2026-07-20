import Combine
import Foundation

/// Represents a single channel with a fader on any bus
public class Channel: FadeableChannel {
    let conn: MixerConnection
    let store: MixerStore
    let channelType: ChannelType
    let channel: Int
    let busType: BusType
    let bus: Int

    /// Full dot-notation channel ID (e.g. "i.0")
    var fullChannelId: String
    /// The property name for fader level (mix for master, value for sends)
    var faderLevelCommand: String = "mix"
    /// IDs of stereo-linked channels to mirror commands to
    var linkedChannelIds: [String] = []

    private var cancellables = Set<AnyCancellable>()
    private var transitionCancellable: AnyCancellable?

    // MARK: - Publishers

    /// Linear fader level (0..1)
    public lazy var faderLevel: AnyPublisher<Double, Never> = {
        store.faderValue(channelType: channelType, channel: channel, busType: busType, bus: bus)
    }()

    /// dB fader level
    public lazy var faderLevelDB: AnyPublisher<Double, Never> = {
        faderLevel.map { faderValueToDB($0) }.eraseToAnyPublisher()
    }()

    /// Mute state
    public lazy var mute$: AnyPublisher<Bool, Never> = {
        store.muteValue(channelType: channelType, channel: channel, busType: busType, bus: bus)
    }()

    /// Channel name
    public lazy var name: AnyPublisher<String, Never> = {
        // Channel name is only available directly in the channel, e.g. `i.1.name`.
        // `i.1.aux.2.name` will not work!
        let path = joinStatePath(channelType.rawValue, channel - 1, "name")
        let rawName = store.select(path: path, default: "")

        guard channelType == .aux else {
            return rawName
                .map { [channelType, channel] name in
                    name.isEmpty ? getDefaultChannelName(type: channelType, channel: channel) : name
                }
                .eraseToAnyPublisher()
        }

        // an AUX slot can be switched into a matrix bus (Ui24R), which uses a different default name
        return Publishers.CombineLatest(rawName, store.matrix(bus: channel))
            .map { [channelType, channel] name, isMatrix -> String in
                if !name.isEmpty { return name }
                return isMatrix
                    ? getDefaultMatrixName(channel: channel)
                    : getDefaultChannelName(type: channelType, channel: channel)
            }
            .eraseToAnyPublisher()
    }()

    /// Stereo index (-1 = not linked, 0 = left, 1 = right)
    lazy var stereoIndex: AnyPublisher<Int, Never> = {
        store.stereoIndex(channelType: channelType, channel: channel)
    }()

    // MARK: - Init

    init(conn: MixerConnection, store: MixerStore,
         channelType: ChannelType, channel: Int,
         busType: BusType = .master, bus: Int = 0) {
        self.conn = conn
        self.store = store
        self.channelType = channelType
        self.channel = channel
        self.busType = busType
        self.bus = bus
        self.fullChannelId = "\(channelType.rawValue).\(channel - 1)"
    }

    /// Factory method with object store caching
    static func resolve(conn: MixerConnection, store: MixerStore,
                        channelType: ChannelType, channel: Int,
                        busType: BusType = .master, bus: Int = 0) -> Channel {
        let storeId = "\(busType.rawValue)\(bus)\(channelType.rawValue)\(channel)"
        if let cached: Channel = store.objectStore.get(storeId) {
            return cached
        }
        let instance = Channel(conn: conn, store: store, channelType: channelType,
                               channel: channel, busType: busType, bus: bus)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Fader

    public func setFaderLevel(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        setFaderLevelRaw(clamped)
    }

    func setFaderLevelRaw(_ value: Double) {
        for cid in linkedChannelIds + [fullChannelId] {
            conn.setd("\(cid).\(faderLevelCommand)", value)
        }
    }

    public func setFaderLevelDB(_ dbValue: Double) {
        setFaderLevel(dBToFaderValue(dbValue))
    }

    public func changeFaderLevel(_ offset: Double) {
        faderLevel
            .first()
            .sink { [weak self] v in self?.setFaderLevel(v + offset) }
            .store(in: &cancellables)
    }

    public func changeFaderLevelDB(_ offsetDB: Double) {
        faderLevelDB
            .first()
            .sink { [weak self] v in
                self?.setFaderLevelDB(max(v, -100) + offsetDB)
            }
            .store(in: &cancellables)
    }

    public func fadeTo(_ targetValue: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        let target = clamp(targetValue, min: 0, max: 1)
        transitionCancellable?.cancel()

        faderLevel
            .first()
            .flatMap { sourceValue in
                generateTransition(sourceValue: sourceValue, targetValue: target,
                                   fadeTime: fadeTime, easing: easing, fps: fps)
            }
            .sink { [weak self] value in
                self?.setFaderLevelRaw(value)
            }
            .store(in: &cancellables)
    }

    public func fadeToDB(_ targetValueDB: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        fadeTo(dBToFaderValue(targetValueDB), fadeTime: fadeTime, easing: easing, fps: fps)
    }

    // MARK: - Mute

    public func setMute(_ value: Bool) {
        for cid in linkedChannelIds + [fullChannelId] {
            conn.setdBool("\(cid).mute", value)
        }
    }

    public func enableMute() { setMute(true) }
    public func disableMute() { setMute(false) }

    public func toggleMute() {
        mute$
            .first()
            .sink { [weak self] value in
                self?.setMute(!value)
            }
            .store(in: &cancellables)
    }

    // MARK: - Name

    public func setName(_ name: String) {
        let sanitized = sanitizeName(name)
        let path = joinStatePath(channelType.rawValue, channel - 1, "name")
        conn.sets(path, sanitized)
    }
}
