import XCTest
@testable import SoundcraftUI

final class BitmaskTests: XCTestCase {

    func testSetBit() {
        XCTAssertEqual(Bitmask.setBit(0, at: 0), 1)
        XCTAssertEqual(Bitmask.setBit(0, at: 1), 2)
        XCTAssertEqual(Bitmask.setBit(0, at: 2), 4)
        XCTAssertEqual(Bitmask.setBit(1, at: 1), 3) // 01 -> 11
    }

    func testClearBit() {
        XCTAssertEqual(Bitmask.clearBit(3, at: 0), 2) // 11 -> 10
        XCTAssertEqual(Bitmask.clearBit(3, at: 1), 1) // 11 -> 01
        XCTAssertEqual(Bitmask.clearBit(0, at: 0), 0) // already clear
    }

    func testToggleBit() {
        XCTAssertEqual(Bitmask.toggleBit(0, at: 0), 1) // set
        XCTAssertEqual(Bitmask.toggleBit(1, at: 0), 0) // clear
        XCTAssertEqual(Bitmask.toggleBit(2, at: 0), 3) // 10 -> 11
    }

    func testGetValueOfBit() {
        XCTAssertTrue(Bitmask.getValueOfBit(5, at: 0)) // 101 -> bit 0 = 1
        XCTAssertFalse(Bitmask.getValueOfBit(5, at: 1)) // 101 -> bit 1 = 0
        XCTAssertTrue(Bitmask.getValueOfBit(5, at: 2)) // 101 -> bit 2 = 1
    }

    func testNegativeBitIndex() {
        // Negative index should return value unchanged (bit operations) / false (bit read)
        XCTAssertEqual(Bitmask.toggleBit(42, at: -1), 42)
        XCTAssertEqual(Bitmask.clearBit(42, at: -1), 42)
        XCTAssertEqual(Bitmask.setBit(42, at: -1), 42)
        XCTAssertFalse(Bitmask.getValueOfBit(42, at: -1))
    }

    func testMuteGroupBitPositions() {
        // Group 1 -> bit 0
        XCTAssertEqual(MuteGroupID.group(1).bitIndex, 0)
        // Group 6 -> bit 5
        XCTAssertEqual(MuteGroupID.group(6).bitIndex, 5)
        // FX -> bit 22
        XCTAssertEqual(MuteGroupID.fx.bitIndex, 22)
        // ALL -> bit 23
        XCTAssertEqual(MuteGroupID.all.bitIndex, 23)
    }

    func testMuteGroupOperations() {
        var mask = 0
        // Mute group 1
        mask = Bitmask.setBit(mask, at: MuteGroupID.group(1).bitIndex)
        XCTAssertEqual(mask, 1)
        XCTAssertTrue(Bitmask.getValueOfBit(mask, at: 0))

        // Mute group 3
        mask = Bitmask.setBit(mask, at: MuteGroupID.group(3).bitIndex)
        XCTAssertTrue(Bitmask.getValueOfBit(mask, at: 2))

        // Unmute group 1
        mask = Bitmask.clearBit(mask, at: MuteGroupID.group(1).bitIndex)
        XCTAssertFalse(Bitmask.getValueOfBit(mask, at: 0))
        XCTAssertTrue(Bitmask.getValueOfBit(mask, at: 2)) // group 3 still muted
    }
}
