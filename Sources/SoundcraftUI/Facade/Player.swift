import Combine
import Foundation

/// Represents the media player
public final class Player {
    private let conn: MixerConnection
    private let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Current player state
    public lazy var state: AnyPublisher<PlayerState, Never> = {
        store.select(path: "var.currentState", default: 0)
            .map { PlayerState(rawValue: $0) ?? .stopped }
            .eraseToAnyPublisher()
    }()

    /// Current playlist name
    public lazy var playlist: AnyPublisher<String, Never> = {
        store.select(path: "var.currentPlaylist", default: "")
    }()

    /// Current track name
    public lazy var track: AnyPublisher<String, Never> = {
        store.select(path: "var.currentTrack", default: "")
    }()

    /// Current track length in seconds
    public lazy var length: AnyPublisher<Double, Never> = {
        store.playerLength
    }()

    /// Elapsed time in seconds
    public lazy var elapsedTime: AnyPublisher<Int, Never> = {
        store.playerElapsedTime
    }()

    /// Remaining time in seconds
    public lazy var remainingTime: AnyPublisher<Int, Never> = {
        store.playerRemainingTime
    }()

    /// Shuffle setting (0 or 1)
    public lazy var shuffle: AnyPublisher<Int, Never> = {
        store.select(path: "settings.shuffle", default: 0)
    }()

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
    }

    public func play() { conn.sendMessage("MEDIA_PLAY") }
    public func pause() { conn.sendMessage("MEDIA_PAUSE") }
    public func stop() { conn.sendMessage("MEDIA_STOP") }
    public func next() { conn.sendMessage("MEDIA_NEXT") }
    public func prev() { conn.sendMessage("MEDIA_PREV") }

    public func loadPlaylist(_ playlist: String) {
        conn.sendMessage("MEDIA_SWITCH_PLIST^\(playlist)")
    }

    public func loadTrack(playlist: String, track: String) {
        conn.sendMessage("MEDIA_SWITCH_TRACK^\(playlist)^\(track)")
    }

    public func setShuffle(_ value: Int) {
        conn.sendMessage("SETD^settings.shuffle^\(value)")
    }

    public func toggleShuffle() {
        shuffle.first()
            .sink { [weak self] v in self?.setShuffle(v ^ 1) }
            .store(in: &cancellables)
    }

    public func setPlayMode(_ value: Int) {
        conn.sendMessage("SETD^settings.playMode^\(value)")
    }

    public func setManual() { setPlayMode(0) }
    public func setAuto() { setPlayMode(3) }
}
