import XCTest
@testable import SoundcraftUI

final class FacadeParityTests: MixerTestCase {
    func testAuxChannelPanMirrorsLinkedAuxBus() {
        let channel = AuxChannel.resolve(conn: conn, store: store, channelType: .input, channel: 1, bus: 1)

        transport.simulateSetd(path: "a.0.stereoIndex", value: "0")
        drainMainQueue()

        channel.setPan(0.65)

        assertSent("SETD^i.0.aux.0.pan^0.65")
        assertSent("SETD^i.0.aux.1.pan^0.65")
    }

    func testAuxChannelPostProcMirrorsAllLinkedTargets() {
        let channel = AuxChannel.resolve(conn: conn, store: store, channelType: .input, channel: 1, bus: 1)

        transport.simulateSetd(path: "a.0.stereoIndex", value: "0")
        transport.simulateSetd(path: "i.0.stereoIndex", value: "0")
        drainMainQueue()

        channel.setPostProc(true)

        assertSent("SETD^i.0.aux.0.postproc^1")
        assertSent("SETD^i.1.aux.0.postproc^1")
        assertSent("SETD^i.0.aux.1.postproc^1")
        assertSent("SETD^i.1.aux.1.postproc^1")
    }

    func testVolumeBusHeadphonePublishesNameAndUsesIndexedPath() {
        let headphone = VolumeBus.resolve(conn: conn, store: store, busName: .hpvol, busId: 2)

        XCTAssertEqual(awaitValue(headphone.name), "HEADPHONE 2 LEVEL")

        transport.simulateSetd(path: "settings.hpvol.1", value: "0.5")
        headphone.changeFaderLevel(0.25)

        assertSent("SETD^settings.hpvol.1^0.75")
    }

    func testAutomixGroupToggleUsesCurrentState() {
        let automix = AutomixController(conn: conn, store: store)

        transport.simulateSetd(path: "automix.a.on", value: "1")
        automix.groups.a.toggle()

        assertSent("SETD^automix.a.on^0")
    }

    func testAutomixResponseTimePublisherAndMillisecondsSetter() {
        let automix = AutomixController(conn: conn, store: store)

        transport.simulateSetd(path: "automix.time", value: "0.5")

        XCTAssertEqual(awaitValue(automix.responseTimeMs), faderValueToTimeMs(0.5))

        automix.setResponseTimeMs(4000)
        assertSent("SETD^automix.time^\(timeMsToFaderValue(4000))")
    }

    func testMuteGroupPublishesStateAndUpdatesMask() {
        let group = MuteGroup.resolve(conn: conn, store: store, id: .group(2))

        transport.simulateSetd(path: "mgmask", value: "2")
        XCTAssertEqual(awaitValue(group.state), true)

        transport.sentMessages.removeAll()
        group.toggle()
        assertSent("SETD^mgmask^0")

        transport.simulateSetd(path: "mgmask", value: "0")
        transport.sentMessages.removeAll()
        group.mute()
        assertSent("SETD^mgmask^2")
    }

    func testDeviceInfoPublishesModelCapabilitiesFirmwareAndCurrentModel() {
        let deviceInfo = DeviceInfo(store: store)

        transport.simulateSetd(path: "model", value: "ui24")
        transport.simulateSetd(path: "firmware", value: "3.5.1")

        XCTAssertEqual(awaitValue(deviceInfo.model), .some(.ui24))
        XCTAssertEqual(awaitValue(deviceInfo.capabilities)?.input, 24)
        XCTAssertEqual(awaitValue(deviceInfo.capabilities)?.vca, 6)
        XCTAssertEqual(awaitValue(deviceInfo.firmware), .some("3.5.1"))
        XCTAssertEqual(deviceInfo.currentModel, .some(.ui24))
    }

    func testFxBusSupportsTypeBypassStereoAndMuteControls() {
        let fx = FxBus.resolve(conn: conn, store: store, bus: 1)

        transport.simulateSetd(path: "f.0.fxtype", value: "1")
        transport.simulateSetd(path: "f.0.smix", value: "0.25")
        transport.simulateSetd(path: "f.0.span", value: "0.75")

        XCTAssertEqual(awaitValue(fx.fxType), .delay)
        XCTAssertEqual(awaitValue(fx.stereoMix()), 0.25)
        XCTAssertEqual(awaitValue(fx.stereoPan()), 0.75)

        fx.setFxType(.chorus)
        fx.setBypass(1)
        fx.setStereoMix(1.5)
        fx.setStereoPan(-0.5)
        fx.setMute(1)

        assertSent("SETD^f.0.fxtype^2")
        assertSent("SETD^f.0.bypass^1")
        assertSent("SETD^f.0.smix^1.0")
        assertSent("SETD^f.0.span^0.0")
        assertSent("SETD^f.0.mute^1")
    }

