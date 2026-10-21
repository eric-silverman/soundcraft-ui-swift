import Combine
import Foundation

/// High-pass or low-pass filter type
public enum EQFilterType: String {
    case hpf
    case lpf
}

/// Filter slope in dB/oct
public enum EQFilterSlope: Int, CaseIterable {
    case slope12 = 12
    case slope24 = 24
    case slope36 = 36

    init?(rawIndex: Int) {
        let slopes = EQFilterSlope.allCases
        let clamped = min(max(rawIndex, 0), slopes.count - 1)
        self = slopes[clamped]
    }

    var index: Int {
        switch self {
        case .slope12: return 0
        case .slope24: return 1
        case .slope36: return 2
        }
    }
}

/// Frequency limits for each filter type
public let eqFilterRanges: [EQFilterType: (minHz: Double, maxHz: Double)] = [
    .hpf: (minHz: eqFrequencyMin, maxHz: 1000),
    .lpf: (minHz: 1000, maxHz: eqFrequencyMax),
]

/// Represents the high-pass or low-pass filter of the channel EQ.
/// To switch a filter off, set it to its lowest (HPF, 20 Hz) or highest (LPF, 22050 Hz) frequency.
/// Port of upstream `eq-filter.ts`.
public final class EQFilter {
    private let conn: MixerConnection
    private let store: MixerStore
    private let channelId: String
    private let linkedChannelIds: () -> [String]
    private let range: (minHz: Double, maxHz: Double)

    /// Filter type (`hpf` or `lpf`)
    public let type: EQFilterType

    /// Frequency in Hz (20 for a switched-off HPF, 22050 for a switched-off LPF)
    public lazy var frequency: AnyPublisher<Double, Never> = {
        selectParam("freq").map { faderValueToFrequency($0) }.eraseToAnyPublisher()
    }()

    /// Slope in dB/oct (12, 24, or 36). Ui24R only, never emits on Ui12/Ui16.
    public lazy var slope: AnyPublisher<EQFilterSlope, Never> = {
        selectParam("slope")
            .map { EQFilterSlope(rawIndex: Int($0.rounded())) ?? .slope12 }
            .eraseToAnyPublisher()
    }()

    init(conn: MixerConnection, store: MixerStore,
         channelId: String, linkedChannelIds: @escaping () -> [String],
         type: EQFilterType) {
        self.conn = conn
        self.store = store
        self.channelId = channelId
        self.linkedChannelIds = linkedChannelIds
        self.type = type
        self.range = eqFilterRanges[type]!
    }

    /// Set the filter frequency (clamped to the valid range for this filter type)
    public func setFrequency(_ hz: Double) {
        let value = clamp(hz, min: range.minHz, max: range.maxHz)
        setParam("freq", frequencyToFaderValue(value))
    }

    /// Set the filter slope (Ui24R only)
    public func setSlope(_ slope: EQFilterSlope) {
        setParam("slope", Double(slope.index))
    }

    private func selectParam(_ param: String) -> AnyPublisher<Double, Never> {
        store.state
            .map { dict -> Double in
                let key = "\(self.channelId).eq.\(self.type.rawValue).\(param)"
                if let d = dict[key] as? Double { return d }
                if let i = dict[key] as? Int { return Double(i) }
                return 0.0
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func setParam(_ param: String, _ value: Double) {
        for cid in linkedChannelIds() {
            conn.setd("\(cid).eq.\(type.rawValue).\(param)", value)
        }
    }
}
