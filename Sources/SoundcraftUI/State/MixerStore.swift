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

    /// Facade object cache
    let objectStore = ObjectStore()

    init(connection: MixerConnection) {
        // Accumulate SETD/SETS messages into the state dictionary
        connection.allMessages
            .compactMap { MessageProtocol.parseSetMessage($0) }
            .scan([String: Any]()) { acc, parsed in
                var dict = acc
                dict[parsed.path] = transformStringValue(parsed.value)
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
