import XCTest
@testable import SoundcraftUI

final class VUProcessorTests: XCTestCase {

    /// Dynamics byte: low 7 bits = comp GR, top bit = gate open (stock web UI layout).
    private static let gateOpenNoGR: UInt8 = 247   // what an idle Ui24R sends
    private static let gateClosed10dB: UInt8 = 105  // ~10 dB GR, top bit clear

    func testParseBasicVUData() {
        // Header: 8 inputs, 2 players, 4 subs, 4 fx, 4 aux, 2 master, 2 line
        var bytes: [UInt8] = [8, 2, 4, 4, 4, 2, 2, 0]

        // Inputs: pre, post, post-fader, dyn in, dyn out, dynamics byte
        for i in 0..<8 {
            let dyn = i == 0 ? Self.gateClosed10dB : Self.gateOpenNoGR
            bytes += [UInt8(100 + i), UInt8(80 + i), UInt8(60 + i), UInt8(20 + i), UInt8(10 + i), dyn]
        }
        for _ in 0..<2 { bytes += [50, 40, 30, 0, 0, Self.gateOpenNoGR] }                 // players
        for _ in 0..<4 { bytes += [120, 110, 90, 80, 0, 0, Self.gateClosed10dB] }         // subs
        for _ in 0..<4 { bytes += [70, 60, 50, 40, 0, 0, Self.gateOpenNoGR] }             // fx
        for _ in 0..<4 { bytes += [100, 80, 0, 0, Self.gateClosed10dB] }                  // aux
        bytes += [200, 180, 0, 0, Self.gateOpenNoGR]                                      // master L
        bytes += [190, 170, 0, 0, Self.gateClosed10dB]                                    // master R
        for _ in 0..<2 { bytes += [45, 35, 25, 18, 16, Self.gateOpenNoGR] }               // line

        guard let vu = VUProcessor.parse(Data(bytes)) else { return XCTFail("parse failed") }
        let norm = 0.004167508166392142

        XCTAssertEqual(vu.input.count, 8)
        XCTAssertEqual(vu.player.count, 2)
        XCTAssertEqual(vu.sub.count, 4)
        XCTAssertEqual(vu.fx.count, 4)
        XCTAssertEqual(vu.aux.count, 4)
        XCTAssertEqual(vu.master.count, 2)
        XCTAssertEqual(vu.line.count, 2)

        XCTAssertEqual(vu.input[0].vuPre, 100 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].vuPost, 80 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].vuPostFader, 60 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].dynamicsIn, 20 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].dynamicsOut, 10 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].grFraction, 0.48, accuracy: 0.02)   // ~10 dB of 20
        XCTAssertFalse(vu.input[0].gateOpen)
        XCTAssertEqual(vu.input[1].grFraction, 0)
        XCTAssertTrue(vu.input[1].gateOpen)

        XCTAssertEqual(vu.player[0].vuPre, 50 * norm, accuracy: 0.0001)
        XCTAssertTrue(vu.player[0].gateOpen)

        XCTAssertEqual(vu.sub[0].vuPostL, 120 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].vuPostR, 110 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].vuPostFaderL, 90 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].vuPostFaderR, 80 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.sub[0].grFractionL, 0.48, accuracy: 0.02)
        XCTAssertEqual(vu.sub[0].grFractionR, vu.sub[0].grFractionL)
        XCTAssertFalse(vu.sub[0].gateOpenL)
        XCTAssertEqual(vu.fx[0].grFractionL, 0)

        XCTAssertEqual(vu.aux[0].vuPost, 100 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.aux[0].vuPostFader, 80 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.aux[0].grFraction, 0.48, accuracy: 0.02)

        let stereo = vu.stereoMaster
        XCTAssertEqual(stereo?.vuPostL ?? 0, 200 * norm, accuracy: 0.0001)
        XCTAssertEqual(stereo?.vuPostR ?? 0, 190 * norm, accuracy: 0.0001)
        XCTAssertEqual(stereo?.grFractionL, 0)
        XCTAssertEqual(stereo?.grFractionR ?? 0, 0.48, accuracy: 0.02)
        XCTAssertEqual(stereo?.gateOpenR, false)

        XCTAssertEqual(vu.line[0].vuPre, 45 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.line[0].dynamicsOut, 16 * norm, accuracy: 0.0001)
        XCTAssertEqual(vu.line[0].grFraction, 0)
    }

    /// A VU2 frame captured from a Ui24R during soundcheck playback. Every
    /// dynamics byte is 247 (gate open, no GR) except input 17, whose compressor
    /// was working (239 ≈ 5.7 dB of reduction).
    func testParseCapturedUi24RFrame() throws {
        let data = try XCTUnwrap(Data(base64Encoded: "\(Self.capturedUi24RFrame)"))
        let vu = try XCTUnwrap(VUProcessor.parse(data))
        XCTAssertEqual(vu.input.count, 24)
        XCTAssertEqual(vu.aux.count, 10)
        for (i, ch) in (vu.input + vu.line + vu.player).enumerated() where i != 16 {
            XCTAssertEqual(ch.grFraction, 0, "channel index \(i)")
            XCTAssertTrue(ch.gateOpen)
        }
        XCTAssertEqual(vu.input[16].grFraction * 20, 5.7, accuracy: 0.2)   // dB
        XCTAssertTrue(vu.input[16].gateOpen)
        for ch in vu.aux { XCTAssertEqual(ch.grFraction, 0) }
        for ch in vu.sub + vu.fx { XCTAssertEqual(ch.grFractionL, 0); XCTAssertTrue(ch.gateOpenL) }
        // Input 1 had signal: post-processing level is byte 1, dynamics in/out bytes 3/4.
        XCTAssertEqual(vu.input[0].vuPost, 143 * 0.004167508166392142, accuracy: 0.0001)
        XCTAssertEqual(vu.input[0].dynamicsOut, 142 * 0.004167508166392142, accuracy: 0.0001)
    }

    private static let capturedUi24RFrame = "GAIGBAoCAgCAjwCAjvdqfABqdPcAAAAAAPcAAAAAAPeprACppfcACgAAAPcAAAAAAPeevQCetveSrwCSrfeJoQCEn/fIygDIx/fGyADHxvcAAAAAAPcAAAAAAPcACAAAAfcAAAAAAPfVwQDVw+8AAAAAAPetygCswPcPDwAPD/cAAAAAAPcAAAAAAPcAAAAAAPcAAAAAAPcAAAAAAPcAAAAAAPcAAAAAAAD3AAAAAAAA9wAAAAAAAPcAAAAAAAD3AAAAAAAA9wAAAAAAAPcAAAAAAAD3XmIAAGJi9wAAAAAAAPcAAAAAAAD31tYAAPfT0wAA98zMAAD369oAAPe6kQC497uSALj3AAAAAPcAAAAA914AXl73AAAAAPcAAAAA9wAAAAD3AAAAAAD3AAAAAAD3"

    func testDynamicsByte() {
        XCTAssertEqual(VUProcessor.dynamics(247).gr, 0)
        XCTAssertTrue(VUProcessor.dynamics(247).gateOpen)
        XCTAssertFalse(VUProcessor.dynamics(0x7F).gateOpen)
        XCTAssertEqual(VUProcessor.dynamics(0).gr, 1)   // byte 0 = maximum reduction
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
