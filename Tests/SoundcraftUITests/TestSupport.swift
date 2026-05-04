import Combine
import XCTest
@testable import SoundcraftUI

class MixerTestCase: XCTestCase {
    var transport: MockWebSocketTransport!
    var conn: MixerConnection!
    var store: MixerStore!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        transport = MockWebSocketTransport()
        conn = MixerConnection(ip: "127.0.0.1", transport: transport)
        store = MixerStore(connection: conn)
        cancellables = Set<AnyCancellable>()
        conn.connect()
    }

    override func tearDown() {
        cancellables = nil
        store = nil
        conn = nil
        transport = nil
        super.tearDown()
    }

    func makeConnectedMixer(ip: String = "127.0.0.1") -> (SoundcraftUI, MockWebSocketTransport) {
        let mixerTransport = MockWebSocketTransport()
        let mixer = SoundcraftUI(ip: ip, transport: mixerTransport)
        mixer.connect()
        return (mixer, mixerTransport)
    }

    func awaitValue<P: Publisher>(
        _ publisher: P,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> P.Output where P.Failure == Never {
        let expectation = expectation(description: "Awaiting publisher output")
        var values = [P.Output]()
        var cancellable: AnyCancellable?

        cancellable = publisher
            .prefix(1)
            .sink { value in
                values.append(value)
                expectation.fulfill()
                cancellable?.cancel()
            }

        wait(for: [expectation], timeout: timeout)
        XCTAssertFalse(values.isEmpty, file: file, line: line)
        return values[0]
    }

    func drainMainQueue(for duration: TimeInterval = 0.05) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: duration))
    }

    func assertSent(
        _ command: String,
        via transport: MockWebSocketTransport? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue((transport ?? self.transport).sentCommands.contains(command), file: file, line: line)
    }
}
