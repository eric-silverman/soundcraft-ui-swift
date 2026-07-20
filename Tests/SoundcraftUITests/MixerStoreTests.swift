import Combine
import XCTest
@testable import SoundcraftUI

final class MixerStoreTests: XCTestCase {
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

    func testStateAccumulatesSetdMessages() {
        let expectation = XCTestExpectation(description: "State updated")

        store.state
            .dropFirst() // skip initial empty state
            .first()
            .sink { state in
                XCTAssertEqual(state["i.0.mute"] as? Int, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        transport.simulateSetd(path: "i.0.mute", value: "1")
        wait(for: [expectation], timeout: 1)
    }

    func testStateAccumulatesMultipleMessages() {
        let expectation = XCTestExpectation(description: "Multiple states")

        transport.simulateSetd(path: "i.0.mix", value: "0.5")
        transport.simulateSetd(path: "i.1.mix", value: "0.75")
        transport.simulateSetd(path: "i.0.mute", value: "1")

        // Give a small delay for scan to accumulate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.state.value
            XCTAssertEqual(state["i.0.mix"] as? Double, 0.5)
            XCTAssertEqual(state["i.1.mix"] as? Double, 0.75)
            XCTAssertEqual(state["i.0.mute"] as? Int, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testTransformStringValue_int() {
        let result = transformStringValue("42")
        XCTAssertTrue(result is Int)
        XCTAssertEqual(result as? Int, 42)
    }

    func testTransformStringValue_negativeInt() {
        let result = transformStringValue("-1")
        XCTAssertTrue(result is Int)
        XCTAssertEqual(result as? Int, -1)
    }

    func testTransformStringValue_float() {
        let result = transformStringValue("0.76470588235")
        XCTAssertTrue(result is Double)
        XCTAssertEqual(result as! Double, 0.76470588235, accuracy: 0.0000001)
    }

    func testTransformStringValue_negativeFloat() {
        let result = transformStringValue("-0.25")
        XCTAssertTrue(result is Double)
        XCTAssertEqual(result as! Double, -0.25, accuracy: 0.0000001)
    }

    func testTransformStringValue_string() {
        let result = transformStringValue("VOCALS")
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, "VOCALS")
    }

    func testSetdConvertsIntFloatAndNegativeValues() {
        let expectation = XCTestExpectation(description: "SETD numeric conversion")

        transport.simulateSetd(path: "i.3.mute", value: "1")
        transport.simulateSetd(path: "i.3.mix", value: "0.5236732")
        transport.simulateSetd(path: "i.3.pan", value: "-0.25")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.state.value
            XCTAssertEqual(state["i.3.mute"] as? Int, 1)
            XCTAssertEqual(state["i.3.mix"] as? Double, 0.5236732)
            XCTAssertEqual(state["i.3.pan"] as? Double, -0.25)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSetsKeepsValueContainingSeparator() {
        let expectation = XCTestExpectation(description: "SETS keeps ^ in value")

        transport.simulateInbound("SETS^i.3.name^foo^bar")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.state.value
            XCTAssertEqual(state["i.3.name"] as? String, "foo^bar")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSetsMessages() {
        let expectation = XCTestExpectation(description: "SETS processed")

        transport.simulateInbound("SETS^i.0.name^VOCALS")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.state.value
            XCTAssertEqual(state["i.0.name"] as? String, "VOCALS")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSetsKeepsNumericLookingValuesAsStrings() {
        // SETD values are numeric, SETS values are always strings — so a SETS value
        // that looks numeric (e.g. a session name "0001") must stay a string.
        let expectation = XCTestExpectation(description: "SETS numeric kept as string")

        transport.simulateInbound("SETS^var.mtk.session^0001")
        transport.simulateSetd(path: "i.0.mute", value: "1")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.state.value
            XCTAssertEqual(state["var.mtk.session"] as? String, "0001")
            XCTAssertNil(state["var.mtk.session"] as? Int)
            XCTAssertEqual(state["i.0.mute"] as? Int, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testResourceListStateStoresFlatAndKeyedLists() {
        let expectation = XCTestExpectation(description: "Resource lists accumulated")

        // flat list
        transport.simulateInbound("PLISTS^Rock^Jazz")
        // keyed list
        transport.simulateInbound("PLIST_TRACKS^Rock^t1^t2")
        // empty keyed list (trailing separator, no entries)
        transport.simulateInbound("CUELIST^Default^")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.resourceListState.value
            XCTAssertEqual(state["PLISTS"], ["Rock", "Jazz"])
            XCTAssertEqual(state["PLIST_TRACKS^Rock"], ["t1", "t2"])
            XCTAssertEqual(state["CUELIST^Default"], [])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSelectWithDefault() {
        let expectation = XCTestExpectation(description: "Select default")

        store.select(path: "nonexistent.path", default: 42)
            .first()
            .sink { value in
                XCTAssertEqual(value, 42)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func testSyncState() {
        let expectation = XCTestExpectation(description: "Sync state")

        transport.simulateInbound("BMSG^SYNC^SYNC_ID^5")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let state = self.store.syncState.value
            XCTAssertEqual(state["SYNC_ID"], 5)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
