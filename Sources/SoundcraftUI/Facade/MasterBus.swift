import Combine
import Foundation

/// Represents the master bus with fader, pan, dim, delay, and channel factories
public final class MasterBus: FadeableChannel, PannableChannel {
    let conn: MixerConnection
    let store: MixerStore
    private var cancellables = Set<AnyCancellable>()

    /// Name is always "MASTER"
    public let name: AnyPublisher<String, Never> = Just("MASTER").eraseToAnyPublisher()

    /// Linear master fader level (0..1)
    public lazy var faderLevel: AnyPublisher<Double, Never> = {
        store.masterValue
    }()

    /// dB master fader level
    public lazy var faderLevelDB: AnyPublisher<Double, Never> = {
        faderLevel.map { faderValueToDB($0) }.eraseToAnyPublisher()
    }()

    /// Master pan (0..1)
    public lazy var pan: AnyPublisher<Double, Never> = {
        store.masterPan
    }()

    /// Master dim state
    public lazy var dim$: AnyPublisher<Bool, Never> = {
        store.masterDim
    }()

    /// Left delay in ms
    public lazy var delayL: AnyPublisher<Double, Never> = {
        store.masterDelay(side: "L")
    }()

    /// Right delay in ms
    public lazy var delayR: AnyPublisher<Double, Never> = {
        store.masterDelay(side: "R")
    }()

    init(conn: MixerConnection, store: MixerStore) {
        self.conn = conn
        self.store = store
    }

    // MARK: - Channel Factories

    public func input(_ channel: Int) -> DelayableMasterChannel {
        DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .input, channel: channel)
    }

    public func line(_ channel: Int) -> DelayableMasterChannel {
        DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .line, channel: channel)
    }

    public func player(_ channel: Int) -> MasterChannel {
        MasterChannel.resolve(conn: conn, store: store, channelType: .player, channel: channel)
    }

    public func aux(_ channel: Int) -> DelayableMasterChannel {
        DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .aux, channel: channel)
    }

    /// Get a matrix output channel on the master bus.
    /// A matrix occupies the same slot as the AUX it replaced, so this is an alias
    /// for `aux(channel)` that reads more clearly when controlling a matrix output.
    /// Matrix buses are only available on the Ui24R.
    public func mtx(_ channel: Int) -> DelayableMasterChannel {
        aux(channel)
    }

    public func fx(_ channel: Int) -> MasterChannel {
        MasterChannel.resolve(conn: conn, store: store, channelType: .fx, channel: channel)
    }

    public func sub(_ channel: Int) -> MasterChannel {
        MasterChannel.resolve(conn: conn, store: store, channelType: .sub, channel: channel)
    }

    public func vca(_ channel: Int) -> MasterChannel {
        MasterChannel.resolve(conn: conn, store: store, channelType: .vca, channel: channel)
    }

    // MARK: - Fader

    public func setFaderLevel(_ value: Double) {
        let clamped = clamp(value, min: 0, max: 1)
        conn.sendMessage("SETD^m.mix^\(clamped)")
    }

    public func setFaderLevelDB(_ dbValue: Double) {
        setFaderLevel(dBToFaderValue(dbValue))
    }

    public func changeFaderLevel(_ offset: Double) {
        faderLevel.first()
            .sink { [weak self] v in self?.setFaderLevel(v + offset) }
            .store(in: &cancellables)
    }

    public func changeFaderLevelDB(_ offsetDB: Double) {
        faderLevelDB.first()
            .sink { [weak self] v in self?.setFaderLevelDB(max(v, -100) + offsetDB) }
            .store(in: &cancellables)
    }

    public func fadeTo(_ targetValue: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        let target = clamp(targetValue, min: 0, max: 1)
        faderLevel.first()
            .flatMap { sourceValue in
                generateTransition(sourceValue: sourceValue, targetValue: target,
                                   fadeTime: fadeTime, easing: easing, fps: fps)
            }
            .sink { [weak self] value in
                self?.conn.sendMessage("SETD^m.mix^\(value)")
            }
            .store(in: &cancellables)
    }

    public func fadeToDB(_ targetValueDB: Double, fadeTime: Double, easing: Easing = .linear, fps: Int = 25) {
        fadeTo(dBToFaderValue(targetValueDB), fadeTime: fadeTime, easing: easing, fps: fps)
    }

    // MARK: - Pan

    public func setPan(_ value: Double) {
        let clamped = roundToThreeDecimals(clamp(value, min: 0, max: 1))
        conn.sendMessage("SETD^m.pan^\(clamped)")
    }

    public func changePan(_ offset: Double) {
        pan.first()
            .sink { [weak self] v in self?.setPan(v + offset) }
            .store(in: &cancellables)
    }

    // MARK: - Dim

    public func setDim(_ value: Bool) {
        conn.setdBool("m.dim", value)
    }

    public func enableDim() { setDim(true) }
    public func disableDim() { setDim(false) }

    public func toggleDim() {
        dim$.first()
            .sink { [weak self] v in self?.setDim(!v) }
            .store(in: &cancellables)
    }

    // MARK: - Delay

    public func setDelayL(_ ms: Double) { setDelay(ms, side: "L") }
    public func setDelayR(_ ms: Double) { setDelay(ms, side: "R") }

    public func changeDelayL(_ offsetMs: Double) {
        delayL.first()
            .sink { [weak self] v in self?.setDelayL(v + offsetMs) }
            .store(in: &cancellables)
    }

    public func changeDelayR(_ offsetMs: Double) {
        delayR.first()
            .sink { [weak self] v in self?.setDelayR(v + offsetMs) }
            .store(in: &cancellables)
    }

    private func setDelay(_ ms: Double, side: String) {
        let value = sanitizeDelayValue(ms, maximumMs: 500)
        conn.sendMessage("SETD^m.delay\(side)^\(value)")
    }
}
