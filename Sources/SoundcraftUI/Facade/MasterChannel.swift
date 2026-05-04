import Combine
import Foundation

/// A channel on the master bus with solo, pan, automix, and multitrack
public class MasterChannel: Channel, PannableChannel {
    private var masterCancellables = Set<AnyCancellable>()

    // MARK: - Publishers

    /// Solo state (0 or 1)
    public lazy var solo$: AnyPublisher<Int, Never> = {
        store.soloValue(channelType: channelType, channel: channel)
    }()

    /// Pan value (0..1)
    public lazy var pan: AnyPublisher<Double, Never> = {
        store.panValue(channelType: channelType, channel: channel, busType: busType, bus: bus)
    }()

    /// Assigned automix group (a, b, or nil for none)
    public lazy var automixGroup: AnyPublisher<AutomixGroupID?, Never> = {
        store.select(path: "\(fullChannelId).amixgroup", default: -1)
            .map { (groupId: Int) -> AutomixGroupID? in
                switch groupId {
                case 0: return .a
                case 1: return .b
                default: return nil
                }
            }
            .eraseToAnyPublisher()
    }()

    /// Automix weight (linear 0..1)
    public lazy var automixWeight: AnyPublisher<Double, Never> = {
        store.select(path: "\(fullChannelId).amix", default: 0.5)
    }()

    /// Automix weight in dB (-12..+12)
    public lazy var automixWeightDB: AnyPublisher<Double, Never> = {
        automixWeight.map { linearMappingValueToRange($0, lowerBound: -12, upperBound: 12) }.eraseToAnyPublisher()
    }()

    /// Multitrack recording selection (0 or 1)
    public lazy var multiTrackSelected: AnyPublisher<Int, Never> = {
        store.select(path: "\(fullChannelId).mtkrec", default: 0)
    }()

    // MARK: - Init

    override init(conn: MixerConnection, store: MixerStore,
                  channelType: ChannelType, channel: Int,
                  busType: BusType = .master, bus: Int = 0) {
        super.init(conn: conn, store: store, channelType: channelType,
                   channel: channel, busType: busType, bus: bus)
        self.fullChannelId = "\(channelType.rawValue).\(channel - 1)"
        self.faderLevelCommand = "mix"

        // Track stereo linking
        stereoIndex
            .map { [channelType, channel] index -> [String] in
                if let linked = getLinkedChannelNumber(channel, stereoIndex: index) {
                    return ["\(channelType.rawValue).\(linked - 1)"]
                }
                return []
            }
            .sink { [weak self] ids in
                self?.linkedChannelIds = ids
            }
            .store(in: &masterCancellables)
    }

    static func resolve(conn: MixerConnection, store: MixerStore,
                        channelType: ChannelType, channel: Int) -> MasterChannel {
        let storeId = "master0\(channelType.rawValue)\(channel)"
        if let cached: MasterChannel = store.objectStore.get(storeId) {
            return cached
        }
        let instance = MasterChannel(conn: conn, store: store,
                                     channelType: channelType, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Pan

    public func setPan(_ value: Double) {
        let clamped = roundToThreeDecimals(clamp(value, min: 0, max: 1))
        conn.sendMessage("SETD^\(fullChannelId).pan^\(clamped)")
    }

    public func changePan(_ offset: Double) {
        pan.first()
            .sink { [weak self] v in self?.setPan(v + offset) }
            .store(in: &masterCancellables)
    }

    // MARK: - Solo

    public func setSolo(_ value: Int) {
        for cid in linkedChannelIds + [fullChannelId] {
            conn.sendMessage("SETD^\(cid).solo^\(value)")
        }
    }

    public func enableSolo() { setSolo(1) }
    public func disableSolo() { setSolo(0) }

    public func toggleSolo() {
        solo$.first()
            .sink { [weak self] v in self?.setSolo(v ^ 1) }
            .store(in: &masterCancellables)
    }

    // MARK: - Multitrack

    public func multiTrackSelect() { setMultiTrackSelection(1) }
    public func multiTrackUnselect() { setMultiTrackSelection(0) }

    public func multiTrackToggle() {
        multiTrackSelected.first()
            .sink { [weak self] v in self?.setMultiTrackSelection(v ^ 1) }
            .store(in: &masterCancellables)
    }

    private func setMultiTrackSelection(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).mtkrec^\(value)")
    }

    // MARK: - Automix

    public func automixAssignGroup(_ group: AutomixGroupID?) {
        let groupValue: Int
        switch group {
        case .a: groupValue = 0
        case .b: groupValue = 1
        case nil: groupValue = -1
        }
        for cid in linkedChannelIds + [fullChannelId] {
            conn.sendMessage("SETD^\(cid).amixgroup^\(groupValue)")
        }
    }

    public func automixRemove() { automixAssignGroup(nil) }

    public func automixSetWeight(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        for cid in linkedChannelIds + [fullChannelId] {
            conn.sendMessage("SETD^\(cid).amix^\(clamped)")
        }
    }

    public func automixSetWeightDB(_ dbValue: Double) {
        automixSetWeight(linearMappingRangeToValue(dbValue, lowerBound: -12, upperBound: 12))
    }

    public func automixChangeWeightDB(_ offsetDB: Double) {
        automixWeightDB.first()
            .sink { [weak self] v in self?.automixSetWeightDB(v + offsetDB) }
            .store(in: &masterCancellables)
    }
}
