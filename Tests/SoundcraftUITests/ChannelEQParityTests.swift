import XCTest
@testable import SoundcraftUI

// MARK: - EQ Converter Tests

final class EQConverterTests: XCTestCase {

    // Default raw values from the mixer (identical on Ui12, Ui16, Ui24R)
    static let defaultFrequencies: [(hz: Double, raw: Double)] = [
        (200, 0.3286901902),
        (1000, 0.5584347738),
        (4000, 0.7563259869),
        (10000, 0.887124964),
        (16000, 0.9542171999),
    ]
    static let defaultQ: Double = 0.5252185347

    func testFrequencyToFaderValueDefaultBands() {
        for (hz, raw) in Self.defaultFrequencies {
            XCTAssertEqual(frequencyToFaderValue(hz), raw, "Failed for \(hz) Hz")
        }
    }

    func testFrequencyToFaderValueLimits() {
        XCTAssertEqual(frequencyToFaderValue(20), 0)
        XCTAssertEqual(frequencyToFaderValue(22050), 1)
        XCTAssertEqual(frequencyToFaderValue(10), 0)
        XCTAssertEqual(frequencyToFaderValue(0), 0)
        XCTAssertEqual(frequencyToFaderValue(-5), 0)
        XCTAssertEqual(frequencyToFaderValue(30000), 1)
    }

    func testFaderValueToFrequencyDefaultBands() {
        for (hz, raw) in Self.defaultFrequencies {
            XCTAssertEqual(faderValueToFrequency(raw), hz, "Failed for raw \(raw)")
        }
    }

    func testFaderValueToFrequencyKnownValues() {
        XCTAssertEqual(faderValueToFrequency(0), 20)
        XCTAssertEqual(faderValueToFrequency(0.5), 664)
        XCTAssertEqual(faderValueToFrequency(1), 22050)
    }

    func testFaderValueToFrequencyLimits() {
        XCTAssertEqual(faderValueToFrequency(-1), 20)
        XCTAssertEqual(faderValueToFrequency(2), 22050)
    }

    func testFrequencyRoundTrip() {
        for hz: Double in [20, 21, 80, 200, 440, 1000, 2500, 12345, 22049, 22050] {
            XCTAssertEqual(faderValueToFrequency(frequencyToFaderValue(hz)), hz, "Round-trip failed for \(hz) Hz")
        }
    }

    func testQToFaderValueDefault() {
        XCTAssertEqual(qToFaderValue(1), Self.defaultQ)
    }

    func testQToFaderValueLimits() {
        XCTAssertEqual(qToFaderValue(0.05), 0)
        XCTAssertEqual(qToFaderValue(15), 1)
        XCTAssertEqual(qToFaderValue(0.01), 0)
        XCTAssertEqual(qToFaderValue(0), 0)
        XCTAssertEqual(qToFaderValue(-1), 0)
        XCTAssertEqual(qToFaderValue(20), 1)
    }

    func testFaderValueToQKnownValues() {
        XCTAssertEqual(faderValueToQ(Self.defaultQ), 1)
        XCTAssertEqual(faderValueToQ(0), 0.05)
        XCTAssertEqual(faderValueToQ(0.5), 0.87)
        XCTAssertEqual(faderValueToQ(1), 15)
    }

    func testFaderValueToQLimits() {
        XCTAssertEqual(faderValueToQ(-1), 0.05)
        XCTAssertEqual(faderValueToQ(2), 15)
    }

    func testQRoundTrip() {
        for q: Double in [0.05, 0.1, 0.5, 0.7, 1, 1.4, 2, 4, 10, 15] {
            XCTAssertEqual(faderValueToQ(qToFaderValue(q)), q, "Round-trip failed for Q \(q)")
        }
    }

