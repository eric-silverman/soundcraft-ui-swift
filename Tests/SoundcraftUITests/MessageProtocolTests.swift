import XCTest
@testable import SoundcraftUI

final class MessageProtocolTests: XCTestCase {

    func testFrame() {
        XCTAssertEqual(MessageProtocol.frame("ALIVE"), "3:::ALIVE")
        XCTAssertEqual(MessageProtocol.frame("SETD^i.0.mute^1"), "3:::SETD^i.0.mute^1")
    }

    func testUnframe() {
        XCTAssertEqual(MessageProtocol.unframe("3:::ALIVE"), "ALIVE")
        XCTAssertEqual(MessageProtocol.unframe("3:::SETD^i.0.mute^1"), "SETD^i.0.mute^1")
    }

    func testUnframe_noPrefix() {
        XCTAssertNil(MessageProtocol.unframe("ALIVE"))
        XCTAssertNil(MessageProtocol.unframe("random message"))
    }

    func testUnframe_multiline() {
        let raw = "3:::SETD^i.0.mute^1\nSETD^i.1.mute^0"
        let unframed = MessageProtocol.unframe(raw)
        XCTAssertNotNil(unframed)
        XCTAssertTrue(unframed!.contains("\n"))
    }

    func testSplitLines() {
        let message = "SETD^i.0.mute^1\nSETD^i.1.mute^0\nSETD^i.2.mix^0.5"
        let lines = MessageProtocol.splitLines(message)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "SETD^i.0.mute^1")
        XCTAssertEqual(lines[1], "SETD^i.1.mute^0")
        XCTAssertEqual(lines[2], "SETD^i.2.mix^0.5")
    }

    func testSplitLines_emptyLines() {
        let message = "SETD^a^b\n\nSETD^c^d"
        let lines = MessageProtocol.splitLines(message)
        XCTAssertEqual(lines.count, 2)
    }

    func testParseSetMessage_SETD() {
        let result = MessageProtocol.parseSetMessage("SETD^i.0.mute^1")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "SETD")
        XCTAssertEqual(result?.path, "i.0.mute")
        XCTAssertEqual(result?.value, "1")
    }

    func testParseSetMessage_SETS() {
        let result = MessageProtocol.parseSetMessage("SETS^i.0.name^VOCALS")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "SETS")
        XCTAssertEqual(result?.path, "i.0.name")
        XCTAssertEqual(result?.value, "VOCALS")
    }

    func testParseSetMessage_floatValue() {
        let result = MessageProtocol.parseSetMessage("SETD^i.0.mix^0.76470588235")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "i.0.mix")
        XCTAssertEqual(result?.value, "0.76470588235")
    }

    func testParseSetMessage_invalidMessage() {
        XCTAssertNil(MessageProtocol.parseSetMessage("ALIVE"))
        XCTAssertNil(MessageProtocol.parseSetMessage("VU2^abc"))
        XCTAssertNil(MessageProtocol.parseSetMessage("MEDIA_PLAY"))
    }
}
