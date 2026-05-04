import XCTest
@testable import SoundcraftUI

final class DSPAndSettingsTests: MixerTestCase {
    func testParametricEQPublishesAndClampsBandAndFilterControls() {
        let channel = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        let eq = channel.eq()

        transport.simulateSetd(path: "i.0.eq.bypass", value: "1")
        transport.simulateSetd(path: "i.0.eq.easy", value: "1")
        transport.simulateSetd(path: "i.0.eq.b3.gain", value: "0.6")
        transport.simulateSetd(path: "i.0.eq.hpf.slope", value: "4")

        XCTAssertEqual(awaitValue(eq.bypass), 1)
        XCTAssertEqual(awaitValue(eq.easyMode), 1)
        XCTAssertEqual(awaitValue(eq.bandGain(3)), 0.6, accuracy: 0.001)
        XCTAssertEqual(awaitValue(eq.hpfSlope), 4)

        eq.setBandGain(3, value: 1.5)
        eq.setBandFreq(3, value: -1)
        eq.setBandQ(3, value: 0.25)
        eq.setBandEnabled(3, value: 1)
        eq.setHpfSlope(9)
        eq.setLpfFreq(2)

        assertSent("SETD^i.0.eq.b3.gain^1.0")
        assertSent("SETD^i.0.eq.b3.freq^0.0")
        assertSent("SETD^i.0.eq.b3.q^0.25")
        assertSent("SETD^i.0.eq.b3.on^1")
        assertSent("SETD^i.0.eq.hpf.slope^4")
        assertSent("SETD^i.0.eq.lpf.freq^1.0")
    }

    func testGraphicEQSupportsMasterAndAuxPaths() {
        let master = MasterBus(conn: conn, store: store)
        let aux = AuxBus.resolve(conn: conn, store: store, bus: 1)
        let masterEQ = master.graphicEQ()
        let auxEQ = aux.graphicEQ()

        transport.simulateSetd(path: "m.eq.linked", value: "1")
        transport.simulateSetd(path: "m.eq.peak.l.5", value: "0.25")
        transport.simulateSetd(path: "a.0.eq.peak.7", value: "0.8")

        XCTAssertEqual(awaitValue(masterEQ.linked), 1)
        XCTAssertEqual(awaitValue(masterEQ.bandValue(5)), 0.25, accuracy: 0.001)
        XCTAssertEqual(awaitValue(auxEQ.bandValue(7)), 0.8, accuracy: 0.001)

        masterEQ.setBandValue(5, side: "r", value: 1.5)
        masterEQ.setLinked(0)
        masterEQ.setHpf(side: "r", value: 0.2)
        auxEQ.setBandValue(7, value: -1)
        auxEQ.setLpf(value: 2)

        assertSent("SETD^m.eq.peak.r.5^1.0")
        assertSent("SETD^m.eq.linked^0")
        assertSent("SETD^m.eq.hpf.r^0.2")
        assertSent("SETD^a.0.eq.peak.7^0.0")
        assertSent("SETD^a.0.eq.lpf^1.0")
    }

    func testDynamicsSupportsChannelAndMasterSpecificControls() {
        let inputChannel = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        let master = MasterBus(conn: conn, store: store)
        let channelDynamics = inputChannel.dynamics()
        let masterDynamics = master.dynamics()

        transport.simulateSetd(path: "i.0.dyn.threshold", value: "0.25")
        transport.simulateSetd(path: "i.0.dyn.prmod", value: "1")
        transport.simulateSetd(path: "i.0.dyn.prname", value: "VOCAL")
        transport.simulateSetd(path: "m.dyn.linked", value: "1")
        transport.simulateSetd(path: "m.dyn.r.attack", value: "0.8")

        XCTAssertEqual(awaitValue(channelDynamics.threshold()), 0.25, accuracy: 0.001)
        XCTAssertEqual(awaitValue(channelDynamics.prmod), 1)
        XCTAssertEqual(awaitValue(channelDynamics.prname), "VOCAL")
        XCTAssertEqual(awaitValue(masterDynamics.linked), 1)
        XCTAssertEqual(awaitValue(masterDynamics.attack(side: "r")), 0.8, accuracy: 0.001)

        channelDynamics.setThreshold(value: 1.5)
        channelDynamics.setPrmod(2)
        channelDynamics.setBypass(1)
        masterDynamics.setAttack(side: "r", value: -1)
        masterDynamics.setLinked(0)

        assertSent("SETD^i.0.dyn.threshold^1.0")
        assertSent("SETD^i.0.dyn.prmod^2")
        assertSent("SETD^i.0.dyn.bypass^1")
        assertSent("SETD^m.dyn.r.attack^0.0")
        assertSent("SETD^m.dyn.linked^0")
    }

    func testGatePublishesAndSendsCoreControls() {
        let gate = Channel(conn: conn, store: store, channelType: .input, channel: 1).gate()

        transport.simulateSetd(path: "i.0.gate.enabled", value: "1")
        transport.simulateSetd(path: "i.0.gate.thresh", value: "0.35")

        XCTAssertEqual(awaitValue(gate.enabled), 1)
        XCTAssertEqual(awaitValue(gate.threshold), 0.35, accuracy: 0.001)

        gate.setThreshold(1.5)
        gate.setBypass(1)
        gate.setPrmod(2)
        gate.setSoftknee(1)

        assertSent("SETD^i.0.gate.thresh^1.0")
        assertSent("SETD^i.0.gate.bypass^1")
        assertSent("SETD^i.0.gate.prmod^2")
        assertSent("SETD^i.0.gate.softknee^1")
    }

