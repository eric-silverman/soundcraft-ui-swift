import Combine
import Foundation

/// A channel on an FX bus
public class FxChannel: SendChannel {
    private var fxCancellables = Set<AnyCancellable>()

    init(conn: MixerConnection, store: MixerStore,
         channelType: ChannelType, channel: Int, bus: Int) {
        super.init(conn: conn, store: store, channelType: channelType,
                   channel: channel, busType: .fx, bus: bus)

        // Track stereo linking
        stereoIndex
            .map { index -> [String] in
                guard let linked = getLinkedChannelNumber(channel, stereoIndex: index) else {
                    return []
                }
                return [constructSendChannelId(channelType, linked, .fx, bus)]
            }
            .sink { [weak self] ids in
                self?.linkedChannelIds = ids
            }
            .store(in: &fxCancellables)
    }

    static func resolve(conn: MixerConnection, store: MixerStore,
                        channelType: ChannelType, channel: Int, bus: Int) -> FxChannel {
        let storeId = "fx\(bus)\(channelType.rawValue)\(channel)"
        if let cached: FxChannel = store.objectStore.get(storeId) {
            return cached
        }
        let instance = FxChannel(conn: conn, store: store, channelType: channelType, channel: channel, bus: bus)
        store.objectStore.set(storeId, instance)
        return instance
    }
}
