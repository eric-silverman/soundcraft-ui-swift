import Foundation

/// Protocol message framing and parsing for the Soundcraft UI mixer
public enum MessageProtocol {
    /// Socket.IO-like prefix for all messages
    static let framePrefix = "3:::"

    /// SETD/SETS message regex pattern
    static let setdSetsPattern = try! NSRegularExpression(
        pattern: #"(SETD|SETS)\^([a-zA-Z0-9.]+)\^(.*)"#
    )

    /// Add `3:::` framing prefix for outbound messages
    public static func frame(_ message: String) -> String {
        "\(framePrefix)\(message)"
    }

    /// Strip `3:::` prefix from inbound message. Returns nil if prefix not present.
    public static func unframe(_ rawMessage: String) -> String? {
        let pattern = #"^(3:::)([\s\S]*)"#
        guard let range = rawMessage.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        let match = rawMessage[range]
        let afterPrefix = String(match).dropFirst(framePrefix.count)
        return String(afterPrefix)
    }

    /// Split a potentially multi-line message into individual commands
    public static func splitLines(_ message: String) -> [String] {
        message.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    /// Parse a SETD or SETS message into (type, path, value) components
    public static func parseSetMessage(_ message: String) -> (type: String, path: String, value: String)? {
        let nsRange = NSRange(message.startIndex..., in: message)
        guard let match = setdSetsPattern.firstMatch(in: message, range: nsRange) else {
            return nil
        }
        guard match.numberOfRanges >= 4,
              let typeRange = Range(match.range(at: 1), in: message),
              let pathRange = Range(match.range(at: 2), in: message),
              let valueRange = Range(match.range(at: 3), in: message) else {
            return nil
        }
        return (
            type: String(message[typeRange]),
            path: String(message[pathRange]),
            value: String(message[valueRange])
        )
    }
}
