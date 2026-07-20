import Combine
import XCTest
@testable import SoundcraftUI

final class ChannelTests: XCTestCase {
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

    // MARK: - Master Bus

    func testMasterBusSetFaderLevel() {
        let master = MasterBus(conn: conn, store: store)
        master.setFaderLevel(0.5)

        XCTAssertTrue(transport.sentCommands.contains("SETD^m.mix^0.5"))
    }

    func testMasterBusSetPan() {
        let master = MasterBus(conn: conn, store: store)
        master.setPan(0.75)

        XCTAssertTrue(transport.sentCommands.contains("SETD^m.pan^0.75"))
    }

    func testMasterBusSetDim() {
        let master = MasterBus(conn: conn, store: store)
        master.setDim(true)

        XCTAssertTrue(transport.sentCommands.contains("SETD^m.dim^1"))
    }

    func testMasterBusSetDelay() {
        let master = MasterBus(conn: conn, store: store)
        master.setDelayL(100)

        // 100ms = 0.1s
        XCTAssertTrue(transport.sentCommands.contains("SETD^m.delayL^0.1"))
    }

    // MARK: - Channel

    func testChannelSetFaderLevel() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setFaderLevel(0.5)

        XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.mix^0.5"))
    }

    func testChannelClampsFaderLevel() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setFaderLevel(1.5)

        XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.mix^1.0"))
    }

    func testChannelSetMute() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 3)
        ch.setMute(true)

        XCTAssertTrue(transport.sentCommands.contains("SETD^i.2.mute^1"))
    }

    func testChannelSetName() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setName("vocals")

        XCTAssertTrue(transport.sentCommands.contains("SETS^i.0.name^VOCALS"))
    }

    func testChannelSetNameSanitized() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setName("test^name")

        XCTAssertTrue(transport.sentCommands.contains("SETS^i.0.name^TESTNAME"))
    }

    func testChannelChangeFaderLevel() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        transport.simulateSetd(path: "i.0.mix", value: "0.5")
        ch.changeFaderLevel(0.1)

        let sent = transport.sentCommands.first { $0.hasPrefix("SETD^i.0.mix^") }
        XCTAssertNotNil(sent)
        if let sent {
            let value = Double(sent.components(separatedBy: "^").last ?? "")
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, 0.6, accuracy: 0.001)
        }
    }

    func testChannelChangeFaderLevelClampsToOne() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        transport.simulateSetd(path: "i.0.mix", value: "0.9")
        ch.changeFaderLevel(0.5)

        let sent = transport.sentCommands.first { $0.hasPrefix("SETD^i.0.mix^") }
        XCTAssertNotNil(sent)
        if let sent {
            let value = Double(sent.components(separatedBy: "^").last ?? "")
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, 1.0, accuracy: 0.001)
        }
    }

    func testChannelChangeFaderLevelClampsToZero() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        transport.simulateSetd(path: "i.0.mix", value: "0.1")
        ch.changeFaderLevel(-0.5)

        let sent = transport.sentCommands.first { $0.hasPrefix("SETD^i.0.mix^") }
        XCTAssertNotNil(sent)
        if let sent {
            let value = Double(sent.components(separatedBy: "^").last ?? "")
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, 0.0, accuracy: 0.001)
        }
    }

    func testChannelSetFaderLevelDB() {
        let ch = Channel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setFaderLevelDB(0) // 0 dB should send ~0.7647

        let sent = transport.sentCommands.first { $0.hasPrefix("SETD^i.0.mix^") }
        XCTAssertNotNil(sent)
        if let sent {
            let value = Double(sent.components(separatedBy: "^").last ?? "")
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, 0.76470588235, accuracy: 0.001)
        }
    }

    // MARK: - MasterChannel

    func testMasterChannelSolo() {
        let ch = MasterChannel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setSolo(true)

        XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.solo^1"))
    }

    func testMasterChannelSetPan() {
        let ch = MasterChannel(conn: conn, store: store, channelType: .input, channel: 1)
        ch.setPan(0.3)

        XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.pan^0.3"))
    }

    // MARK: - SendChannel

    func testSendChannelPath() {
        let ch = SendChannel(conn: conn, store: store, channelType: .input, channel: 2, busType: .aux, bus: 3)
        ch.setFaderLevel(0.5)

        // Should use value (not mix) for send channels
        XCTAssertTrue(transport.sentCommands.contains("SETD^i.1.aux.2.value^0.5"))
    }

    func testSendChannelPost() {
        let ch = SendChannel(conn: conn, store: store, channelType: .input, channel: 1, busType: .aux, bus: 1)
        ch.setPost(true)

        XCTAssertTrue(transport.sentCommands.contains("SETD^i.0.aux.0.post^1"))
    }

    // MARK: - Player

    func testPlayerCommands() {
        let player = Player(conn: conn, store: store)
        player.play()
        player.pause()
        player.stop()
        player.next()
        player.prev()

        let commands = transport.sentCommands
        XCTAssertTrue(commands.contains("MEDIA_PLAY"))
        XCTAssertTrue(commands.contains("MEDIA_PAUSE"))
        XCTAssertTrue(commands.contains("MEDIA_STOP"))
        XCTAssertTrue(commands.contains("MEDIA_NEXT"))
        XCTAssertTrue(commands.contains("MEDIA_PREV"))
    }

    func testPlayerLoadPlaylist() {
        let player = Player(conn: conn, store: store)
        player.loadPlaylist("My Playlist")

        XCTAssertTrue(transport.sentCommands.contains("MEDIA_SWITCH_PLIST^My Playlist"))
    }

    func testPlayerLoadTrack() {
        let player = Player(conn: conn, store: store)
        player.loadTrack(playlist: "Playlist", track: "Song.mp3")

        XCTAssertTrue(transport.sentCommands.contains("MEDIA_SWITCH_TRACK^Playlist^Song.mp3"))
    }

    // MARK: - Show Controller

    func testShowControllerCommands() {
        let shows = ShowController(conn: conn, store: store)
        shows.loadShow("MyShow")
        shows.loadSnapshot(show: "MyShow", snapshot: "Snap1")
        shows.loadCue(show: "MyShow", cue: "Cue1")
        shows.saveSnapshot(show: "MyShow", snapshot: "Snap1")
        shows.saveCue(show: "MyShow", cue: "Cue1")

        let commands = transport.sentCommands
        XCTAssertTrue(commands.contains("LOADSHOW^MyShow"))
        XCTAssertTrue(commands.contains("LOADSNAPSHOT^MyShow^Snap1"))
        XCTAssertTrue(commands.contains("LOADCUE^MyShow^Cue1"))
        XCTAssertTrue(commands.contains("SAVESNAPSHOT^MyShow^Snap1"))
        XCTAssertTrue(commands.contains("SAVECUE^MyShow^Cue1"))
    }

    // MARK: - Multitrack Recorder

    func testMultiTrackRecorderCommands() {
        let mtk = MultiTrackRecorder(conn: conn, store: store)
        mtk.play()
        mtk.pause()
        mtk.stop()
        mtk.recordToggle()

        let commands = transport.sentCommands
        XCTAssertTrue(commands.contains("MTK_PLAY"))
        XCTAssertTrue(commands.contains("MTK_PAUSE"))
        XCTAssertTrue(commands.contains("MTK_STOP"))
        XCTAssertTrue(commands.contains("MTK_REC_TOGGLE"))
    }

    // MARK: - FxBus

    func testFxBusSetBpm() {
        let fx = FxBus(conn: conn, store: store, bus: 1)
        fx.setBpm(120)

        XCTAssertTrue(transport.sentCommands.contains("SETD^f.0.bpm^120"))
    }

    func testFxBusSetParam() {
        let fx = FxBus(conn: conn, store: store, bus: 2)
        fx.setParam(3, value: 0.7)

        XCTAssertTrue(transport.sentCommands.contains("SETD^f.1.par3^0.7"))
    }

    // MARK: - Clear Mute Groups

    func testClearMuteGroups() {
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        mixer.clearMuteGroups()

        XCTAssertTrue(transport.sentCommands.contains("SETD^mgmask^0"))
    }

    // MARK: - DualTrackRecorder

    func testDualTrackRecorderToggle() {
        let recorder = DualTrackRecorder(conn: conn, store: store)
        recorder.recordToggle()

        XCTAssertTrue(transport.sentCommands.contains("RECTOGGLE"))
    }

    // MARK: - HwChannel

    func testHwChannelChangeGain() {
        let deviceInfo = DeviceInfo(store: store)
        transport.simulateSetd(path: "model", value: "ui24")
        let hw = HwChannel(conn: conn, store: store, deviceInfo: deviceInfo, channel: 1)
        transport.simulateSetd(path: "hw.0.gain", value: "0.5")
        hw.changeGain(0.2)

        let sent = transport.sentCommands.first { $0.hasPrefix("SETD^hw.0.gain^") }
        XCTAssertNotNil(sent)
        if let sent {
            let value = Double(sent.components(separatedBy: "^").last ?? "")
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, 0.7, accuracy: 0.001)
        }
    }

    func testHwChannelChangeGainClampsToOne() {
        let deviceInfo = DeviceInfo(store: store)
        transport.simulateSetd(path: "model", value: "ui24")
        let hw = HwChannel(conn: conn, store: store, deviceInfo: deviceInfo, channel: 1)
        transport.simulateSetd(path: "hw.0.gain", value: "0.8")
        hw.changeGain(0.5)

        let sent = transport.sentCommands.first { $0.hasPrefix("SETD^hw.0.gain^") }
        XCTAssertNotNil(sent)
        if let sent {
            let value = Double(sent.components(separatedBy: "^").last ?? "")
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, 1.0, accuracy: 0.001)
        }
    }

    // MARK: - Channel Sync

    func testChannelSyncSelectIndex() {
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        mixer.channelSync.selectChannelIndex(5)

        XCTAssertTrue(transport.sentCommands.contains("BMSG^SYNC^SYNC_ID^5"))
    }

    func testChannelSyncSelectMaster() {
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        mixer.channelSync.selectMaster()

        XCTAssertTrue(transport.sentCommands.contains("BMSG^SYNC^SYNC_ID^-1"))
    }

    func testChannelSyncGetSelectedChannelResolvesInput() {
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        transport.simulateSetd(path: "model", value: "ui24")
        // Index 2 = input 3 in ui24 mapping
        transport.simulateInbound("BMSG^SYNC^SYNC_ID^2")

        var resolved: MasterChannel?
        mixer.channelSync.getSelectedChannel()
            .compactMap { $0 }
            .first()
            .sink { resolved = $0 }
            .store(in: &cancellables)

        XCTAssertNotNil(resolved)
    }

    func testChannelSyncGetSelectedChannelNilForMaster() {
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        transport.simulateSetd(path: "model", value: "ui24")
        // Index -1 = master bus selected
        transport.simulateInbound("BMSG^SYNC^SYNC_ID^-1")

        var sinkFired = false
        mixer.channelSync.getSelectedChannel()
            .first()
            .sink { channel in
                XCTAssertNil(channel)
                sinkFired = true
            }
            .store(in: &cancellables)

        XCTAssertTrue(sinkFired)
    }

    func testChannelSyncGetSelectedChannelCustomSyncId() {
        let mixer = SoundcraftUI(ip: "127.0.0.1", transport: transport)
        mixer.connect()
        transport.simulateSetd(path: "model", value: "ui24")
        transport.simulateInbound("BMSG^SYNC^MIXER_B^0")

        var resolved: MasterChannel?
        mixer.channelSync.getSelectedChannel(syncId: "MIXER_B")
            .compactMap { $0 }
            .first()
            .sink { resolved = $0 }
            .store(in: &cancellables)

        XCTAssertNotNil(resolved)
    }
}
