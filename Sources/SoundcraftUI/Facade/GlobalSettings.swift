import Combine
import Foundation

/// Global mixer settings and hardware routing.
///
/// Provides access to system-wide settings, AFS, hardware output routing,
/// and input source routing.
public final class GlobalSettings {
    private let conn: MixerConnection
    private let store: MixerStore

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
    }

    // MARK: - AFS (Automatic Feedback Suppression)

    /// Global AFS enabled (0 or 1)
    public lazy var afsEnabled: AnyPublisher<Int, Never> = {
        store.select(path: "afs.enabled", default: 0)
    }()

    public func setAfsEnabled(_ value: Int) {
        conn.sendMessage("SETD^afs.enabled^\(value)")
    }

    // MARK: - Solo Settings

    /// Solo type (0 = PFL, 1 = AFL, 2 = SIP)
    public lazy var soloType: AnyPublisher<Int, Never> = {
        store.select(path: "settings.solotype", default: 0)
    }()

    /// Solo mode
    public lazy var soloMode: AnyPublisher<Int, Never> = {
        store.select(path: "settings.soloMode", default: 0)
    }()

    /// Multiple solo enabled (0 or 1)
    public lazy var multipleSolo: AnyPublisher<Int, Never> = {
        store.select(path: "settings.multiplesolo", default: 0)
    }()

    public func setSoloType(_ value: Int) {
        conn.sendMessage("SETD^settings.solotype^\(value)")
    }

    public func setSoloMode(_ value: Int) {
        conn.sendMessage("SETD^settings.soloMode^\(value)")
    }

    public func setMultipleSolo(_ value: Int) {
        conn.sendMessage("SETD^settings.multiplesolo^\(value)")
    }

    // MARK: - Clock

    /// Clock source
    public lazy var clock: AnyPublisher<Int, Never> = {
        store.select(path: "settings.clock", default: 0)
    }()

    public func setClock(_ value: Int) {
        conn.sendMessage("SETD^settings.clock^\(value)")
    }

    // MARK: - Hardware Output Routing

    /// USB/DAW output source for a channel (0-based index)
    public func usbDawSrc(_ channel: Int) -> AnyPublisher<Int, Never> {
        store.select(path: "usbdaw.\(channel - 1).src", default: 0)
    }

    /// Headphone output source
    public func hwOutHpSrc(_ channel: Int) -> AnyPublisher<Int, Never> {
        store.select(path: "hwouthp.\(channel - 1).src", default: 0)
    }

    /// Main output source
    public func hwOutMainSrc(_ channel: Int) -> AnyPublisher<Int, Never> {
        store.select(path: "hwoutm.\(channel - 1).src", default: 0)
    }

    /// AUX output source
    public func hwOutAuxSrc(_ channel: Int) -> AnyPublisher<Int, Never> {
        store.select(path: "hwoutaux.\(channel - 1).src", default: 0)
    }

    public func setUsbDawSrc(_ channel: Int, value: Int) {
        conn.sendMessage("SETD^usbdaw.\(channel - 1).src^\(value)")
    }

    public func setHwOutHpSrc(_ channel: Int, value: Int) {
        conn.sendMessage("SETD^hwouthp.\(channel - 1).src^\(value)")
    }

    public func setHwOutMainSrc(_ channel: Int, value: Int) {
        conn.sendMessage("SETD^hwoutm.\(channel - 1).src^\(value)")
    }

    public func setHwOutAuxSrc(_ channel: Int, value: Int) {
        conn.sendMessage("SETD^hwoutaux.\(channel - 1).src^\(value)")
    }

    // MARK: - Footswitch / F-Buttons

    /// Footswitch (pedal) assignment
    public lazy var pedal: AnyPublisher<Int, Never> = {
        store.select(path: "settings.pedal", default: 0)
    }()

    /// F1 button assignment
    public lazy var f1: AnyPublisher<Int, Never> = {
        store.select(path: "settings.f1", default: 0)
    }()

    /// F2 button assignment
    public lazy var f2: AnyPublisher<Int, Never> = {
        store.select(path: "settings.f2", default: 0)
    }()

    public func setPedal(_ value: Int) {
        conn.sendMessage("SETD^settings.pedal^\(value)")
    }

    public func setF1(_ value: Int) {
        conn.sendMessage("SETD^settings.f1^\(value)")
    }

    public func setF2(_ value: Int) {
        conn.sendMessage("SETD^settings.f2^\(value)")
    }

    // MARK: - Multitrack Recording Format

    /// Multitrack recording format (0=WAV 24-bit, 1=WAV 16-bit, 2=FLAC 24-bit, 3=FLAC 16-bit)
    public lazy var mtkFormat: AnyPublisher<Int, Never> = {
        store.select(path: "settings.mtkformat", default: 0)
    }()

    public func setMtkFormat(_ value: Int) {
        conn.sendMessage("SETD^settings.mtkformat^\(value)")
    }
}
