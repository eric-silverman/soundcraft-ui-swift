import Combine
import Foundation

/// Base class for all sources routed to a matrix bus.
/// A matrix source can be an AUX bus or subgroup (`MtxBusChannel`) or the
/// master mix (`MtxMasterChannel`). Matrix buses are only available on the Ui24R.
///
/// The level, MUTE and PAN publishers are derived purely from the `fullChannelId`,
/// because the matrix state always lives at `<fullChannelId>.value/.mute/.pan`.
/// The concrete subclass only has to provide the `fullChannelId` and override `name`,
/// which is the one source that can't be derived from the id (the master source has no
/// channel index and therefore no name path).
public class MtxChannel: FadeableChannel, PannableChannel, PostProcessableChannel {
    let conn: MixerConnection
    let store: MixerStore
    let fullChannelId: String

    /// all linked channels (mirror on the stereo-linked matrix output and stereo-link neighbour)
    var linkedChannelIds: [String]
    /// channels that mirror the PAN value (the stereo-linked matrix output, but not a neighbour source)
    var panLinkChannelIds: [String]

    private var cancellables = Set<AnyCancellable>()
    private var transitionCancellable: AnyCancellable?

    /// Name of the matrix source (provided by the concrete subclass)
    public var name: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    /// Linear level of the matrix source (between `0` and `1`)
    public lazy var faderLevel: AnyPublisher<Double, Never> = {
        store.select(path: "\(fullChannelId).value", default: 0.0)
    }()

    /// dB level of the matrix source (between `-Infinity` and `10`)
    public lazy var faderLevelDB: AnyPublisher<Double, Never> = {
        faderLevel.map { faderValueToDB($0) }.eraseToAnyPublisher()
    }()

    /// MUTE state of the matrix source
    public lazy var mute$: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "\(fullChannelId).mute")
    }()

    /// PAN value of the matrix source (between `0` and `1`)
    public lazy var pan: AnyPublisher<Double, Never> = {
        store.select(path: "\(fullChannelId).pan", default: 0.0)
    }()

    /// PRE/POST PROC state of the matrix source (`false` for PRE PROC, `true` for POST PROC)
    public lazy var postProc$: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "\(fullChannelId).postproc")
    }()

    init(conn: MixerConnection, store: MixerStore, fullChannelId: String) {
        self.conn = conn
        self.store = store
        self.fullChannelId = fullChannelId
        self.linkedChannelIds = [fullChannelId]
        self.panLinkChannelIds = [fullChannelId]
    }

    // MARK: - Fader

    public func setFaderLevel(_ value: Double) {
        setFaderLevelRaw(clamp(value, min: 0, max: 1))
    }

    private func setFaderLevelRaw(_ value: Double) {
        for cid in linkedChannelIds {
            conn.setd("\(cid).value", value)
        }
    }

    public func setFaderLevelDB(_ dbValue: Double) {
        setFaderLevel(dBToFaderValue(dbValue))
    }

    public func changeFaderLevel(_ offset: Double) {
        faderLevel.first()
            .sink { [weak self] v in self?.setFaderLevel(roundToThreeDecimals(v + offset)) }
            .store(in: &cancellables)
    }

    public func changeFaderLevelDB(_ offsetDB: Double) {
        faderLevelDB.first()
            .sink { [weak self] v in self?.setFaderLevelDB(max(v, -100) + offsetDB) }
            .store(in: &cancellables)
    }

    public func fadeTo(_ targetValue: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        let target = clamp(targetValue, min: 0, max: 1)
        transitionCancellable?.cancel()
        transitionCancellable = faderLevel.first()
            .flatMap { sourceValue in
                generateTransition(sourceValue: sourceValue, targetValue: target,
                                   fadeTime: fadeTime, easing: easing, fps: fps)
            }
            .sink { [weak self] value in self?.setFaderLevelRaw(value) }
    }

    public func fadeToDB(_ targetValueDB: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        fadeTo(dBToFaderValue(targetValueDB), fadeTime: fadeTime, easing: easing, fps: fps)
    }

    // MARK: - Mute

    public func setMute(_ value: Bool) {
        for cid in linkedChannelIds {
            conn.setdBool("\(cid).mute", value)
        }
    }

    public func enableMute() { setMute(true) }
    public func disableMute() { setMute(false) }

    public func toggleMute() {
        mute$.first()
            .sink { [weak self] v in self?.setMute(!v) }
            .store(in: &cancellables)
    }

    // MARK: - Pan

    /// Set PAN value of the matrix source.
    /// This only works for stereo-linked matrix buses, not for mono matrix.
    public func setPan(_ value: Double) {
        let clamped = roundToThreeDecimals(clamp(value, min: 0, max: 1))
        for cid in panLinkChannelIds {
            conn.setd("\(cid).pan", clamped)
        }
    }

    public func changePan(_ offset: Double) {
        pan.first()
            .sink { [weak self] v in self?.setPan(v + offset) }
            .store(in: &cancellables)
    }

    // MARK: - Post Proc

    public func setPostProc(_ value: Bool) {
        for cid in linkedChannelIds {
            conn.setdBool("\(cid).postproc", value)
        }
    }

    public func postProc() { setPostProc(true) }
    public func preProc() { setPostProc(false) }
}
