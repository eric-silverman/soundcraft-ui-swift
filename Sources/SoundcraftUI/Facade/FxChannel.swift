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
            .map { [weak self] index -> [String] in
                guard let self,
                      let linked = getLinkedChannelNumber(channel, stereoIndex: index) else {
                    return []
                }
                return [self.constructSendChannelId(channelType, linked, .fx, bus)]
            }
            .sink { [weak self] ids in
                self?.linkedChannelIds = ids
            }
            .store(in: &fxCancellables)
    }
}
