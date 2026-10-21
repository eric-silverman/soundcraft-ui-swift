import Combine
import Foundation

/// Channel types that have a parametric EQ: input, line, player, FX, and sub group
private let eqChannelTypes: Set<ChannelType> = [.input, .line, .player, .fx, .sub]

/// Represents the parametric EQ of a channel on the master bus:
/// four bands, a high-pass filter, and (on input channels) a low-pass filter.
/// Available for input, line, player, FX, and sub group channels.
/// Port of upstream `channel-eq.ts`.
public final class ChannelEQ {
    static let bandCount = 4

    private let conn: MixerConnection
    private let store: MixerStore
    private let channelType: ChannelType
    private let channelId: String
    private let linkedChannelIds: () -> [String]

    private var bands: [Int: EQBand] = [:]
    private var lowPass: EQFilter?
    private var cancellables = Set<AnyCancellable>()

    /// BYPASS state of the EQ (`true` if the EQ is switched off)
    public lazy var bypass: AnyPublisher<Bool, Never> = {
        store.selectBoolean(path: "\(channelId).eq.bypass")
    }()

    /// High-pass filter
    public lazy var hpf: EQFilter = {
        EQFilter(conn: conn, store: store, channelId: channelId,
                 linkedChannelIds: linkedChannelIds, type: .hpf)
    }()

    init(conn: MixerConnection, store: MixerStore,
         channelType: ChannelType, channelId: String,
         linkedChannelIds: @escaping () -> [String]) {
        precondition(eqChannelTypes.contains(channelType),
                     "EQ is only available for input, line, player, FX and sub group channels")
        self.conn = conn
        self.store = store
        self.channelType = channelType
        self.channelId = channelId
        self.linkedChannelIds = linkedChannelIds
    }

    /// Low-pass filter (Ui24R only; input channels only, other channel types crash).
    public var lpf: EQFilter {
        precondition(channelType == .input,
                     "The low-pass filter is only available for input channels")
        if lowPass == nil {
            lowPass = EQFilter(conn: conn, store: store, channelId: channelId,
                               linkedChannelIds: linkedChannelIds, type: .lpf)
        }
        return lowPass!
    }

    /// Get an EQ band (1–4)
    public func band(_ band: Int) -> EQBand {
        precondition(band >= 1 && band <= ChannelEQ.bandCount,
                     "EQ band must be between 1 and \(ChannelEQ.bandCount).")
        if let existing = bands[band] {
            return existing
        }
        let b = EQBand(conn: conn, store: store, channelId: channelId,
                       linkedChannelIds: linkedChannelIds, band: band)
        bands[band] = b
        return b
    }

    /// Set BYPASS state (`true` switches the EQ off)
    public func setBypass(_ value: Bool) {
        for cid in linkedChannelIds() {
            conn.setdBool("\(cid).eq.bypass", value)
        }
    }

    /// Enable BYPASS (switch the EQ off)
    public func enableBypass() { setBypass(true) }

    /// Disable BYPASS (switch the EQ on)
    public func disableBypass() { setBypass(false) }

    /// Toggle BYPASS state
    public func toggleBypass() {
        bypass.first()
            .sink { [weak self] v in self?.setBypass(!v) }
            .store(in: &cancellables)
    }
}
