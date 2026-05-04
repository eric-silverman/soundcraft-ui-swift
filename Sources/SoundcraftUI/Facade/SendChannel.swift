import Combine
import Foundation

/// A channel on a send bus (AUX or FX) with pre/post control
public class SendChannel: Channel {
    private var sendCancellables = Set<AnyCancellable>()

    /// PRE/POST state (1 = POST, 0 = PRE)
    public lazy var post: AnyPublisher<Int, Never> = {
        store.postValue(channelType: channelType, channel: channel, busType: busType, bus: bus)
    }()

    override init(conn: MixerConnection, store: MixerStore,
                  channelType: ChannelType, channel: Int,
                  busType: BusType = .aux, bus: Int) {
        super.init(conn: conn, store: store, channelType: channelType,
                   channel: channel, busType: busType, bus: bus)
        self.fullChannelId = "\(channelType.rawValue).\(channel - 1).\(busType.rawValue).\(bus - 1)"
        self.faderLevelCommand = "value"
    }

    func constructSendChannelId(_ channelType: ChannelType, _ channel: Int,
                                _ busType: BusType, _ bus: Int) -> String {
        "\(channelType.rawValue).\(channel - 1).\(busType.rawValue).\(bus - 1)"
    }

    // MARK: - Pre/Post

    public func setPost(_ value: Int) {
        for cid in linkedChannelIds + [fullChannelId] {
            conn.sendMessage("SETD^\(cid).post^\(value)")
        }
    }

    public func postMode() { setPost(1) }
    public func preMode() { setPost(0) }

    public func togglePost() {
        post.first()
            .sink { [weak self] v in self?.setPost(v ^ 1) }
            .store(in: &sendCancellables)
    }
}
