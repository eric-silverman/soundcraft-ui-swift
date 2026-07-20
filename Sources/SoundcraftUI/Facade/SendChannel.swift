import Combine
import Foundation

/// A channel on a send bus (AUX or FX) with pre/post control
public class SendChannel: Channel {
    private var sendCancellables = Set<AnyCancellable>()

    /// PRE/POST state (`false` for PRE, `true` for POST)
    public lazy var post: AnyPublisher<Bool, Never> = {
        store.postValue(channelType: channelType, channel: channel, busType: busType, bus: bus)
    }()

    override init(conn: MixerConnection, store: MixerStore,
                  channelType: ChannelType, channel: Int,
                  busType: BusType = .aux, bus: Int) {
        super.init(conn: conn, store: store, channelType: channelType,
                   channel: channel, busType: busType, bus: bus)
        self.fullChannelId = constructSendChannelId(channelType, channel, busType, bus)
        self.faderLevelCommand = "value"
    }

    // MARK: - Pre/Post

    public func setPost(_ value: Bool) {
        for cid in [fullChannelId] + linkedChannelIds {
            conn.setdBool("\(cid).post", value)
        }
    }

    public func postMode() { setPost(true) }
    public func preMode() { setPost(false) }

    public func togglePost() {
        post.first()
            .sink { [weak self] v in self?.setPost(!v) }
            .store(in: &sendCancellables)
    }
}
