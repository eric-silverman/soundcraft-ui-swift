import Combine
import Foundation

/// Represents a mute group (1-6, ALL, or FX)
public final class MuteGroup {
    private let conn: MixerConnection
    private let store: MixerStore
    public let id: MuteGroupID
    private let groupIndex: Int
    private var cancellables = Set<AnyCancellable>()

    private lazy var mgMask: AnyPublisher<Int, Never> = {
        store.select(path: "mgmask", default: 0)
    }()

    /// Mute state of the group
    public lazy var state: AnyPublisher<Bool, Never> = {
        mgMask.map { [groupIndex] value in
            Bitmask.getValueOfBit(value, at: groupIndex)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }()

    init(conn: MixerConnection, store: MixerStore, id: MuteGroupID) {
        self.conn = conn
        self.store = store
        self.id = id
        self.groupIndex = id.bitIndex
    }

    static func resolve(conn: MixerConnection, store: MixerStore, id: MuteGroupID) -> MuteGroup {
        let storeId = "mutegroup\(id)"
        if let cached: MuteGroup = store.objectStore.get(storeId) {
            return cached
        }
        let instance = MuteGroup(conn: conn, store: store, id: id)
        store.objectStore.set(storeId, instance)
        return instance
    }

    public func mute() {
        mgMask.first()
            .sink { [weak self] mask in
                guard let self else { return }
                self.setMgMask(Bitmask.setBit(mask, at: self.groupIndex))
            }
            .store(in: &cancellables)
    }

    public func unmute() {
        mgMask.first()
            .sink { [weak self] mask in
                guard let self else { return }
                self.setMgMask(Bitmask.clearBit(mask, at: self.groupIndex))
            }
            .store(in: &cancellables)
    }

    public func toggle() {
        mgMask.first()
            .sink { [weak self] mask in
                guard let self else { return }
                self.setMgMask(Bitmask.toggleBit(mask, at: self.groupIndex))
            }
            .store(in: &cancellables)
    }

    private func setMgMask(_ mask: Int) {
        conn.setd("mgmask", mask)
    }
}
