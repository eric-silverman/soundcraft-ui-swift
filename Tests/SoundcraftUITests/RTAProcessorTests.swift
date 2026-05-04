import XCTest
@testable import SoundcraftUI

final class RTAProcessorTests: XCTestCase {

    func testParseRTAData() {
        // 120 bytes: values 0 through 119
        let bytes: [UInt8] = (0..<120).map { UInt8($0) }
        let frame = RTAProcessor.parse(Data(bytes))
        XCTAssertNotNil(frame)
        guard let f = frame else { return }
        XCTAssertEqual(f.bins.count, 120)
        // First bin: 0 / 240 = 0.0
        XCTAssertEqual(f.bins[0], 0.0, accuracy: 0.001)
        // Second bin: 1 / 240
        XCTAssertEqual(f.bins[1], 1.0 / 240.0, accuracy: 0.001)
        // 120th bin: 119 / 240
        XCTAssertEqual(f.bins[119], 119.0 / 240.0, accuracy: 0.001)
    }

    func testParseEmptyDataReturnsNil() {
        let frame = RTAProcessor.parse(Data())
        XCTAssertNil(frame)
    }

    func testParseSingleBin() {
        let frame = RTAProcessor.parse(Data([120]))
        XCTAssertNotNil(frame)
        XCTAssertEqual(frame?.bins.count, 1)
        XCTAssertEqual(frame?.bins[0] ?? 0, 120.0 / 240.0, accuracy: 0.001)
    }

    func testParseMaxValue() {
        let frame = RTAProcessor.parse(Data([255]))
        XCTAssertNotNil(frame)
        // 255 / 240 ≈ 1.0625
        XCTAssertEqual(frame?.bins[0] ?? 0, 255.0 / 240.0, accuracy: 0.001)
    }

    func testRTAFrameEmpty() {
        XCTAssertTrue(RTAFrame.empty.bins.isEmpty)
    }

    func testRTAFrameEquality() {
        let a = RTAFrame(bins: [0.5, 0.3, 0.8])
        let b = RTAFrame(bins: [0.5, 0.3, 0.8])
        let c = RTAFrame(bins: [0.5, 0.3, 0.9])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
