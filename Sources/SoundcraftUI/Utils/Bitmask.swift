import Foundation

/// Bitmask manipulation utilities for mute groups
public enum Bitmask {
    /// Toggle a bit at the given index (right to left)
    public static func toggleBit(_ value: Int, at bitIndex: Int) -> Int {
        guard bitIndex >= 0 else { return value }
        return value ^ (1 << bitIndex)
    }

    /// Clear (set to 0) a bit at the given index
    public static func clearBit(_ value: Int, at bitIndex: Int) -> Int {
        guard bitIndex >= 0 else { return value }
        return value & ~(1 << bitIndex)
    }

    /// Set (set to 1) a bit at the given index
    public static func setBit(_ value: Int, at bitIndex: Int) -> Int {
        guard bitIndex >= 0 else { return value }
        return value | (1 << bitIndex)
    }

    /// Return whether a specific bit at the given index is set
    public static func getValueOfBit(_ value: Int, at bitIndex: Int) -> Bool {
        guard bitIndex >= 0 else { return false }
        return (value & (1 << bitIndex)) != 0
    }
}
