import Foundation

/// Capabilities and channel counts for a mixer model
public struct DeviceCapabilities: Sendable {
    public let model: MixerModel
    public let input: Int
    public let line: Int
    public let player: Int
    public let fx: Int
    public let sub: Int
    public let aux: Int
    public let vca: Int
    public let multitrack: Bool
    public let masterDim: Bool

    /// Lookup table: mixer model → capabilities
    public static let capabilities: [MixerModel: DeviceCapabilities] = [
        .ui12: DeviceCapabilities(
            model: .ui12, input: 8, line: 2, player: 2,
            fx: 4, sub: 4, aux: 4, vca: 0,
            multitrack: false, masterDim: false
        ),
        .ui16: DeviceCapabilities(
            model: .ui16, input: 12, line: 2, player: 2,
            fx: 4, sub: 4, aux: 6, vca: 0,
            multitrack: false, masterDim: false
        ),
        .ui24: DeviceCapabilities(
            model: .ui24, input: 24, line: 2, player: 2,
            fx: 4, sub: 6, aux: 10, vca: 6,
            multitrack: true, masterDim: true
        ),
    ]

    /// Get capabilities for a mixer model
    public static func forModel(_ model: MixerModel) -> DeviceCapabilities {
        capabilities[model]!
    }
}
