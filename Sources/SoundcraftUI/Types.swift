import Foundation

// MARK: - Channel Types

/// Type identifier for mixer channels
public enum ChannelType: String, Sendable {
    case input = "i"
    case line = "l"
    case player = "p"
    case fx = "f"
    case sub = "s"
    case aux = "a"
    case vca = "v"
}

/// Type of volume bus
public enum VolumeBusType: String, Sendable {
    case solovol
    case hpvol
}

/// Type of bus routing
public enum BusType: String, Sendable {
    case master
    case aux
    case fx
    case mtx
}

// MARK: - Connection

/// Connection status of the mixer WebSocket
public enum ConnectionStatus: String, Sendable {
    case opening = "OPENING"
    case open = "OPEN"
    case close = "CLOSE"
    case closing = "CLOSING"
    case error = "ERROR"
    case reconnecting = "RECONNECTING"
}

// MARK: - Player

/// State of the media player
public enum PlayerState: Int, Sendable {
    case stopped = 0
    case playing = 2
    case paused = 3
}

/// State of the multitrack recorder
public enum MtkState: Int, Sendable {
    case stopped = 0
    case paused = 1
    case playing = 2
}

// MARK: - Resource Lists

/// A map of playlist name to its list of track names.
public typealias PlaylistsWithTracks = [String: [String]]

/// The snapshots and cues that belong to a show.
public struct ShowDetails: Equatable, Sendable {
    public var snapshots: [String]
    public var cues: [String]

    public init(snapshots: [String] = [], cues: [String] = []) {
        self.snapshots = snapshots
        self.cues = cues
    }
}

/// A map of show name to its snapshots and cues.
public typealias ShowsWithDetails = [String: ShowDetails]

// MARK: - Effects

/// Type of effect on an FX bus
public enum FxType: Int, Sendable {
    case none = -1
    case reverb = 0
    case delay = 1
    case chorus = 2
    case room = 3

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .reverb: return "Reverb"
        case .delay: return "Delay"
        case .chorus: return "Chorus"
        case .room: return "Room"
        }
    }
}

// MARK: - Mixer Model

/// Hardware model of the Soundcraft UI mixer
public enum MixerModel: String, Sendable {
    case ui12
    case ui16
    case ui24
}

// MARK: - Easing

/// Easing functions for fade transitions
public enum Easing: Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut

    public func apply(_ t: Double) -> Double {
        switch self {
        case .linear: return t
        case .easeIn: return t * t
        case .easeOut: return t * (2 - t)
        case .easeInOut: return t * t * (3 - 2 * t)
        }
    }
}

// MARK: - Mute Group

/// Identifier for a mute group
public enum MuteGroupID: Sendable, Hashable {
    case group(Int) // 1-6
    case all
    case fx

    /// Bit index in the mute group bitmask
    var bitIndex: Int {
        switch self {
        case .all: return 23
        case .fx: return 22
        case .group(let id): return id - 1
        }
    }
}

// MARK: - Automix

/// Automix group identifier
public enum AutomixGroupID: String, Sendable {
    case a
    case b
}
