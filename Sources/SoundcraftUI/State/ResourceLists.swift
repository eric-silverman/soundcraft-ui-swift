import Combine
import Foundation

/// Per-client resource listings (playlists, shows, snapshots, cues) are not part of the
/// global SETD/SETS mixer state. They are sent only on request, via dedicated list messages.
///
/// This config maps each reply command to whether it is keyed by a parent:
/// - flat list `CMD^entry^entry…`      (`keyed == false`, e.g. `PLISTS`, `SHOWLIST`)
/// - keyed list `CMD^key^entry^entry…` (`keyed == true`, e.g. `PLIST_TRACKS`, `SNAPSHOTLIST`,
///   `CUELIST`), where `key` is the parent (playlist/show)
///
/// The store stores each message under its "address" (the command plus its key, i.e. everything
/// before the entries): 1 leading part for flat lists, 2 for keyed lists.
public enum ResourceListConfig {
    public struct Config {
        public let keyed: Bool
    }

    public static let entries: [String: Config] = [
        PlaylistsKey: Config(keyed: false),
        PlaylistTracksKey: Config(keyed: true),
        ShowsKey: Config(keyed: false),
        SnapshotsKey: Config(keyed: true),
        CuesKey: Config(keyed: true),
    ]

    /// Key addresses and prefixes in the resource list state
    public static let PlaylistsKey = "PLISTS"
    public static let PlaylistTracksKey = "PLIST_TRACKS"
    public static let ShowsKey = "SHOWLIST"
    public static let SnapshotsKey = "SNAPSHOTLIST"
    public static let CuesKey = "CUELIST"
}

/// Request a per-client resource list and emit the entries of the matching reply once.
/// Subscribes to the reply BEFORE sending the request, so the reply is never missed.
/// - Parameters:
///   - conn: connection
///   - requestCmd: full message to send, e.g. `MEDIA_GET_PLISTS` or `SHOWLIST`
///   - replyCmd: reply command to wait for, e.g. `PLISTS` or `SHOWLIST`
func requestResourceList(_ conn: MixerConnection, requestCmd: String, replyCmd: String) -> AnyPublisher<[String], Never> {
    conn.inbound
        .filter { $0.hasPrefix(replyCmd + "^") }
        .first()
        // drop the trailing empty entry of an empty list (e.g. `SHOWLIST^`)
        .map { $0.components(separatedBy: "^").dropFirst().filter { !$0.isEmpty } }
        .handleEvents(receiveSubscription: { _ in conn.sendMessage(requestCmd) })
        .eraseToAnyPublisher()
}
