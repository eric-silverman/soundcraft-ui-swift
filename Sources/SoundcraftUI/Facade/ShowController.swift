import Combine
import Foundation

/// Controller for shows, snapshots, and cues
public final class ShowController {
    private let conn: MixerConnection
    private let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Currently loaded show
    public lazy var currentShow: AnyPublisher<String, Never> = {
        store.select(path: "var.currentShow", default: "")
    }()

    /// Currently loaded snapshot
    public lazy var currentSnapshot: AnyPublisher<String, Never> = {
        store.select(path: "var.currentSnapshot", default: "")
    }()

    /// Currently loaded cue
    public lazy var currentCue: AnyPublisher<String, Never> = {
        store.select(path: "var.currentCue", default: "")
    }()

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
    }

    public func loadShow(_ show: String) {
        conn.sendMessage("LOADSHOW^\(show)")
    }

    public func loadSnapshot(show: String, snapshot: String) {
        conn.sendMessage("LOADSNAPSHOT^\(show)^\(snapshot)")
    }

    public func loadCue(show: String, cue: String) {
        conn.sendMessage("LOADCUE^\(show)^\(cue)")
    }

    public func saveSnapshot(show: String, snapshot: String) {
        conn.sendMessage("SAVESNAPSHOT^\(show)^\(snapshot)")
    }

    public func saveCue(show: String, cue: String) {
        conn.sendMessage("SAVECUE^\(show)^\(cue)")
    }

    public func updateCurrentSnapshot() {
        Publishers.CombineLatest(currentShow, currentSnapshot)
            .first()
            .filter { !$0.0.isEmpty && !$0.1.isEmpty }
            .sink { [weak self] show, snapshot in
                self?.saveSnapshot(show: show, snapshot: snapshot)
            }
            .store(in: &cancellables)
    }

    public func updateCurrentCue() {
        Publishers.CombineLatest(currentShow, currentCue)
            .first()
            .filter { !$0.0.isEmpty && !$0.1.isEmpty }
            .sink { [weak self] show, cue in
                self?.saveCue(show: show, cue: cue)
            }
            .store(in: &cancellables)
    }

    /// Export current show state as JSON to the mixer's USB drive (V3)
    public func exportJSON() {
        conn.sendMessage("SETD^shows.exportJSON^1")
    }

    /// Import show state from a JSON file on the mixer's USB drive (V3)
    public func importJSON(path: String) {
        conn.sendMessage("SETD^shows.importJSON^\(path)")
    }
}
