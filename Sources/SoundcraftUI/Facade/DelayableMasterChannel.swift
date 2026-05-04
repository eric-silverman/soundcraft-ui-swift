import Combine
import Foundation

/// A channel on the master bus that supports delay (input, line, aux)
public class DelayableMasterChannel: MasterChannel {
    private var delayCancellables = Set<AnyCancellable>()

    /// Maximum delay in ms (250 for input/line, 500 for aux)
    private let delayMaxValueMs: Double

    /// Delay value in milliseconds
    public lazy var delay: AnyPublisher<Double, Never> = {
        store.delayValue(channelType: channelType, channel: channel)
    }()

    override init(conn: MixerConnection, store: MixerStore,
                  channelType: ChannelType, channel: Int,
                  busType: BusType = .master, bus: Int = 0) {
        self.delayMaxValueMs = channelType == .aux ? 500 : 250
        super.init(conn: conn, store: store, channelType: channelType,
                   channel: channel, busType: busType, bus: bus)
    }

    static func resolveDelayable(conn: MixerConnection, store: MixerStore,
                                 channelType: ChannelType, channel: Int) -> DelayableMasterChannel {
        let storeId = "master0\(channelType.rawValue)\(channel)"
        if let cached: DelayableMasterChannel = store.objectStore.get(storeId) {
            return cached
        }
        let instance = DelayableMasterChannel(conn: conn, store: store,
                                              channelType: channelType, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    /// Set delay in milliseconds
    public func setDelay(_ ms: Double) {
        let value = sanitizeDelayValue(ms, maximumMs: delayMaxValueMs)
        conn.sendMessage("SETD^\(fullChannelId).delay^\(value)")
    }

    /// Change delay relatively
    public func changeDelay(_ offsetMs: Double) {
        delay.first()
            .sink { [weak self] value in self?.setDelay(value + offsetMs) }
            .store(in: &delayCancellables)
    }
}