    func testEqGainDBToFaderValue() {
        XCTAssertEqual(eqGainDBToFaderValue(-20), 0)
        XCTAssertEqual(eqGainDBToFaderValue(-3), 0.425)
        XCTAssertEqual(eqGainDBToFaderValue(0), 0.5)
        XCTAssertEqual(eqGainDBToFaderValue(3), 0.575)
        XCTAssertEqual(eqGainDBToFaderValue(6), 0.65)
        XCTAssertEqual(eqGainDBToFaderValue(20), 1)
        XCTAssertEqual(eqGainDBToFaderValue(-30), 0)
        XCTAssertEqual(eqGainDBToFaderValue(30), 1)
    }

    func testFaderValueToEqGainDB() {
        XCTAssertEqual(faderValueToEqGainDB(0), -20)
        XCTAssertEqual(faderValueToEqGainDB(0.425), -3)
        XCTAssertEqual(faderValueToEqGainDB(0.5), 0)
        XCTAssertEqual(faderValueToEqGainDB(0.65), 6)
        XCTAssertEqual(faderValueToEqGainDB(1), 20)
        XCTAssertEqual(faderValueToEqGainDB(0.57771261), 3.1)
        XCTAssertEqual(faderValueToEqGainDB(-1), -20)
        XCTAssertEqual(faderValueToEqGainDB(2), 20)
    }
}

// MARK: - EQ Band Tests

final class EQBandTests: MixerTestCase {

    func testFrequencyPublisherEmitsHz() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        transport.simulateSetd(path: "i.2.eq.b1.freq", value: "0.3286901902")
        XCTAssertEqual(awaitValue(band.frequency), 200)
    }

    func testSetFrequency() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setFrequency(1000)
        assertSent("SETD^i.2.eq.b1.freq^0.5584347738")
        XCTAssertEqual(awaitValue(band.frequency), 1000)
    }

    func testSetFrequencyClamped() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setFrequency(10)
        XCTAssertEqual(awaitValue(band.frequency), 20)

        band.setFrequency(30000)
        XCTAssertEqual(awaitValue(band.frequency), 22050)
    }

    func testQPublisher() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        transport.simulateSetd(path: "i.2.eq.b1.q", value: "0.5252185347")
        XCTAssertEqual(awaitValue(band.q), 1)
    }

    func testSetQ() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setQ(2)
        assertSent("SETD^i.2.eq.b1.q^0.6467426608")
        XCTAssertEqual(awaitValue(band.q), 2)
    }

    func testSetQClamped() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setQ(0.01)
        XCTAssertEqual(awaitValue(band.q), 0.05)

        band.setQ(20)
        XCTAssertEqual(awaitValue(band.q), 15)
    }

    func testGainAndGainDB() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        transport.simulateSetd(path: "i.2.eq.b1.gain", value: "0.65")
        XCTAssertEqual(awaitValue(band.gain), 0.65)
        XCTAssertEqual(awaitValue(band.gainDB), 6)
    }

    func testSetGainClamped() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setGain(0.25)
        XCTAssertEqual(awaitValue(band.gain), 0.25)

        band.setGain(1.5)
        XCTAssertEqual(awaitValue(band.gain), 1)

        band.setGain(-1)
        XCTAssertEqual(awaitValue(band.gain), 0)
    }

    func testSetGainDB() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setGainDB(6)
        assertSent("SETD^i.2.eq.b1.gain^0.65")
        XCTAssertEqual(awaitValue(band.gainDB), 6)
    }

    func testSetGainDBClamped() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setGainDB(25)
        XCTAssertEqual(awaitValue(band.gainDB), 20)

        band.setGainDB(-25)
        XCTAssertEqual(awaitValue(band.gainDB), -20)
    }

    func testChangeGainDB() {
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { ["i.2"] }, band: 1)
        band.setGainDB(-3)
        band.changeGainDB(1.5)
        XCTAssertEqual(awaitValue(band.gainDB), -1.5)

        band.changeGainDB(30)
        XCTAssertEqual(awaitValue(band.gainDB), 20)
    }

    func testBandNumberInPaths() {
        let band = EQBand(conn: conn, store: store, channelId: "s.5",
                          linkedChannelIds: { ["s.5"] }, band: 3)
        band.setGainDB(0)
        band.setFrequency(1000)
        band.setQ(1)
        assertSent("SETD^s.5.eq.b3.gain^0.5")
        assertSent("SETD^s.5.eq.b3.freq^0.5584347738")
        assertSent("SETD^s.5.eq.b3.q^0.5252185347")
    }

    func testLinkedChannelWrites() {
        var linked = ["i.2"]
        let band = EQBand(conn: conn, store: store, channelId: "i.2",
                          linkedChannelIds: { linked }, band: 2)

        linked = ["i.2", "i.3"]
        band.setGainDB(6)
        band.setFrequency(2500)
        band.setQ(1.4)
        assertSent("SETD^i.2.eq.b2.gain^0.65")
        assertSent("SETD^i.3.eq.b2.gain^0.65")
        assertSent("SETD^i.2.eq.b2.freq^0.689233751")
        assertSent("SETD^i.3.eq.b2.freq^0.689233751")
        assertSent("SETD^i.2.eq.b2.q^0.5842096056")
        assertSent("SETD^i.3.eq.b2.q^0.5842096056")
    }
}

