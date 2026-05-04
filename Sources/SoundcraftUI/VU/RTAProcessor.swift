import Combine
import Foundation

/// A single RTA spectrum frame from the mixer.
/// `bins` contains ~120 magnitude values in [0, 1.06], log-spaced from ~20 Hz to ~22.35 kHz.
public struct RTAFrame: Sendable, Equatable {
    public let bins: [Float]

    public static let empty = RTAFrame(bins: [])

    public init(bins: [Float]) {
        self.bins = bins
    }
}

/// Processes `RTA^<base64>` messages from the mixer into structured spectrum frames.
///
/// The mixer streams RTA data for one subscribed channel at a time.
/// Use `subscribeChannel(path:)` / `unsubscribe()` to control which channel is active.
///
/// Protocol details:
/// - Message prefix: `RTA^` followed by base64-encoded binary payload
/// - Each byte is an unsigned magnitude value scaled by 1/240 → Float in [0, ~1.06]
/// - ~120 bins spanning ~20 Hz to ~22.35 kHz on a log scale
/// - Subscribe: `SETS^var.rta^<channelPath>` (e.g. `i.0`, `a.2`, `s.1`)
/// - Unsubscribe: `SETS^var.rta^` (empty value)
public final class RTAProcessor {

    /// Publisher for decoded RTA frames (fires at mixer's RTA refresh rate, typically 20 Hz)
    public let rtaFrame: AnyPublisher<RTAFrame, Never>

    private let conn: MixerConnection

    init(inbound: AnyPublisher<String, Never>, conn: MixerConnection) {
        self.conn = conn
        rtaFrame = inbound
            .filter { $0.hasPrefix("RTA^") }
            .compactMap { message -> RTAFrame? in
                let base64String = String(message.dropFirst(4))
                guard let data = Data(base64Encoded: base64String), !data.isEmpty else { return nil }
                let bins = [UInt8](data).map { Float($0) / 240.0 }
                return RTAFrame(bins: bins)
            }
            .share()
            .eraseToAnyPublisher()
    }

    /// Start receiving RTA data for the given channel path (e.g. `"i.0"`, `"a.2"`, `"s.1"`).
    /// Only one channel at a time is supported by the mixer.
    public func subscribeChannel(path: String) {
        conn.sendMessage("SETS^var.rta^\(path)")
    }

    /// Stop receiving RTA data.
    public func unsubscribe() {
        conn.sendMessage("SETS^var.rta^")
    }

    // MARK: - Parsing (internal, for testing)

    static func parse(_ data: Data) -> RTAFrame? {
        guard !data.isEmpty else { return nil }
        let bins = [UInt8](data).map { Float($0) / 240.0 }
        return RTAFrame(bins: bins)
    }
}
