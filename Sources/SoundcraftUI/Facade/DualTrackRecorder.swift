import Combine
import Foundation

/// Represents the 2-track recorder
public final class DualTrackRecorder {
    private let conn: MixerConnection
    private let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Recording state
    public lazy var recording: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "var.isRecording")
    }()

    /// Recording busy state
    public lazy var busy: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "var.recBusy")
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
                if !rec { self?.recordToggle() }
            }
            .store(in: &cancellables)
    }

    public func recordStop() {
        recording.first()
            .sink { [weak self] rec in
                if rec { self?.recordToggle() }
            }
            .store(in: &cancellables)
    }
}
