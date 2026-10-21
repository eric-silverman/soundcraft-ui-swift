import Combine
import Foundation

/// Represents one band (bell filter) of the parametric channel EQ.
/// Port of upstream `eq-band.ts`.
public final class EQBand {
    private let conn: MixerConnection
    private let store: MixerStore
    private let channelId: String
    private let linkedChannelIds: () -> [String]

    /// Band number (1–4)
    public let band: Int

    /// Center frequency of the band in Hz (20–22050)
    public lazy var frequency: AnyPublisher<Double, Never> = {
        selectParam("freq").map { faderValueToFrequency($0) }.eraseToAnyPublisher()
    }()

    /// Bandwidth as Q value (0.05–15, higher values are narrower)
    public lazy var q: AnyPublisher<Double, Never> = {
        selectParam("q").map { faderValueToQ($0) }.eraseToAnyPublisher()
    }()

    /// Linear gain (0–1, 0.5 is 0 dB)
    public lazy var gain: AnyPublisher<Double, Never> = {
        selectParam("gain")
    }()

    /// Gain in dB (-20–+20)
    public lazy var gainDB: AnyPublisher<Double, Never> = {
        gain.map { faderValueToEqGainDB($0) }.eraseToAnyPublisher()
    }()

    private var cancellables = Set<AnyCancellable>()

    init(conn: MixerConnection, store: MixerStore,
         channelId: String, linkedChannelIds: @escaping () -> [String],
         band: Int) {
        precondition(band >= 1 && band <= ChannelEQ.bandCount, "EQ band must be between 1 and \(ChannelEQ.bandCount).")
        self.conn = conn
        self.store = store
        self.channelId = channelId
        self.linkedChannelIds = linkedChannelIds
        self.band = band
    }

    /// Set the center frequency of the band (20–22050 Hz)
    public func setFrequency(_ hz: Double) {
        setParam("freq", frequencyToFaderValue(hz))
    }

    /// Set the bandwidth (Q 0.05–15, higher values are narrower)
    public func setQ(_ q: Double) {
        setParam("q", qToFaderValue(q))
    }

    /// Set the linear gain (0–1, 0.5 is 0 dB)
    public func setGain(_ value: Double) {
        setParam("gain", clamp(value, min: 0, max: 1))
    }

    /// Set the gain in dB (-20–+20)
    public func setGainDB(_ dbValue: Double) {
        setParam("gain", eqGainDBToFaderValue(dbValue))
    }

    /// Change the gain relatively by adding a dB offset
    public func changeGainDB(_ offsetDB: Double) {
        gainDB.first()
            .sink { [weak self] v in self?.setGainDB(v + offsetDB) }
            .store(in: &cancellables)
    }

    private func selectParam(_ param: String) -> AnyPublisher<Double, Never> {
        store.state
            .map { [channelId, band] dict -> Double in
                let key = "\(channelId).eq.b\(band).\(param)"
                if let d = dict[key] as? Double { return d }
                if let i = dict[key] as? Int { return Double(i) }
                return 0.0
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func setParam(_ param: String, _ value: Double) {
        for cid in linkedChannelIds() {
            conn.setd("\(cid).eq.b\(band).\(param)", value)
        }
    }
}
