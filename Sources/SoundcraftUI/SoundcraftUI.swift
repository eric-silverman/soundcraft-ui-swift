import Combine
import Foundation

/// Top-level API for connecting to and controlling a Soundcraft UI mixer.
///
/// Usage:
/// ```swift
/// let mixer = SoundcraftUI(ip: "192.168.1.123")
/// mixer.connect()
///
/// // Control the master fader
/// mixer.master.setFaderLevel(0.75)
///
/// // Subscribe to VU data
/// mixer.vuProcessor.master()
///     .sink { vu in print(vu.vuPostL) }
///
/// // Control a channel on the master bus
/// mixer.master.input(1).setFaderLevel(0.5)
/// mixer.master.input(1).mute()
///
/// // Control a channel on an AUX bus
/// mixer.aux(1).input(3).setFaderLevel(0.7)
/// ```
public final class SoundcraftUI {
    /// The mixer connection
    public let conn: MixerConnection

    /// The state store
    public let store: MixerStore

    /// Device hardware/software info
    public let deviceInfo: DeviceInfo

    /// Connection status
    public var status: AnyPublisher<ConnectionStatus, Never> {
        conn.status
    }

    /// VU meter processor
    public let vuProcessor: VUProcessor

    /// RTA (Real-Time Analyser) processor
    public let rtaProcessor: RTAProcessor

    /// Master bus
    public let master: MasterBus

    /// Media player
    public let player: Player

    /// 2-track recorder
    public let recorderDualTrack: DualTrackRecorder

    /// Multitrack recorder (UI24R only)
    public let recorderMultiTrack: MultiTrackRecorder

    /// Solo and headphone volume buses
    public let volume: (solo: VolumeBus, headphone: (Int) -> VolumeBus)

    /// Show/snapshot/cue controller
    public let shows: ShowController

    /// Automix controller
    public let automix: AutomixController

    /// Global settings (solo, clock, AFS, hardware routing)
    public let settings: GlobalSettings

    /// Channel sync controller
    public private(set) lazy var channelSync: ChannelSync = ChannelSync(sui: self)

    /// Create a new SoundcraftUI instance.
    /// - Parameters:
    ///   - ip: IP address of the mixer (e.g. "192.168.1.123")
    ///   - transport: Optional custom WebSocket transport (for testing)
    public init(ip: String, transport: WebSocketTransport? = nil) {
        self.conn = MixerConnection(ip: ip, transport: transport)
        self.store = MixerStore(connection: conn)
        self.deviceInfo = DeviceInfo(store: store)
        self.vuProcessor = VUProcessor(inbound: conn.inbound)
        self.rtaProcessor = RTAProcessor(inbound: conn.inbound, conn: conn)
        self.master = MasterBus(conn: conn, store: store)
        self.player = Player(conn: conn, store: store)
        self.recorderDualTrack = DualTrackRecorder(conn: conn, store: store)
        self.recorderMultiTrack = MultiTrackRecorder(conn: conn, store: store)

        let c = conn
        let s = store
        self.volume = (
            solo: VolumeBus(conn: c, store: s, busName: .solovol),
            headphone: { id in VolumeBus(conn: c, store: s, busName: .hpvol, busId: id) }
        )
        self.shows = ShowController(conn: conn, store: store)
        self.automix = AutomixController(conn: conn, store: store)
        self.settings = GlobalSettings(conn: conn, store: store)
    }

    // MARK: - Bus Factories

    /// Get an AUX bus
    public func aux(_ bus: Int) -> AuxBus {
        AuxBus(conn: conn, store: store, bus: bus)
    }

    /// Get an FX bus
    public func fx(_ bus: Int) -> FxBus {
        FxBus(conn: conn, store: store, bus: bus)
    }

    /// Get a mute group
    public func muteGroup(_ id: MuteGroupID) -> MuteGroup {
        MuteGroup(conn: conn, store: store, id: id)
    }

    /// Unmute all mute groups
    public func clearMuteGroups() {
        conn.sendMessage("SETD^mgmask^0")
    }

    /// Get a hardware channel
    public func hw(_ channel: Int) -> HwChannel {
        HwChannel.resolve(conn: conn, store: store, deviceInfo: deviceInfo, channel: channel)
    }

    // MARK: - Connection

    /// Connect to the mixer
    public func connect() {
        conn.connect()
    }

    /// Disconnect from the mixer
    public func disconnect() {
        conn.disconnect()
    }

    /// Reconnect: disconnect, wait 1s, then connect again
    public func reconnect() {
        conn.reconnect()
    }
}
