import Combine
import Foundation

/// A channel on an AUX bus with pan and post-proc control
public class AuxChannel: SendChannel, PannableChannel {
    private var auxCancellables = Set<AnyCancellable>()
    private var auxLinkChannelIds: [String] = []

    /// Pan value (0..1) - only works for stereo-linked AUX buses
    public lazy var pan: AnyPublisher<Double, Never> = {
        store.panValue(channelType: channelType, channel: channel, busType: busType, bus: bus)
    }()

    init(conn: MixerConnection, store: MixerStore,
         channelType: ChannelType, channel: Int, bus: Int) {
        super.init(conn: conn, store: store, channelType: channelType,
                   channel: channel, busType: .aux, bus: bus)

        // Track stereo linking for both the channel and the aux bus
        Publishers.CombineLatest(
            store.stereoIndex(channelType: .aux, channel: bus),
            stereoIndex
        )
        .map { [weak self] auxIndex, channelIndex -> (all: [String], auxLink: [String]) in
            guard let self else { return ([], []) }
            let linkedAuxNo = getLinkedChannelNumber(bus, stereoIndex: auxIndex)
            let linkedChNo = getLinkedChannelNumber(channel, stereoIndex: channelIndex)

            var allChannelIds: [String] = []
            var auxLinkIds: [String] = []

            if let linkedChNo {
                allChannelIds.append(self.constructSendChannelId(channelType, linkedChNo, .aux, bus))
            }
            if let linkedAuxNo {
                let cid = self.constructSendChannelId(channelType, channel, .aux, linkedAuxNo)
                allChannelIds.append(cid)
                auxLinkIds.append(cid)
            }
            if let linkedAuxNo, let linkedChNo {
                allChannelIds.append(self.constructSendChannelId(channelType, linkedChNo, .aux, linkedAuxNo))
            }
            return (allChannelIds, auxLinkIds)
        }
        .sink { [weak self] result in
            self?.linkedChannelIds = result.all
            self?.auxLinkChannelIds = result.auxLink
        }
        .store(in: &auxCancellables)
    }

    static func resolve(conn: MixerConnection, store: MixerStore,
                        channelType: ChannelType, channel: Int, bus: Int) -> AuxChannel {
        let storeId = "aux\(bus)\(channelType.rawValue)\(channel)"
        if let cached: AuxChannel = store.objectStore.get(storeId) {
            return cached
        }
        let instance = AuxChannel(conn: conn, store: store, channelType: channelType, channel: channel, bus: bus)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Pan

    public func setPan(_ value: Double) {
        let clamped = roundToThreeDecimals(clamp(value, min: 0, max: 1))
        for cid in auxLinkChannelIds + [fullChannelId] {
            conn.sendMessage("SETD^\(cid).pan^\(clamped)")
        }
    }

    public func changePan(_ offset: Double) {
        pan.first()
            .sink { [weak self] v in self?.setPan(v + offset) }
            .store(in: &auxCancellables)
    }

    // MARK: - Post Proc

    public func setPostProc(_ value: Int) {
        for cid in linkedChannelIds + [fullChannelId] {
            conn.sendMessage("SETD^\(cid).postproc^\(value)")
        }
    }

    public func postProc() { setPostProc(1) }
    public func preProc() { setPostProc(0) }
}
