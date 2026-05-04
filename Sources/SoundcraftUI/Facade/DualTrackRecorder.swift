import Combine
import Foundation

/// Represents the 2-track recorder
public final class DualTrackRecorder {
    private let conn: MixerConnection
    private let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Recording state (0 or 1)
    public lazy var recording: AnyPublisher<Int, Never> = {
        store.select(path: "var.isRecording", default: 0)
    }()

    /// Recording busy state (0 or 1)
    public lazy var busy: AnyPublisher<Int, Never> = {
        store.select(path: "var.recBusy", default: 0)
    }()

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
    }

    public func recordToggle() {
        conn.sendMessage("RECTOGGLE")
    }

    public func recordStart() {
        recording.first()
            .sink { [weak self] rec in
                if rec == 0 { self?.recordToggle() }
            }
            .store(in: &cancellables)
    }

    public func recordStop() {
        recording.first()
            .sink { [weak self] rec in
                if rec != 0 { self?.recordToggle() }
            }
            .store(in: &cancellables)
    }
}
