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

    /// Shuffle state
    public lazy var shuffle: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "settings.shuffle")
    }()

    /// All available playlists with their tracks (playlist name -> track names).
    /// Fetched on connect; refresh manually with `refreshPlaylists()`.
    public lazy var playlistsWithTracks: AnyPublisher<PlaylistsWithTracks, Never> = {
        store.resourceListState
            .map { state -> PlaylistsWithTracks in
                let names = state[ResourceListConfig.PlaylistsKey] ?? []
                var result: PlaylistsWithTracks = [:]
                for name in names {
                    result[name] = state["\(ResourceListConfig.PlaylistTracksKey)^\(name)"] ?? []
                }
                return result
            }
            .eraseToAnyPublisher()
    }()

    /// Names of all available playlists.
    /// Fetched on connect; refresh manually with `refreshPlaylists()`.
    public lazy var playlists: AnyPublisher<[String], Never> = {
        store.resourceListState
            .map { $0[ResourceListConfig.PlaylistsKey] ?? [] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store

        // playlists are sent per-client on request, so (re-)fetch them on every connection open
        conn.status
            .filter { $0 == .open }
            .sink { [weak self] _ in self?.refreshPlaylists() }
            .store(in: &cancellables)
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

    public func setShuffle(_ value: Bool) {
        conn.setdBool("settings.shuffle", value)
    }

    public func toggleShuffle() {
        shuffle.first()
            .sink { [weak self] v in self?.setShuffle(!v) }
            .store(in: &cancellables)
    }

    public func setPlayMode(_ value: Int) {
        conn.setd("settings.playMode", value)
    }

    public func setManual() { setPlayMode(0) }
    public func setAuto() { setPlayMode(3) }

    /// Request the list of playlists and their tracks from the mixer.
    /// Results are exposed through `playlists` and `playlistsWithTracks`.
    /// This is called automatically on every connection open.
    public func refreshPlaylists() {
        requestResourceList(conn, requestCmd: "MEDIA_GET_PLISTS", replyCmd: "PLISTS")
            .sink { [weak self] playlists in
                for name in playlists {
                    self?.conn.sendMessage("MEDIA_GET_PLIST_TRACKS^\(name)")
                }
            }
            .store(in: &cancellables)
    }
}
