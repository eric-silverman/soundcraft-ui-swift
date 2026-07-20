import Combine
import XCTest
@testable import SoundcraftUI

final class StateAndConnectionTests: MixerTestCase {
    func testStateSelectorsCoverMasterChannelBusAndVolumeValues() {
        transport.simulateSetd(path: "m.mix", value: "0.8")
        transport.simulateSetd(path: "m.pan", value: "0.4")
        transport.simulateSetd(path: "m.dim", value: "1")
        transport.simulateSetd(path: "m.delayL", value: "0.25")
        transport.simulateSetd(path: "i.0.mix", value: "0.5")
        transport.simulateSetd(path: "i.0.aux.0.value", value: "0.6")
        transport.simulateSetd(path: "i.0.fx.0.value", value: "0.7")
        transport.simulateSetd(path: "i.0.mute", value: "1")
        transport.simulateSetd(path: "i.0.solo", value: "1")
        transport.simulateSetd(path: "i.0.pan", value: "0.2")
        transport.simulateSetd(path: "i.0.stereoIndex", value: "0")
        transport.simulateSetd(path: "i.0.aux.0.post", value: "1")
        transport.simulateSetd(path: "i.0.aux.0.postproc", value: "1")
        transport.simulateSetd(path: "i.0.delay", value: "0.1")
        transport.simulateSetd(path: "f.0.fxtype", value: "3")
        transport.simulateSetd(path: "f.0.bpm", value: "140")
        transport.simulateSetd(path: "settings.solovol", value: "0.9")
        transport.simulateSetd(path: "settings.hpvol.1", value: "0.65")

        XCTAssertEqual(awaitValue(store.masterValue), 0.8, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.masterPan), 0.4, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.masterDim), true)
        XCTAssertEqual(awaitValue(store.masterDelay(side: "L")), 250, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.faderValue(channelType: .input, channel: 1, busType: .master)), 0.5, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.faderValue(channelType: .input, channel: 1, busType: .aux, bus: 1)), 0.6, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.faderValue(channelType: .input, channel: 1, busType: .fx, bus: 1)), 0.7, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.muteValue(channelType: .input, channel: 1, busType: .master)), true)
        XCTAssertEqual(awaitValue(store.soloValue(channelType: .input, channel: 1)), true)
        XCTAssertEqual(awaitValue(store.panValue(channelType: .input, channel: 1, busType: .master)), 0.2, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.stereoIndex(channelType: .input, channel: 1)), 0)
        XCTAssertEqual(awaitValue(store.stereoIndex(channelType: .sub, channel: 1)), -1)
        XCTAssertEqual(awaitValue(store.postValue(channelType: .input, channel: 1, busType: .aux, bus: 1)), true)
        XCTAssertEqual(awaitValue(store.postProc(channelType: .input, channel: 1, busType: .aux, bus: 1)), true)
        XCTAssertEqual(awaitValue(store.delayValue(channelType: .input, channel: 1)), 100, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.fxType(bus: 1)), 3)
        XCTAssertEqual(awaitValue(store.fxBpm(bus: 1)), 140)
        XCTAssertEqual(awaitValue(store.volumeBusValue(busName: "solovol")), 0.9, accuracy: 0.001)
        XCTAssertEqual(awaitValue(store.volumeBusValue(busName: "hpvol", busId: 1)), 0.65, accuracy: 0.001)
    }

    func testStateSelectorsDerivePlayerAndMultitrackTimes() {
        transport.simulateSetd(path: "var.currentTrackPos", value: "0.25")
        transport.simulateSetd(path: "var.currentLength", value: "200.0")
        transport.simulateSetd(path: "var.mtk.currentTrackPos", value: "0.1")
        transport.simulateSetd(path: "var.mtk.currentLength", value: "300.0")

        XCTAssertEqual(awaitValue(store.playerElapsedTime), 50)
        XCTAssertEqual(awaitValue(store.playerRemainingTime), 150)
        XCTAssertEqual(awaitValue(store.mtkElapsedTime), 30)
        XCTAssertEqual(awaitValue(store.mtkRemainingTime), 270)
    }

    func testObjectStoreStoresAndReturnsTypedInstances() {
        let objectStore = ObjectStore()
        let value = NSObject()

        objectStore.set("test", value)

        let loaded: NSObject? = objectStore.get("test")
        let missing: NSString? = objectStore.get("missing")

        XCTAssertTrue(loaded === value)
        XCTAssertNil(missing)
    }

    func testMixerConnectionPublishesStatusAndFramesOutboundMessages() {
        let transport = MockWebSocketTransport()
        let connection = MixerConnection(ip: "127.0.0.1", transport: transport)
        var statuses = [ConnectionStatus]()
        let expectation = expectation(description: "Status transitions")

        connection.status
            .prefix(3)
            .sink { status in
                statuses.append(status)
                if statuses.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        connection.connect()
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(statuses, [.close, .opening, .open])
        XCTAssertEqual(transport.lastConnectedURL?.absoluteString, "ws://127.0.0.1")

        var outbound: [String] = []
        connection.outbound
            .prefix(1)
            .sink { outbound.append($0) }
            .store(in: &cancellables)

        connection.sendMessage("PING")

        XCTAssertEqual(outbound, ["PING"])
        XCTAssertEqual(transport.sentMessages.last, "3:::PING")
    }

    func testMixerConnectionSplitsInboundLinesAndPublishesAllMessages() {
        let transport = MockWebSocketTransport()
        let connection = MixerConnection(ip: "127.0.0.1", transport: transport)
        var inbound = [String]()
        var all = [String]()
        let inboundExpectation = expectation(description: "Inbound split")
        let allExpectation = expectation(description: "All messages")

        connection.inbound
            .prefix(2)
            .sink { message in
                inbound.append(message)
                if inbound.count == 2 {
                    inboundExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        connection.allMessages
            .prefix(3)
            .sink { message in
                all.append(message)
                if all.count == 3 {
                    allExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        connection.connect()
        connection.sendMessage("PING")
        transport.simulateInbound("SETD^a^1\nSETD^b^2")

        wait(for: [inboundExpectation, allExpectation], timeout: 1)

        XCTAssertEqual(inbound, ["SETD^a^1", "SETD^b^2"])
        XCTAssertEqual(all, ["PING", "SETD^a^1", "SETD^b^2"])
    }

    func testMixerConnectionReconnectsAfterExplicitReconnectCall() {
        let transport = MockWebSocketTransport()
        let connection = MixerConnection(ip: "127.0.0.1", transport: transport)
        let expectation = expectation(description: "Reconnect invoked")

        connection.connect()
        XCTAssertEqual(transport.connectCallCount, 1)

        connection.reconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            XCTAssertEqual(transport.disconnectCallCount, 1)
            XCTAssertGreaterThanOrEqual(transport.connectCallCount, 2)
            XCTAssertEqual(connection.currentStatus, .open)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }
}
