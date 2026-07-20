import Foundation

/// Clamp a numeric value to min and max
public func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
    Swift.min(max, Swift.max(min, value))
}

/// Round a number to three decimal places
public func roundToThreeDecimals(_ value: Double) -> Double {
    (value * 1000).rounded() / 1000
}

/// Transform a numeric `SETD` string value to Int or Double (falling back to String).
/// Upstream stores `SETD` values via JS `Number()`, which has no Int/Double distinction;
/// this preserves it. `SETS` values are kept as raw strings by the store and never pass here.
public func transformStringValue(_ value: String) -> Any {
    // Match integer: optional minus, digits only
    if value.range(of: #"^-?\d+$"#, options: .regularExpression) != nil {
        return Int(value) ?? value
    }
    // Match float: digits.digits
    if value.range(of: #"^\d+\.\d+$"#, options: .regularExpression) != nil {
        return Double(value) ?? value
    }
    return value
}

/// Transform player time in seconds to human-readable format M:SS
public func playerTimeToString(_ value: Int) -> String {
    guard value >= 0 else { return "" }
    let minutes = value / 60
    let seconds = value % 60
    return "\(minutes):\(String(format: "%02d", seconds))"
}

/// Get the linked channel number for stereo linking
public func getLinkedChannelNumber(_ channel: Int, stereoIndex: Int) -> Int? {
    switch stereoIndex {
    case 1: return channel - 1
    case 0: return channel + 1
    default: return nil
    }
}

/// Sanitize a channel name: strip ^ characters, limit to 20 chars, uppercase
public func sanitizeName(_ name: String) -> String {
    let cleaned = name.replacingOccurrences(of: "^", with: "")
    let truncated = String(cleaned.prefix(20))
    return truncated.uppercased()
}

/// Build a dot-separated state path from components
public func joinStatePath(_ components: Any...) -> String {
    components.map { "\($0)" }.joined(separator: ".")
}

/// Construct the default human-readable name for a channel,
/// based on the default labels from the web interface
public func getDefaultChannelName(type: ChannelType, channel: Int) -> String {
    switch type {
    case .input: return "CH \(channel)"
    case .aux: return "AUX \(channel)"
    case .fx: return "FX \(channel)"
    case .sub: return "SUB \(channel)"
    case .vca: return "VCA \(channel)"
    case .line: return "LINE IN \(channel == 1 ? "L" : "R")"
    case .player: return "PLAYER \(channel == 1 ? "L" : "R")"
    }
}

/// Construct the default human-readable name for a matrix bus output (Ui24R only).
/// A matrix lives in the same `a` slot as the AUX it replaced, but uses a different
/// default label.
public func getDefaultMatrixName(channel: Int) -> String {
    "MTX \(channel)"
}

/// Construct the default human-readable name for a volume bus (solo or headphones),
/// based on the default labels from the web interface
public func getDefaultVolumeBusName(type: VolumeBusType, id: Int) -> String {
    switch type {
    case .solovol: return "SOLO LEVEL"
    case .hpvol: return "HEADPHONE \(id) LEVEL"
    }
}

// MARK: - Channel ID construction

/// Construct the channel id for a master channel, e.g. `i.0`
public func constructMasterChannelId(_ channelType: ChannelType, _ channel: Int) -> String {
    "\(channelType.rawValue).\(channel - 1)"
}

/// Construct the channel id for a send (AUX/FX) channel, e.g. `i.0.aux.2`
public func constructSendChannelId(_ channelType: ChannelType, _ channel: Int,
                                   _ busType: BusType, _ bus: Int) -> String {
    "\(channelType.rawValue).\(channel - 1).\(busType.rawValue).\(bus - 1)"
}

/// Construct the channel id for a matrix source, e.g. `a.0.mtx.6`
public func constructMtxChannelId(_ channelType: ChannelType, _ channel: Int, _ bus: Int) -> String {
    "\(channelType.rawValue).\(channel - 1).mtx.\(bus - 1)"
}
