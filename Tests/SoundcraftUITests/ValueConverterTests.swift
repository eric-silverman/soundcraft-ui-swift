import XCTest
@testable import SoundcraftUI

final class ValueConverterTests: XCTestCase {

    // MARK: - dB ↔ Fader Value

    func testDBToFaderValue_unity() {
        // 0 dB should be ~0.7647
        let value = dBToFaderValue(0)
        XCTAssertEqual(value, 0.76470588235, accuracy: 0.0001)
    }

    func testDBToFaderValue_max() {
        // +10 dB should be 1.0
        let value = dBToFaderValue(10)
        XCTAssertEqual(value, 1.0, accuracy: 0.0001)
    }

    func testDBToFaderValue_negative() {
        // -10 dB should be ~0.5294
        let value = dBToFaderValue(-10)
        XCTAssertEqual(value, 0.5294117647, accuracy: 0.0001)
    }

    func testFaderValueToDB_unity() {
        // ~0.7647 should be 0 dB
        let db = faderValueToDB(0.76470588235)
        XCTAssertEqual(db, 0.0, accuracy: 0.1)
    }

    func testFaderValueToDB_max() {
        let db = faderValueToDB(1.0)
        XCTAssertEqual(db, 10.0, accuracy: 0.1)
    }

    func testFaderValueToDB_roundsToOneDecimal() {
        let db = faderValueToDB(0.5)
        // Should be rounded to 1 decimal
        XCTAssertEqual(db, (db * 10).rounded() / 10, accuracy: 0.001)
    }

    func testRoundTrip_DBToFaderAndBack() {
        let testValues: [Double] = [-20, -10, -5, 0, 3, 5, 10]
        for db in testValues {
            let fader = dBToFaderValue(db)
            let backDB = faderValueToDB(fader)
            XCTAssertEqual(backDB, db, accuracy: 0.2, "Round-trip failed for \(db) dB")
        }
    }

    // MARK: - Time Conversions

    func testFaderValueToTimeMs_zero() {
        let ms = faderValueToTimeMs(0)
        XCTAssertEqual(ms, 20)
    }

    func testFaderValueToTimeMs_one() {
        let ms = faderValueToTimeMs(1)
        XCTAssertEqual(ms, 4000)
    }

    func testTimeMsToFaderValue_lowerBound() {
        let value = timeMsToFaderValue(20)
        XCTAssertEqual(value, 0, accuracy: 0.001)
    }

    func testTimeMsToFaderValue_upperBound() {
        let value = timeMsToFaderValue(4000)
        XCTAssertEqual(value, 1, accuracy: 0.001)
    }

    func testTimeRoundTrip() {
        let testMs: [Double] = [20, 100, 500, 1000, 2000, 4000]
        for ms in testMs {
            let fader = timeMsToFaderValue(ms)
            let backMs = faderValueToTimeMs(fader)
            XCTAssertEqual(Double(backMs), ms, accuracy: 5, "Round-trip failed for \(ms) ms")
        }
    }

    // MARK: - Linear Range Mapping

    func testLinearMappingRangeToValue() {
        XCTAssertEqual(linearMappingRangeToValue(0, lowerBound: -80, upperBound: 0), 1.0, accuracy: 0.001)
        XCTAssertEqual(linearMappingRangeToValue(-80, lowerBound: -80, upperBound: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(linearMappingRangeToValue(-40, lowerBound: -80, upperBound: 0), 0.5, accuracy: 0.001)
    }

    func testLinearMappingValueToRange() {
        XCTAssertEqual(linearMappingValueToRange(0.5, lowerBound: -80, upperBound: 0), -40.0, accuracy: 0.1)
        XCTAssertEqual(linearMappingValueToRange(0, lowerBound: -80, upperBound: 0), -80.0, accuracy: 0.1)
        XCTAssertEqual(linearMappingValueToRange(1, lowerBound: -80, upperBound: 0), 0.0, accuracy: 0.1)
    }

    // MARK: - Delay

    func testSanitizeDelayValue() {
        XCTAssertEqual(sanitizeDelayValue(100, maximumMs: 250), 0.1, accuracy: 0.001)
        XCTAssertEqual(sanitizeDelayValue(300, maximumMs: 250), 0.25, accuracy: 0.001) // clamps to max
        XCTAssertEqual(sanitizeDelayValue(-10, maximumMs: 250), 0.0, accuracy: 0.001)  // clamps to 0
    }

    // MARK: - VU to dB

    func testVuValueToDB() {
        XCTAssertEqual(vuValueToDB(0), -80, accuracy: 0.1)
        XCTAssertEqual(vuValueToDB(1), 0, accuracy: 0.1)
        XCTAssertEqual(vuValueToDB(0.5), -40, accuracy: 0.1)
    }
}
