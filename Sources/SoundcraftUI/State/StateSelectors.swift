import Combine
import Foundation

/// Helper extensions on MixerStore for common state selections
extension MixerStore {
    // MARK: - Master

    /// Master fader level (0..1)
    public var masterValue: AnyPublisher<Double, Never> {
        select(path: "m.mix", default: 0.0)
    }

    /// Master pan (0..1)
    public var masterPan: AnyPublisher<Double, Never> {
        select(path: "m.pan", default: 0.5)
    }

    /// Master dim (0 or 1)
    public var masterDim: AnyPublisher<Int, Never> {
        select(path: "m.dim", default: 0)
    }

    /// Master delay (L or R) in milliseconds
    public func masterDelay(side: String) -> AnyPublisher<Double, Never> {
        state
            .map { dict -> Double in
                let raw = (dict["m.delay\(side)"] as? Double) ?? 0
                return raw * 1000
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Channel Selectors

    /// Fader value for a channel on a specific bus
    public func faderValue(channelType: ChannelType, channel: Int, busType: BusType, bus: Int = 1) -> AnyPublisher<Double, Never> {
        let path: String
        switch busType {
        case .master:
            path = joinStatePath(channelType.rawValue, channel - 1, "mix")
        case .aux, .fx:
            path = joinStatePath(channelType.rawValue, channel - 1, busType.rawValue, bus - 1, "value")
        }
        return select(path: path, default: 0.0)
    }

    /// Mute value for a channel
    public func muteValue(channelType: ChannelType, channel: Int, busType: BusType, bus: Int = 1) -> AnyPublisher<Int, Never> {
        let path: String
        switch busType {
        case .master:
            path = joinStatePath(channelType.rawValue, channel - 1, "mute")
        case .aux, .fx:
            path = joinStatePath(channelType.rawValue, channel - 1, busType.rawValue, bus - 1, "mute")
        }
        return select(path: path, default: 0)
    }

    /// Solo value for a channel (master bus only)
    public func soloValue(channelType: ChannelType, channel: Int) -> AnyPublisher<Int, Never> {
        let path = joinStatePath(channelType.rawValue, channel - 1, "solo")
        return select(path: path, default: 0)
    }

    /// Pan value for a channel
    public func panValue(channelType: ChannelType, channel: Int, busType: BusType, bus: Int = 1) -> AnyPublisher<Double, Never> {
        let path: String
        switch busType {
        case .master:
            path = joinStatePath(channelType.rawValue, channel - 1, "pan")
        case .aux, .fx:
            path = joinStatePath(channelType.rawValue, channel - 1, busType.rawValue, bus - 1, "pan")
        }
        return select(path: path, default: 0.0)
    }

    /// Stereo index for a channel (-1 = not linked, 0 = left, 1 = right)
    public func stereoIndex(channelType: ChannelType, channel: Int) -> AnyPublisher<Int, Never> {
        guard ["i", "l", "p", "a"].contains(channelType.rawValue) else {
            return Just(-1).eraseToAnyPublisher()
        }
        let path = joinStatePath(channelType.rawValue, channel - 1, "stereoIndex")
        return select(path: path, default: -1)
    }

    /// Post value for a send channel
    public func postValue(channelType: ChannelType, channel: Int, busType: BusType, bus: Int) -> AnyPublisher<Int, Never> {
        let path = joinStatePath(channelType.rawValue, channel - 1, busType.rawValue, bus - 1, "post")
        return select(path: path, default: 0)
    }

    /// Post-proc value for an aux channel
    public func auxPostProc(channelType: ChannelType, channel: Int, aux: Int) -> AnyPublisher<Int, Never> {
        let path = joinStatePath(channelType.rawValue, channel - 1, "aux", aux - 1, "postproc")
        return select(path: path, default: 0)
    }

    /// Delay value for a master channel in ms
    public func delayValue(channelType: ChannelType, channel: Int) -> AnyPublisher<Double, Never> {
        let path = joinStatePath(channelType.rawValue, channel - 1, "delay")
        return state
            .map { dict -> Double in
                let raw = (dict[path] as? Double) ?? 0
                return raw * 1000
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Hardware

    /// Phantom power for a hardware channel
    public func phantom(channel: Int, key: String) -> AnyPublisher<Int, Never> {
        let path = joinStatePath(key, channel - 1, "phantom")
        return select(path: path, default: 0)
    }

    /// Gain for a hardware channel (linear 0..1)
    public func gain(channel: Int, key: String) -> AnyPublisher<Double, Never> {
        let path = joinStatePath(key, channel - 1, "gain")
        return select(path: path, default: 0.0)
    }

    // MARK: - FX

    /// FX type for a bus
    public func fxType(bus: Int) -> AnyPublisher<Int, Never> {
        let path = joinStatePath("f", bus - 1, "fxtype")
        return select(path: path, default: -1)
    }

    /// FX BPM for a bus
    public func fxBpm(bus: Int) -> AnyPublisher<Int, Never> {
        let path = joinStatePath("f", bus - 1, "bpm")
        return select(path: path, default: 120)
    }

    // MARK: - Volume Bus

    /// Volume bus fader value
    public func volumeBusValue(busName: String, busId: Int? = nil) -> AnyPublisher<Double, Never> {
        var path = "settings.\(busName)"
        if let busId, busId >= 0 {
            path += ".\(busId)"
        }
        return select(path: path, default: 0.0)
    }

    // MARK: - Player

    /// Player track length in seconds
    public var playerLength: AnyPublisher<Double, Never> {
        select(path: "var.currentLength", default: -1.0)
    }

    /// Player track position (0..1 normalized)
    public var playerCurrentTrackPos: AnyPublisher<Double, Never> {
        select(path: "var.currentTrackPos", default: 0.0)
    }

    /// Player elapsed time in seconds
    public var playerElapsedTime: AnyPublisher<Int, Never> {
        state
            .map { dict -> Int in
                let pos = (dict["var.currentTrackPos"] as? Double) ?? 0
                let length = (dict["var.currentLength"] as? Double) ?? -1
                return max(0, Int(pos * length))
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Player remaining time in seconds
    public var playerRemainingTime: AnyPublisher<Int, Never> {
        state
            .map { dict -> Int in
                let pos = (dict["var.currentTrackPos"] as? Double) ?? 0
                let length = (dict["var.currentLength"] as? Double) ?? -1
                let elapsed = max(0, Int(pos * length))
                return max(0, Int(length) - elapsed)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Multitrack

    /// MTK track length
    public var mtkLength: AnyPublisher<Double, Never> {
        select(path: "var.mtk.currentLength", default: -1.0)
    }

    /// MTK track position
    public var mtkCurrentTrackPos: AnyPublisher<Double, Never> {
        select(path: "var.mtk.currentTrackPos", default: 0.0)
    }

    /// MTK elapsed time
    public var mtkElapsedTime: AnyPublisher<Int, Never> {
        state
            .map { dict -> Int in
                let pos = (dict["var.mtk.currentTrackPos"] as? Double) ?? 0
                let length = (dict["var.mtk.currentLength"] as? Double) ?? -1
                return max(0, Int(pos * length))
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// MTK remaining time
    public var mtkRemainingTime: AnyPublisher<Int, Never> {
        state
            .map { dict -> Int in
                let pos = (dict["var.mtk.currentTrackPos"] as? Double) ?? 0
                let length = (dict["var.mtk.currentLength"] as? Double) ?? -1
                let elapsed = max(0, Int(pos * length))
                return max(0, Int(length) - elapsed)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Raw Value Helper

    /// Get current value for a path synchronously
    func currentValue<T>(path: String, default defaultValue: T) -> T {
        (state.value[path] as? T) ?? defaultValue
    }
}
