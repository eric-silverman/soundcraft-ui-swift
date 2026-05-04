import Combine
import Foundation

/// Cross-client channel selection synchronization
public final class ChannelSync {
    private let defaultSyncId = "SYNC_ID"
    private weak var sui: SoundcraftUI?

    init(sui: SoundcraftUI) {
        self.sui = sui
    }

    /// Get the index of the currently selected channel
    public func getSelectedChannelIndex(syncId: String? = nil) -> AnyPublisher<Int, Never> {
        guard let sui else { return Empty().eraseToAnyPublisher() }
        let finalSyncId = syncId ?? defaultSyncId
        return sui.store.syncState
            .compactMap { $0[finalSyncId] }
            .eraseToAnyPublisher()
    }

    /// Select a channel by index
    public func selectChannelIndex(_ index: Int, syncId: String? = nil) {
        sui?.conn.sendMessage("BMSG^SYNC^\(syncId ?? defaultSyncId)^\(index)")
    }

    /// Get the channel object for the currently selected index.
    /// Emits nil when the master bus is selected (index -1) or the model is not yet known.
    public func getSelectedChannel(syncId: String? = nil) -> AnyPublisher<MasterChannel?, Never> {
        return getSelectedChannelIndex(syncId: syncId)
            .map { [weak self] index -> MasterChannel? in
                guard let sui = self?.sui, index >= 0 else { return nil }
                guard let model = sui.deviceInfo.currentModel else { return nil }
                guard let entry = ChannelSyncMapping.indexToChannel(model: model, index: index) else { return nil }
                switch entry.type {
                case .input:  return sui.master.input(entry.num)
                case .line:   return sui.master.line(entry.num)
                case .player: return sui.master.player(entry.num)
                case .fx:     return sui.master.fx(entry.num)
                case .sub:    return sui.master.sub(entry.num)
                case .aux:    return sui.master.aux(entry.num)
                case .vca:    return sui.master.vca(entry.num)
                }
            }
            .eraseToAnyPublisher()
    }

    /// Select a channel by type and number
    public func selectChannel(type: ChannelType, num: Int, syncId: String? = nil) {
        guard let model = sui?.deviceInfo.currentModel else { return }
        if let index = ChannelSyncMapping.channelToIndex(model: model, type: type, num: num) {
            selectChannelIndex(index, syncId: syncId)
        }
    }

    /// Select the master channel
    public func selectMaster(syncId: String? = nil) {
        selectChannelIndex(-1, syncId: syncId)
    }
}

/// Mapping between channel index and (type, number) per mixer model
enum ChannelSyncMapping {
    typealias ChannelEntry = (type: ChannelType, num: Int)

    static let ui24Mapping: [Int: ChannelEntry] = {
        var m = [Int: ChannelEntry]()
        for i in 0..<24 { m[i] = (.input, i + 1) }
        m[24] = (.line, 1); m[25] = (.line, 2)
        m[26] = (.player, 1); m[27] = (.player, 2)
        for i in 0..<4 { m[28 + i] = (.fx, i + 1) }
        for i in 0..<6 { m[32 + i] = (.sub, i + 1) }
        for i in 0..<10 { m[38 + i] = (.aux, i + 1) }
        for i in 0..<6 { m[48 + i] = (.vca, i + 1) }
        return m
    }()

    static let ui16Mapping: [Int: ChannelEntry] = {
        var m = [Int: ChannelEntry]()
        for i in 0..<12 { m[i] = (.input, i + 1) }
        m[12] = (.line, 1); m[13] = (.line, 2)
        m[14] = (.player, 1); m[15] = (.player, 2)
        for i in 0..<4 { m[16 + i] = (.fx, i + 1) }
        for i in 0..<4 { m[20 + i] = (.sub, i + 1) }
        for i in 0..<6 { m[24 + i] = (.aux, i + 1) }
        return m
    }()

    static let ui12Mapping: [Int: ChannelEntry] = {
        var m = [Int: ChannelEntry]()
        for i in 0..<8 { m[i] = (.input, i + 1) }
        m[8] = (.line, 1); m[9] = (.line, 2)
        m[10] = (.player, 1); m[11] = (.player, 2)
        for i in 0..<4 { m[12 + i] = (.fx, i + 1) }
        for i in 0..<4 { m[16 + i] = (.sub, i + 1) }
        for i in 0..<4 { m[20 + i] = (.aux, i + 1) }
        return m
    }()

    static func mappingForModel(_ model: MixerModel) -> [Int: ChannelEntry] {
        switch model {
        case .ui24: return ui24Mapping
        case .ui16: return ui16Mapping
        case .ui12: return ui12Mapping
        }
    }

    static func channelToIndex(model: MixerModel, type: ChannelType, num: Int) -> Int? {
        let mapping = mappingForModel(model)
        for (index, entry) in mapping {
            if entry.type == type && entry.num == num {
                return index
            }
        }
        return nil
    }

    static func indexToChannel(model: MixerModel, index: Int) -> ChannelEntry? {
        mappingForModel(model)[index]
    }
}