// MARK: - EQ Filter Tests

final class EQFilterTests: MixerTestCase {

    func testHPFAt20HzIsOff() {
        let hpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .hpf)
        transport.simulateSetd(path: "i.2.eq.hpf.freq", value: "0")
        XCTAssertEqual(awaitValue(hpf.frequency), 20)
    }

    func testHPFSetFrequency() {
        let hpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .hpf)
        transport.simulateSetd(path: "i.2.eq.hpf.freq", value: "0")
        hpf.setFrequency(80)
        assertSent("SETD^i.2.eq.hpf.freq^0.197891213")
        XCTAssertEqual(awaitValue(hpf.frequency), 80)
    }

    func testHPFFrequencyClamped() {
        let hpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .hpf)
        hpf.setFrequency(5000)
        XCTAssertEqual(awaitValue(hpf.frequency), 1000)

        hpf.setFrequency(10)
        assertSent("SETD^i.2.eq.hpf.freq^0.0")
        XCTAssertEqual(awaitValue(hpf.frequency), 20)
    }

    func testHPFSlope() {
        let hpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .hpf)
        hpf.setSlope(.slope24)
        assertSent("SETD^i.2.eq.hpf.slope^1.0")
        XCTAssertEqual(awaitValue(hpf.slope), .slope24)

        transport.simulateSetd(path: "i.2.eq.hpf.slope", value: "2")
        XCTAssertEqual(awaitValue(hpf.slope), .slope36)

        hpf.setSlope(.slope12)
        XCTAssertEqual(awaitValue(hpf.slope), .slope12)
    }

    func testLPFAt22050HzIsOff() {
        let lpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .lpf)
        transport.simulateSetd(path: "i.2.eq.lpf.freq", value: "1")
        XCTAssertEqual(awaitValue(lpf.frequency), 22050)
    }

    func testLPFSetFrequency() {
        let lpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .lpf)
        lpf.setFrequency(12000)
        assertSent("SETD^i.2.eq.lpf.freq^0.9131510628")
        XCTAssertEqual(awaitValue(lpf.frequency), 12000)
    }

    func testLPFFrequencyClamped() {
        let lpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .lpf)
        lpf.setFrequency(500)
        XCTAssertEqual(awaitValue(lpf.frequency), 1000)

        lpf.setFrequency(30000)
        assertSent("SETD^i.2.eq.lpf.freq^1.0")
        XCTAssertEqual(awaitValue(lpf.frequency), 22050)
    }

    func testLPFSlope() {
        let lpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .lpf)
        lpf.setSlope(.slope36)
        assertSent("SETD^i.2.eq.lpf.slope^2.0")
        XCTAssertEqual(awaitValue(lpf.slope), .slope36)
    }

    func testFilterType() {
        let lpf = EQFilter(conn: conn, store: store, channelId: "i.2",
                           linkedChannelIds: { ["i.2"] }, type: .lpf)
        XCTAssertEqual(lpf.type, .lpf)
    }

    func testLinkedChannelWrites() {
        var linked = ["l.0"]
        let hpf = EQFilter(conn: conn, store: store, channelId: "l.0",
                            linkedChannelIds: { linked }, type: .hpf)

        linked = ["l.0", "l.1"]
        hpf.setFrequency(100)
        hpf.setSlope(.slope36)
        hpf.setFrequency(20)
        assertSent("SETD^l.0.eq.hpf.freq^0.2297445837")
        assertSent("SETD^l.1.eq.hpf.freq^0.2297445837")
        assertSent("SETD^l.0.eq.hpf.slope^2.0")
        assertSent("SETD^l.1.eq.hpf.slope^2.0")
        assertSent("SETD^l.0.eq.hpf.freq^0.0")
        assertSent("SETD^l.1.eq.hpf.freq^0.0")
    }
}

