import Combine
import Foundation

/// A single automix group (A or B)
public final class AutomixGroup {
    private let conn: MixerConnection
    private let store: MixerStore
    private let group: AutomixGroupID
    private var cancellables = Set<AnyCancellable>()

    /// Active state
    public lazy var state: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "automix.\(group.rawValue).on")
    }()

    init(conn: MixerConnection, store: MixerStore, group: AutomixGroupID) {
        self.conn = conn
        self.store = store
        self.group = group
    }

    public func enable() { setState(true) }
    public func disable() { setState(false) }

    public func toggle() {
        state.first()
            .sink { [weak self] v in self?.setState(!v) }
            .store(in: &cancellables)
    }

    private func setState(_ value: Bool) {
        conn.setdBool("automix.\(group.rawValue).on", value)
    }
}

/// Controller for automix settings
public final class AutomixController {
    private let conn: MixerConnection
    private let store: MixerStore

    /// Global response time (linear 0..1)
    public lazy var responseTime: AnyPublisher<Double, Never> = {
        store.select(path: "automix.time", default: 0.0)
    }()

    /// Global response time in milliseconds (20..4000)
    public lazy var responseTimeMs: AnyPublisher<Int, Never> = {
        responseTime.map { faderValueToTimeMs($0) }.eraseToAnyPublisher()
    }()

    /// Automix groups A and B
    public let groups: (a: AutomixGroup, b: AutomixGroup)

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
        self.groups = (
            a: AutomixGroup(conn: conn, store: store, group: .a),
            b: AutomixGroup(conn: conn, store: store, group: .b)
        )
    }

    public func setResponseTime(_ value: Double) {
        conn.setd("automix.time", value)
    }

    public func setResponseTimeMs(_ timeMs: Double) {
        setResponseTime(timeMsToFaderValue(timeMs))
    }
}
