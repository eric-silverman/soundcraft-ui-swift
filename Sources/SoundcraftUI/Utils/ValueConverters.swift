import Foundation

// MARK: - LUT Interpolation

/// Generic linear interpolation lookup in the dB LUT.
/// Finds the closest entry and interpolates between neighbors.
private func findInLUT(
    sourceVal: Double,
    sourceIndex: Int, // 0 = dB column, 1 = linear column
    resultIndex: Int  // 0 = dB column, 1 = linear column
) -> Double {
    let lut = dBLinearLUT
    func val(_ entry: (dB: Double, linear: Double), _ index: Int) -> Double {
        index == 0 ? entry.dB : entry.linear
    }

    for i in 0..<lut.count {
        let sourceEntry = val(lut[i], sourceIndex)
        if sourceEntry < sourceVal {
            continue
        }
        if i == 0 || i == 1 || sourceVal == sourceEntry {
            return val(lut[i], resultIndex)
        } else {
            let prev = lut[i - 1]
            let curr = lut[i]
            let prevSource = val(prev, sourceIndex)
            let currSource = val(curr, sourceIndex)
            let prevResult = val(prev, resultIndex)
            let currResult = val(curr, resultIndex)
            return prevResult + (currResult - prevResult) * (sourceVal - prevSource) / (currSource - prevSource)
        }
    }
    // fallback
    return val(lut[0], resultIndex)
}

// MARK: - dB ↔ Fader Value

/// Convert dB to linear fader value (0..1) using LUT interpolation
public func dBToFaderValue(_ dbValue: Double) -> Double {
    findInLUT(sourceVal: dbValue, sourceIndex: 0, resultIndex: 1)
}

/// Convert linear fader value (0..1) to dB, rounded to 1 decimal place
public func faderValueToDB(_ value: Double) -> Double {
    let dbValue = findInLUT(sourceVal: value, sourceIndex: 1, resultIndex: 0)
    return (dbValue * 10).rounded() / 10
}

// MARK: - Time Conversions

private let timeMsLowerBound: Double = 20
private let timeMsUpperBound: Double = 4000

/// Convert linear fader value (0..1) to milliseconds (20..4000 ms) for automix time
public func faderValueToTimeMs(_ value: Double) -> Int {
    Int(((timeMsUpperBound - timeMsLowerBound) * pow(value, 3.0517) + timeMsLowerBound).rounded())
}

/// Convert milliseconds (20..4000) to linear fader value (0..1)
public func timeMsToFaderValue(_ timeMs: Double) -> Double {
    let sanitized = clamp(timeMs, min: timeMsLowerBound, max: timeMsUpperBound)
    let result = pow(
        (sanitized - timeMsLowerBound) / (timeMsUpperBound - timeMsLowerBound),
        0.32768620768751844 // 1 / 3.0517
    )
    return Double(Int(result * 10_000_000)) / 10_000_000
}

// MARK: - Linear Range Mapping

/// Linear scaling from range value to normalized 0..1
public func linearMappingRangeToValue(_ rangeValue: Double, lowerBound: Double, upperBound: Double) -> Double {
    let result = (rangeValue - lowerBound) / (upperBound - lowerBound)
    return clamp(result, min: 0, max: 1)
}

/// Linear scaling from normalized 0..1 to range value, rounded to 1 decimal
public func linearMappingValueToRange(_ value: Double, lowerBound: Double, upperBound: Double) -> Double {
    let result = ((value * (upperBound - lowerBound) + lowerBound) * 10).rounded() / 10
    return clamp(result, min: lowerBound, max: upperBound)
}

// MARK: - Delay

/// Sanitize and convert a channel delay value from ms to raw seconds
public func sanitizeDelayValue(_ valueMs: Double, maximumMs: Double) -> Double {
    let clamped = clamp(valueMs, min: 0, max: maximumMs)
    return clamped / 1000
}

// MARK: - VU

/// Convert linear VU value (0..1) to dB (-80..0)
public func vuValueToDB(_ linearValue: Double) -> Double {
    linearMappingValueToRange(linearValue, lowerBound: -80, upperBound: 0)
}