// MARK: - Channel EQ Tests

final class ChannelEQTests: MixerTestCase {

    func testBypassReflectsState() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        transport.simulateSetd(path: "i.2.eq.bypass", value: "1")
        XCTAssertTrue(awaitValue(eq.bypass))

        transport.simulateSetd(path: "i.2.eq.bypass", value: "0")
        XCTAssertFalse(awaitValue(eq.bypass))
    }

    func testBypassDefaultsFalse() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        transport.simulateSetd(path: "i.2.mute", value: "0")
        XCTAssertFalse(awaitValue(eq.bypass))
    }

    func testBypassSettersAndToggle() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        eq.enableBypass()
        eq.disableBypass()
        eq.setBypass(true)
        eq.setBypass(false)
        assertSent("SETD^i.2.eq.bypass^1")
        assertSent("SETD^i.2.eq.bypass^0")
        XCTAssertFalse(awaitValue(eq.bypass))
    }

    func testToggleBypass() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        eq.disableBypass()
        eq.toggleBypass()
        XCTAssertTrue(awaitValue(eq.bypass))

        eq.toggleBypass()
        XCTAssertFalse(awaitValue(eq.bypass))
    }

    func testBandsReturnSameObject() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        XCTAssertTrue(eq.band(2) === eq.band(2))
    }

    func testHPF() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        XCTAssertEqual(eq.hpf.type, .hpf)
        XCTAssertTrue(eq.hpf === eq.hpf)
    }

    func testLPF() {
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { ["i.2"] })
        XCTAssertEqual(eq.lpf.type, .lpf)
        XCTAssertTrue(eq.lpf === eq.lpf)
    }

    func testLinkedChannelPassthrough() {
        var linked = ["i.2"]
        let eq = ChannelEQ(conn: conn, store: store, channelType: .input,
                           channelId: "i.2", linkedChannelIds: { linked })

        linked = ["i.2", "i.3"]
        eq.enableBypass()
        eq.band(4).setGainDB(6)
        eq.hpf.setFrequency(20)
        eq.lpf.setFrequency(22050)
        assertSent("SETD^i.2.eq.bypass^1")
        assertSent("SETD^i.3.eq.bypass^1")
        assertSent("SETD^i.2.eq.b4.gain^0.65")
        assertSent("SETD^i.3.eq.b4.gain^0.65")
        assertSent("SETD^i.2.eq.hpf.freq^0.0")
        assertSent("SETD^i.3.eq.hpf.freq^0.0")
        assertSent("SETD^i.2.eq.lpf.freq^1.0")
        assertSent("SETD^i.3.eq.lpf.freq^1.0")
    }
}

// MARK: - Master Channel EQ Integration Tests

final class MasterChannelEQTests: MixerTestCase {

    func testEQAvailableOnValidChannelTypes() {
        let master = MasterBus(conn: conn, store: store)
        XCTAssertNotNil(master.input(3).eq)
        XCTAssertNotNil(master.line(1).eq)
        XCTAssertNotNil(master.player(2).eq)
        XCTAssertNotNil(master.fx(1).eq)
        XCTAssertNotNil(master.sub(4).eq)
    }

