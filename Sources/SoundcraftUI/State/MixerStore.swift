import Combine
import Foundation

/// The central state store for the mixer.
/// Accumulates SETD/SETS messages into a flat [String: Any] dictionary.
public final class MixerStore {
    private var cancellables = Set<AnyCancellable>()

    /// The full mixer state as a flat dictionary. Updates on every SETD/SETS message.
    public let state = CurrentValueSubject<[String: Any], Never>([:])

    /// Channel sync state: [syncId: channelIndex]
    public let syncState = CurrentValueSubject<[String: Int], Never>([:])

    /// Per-client resource listings (playlists, shows, snapshots, cues).
    /// These are not part of the global SETD/SETS state; they are sent only on request.
    /// Each list is stored under its "address" (the command plus its key), see `ResourceListConfig`.
    public let resourceListState = CurrentValueSubject<[String: [String]], Never>([:])

    /// Facade object cache
    let objectStore = ObjectStore()

    init(connection: MixerConnection) {
        // Accumulate SETD/SETS messages into the state dictionary.
        // SETD messages always carry numeric values, SETS messages always carry strings —
        // so a SETS value that looks numeric (e.g. a session name "0001") is kept as a string.
        connection.allMessages
            .compactMap { MessageProtocol.parseSetMessage($0) }
            .scan([String: Any]()) { acc, parsed in
                var dict = acc
                dict[parsed.path] = parsed.type == "SETD" ? transformStringValue(parsed.value) : parsed.value
                return dict
            }
            .sink { [weak self] newState in
                self?.state.send(newState)
            }
            .store(in: &cancellables)

        // Accumulate BMSG^SYNC messages
        connection.allMessages
            .filter { $0.hasPrefix("BMSG^SYNC^") }
            .compactMap { message -> (String, Int)? in
                let parts = message.dropFirst(10).components(separatedBy: "^")
                guard parts.count >= 2, let index = Int(parts[1]) else { return nil }
                return (parts[0], index)
            }
            .scan([String: Int]()) { acc, pair in
                var dict = acc
                dict[pair.0] = pair.1
                return dict
            }
            .sink { [weak self] newState in
                self?.syncState.send(newState)
            }
            .store(in: &cancellables)

        // Accumulate per-client resource list messages (playlists, shows, snapshots, cues).
        // Scans `inbound` only, so our own outbound requests (whose command can equal the
        // reply command, e.g. `SHOWLIST`) do not pollute the state. The command prefix is
        // checked before splitting, so high-frequency messages (e.g. VU frames) are not
        // split into arrays just to be discarded.
        connection.inbound
            .compactMap { message -> (address: String, entries: [String])? in
                let command = message.firstIndex(of: "^").map { String(message[..<$0]) } ?? message
                guard let config = ResourceListConfig.entries[command] else { return nil }
                let parts = message.components(separatedBy: "^")
                let addressLength = config.keyed ? 2 : 1
                let address = parts.prefix(addressLength).joined(separator: "^")
                // empty lists are sent with a trailing separator (e.g. `CUELIST^Default^`),
                // which yields a single empty-string entry — drop empties
                let entries = parts.dropFirst(addressLength).filter { !$0.isEmpty }
                return (address, Array(entries))
            }
            .scan([String: [String]]()) { acc, item in
                var dict = acc
                dict[item.address] = item.entries
                return dict
            }
            .sink { [weak self] newState in
                self?.resourceListState.send(newState)
            }
            .store(in: &cancellables)
    }

    /// Select a value from state by path, with deduplication
    public func select<T: Equatable>(path: String, default defaultValue: T) -> AnyPublisher<T, Never> {
        state
            .map { dict -> T in
                (dict[path] as? T) ?? defaultValue
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Select a raw value from state by path (optional, no default)
    public func select<T: Equatable>(path: String) -> AnyPublisher<T?, Never> {
        state
            .map { dict -> T? in
                dict[path] as? T
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Select a value from state and apply a transform
    public func select<T: Equatable>(path: String, default defaultValue: T, transform: @escaping (T) -> T) -> AnyPublisher<T, Never> {
        state
            .map { dict -> T in
                let raw = (dict[path] as? T) ?? defaultValue
                return transform(raw)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
