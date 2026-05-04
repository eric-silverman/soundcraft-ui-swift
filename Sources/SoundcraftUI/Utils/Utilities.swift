import Foundation

/// Clamp a numeric value to min and max
public func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
    Swift.min(max, Swift.max(min, value))
}

/// Round a number to three decimal places
public func roundToThreeDecimals(_ value: Double) -> Double {
    (value * 1000).rounded() / 1000
}

/// Transform a string value to Int, Double, or keep as String.
/// Matches the TS `transformStringValue` behavior.
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

/// Construct a human-readable default name for a channel
public func constructReadableChannelName(type: ChannelType, channel: Int) -> String {
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

/// Construct a readable name for a volume bus
public func constructReadableVolumeBusName(type: VolumeBusType, id: Int) -> String {
    switch type {
    case .solovol: return "SOLO LEVEL"
    case .hpvol: return "HEADPHONE \(id) LEVEL"
    }
}