    func testDeesserIsInputOnlyAndSupportsPublishersAndSetters() {
        let input = DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .input, channel: 1)
        let fx = MasterChannel.resolve(conn: conn, store: store, channelType: .fx, channel: 1)
        guard let deesser = input.deesser() else {
            XCTFail("Expected input channel deesser")
            return
        }

        XCTAssertNil(fx.deesser())

        transport.simulateSetd(path: "i.0.deesser.enabled", value: "1")
        transport.simulateSetd(path: "i.0.deesser.freq", value: "0.75")

        XCTAssertEqual(awaitValue(deesser.enabled), 1)
        XCTAssertEqual(awaitValue(deesser.freq), 0.75, accuracy: 0.001)

        deesser.setRatio(1.5)
        deesser.setThreshold(-1)

        assertSent("SETD^i.0.deesser.ratio^1.0")
        assertSent("SETD^i.0.deesser.threshold^0.0")
    }

    func testDigitechIsInputOnlyAndSupportsPublishersAndSetters() {
        let input = DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .input, channel: 1)
        let aux = DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .aux, channel: 1)
        guard let digitech = input.digitech() else {
            XCTFail("Expected input channel digitech")
            return
        }

        XCTAssertNil(aux.digitech())

        transport.simulateSetd(path: "i.0.digitech.enabled", value: "1")
        transport.simulateSetd(path: "i.0.digitech.amp", value: "4")

        XCTAssertEqual(awaitValue(digitech.enabled), 1)
        XCTAssertEqual(awaitValue(digitech.amp), 4)

        digitech.setCab(3)
        digitech.setBass(1.5)
        digitech.setTreble(-1)

        assertSent("SETD^i.0.digitech.cab^3")
        assertSent("SETD^i.0.digitech.bass^1.0")
        assertSent("SETD^i.0.digitech.treble^0.0")
    }

    func testGlobalSettingsPublishesSystemValuesAndRoutingPaths() {
        let settings = GlobalSettings(conn: conn, store: store)

        transport.simulateSetd(path: "afs.enabled", value: "1")
        transport.simulateSetd(path: "settings.solotype", value: "2")
        transport.simulateSetd(path: "settings.clock", value: "1")
        transport.simulateSetd(path: "usbdaw.0.src", value: "5")
        transport.simulateSetd(path: "hwouthp.0.src", value: "6")
        transport.simulateSetd(path: "settings.mtkformat", value: "3")

        XCTAssertEqual(awaitValue(settings.afsEnabled), 1)
        XCTAssertEqual(awaitValue(settings.soloType), 2)
        XCTAssertEqual(awaitValue(settings.clock), 1)
        XCTAssertEqual(awaitValue(settings.usbDawSrc(1)), 5)
        XCTAssertEqual(awaitValue(settings.hwOutHpSrc(1)), 6)
        XCTAssertEqual(awaitValue(settings.mtkFormat), 3)

        settings.setAfsEnabled(0)
        settings.setSoloType(0)
        settings.setSoloMode(1)
        settings.setMultipleSolo(1)
        settings.setClock(2)
        settings.setUsbDawSrc(1, value: 9)
        settings.setHwOutHpSrc(1, value: 6)
        settings.setHwOutMainSrc(1, value: 4)
        settings.setHwOutAuxSrc(1, value: 7)
        settings.setPedal(2)
        settings.setF1(3)
        settings.setF2(4)
        settings.setMtkFormat(1)

        assertSent("SETD^afs.enabled^0")
        assertSent("SETD^settings.solotype^0")
        assertSent("SETD^settings.soloMode^1")
        assertSent("SETD^settings.multiplesolo^1")
        assertSent("SETD^settings.clock^2")
        assertSent("SETD^usbdaw.0.src^9")
        assertSent("SETD^hwouthp.0.src^6")
        assertSent("SETD^hwoutm.0.src^4")
        assertSent("SETD^hwoutaux.0.src^7")
        assertSent("SETD^settings.pedal^2")
        assertSent("SETD^settings.f1^3")
        assertSent("SETD^settings.f2^4")
        assertSent("SETD^settings.mtkformat^1")
    }

    func testMasterAndAuxDSPAccessorsExposeCachedProcessorsAndAFSControls() {
        let master = MasterBus(conn: conn, store: store)
        let aux = AuxBus.resolve(conn: conn, store: store, bus: 1)

        XCTAssertTrue(master.graphicEQ() === master.graphicEQ())
        XCTAssertTrue(master.dynamics() === master.dynamics())
        XCTAssertTrue(aux.graphicEQ() === aux.graphicEQ())

        transport.simulateSetd(path: "m.l.invert", value: "1")
        transport.simulateSetd(path: "a.0.afs.enabled", value: "1")

        XCTAssertEqual(awaitValue(master.invertL), 1)
        XCTAssertEqual(awaitValue(aux.afsEnabled), 1)

        master.setInvertR(1)
        master.setAfsEnabled(1)
        aux.setAfsEnabled(0)

        assertSent("SETD^m.r.invert^1")
        assertSent("SETD^m.afs.enabled^1")
        assertSent("SETD^a.0.afs.enabled^0")
    }
}