    func testDelayableMasterChannelPublishesMillisecondsAndClampsByChannelType() {
        let input = DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .input, channel: 1)
        let aux = DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .aux, channel: 1)

        transport.simulateSetd(path: "i.0.delay", value: "0.12")
        XCTAssertEqual(awaitValue(input.delay), 120, accuracy: 0.001)

        transport.sentMessages.removeAll()
        input.changeDelay(50)
        assertSent("SETD^i.0.delay^0.17")

        aux.setDelay(600)
        assertSent("SETD^a.0.delay^0.5")
    }

    func testMasterChannelMirrorsLinkedControlsAndSupportsAutomixAndMultitrack() {
        let channel = DelayableMasterChannel.resolveDelayable(conn: conn, store: store, channelType: .input, channel: 1)

        transport.simulateSetd(path: "i.0.stereoIndex", value: "0")
        drainMainQueue()

        channel.setPan(0.3)
        assertSent("SETD^i.0.pan^0.3")

        transport.sentMessages.removeAll()
        channel.setSolo(true)
        assertSent("SETD^i.0.solo^1")
        assertSent("SETD^i.1.solo^1")

        transport.sentMessages.removeAll()
        channel.automixAssignGroup(.b)
        assertSent("SETD^i.0.amixgroup^1")
        assertSent("SETD^i.1.amixgroup^1")

        transport.simulateSetd(path: "i.0.amix", value: "0.5")
        XCTAssertEqual(awaitValue(channel.automixWeightDB), 0, accuracy: 0.001)

        transport.sentMessages.removeAll()
        channel.automixSetWeightDB(6)
        let weight = linearMappingRangeToValue(6, lowerBound: -12, upperBound: 12)
        assertSent("SETD^i.0.amix^\(weight)")
        assertSent("SETD^i.1.amix^\(weight)")

        transport.simulateSetd(path: "i.0.mtkrec", value: "1")
        transport.sentMessages.removeAll()
        channel.multiTrackToggle()
        assertSent("SETD^i.0.mtkrec^0")
    }

    func testMasterBusRelativeControlsUseCurrentState() {
        let master = MasterBus(conn: conn, store: store)

        transport.simulateSetd(path: "m.mix", value: "0.5")
        transport.simulateSetd(path: "m.dim", value: "1")
        transport.simulateSetd(path: "m.delayR", value: "0.1")

        transport.sentMessages.removeAll()
        master.changeFaderLevel(0.25)
        assertSent("SETD^m.mix^0.75")

        transport.sentMessages.removeAll()
        master.toggleDim()
        assertSent("SETD^m.dim^0")

        transport.sentMessages.removeAll()
        master.changeDelayR(50)
        assertSent("SETD^m.delayR^0.15")
    }

    func testFxChannelMirrorsStereoLinkedSendControls() {
        let channel = FxChannel.resolve(conn: conn, store: store, channelType: .input, channel: 1, bus: 1)

        transport.simulateSetd(path: "i.0.stereoIndex", value: "0")
        drainMainQueue()

        channel.setFaderLevel(0.4)
        channel.setPost(true)

        assertSent("SETD^i.0.fx.0.value^0.4")
        assertSent("SETD^i.1.fx.0.value^0.4")
        assertSent("SETD^i.0.fx.0.post^1")
        assertSent("SETD^i.1.fx.0.post^1")
    }

    func testHwChannelUsesModelDependentPathsAndGainConversions() {
        let deviceInfo = DeviceInfo(store: store)
        let hw = HwChannel.resolve(conn: conn, store: store, deviceInfo: deviceInfo, channel: 1)

        transport.simulateSetd(path: "model", value: "ui16")
        transport.simulateSetd(path: "i.0.gain", value: "0.5")
        drainMainQueue()

        XCTAssertEqual(awaitValue(hw.gainDB), 5.0, accuracy: 0.001)

        transport.sentMessages.removeAll()
        hw.phantomOn()
        assertSent("SETD^i.0.phantom^1")

        transport.sentMessages.removeAll()
        hw.setGainDB(50)
        assertSent("SETD^i.0.gain^\(linearMappingRangeToValue(50, lowerBound: -40, upperBound: 50))")
    }
}
