import Combine
import Foundation

/// Represents the multi-track recorder (UI24R only)
public final class MultiTrackRecorder {
    private let conn: MixerConnection
    private let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Current MTK state
    public lazy var state: AnyPublisher<MtkState, Never> = {
        store.select(path: "var.mtk.currentState", default: 0)
            .map { MtkState(rawValue: $0) ?? .stopped }
            .eraseToAnyPublisher()
    }()

    /// Current session name
    public lazy var session: AnyPublisher<String, Never> = {
        store.state
            .compactMap { dict -> String? in
                if let intVal = dict["var.mtk.session"] as? Int {
                    return String(format: "%04d", intVal)
                }
                return dict["var.mtk.session"] as? String
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    /// Session length in seconds
    public lazy var length: AnyPublisher<Double, Never> = { store.mtkLength }()

    /// Elapsed time in seconds
    public lazy var elapsedTime: AnyPublisher<Int, Never> = { store.mtkElapsedTime }()

    /// Remaining time in seconds
    public lazy var remainingTime: AnyPublisher<Int, Never> = { store.mtkRemainingTime }()

    /// Recording state
    public lazy var recording: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "var.mtk.rec.currentState")
    }()

    /// Recording busy state
    public lazy var busy: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "var.mtk.rec.busy")
    }()

    /// Soundcheck state
    public lazy var soundcheck: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "var.mtk.soundcheck")
    }()

    /// Recording time in seconds (tracks elapsed recording time).
    /// Set to `0` when not actually recording, otherwise it emits strange values.
    public lazy var recordingTime: AnyPublisher<Int, Never> = {
        store.select(path: "var.mtk.rec.time", default: 0)
            .combineLatest(recording)
            .map { value, recording in recording ? value : 0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
    }

    public func play() { conn.sendMessage("MTK_PLAY") }
    public func pause() { conn.sendMessage("MTK_PAUSE") }
    public func stop() { conn.sendMessage("MTK_STOP") }

    public func recordToggle() { conn.sendMessage("MTK_REC_TOGGLE") }

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

    public func setSoundcheck(_ value: Bool) {
        conn.setdBool("var.mtk.soundcheck", value)
    }

    public func activateSoundcheck() { setSoundcheck(true) }
    public func deactivateSoundcheck() { setSoundcheck(false) }

    public func toggleSoundcheck() {
        soundcheck.first()
            .sink { [weak self] v in self?.setSoundcheck(!v) }
            .store(in: &cancellables)
    }

    /// Rename the current MTK session (V3)
    public func renameSession(_ name: String) {
        conn.sendMessage("SETD^mtk.renameSession^\(name)")
    }
}
