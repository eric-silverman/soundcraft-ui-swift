import Combine
import Foundation

/// Processes VU2 messages from the mixer into structured VU data
public final class VUProcessor {
    private let normalizeFactor: Double = 0.004167508166392142

    /// Publisher for complete VU data frames
    public let vuData: AnyPublisher<VUData, Never>

    init(inbound: AnyPublisher<String, Never>) {
        vuData = inbound
            .filter { $0.hasPrefix("VU2^") }
            .compactMap { message -> VUData? in
                let base64String = String(message.dropFirst(4))
                guard let data = Data(base64Encoded: base64String) else { return nil }
                return VUProcessor.parse(data)
            }
            .share()
            .eraseToAnyPublisher()
    }

    /// Get VU data for a specific input channel (1-indexed)
    public func input(_ channel: Int) -> AnyPublisher<InputChannelVU, Never> {
        vuData.compactMap { $0.input[safe: channel - 1] }.eraseToAnyPublisher()
    }

    /// Get VU data for a specific line channel (1-indexed)
    public func line(_ channel: Int) -> AnyPublisher<InputChannelVU, Never> {
        vuData.compactMap { $0.line[safe: channel - 1] }.eraseToAnyPublisher()
    }

    /// Get VU data for a specific player channel (1-indexed)
    public func player(_ channel: Int) -> AnyPublisher<InputChannelVU, Never> {
        vuData.compactMap { $0.player[safe: channel - 1] }.eraseToAnyPublisher()
    }

    /// Get VU data for a specific aux channel (1-indexed)
    public func aux(_ channel: Int) -> AnyPublisher<AuxChannelVU, Never> {
        vuData.compactMap { $0.aux[safe: channel - 1] }.eraseToAnyPublisher()
    }

    /// Get VU data for a specific fx channel (1-indexed)
    public func fx(_ channel: Int) -> AnyPublisher<StereoVU, Never> {
        vuData.compactMap { $0.fx[safe: channel - 1] }.eraseToAnyPublisher()
    }

    /// Get VU data for a specific sub group (1-indexed)
    public func sub(_ channel: Int) -> AnyPublisher<StereoVU, Never> {
        vuData.compactMap { $0.sub[safe: channel - 1] }.eraseToAnyPublisher()
    }

    /// Get stereo master VU data
    public func master() -> AnyPublisher<StereoVU, Never> {
        vuData.compactMap { $0.stereoMaster }.eraseToAnyPublisher()
    }

    // MARK: - Parsing

    /// Parse raw VU binary data into structured VUData
    static func parse(_ data: Data) -> VUData? {
        let bytes = [UInt8](data)
        guard bytes.count >= 8 else { return nil }

        let norm = 0.004167508166392142

        // Preamble: channel counts per type
        let channelCounts: [(key: String, amount: Int, blockSize: Int)] = [
            ("input",  Int(bytes[0]), 6),
            ("player", Int(bytes[1]), 6),
            ("sub",    Int(bytes[2]), 7),
            ("fx",     Int(bytes[3]), 7),
            ("aux",    Int(bytes[4]), 5),
            ("master", Int(bytes[5]), 5),
            ("line",   Int(bytes[6]), 6),
        ]

        var inputVU: [InputChannelVU] = []
        var playerVU: [InputChannelVU] = []
        var subVU: [StereoVU] = []
        var fxVU: [StereoVU] = []
        var auxVU: [AuxChannelVU] = []
        var masterVU: [MasterVU] = []
        var lineVU: [InputChannelVU] = []

        var idx = 8 // skip preamble

        for ct in channelCounts {
            for _ in 0..<ct.amount {
                guard idx + ct.blockSize <= bytes.count else { break }

                switch ct.key {
                case "input", "player", "line":
                    // byte[3] = compressor/dynamics GR; byte[4] = gate GR (0 if not populated)
                    let vu = InputChannelVU(
                        vuPre: Double(bytes[idx]) * norm,
                        vuPost: Double(bytes[idx + 1]) * norm,
                        vuPostFader: Double(bytes[idx + 2]) * norm,
                        grFraction: Double(bytes[idx + 3]) * norm,
                        gateGRFraction: Double(bytes[idx + 4]) * norm
                    )
                    switch ct.key {
                    case "input": inputVU.append(vu)
                    case "player": playerVU.append(vu)
                    default: lineVU.append(vu)
                    }

                case "aux":
                    // byte[2] = GR fraction
                    auxVU.append(AuxChannelVU(
                        vuPost: Double(bytes[idx]) * norm,
                        vuPostFader: Double(bytes[idx + 1]) * norm,
                        grFraction: Double(bytes[idx + 2]) * norm
                    ))

                case "fx", "sub":
                    // bytes[4] and [5] = L/R GR fractions
                    let vu = StereoVU(
                        vuPostL: Double(bytes[idx]) * norm,
                        vuPostR: Double(bytes[idx + 1]) * norm,
                        vuPostFaderL: Double(bytes[idx + 2]) * norm,
                        vuPostFaderR: Double(bytes[idx + 3]) * norm,
                        grFractionL: Double(bytes[idx + 4]) * norm,
                        grFractionR: Double(bytes[idx + 5]) * norm
                    )
                    if ct.key == "fx" { fxVU.append(vu) } else { subVU.append(vu) }

                case "master":
                    // byte[2] = GR fraction
                    masterVU.append(MasterVU(
                        vuPost: Double(bytes[idx]) * norm,
                        vuPostFader: Double(bytes[idx + 1]) * norm,
                        grFraction: Double(bytes[idx + 2]) * norm
                    ))

                default: break
                }

                idx += ct.blockSize
            }
        }

        return VUData(
            input: inputVU, player: playerVU, sub: subVU,
            fx: fxVU, aux: auxVU, master: masterVU, line: lineVU
        )
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
