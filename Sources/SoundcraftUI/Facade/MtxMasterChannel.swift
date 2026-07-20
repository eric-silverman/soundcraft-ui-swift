import Combine
import Foundation

/// Represents the master mix routed to a matrix bus.
/// This is a special matrix source because the master has no channel index:
/// the state path is `m.mtx.<bus>` instead of `<type>.<channel>.mtx.<bus>`.
/// Matrix buses are only available on the Ui24R.
public final class MtxMasterChannel: MtxChannel {
    private let bus: Int
    private var masterCancellables = Set<AnyCancellable>()

    public override var name: AnyPublisher<String, Never> {
        Just("MASTER").eraseToAnyPublisher()
    }

    init(conn: MixerConnection, store: MixerStore, bus: Int) {
        self.bus = bus
        super.init(conn: conn, store: store, fullChannelId: "m.mtx.\(bus - 1)")

        // the master source is not stereo-linkable itself, but it is mirrored
        // across the stereo-linked matrix output (matrix outputs live in `a` slots).
        // pan and the other sends use the same single mirror.
        store.stereoIndex(channelType: .aux, channel: bus)
            .map { [fullChannelId] mtxIndex -> [String] in
                if let linkedMtxNo = getLinkedChannelNumber(bus, stereoIndex: mtxIndex) {
                    return [fullChannelId, "m.mtx.\(linkedMtxNo - 1)"]
                }
                return [fullChannelId]
            }
            .sink { [weak self] linkedChannels in
                self?.linkedChannelIds = linkedChannels
                self?.panLinkChannelIds = linkedChannels
            }
            .store(in: &masterCancellables)
    }

    static func resolve(conn: MixerConnection, store: MixerStore, bus: Int) -> MtxMasterChannel {
        store.objectStore.getOrCreate("mtxmaster\(bus)") {
            MtxMasterChannel(conn: conn, store: store, bus: bus)
        }
    }
}
