import XCTest
@testable import SoundcraftUI

final class VUProcessorTests: XCTestCase {

    func testParseBasicVUData() {
        // Construct a minimal VU message for ui12-like config:
        // Header: 8 inputs, 2 players, 4 subs, 4 fx, 4 aux, 2 master, 2 line
        var bytes: [UInt8] = [8, 2, 4, 4, 4, 2, 2, 0] // preamble

        // 8 input channels (6 bytes each); byte[3] = compressor GR, byte[4] = gate GR
        for i in 0..<8 {
            let vuPre = UInt8(100 + i)
            let vuPost = UInt8(80 + i)
            let vuPostFader = UInt8(60 + i)
            let gr = UInt8(20 + i)
            let gateGR = UInt8(10 + i)
            bytes += [vuPre, vuPost, vuPostFader, gr, gateGR, 0]
        }

        // 2 player channels (6 bytes each)
        for _ in 0..<2 {
            bytes += [50, 40, 30, 0, 0, 0]
        }

        // 4 sub groups (7 bytes each, stereo); bytes[4,5] = L/R GR
        for _ in 0..<4 {
            bytes += [120, 110, 90, 80, 30, 25, 0]
        }

        // 4 fx channels (7 bytes each, stereo); bytes[4,5] = L/R GR
        for _ in 0..<4 {
            bytes += [70, 60, 50, 40, 10, 5, 0]
        }

        // 4 aux channels (5 bytes each); byte[2] = GR
        for _ in 0..<4 {
            bytes += [100, 80, 15, 0, 0]
        }

        // 2 master channels (5 bytes each); byte[2] = GR
        bytes += [200, 180, 12, 0, 0] // master L
        bytes += [190, 170, 8, 0, 0]  // master R

        // 2 line channels (6 bytes each); byte[3] = GR
        for _ in 0..<2 {
            bytes += [45, 35, 25, 18, 0, 0]
        }

        let data = Data(bytes)
        let result = VUProcessor.parse(data)
        XCTAssertNotNil(result)

        guard let vu = result else { return }

        // Check counts
        XCTAssertEqual(vu.input.count, 8)
        XCTAssertEqual(vu.player.count, 2)
        XCTAssertEqual(vu.sub.count, 4)
        XCTAssertEqual(vu.fx.count, 4)
        XCTAssertEqual(vu.aux.count, 4)
        XCTAssertEqual(vu.master.count, 2)
        XCTAssertEqual(vu.line.count, 2)

        // Check normalization factor
        let norm = 0.004167508166392142

        // First input channel
        XCTAssertEqual(vu.input[0].vuPre, 100 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].vuPost, 80 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].vuPostFader, 60 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].grFraction, 20 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].gateGRFraction, 10 * norm, accuracy: 0.0001)
        // GR increments per channel
        XCTAssertEqual(vu.input[1].grFraction, 21 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[1].gateGRFraction, 11 * norm, accuracy: 0.0001)

        // Player
        XCTAssertEqual(vu.player[0].vuPre, 50 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.player[0].grFraction, 0, accuracy: 0.0001)

        // Sub (stereo) — bytes[4,5] are GR L/R
        XCTAssertEqual(vu.sub[0].vuPostL, 120 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].vuPostR, 110 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].vuPostFaderL, 90 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].grFractionL, 30 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].grFractionR, 25 * norm, accuracy: 0.0001)

        // FX — bytes[4,5] are GR L/R
        XCTAssertEqual(vu.fx[0].grFractionL, 10 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.fx[0].grFractionR, 5 * norm, accuracy: 0.0001)

        // Aux — byte[2] is GR
        XCTAssertEqual(vu.aux[0].vuPost, 100 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.aux[0].vuPostFader, 80 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.aux[0].grFraction, 15 * norm, accuracy: 0.0001)

        // Master — byte[2] is GR
        XCTAssertEqual(vu.master[0].vuPost, 200 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.master[0].grFraction, 12 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.master[1].vuPost, 190 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.master[1].grFraction, 8 * norm, accuracy: 0.0001)

        // Stereo master derived from master L/R
        let stereo = vu.stereoMaster
        XCTAssertNotNil(stereo)
        XCTAssertEqual(stereo!.vuPostL, 200 * norm, accuracy: 0.0001)
        XCTAssertEqual(stereo!.vuPostR, 190 * norm, accuracy: 0.0001)
        XCTAssertEqual(stereo!.grFractionL, 12 * norm, accuracy: 0.0001)
        XCTAssertEqual(stereo!.grFractionR, 8 * norm, accuracy: 0.0001)

        // Line — byte[3] is GR
        XCTAssertEqual(vu.line[0].vuPre, 45 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.line[0].grFraction, 18 * norm, accuracy: 0.0001)
    }

    func testParseInvalidData() {
        // Too short
        let result = VUProcessor.parse(Data([1, 2, 3]))
        XCTAssertNil(result)
    }

    func testParseEmptyChannels() {
        // All zeros in preamble
        let bytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        let result = VUProcessor.parse(Data(bytes))
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.input.count, 0)
        XCTAssertEqual(result?.master.count, 0)
    }
}
