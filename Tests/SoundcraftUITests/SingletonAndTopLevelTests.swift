import Combine
import XCTest
@testable import SoundcraftUI

final class SingletonAndTopLevelTests: XCTestCase {
    func testSoundcraftUISingletonFactoriesReuseInstances() {
        let transport = MockWebSocketTransport()
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()

        XCTAssertTrue(mixer.aux(1) === mixer.aux(1))
        XCTAssertTrue(mixer.fx(1) === mixer.fx(1))
        XCTAssertTrue(mixer.muteGroup(.group(1)) === mixer.muteGroup(.group(1)))
        XCTAssertTrue(mixer.volume.headphone(2) === mixer.volume.headphone(2))
        XCTAssertTrue(mixer.hw(1) === mixer.hw(1))
        XCTAssertTrue(mixer.master.input(1) === mixer.master.input(1))
        XCTAssertTrue(mixer.aux(1).input(1) === mixer.aux(1).input(1))
        XCTAssertTrue(mixer.fx(1).input(1) === mixer.fx(1).input(1))
    }

    func testSoundcraftUIForwardsStatusAndExposesTopLevelCommands() {
        let transport = MockWebSocketTransport()
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        var statuses = [ConnectionStatus]()
        var cancellables = Set<AnyCancellable>()
        let expectation = XCTestExpectation(description: "Top-level status")

        mixer.status
            .prefix(3)
            .sink { status in
                statuses.append(status)
                if statuses.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mixer.connect()
        wait(for: [expectation], timeout: 1)

        mixer.clearMuteGroups()
        transport.simulateSetd(path: "model", value: "ui24")
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        mixer.channelSync.selectChannel(type: .aux, num: 2)

        XCTAssertEqual(statuses, [.close, .opening, .open])
        XCTAssertTrue(transport.sentCommands.contains("SETD^mgmask^0"))
        XCTAssertTrue(transport.sentCommands.contains("BMSG^SYNC^SYNC_ID^39"))
    }
}
