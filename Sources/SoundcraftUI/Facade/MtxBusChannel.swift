import Combine
import Foundation

/// Represents an AUX bus (`a`) or subgroup (`s`) source routed to a matrix bus.
/// For the master source use `MtxMasterChannel`.
/// Matrix buses are only available on the Ui24R.
public final class MtxBusChannel: MtxChannel {
    private let channelType: ChannelType
    private let channel: Int
    private let bus: Int
    private var busChannelCancellables = Set<AnyCancellable>()

    // Channel name is only available directly in the channel, e.g. `a.1.name`.
    private lazy var _name: AnyPublisher<String, Never> = {
        let path = joinStatePath(channelType.rawValue, channel - 1, "name")
        return store.select(path: path, default: "")
            .map { [channelType, channel] name in
                name.isEmpty ? getDefaultChannelName(type: channelType, channel: channel) : name
            }
            .eraseToAnyPublisher()
    }()

    public override var name: AnyPublisher<String, Never> { _name }

    init(conn: MixerConnection, store: MixerStore, channelType: ChannelType, channel: Int, bus: Int) {
        self.channelType = channelType
        self.channel = channel
        self.bus = bus
        super.init(conn: conn, store: store, fullChannelId: constructMtxChannelId(channelType, channel, bus))

        // create list of linked channels. Just like for AUX buses this can be up to three channels:
        // - the direct neighbour source channel (only AUX sources can be stereo-linked)
        // - this channel on the stereo-linked matrix output (matrix outputs live in `a` slots)
        // - the neighbour source channel on the linked matrix output
        Publishers.CombineLatest(
            store.stereoIndex(channelType: .aux, channel: bus),
            store.stereoIndex(channelType: channelType, channel: channel)
        )
        .map { mtxIndex, channelIndex -> (all: [String], mtxLink: [String]) in
            let linkedMtxNo = getLinkedChannelNumber(bus, stereoIndex: mtxIndex)
            let linkedChNo = getLinkedChannelNumber(channel, stereoIndex: channelIndex)

            var allChannelIds = [constructMtxChannelId(channelType, channel, bus)]
            var mtxLinkIds = [constructMtxChannelId(channelType, channel, bus)]

            // add linked source channel on this matrix
            if let linkedChNo {
                allChannelIds.append(constructMtxChannelId(channelType, linkedChNo, bus))
            }
            // add this channel on linked matrix output
            if let linkedMtxNo {
                let cid = constructMtxChannelId(channelType, channel, linkedMtxNo)
                allChannelIds.append(cid)
                mtxLinkIds.append(cid)
            }
            // add linked source channel on linked matrix output
            if let linkedMtxNo, let linkedChNo {
                allChannelIds.append(constructMtxChannelId(channelType, linkedChNo, linkedMtxNo))
            }
            return (allChannelIds, mtxLinkIds)
        }
        .sink { [weak self] result in
            self?.linkedChannelIds = result.all
            self?.panLinkChannelIds = result.mtxLink
        }
        .store(in: &busChannelCancellables)
    }

    static func resolve(conn: MixerConnection, store: MixerStore,
                        channelType: ChannelType, channel: Int, bus: Int) -> MtxBusChannel {
        store.objectStore.getOrCreate("mtx\(bus)\(channelType.rawValue)\(channel)") {
            MtxBusChannel(conn: conn, store: store, channelType: channelType, channel: channel, bus: bus)
        }
    }

    /// Set name of the matrix source channel (the underlying AUX bus or subgroup)
    public func setName(_ name: String) {
        let sanitized = sanitizeName(name)
        let path = joinStatePath(channelType.rawValue, channel - 1, "name")
        conn.sets(path, sanitized)
    }
}