    func testEQReturnsSameObject() {
        let master = MasterBus(conn: conn, store: store)
        XCTAssertTrue(master.input(3).eq === master.input(3).eq)
        XCTAssertTrue(master.input(3).eq.band(1) === master.input(3).eq.band(1))
    }

    func testEQControlsCorrectChannel() {
        let master = MasterBus(conn: conn, store: store)
        master.input(3).eq.band(1).setGainDB(6)
        master.line(2).eq.enableBypass()
        master.player(1).eq.hpf.setSlope(.slope24)
        master.fx(4).eq.band(4).setFrequency(1000)
        master.sub(6).eq.band(2).setQ(1)

        assertSent("SETD^i.2.eq.b1.gain^0.65")
        assertSent("SETD^l.1.eq.bypass^1")
        assertSent("SETD^p.0.eq.hpf.slope^1.0")
        assertSent("SETD^f.3.eq.b4.freq^0.5584347738")
        assertSent("SETD^s.5.eq.b2.q^0.5252185347")

        transport.simulateSetd(path: "i.2.eq.b1.gain", value: "0.65")
        XCTAssertEqual(awaitValue(master.input(3).eq.band(1).gainDB), 6)
    }

    func testStereoLinkMirrorsEQFirstInLink() {
        let master = MasterBus(conn: conn, store: store)
        let eq = master.input(3).eq
        transport.simulateSetd(path: "i.2.stereoIndex", value: "0")
        drainMainQueue()

        eq.band(1).setGainDB(6)
        assertSent("SETD^i.2.eq.b1.gain^0.65")
        assertSent("SETD^i.3.eq.b1.gain^0.65")

        eq.enableBypass()
        assertSent("SETD^i.2.eq.bypass^1")
        assertSent("SETD^i.3.eq.bypass^1")

        eq.hpf.setSlope(.slope24)
        assertSent("SETD^i.2.eq.hpf.slope^1.0")
        assertSent("SETD^i.3.eq.hpf.slope^1.0")

        eq.lpf.setFrequency(22050)
        assertSent("SETD^i.2.eq.lpf.freq^1.0")
        assertSent("SETD^i.3.eq.lpf.freq^1.0")
    }

    func testStereoLinkMirrorsEQSecondInLink() {
        let master = MasterBus(conn: conn, store: store)
        transport.simulateSetd(path: "i.3.stereoIndex", value: "1")
        drainMainQueue()

        master.input(4).eq.band(2).setQ(1)
        assertSent("SETD^i.3.eq.b2.q^0.5252185347")
        assertSent("SETD^i.2.eq.b2.q^0.5252185347")
    }

    func testStereoLinkMirrorsLineAndPlayer() {
        let master = MasterBus(conn: conn, store: store)
        transport.simulateSetd(path: "l.0.stereoIndex", value: "0")
        transport.simulateSetd(path: "p.0.stereoIndex", value: "0")
        drainMainQueue()

        master.line(1).eq.disableBypass()
        master.player(1).eq.band(3).setGainDB(-3)
        assertSent("SETD^l.0.eq.bypass^0")
        assertSent("SETD^l.1.eq.bypass^0")
        assertSent("SETD^p.0.eq.b3.gain^0.425")
        assertSent("SETD^p.1.eq.b3.gain^0.425")
    }

    func testNoMirrorWhenNotLinked() {
        let master = MasterBus(conn: conn, store: store)
        transport.simulateSetd(path: "i.2.stereoIndex", value: "-1")
        drainMainQueue()

        transport.sentMessages.removeAll()
        master.input(3).eq.band(1).setGainDB(6)

        let commands = transport.sentCommands
        let eqCommands = commands.filter { $0.contains("eq.b1.gain") }
        XCTAssertEqual(eqCommands.count, 1)
        assertSent("SETD^i.2.eq.b1.gain^0.65")
    }
}
