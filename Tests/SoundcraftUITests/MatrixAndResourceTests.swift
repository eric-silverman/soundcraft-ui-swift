import Combine
import XCTest
@testable import SoundcraftUI

/// Coverage for the Ui24R matrix (MTX) buses and per-client resource lists
/// (playlists / shows / snapshots / cues) added in the parity sync.
final class MatrixAndResourceTests: MixerTestCase {
    private var testMixer: SoundcraftUI?

    // MARK: - Matrix bus routing

    func testMatrixSourceChannelsUseMtxStatePaths() {
        let mtx = mixerMtx(7)

        mtx.aux(1).setFaderLevel(0.5)
        assertSent("SETD^a.0.mtx.6.value^0.5")

        mtx.sub(2).enableMute()
        assertSent("SETD^s.1.mtx.6.mute^1")

        mtx.master().setFaderLevel(0.4)
        assertSent("SETD^m.mtx.6.value^0.4")
    }

    func testMatrixMasterSourceMirrorsStereoLinkedMatrixOutput() {
        // matrix outputs live in `a` slots; linking slot 7 to 8 mirrors the send
        let mtx = mixerMtx(7)
        transport.simulateSetd(path: "a.6.stereoIndex", value: "0")
        drainMainQueue()

        mtx.master().setFaderLevel(0.5)
        assertSent("SETD^m.mtx.6.value^0.5")
        assertSent("SETD^m.mtx.7.value^0.5")
    }

    func testMatrixOutputIsControlledLikeAnAuxOnMaster() {
        // master.mtx(n) is an alias for master.aux(n)
        let mixer = currentMixer
        mixer.master.mtx(1).setFaderLevel(0.6)
        assertSent("SETD^a.0.mix^0.6")
    }

    func testSwitchToMatrixSwitchesSlotAndLinkedNeighbour() {
        let mixer = currentMixer
        transport.simulateSetd(path: "a.0.stereoIndex", value: "0") // slot 1 linked to slot 2
        drainMainQueue()

        mixer.aux(1).switchToMatrix()
        assertSent("SETD^a.0.matrix^1")
        assertSent("SETD^a.1.matrix^1")
    }

    func testSwitchToAuxSwitchesSlotOff() {
        let mixer = currentMixer
        mixer.mtx(3).switchToAux()
        assertSent("SETD^a.2.matrix^0")
    }

    func testAuxAndMatrixBusesShareCachedInstances() {
        let mixer = currentMixer
        // conn.mtx(n) and aux.switchToMatrix() resolve to the same MtxBus
        let mtxA = mixer.mtx(1)
        let mtxB = mixer.aux(1).switchToMatrix()
        XCTAssertTrue(mtxA === mtxB)

        // conn.aux(n) and mtx.switchToAux() resolve to the same AuxBus
        let auxA = mixer.aux(2)
        let auxB = mixer.mtx(2).switchToAux()
        XCTAssertTrue(auxA === auxB)
    }

    func testAuxSlotNameUsesMatrixDefaultWhenConfiguredAsMatrix() {
        let mixer = currentMixer
        // no custom name set: an AUX slot in matrix mode reads "MTX n"
        transport.simulateSetd(path: "a.0.matrix", value: "1")
        XCTAssertEqual(awaitValue(mixer.master.aux(1).name), "MTX 1")
    }

    func testAuxSlotNameUsesAuxDefaultWhenNotMatrix() {
        let mixer = currentMixer
        transport.simulateSetd(path: "a.0.matrix", value: "0")
        XCTAssertEqual(awaitValue(mixer.master.aux(1).name), "AUX 1")
    }

    func testAuxBusIsMatrixPublisher() {
        let mixer = currentMixer
        transport.simulateSetd(path: "a.0.matrix", value: "1")
        XCTAssertEqual(awaitValue(mixer.aux(1).isMatrix$), true)
    }

    func testMatrixSourceSupportsPostProc() {
        let mtx = mixerMtx(7)
        mtx.aux(1).postProc()
        assertSent("SETD^a.0.mtx.6.postproc^1")
        mtx.aux(1).preProc()
        assertSent("SETD^a.0.mtx.6.postproc^0")
    }

    // MARK: - Resource lists

    func testPlayerExposesPlaylistsAndTracks() {
        let (mixer, mixerTransport) = makeConnectedMixer()
        // refreshPlaylists() runs on connect and subscribed for the PLISTS reply
        mixerTransport.simulateInbound("PLISTS^Rock^Jazz")
        // each playlist's tracks are then requested
        mixerTransport.simulateInbound("PLIST_TRACKS^Rock^t1^t2")
        drainMainQueue()

        XCTAssertEqual(awaitValue(mixer.player.playlists), ["Rock", "Jazz"])
        let withTracks = awaitValue(mixer.player.playlistsWithTracks)
        XCTAssertEqual(withTracks["Rock"], ["t1", "t2"])
        XCTAssertEqual(withTracks["Jazz"], [])

        // refresh is triggered automatically on connect
        XCTAssertTrue(mixerTransport.sentCommands.contains("MEDIA_GET_PLISTS"))
        XCTAssertTrue(mixerTransport.sentCommands.contains("MEDIA_GET_PLIST_TRACKS^Rock"))
    }

    func testShowControllerExposesShowsWithSnapshotsAndCues() {
        let (mixer, mixerTransport) = makeConnectedMixer()
        mixerTransport.simulateInbound("SHOWLIST^ShowA")
        mixerTransport.simulateInbound("SNAPSHOTLIST^ShowA^Snap1^Snap2")
        mixerTransport.simulateInbound("CUELIST^ShowA^Cue1")
        drainMainQueue()

        let shows = awaitValue(mixer.shows.shows)
        XCTAssertEqual(shows["ShowA"]?.snapshots, ["Snap1", "Snap2"])
        XCTAssertEqual(shows["ShowA"]?.cues, ["Cue1"])

        XCTAssertTrue(mixerTransport.sentCommands.contains("SHOWLIST"))
        XCTAssertTrue(mixerTransport.sentCommands.contains("SNAPSHOTLIST^ShowA"))
        XCTAssertTrue(mixerTransport.sentCommands.contains("CUELIST^ShowA"))
    }

    // MARK: - Helpers

    private var currentMixer: SoundcraftUI {
        if let existing = testMixer { return existing }
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        testMixer = mixer
        return mixer
    }

    private func mixerMtx(_ bus: Int) -> MtxBus {
        currentMixer.mtx(bus)
    }
}
