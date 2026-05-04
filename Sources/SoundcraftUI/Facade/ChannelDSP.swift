import Combine
import Foundation

/// DSP processor accessors for channels.
/// Extends Channel with access to EQ, dynamics, gate, and channel properties.
extension Channel {

    // MARK: - DSP Processors

    /// 5-band parametric EQ for this channel
    public func eq() -> ParametricEQ {
        let storeId = "eq_\(channelType.rawValue)\(channel)"
        if let cached: ParametricEQ = store.objectStore.get(storeId) {
            return cached
        }
        let instance = ParametricEQ(conn: conn, store: store, channelType: channelType, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    /// Compressor/dynamics for this channel
    public func dynamics() -> Dynamics {
        let storeId = "dyn_\(channelType.rawValue)\(channel)"
        if let cached: Dynamics = store.objectStore.get(storeId) {
            return cached
        }
        let instance = Dynamics(conn: conn, store: store, channelType: channelType, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    /// Noise gate for this channel
    public func gate() -> Gate {
        let storeId = "gate_\(channelType.rawValue)\(channel)"
        if let cached: Gate = store.objectStore.get(storeId) {
            return cached
        }
        let instance = Gate(conn: conn, store: store, channelType: channelType, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    // MARK: - Channel Properties (Publishers)

    /// Phase invert (0 or 1)
    public func invertPublisher() -> AnyPublisher<Int, Never> {
        store.select(path: "\(fullChannelId).invert", default: 0)
    }

    /// Channel safe (0 or 1) — protects channel from scene recalls
    public func safePublisher() -> AnyPublisher<Int, Never> {
        store.select(path: "\(fullChannelId).safe", default: 0)
    }

    /// Per-channel mute group bitmask
    public func mgmaskPublisher() -> AnyPublisher<Int, Never> {
        store.select(path: "\(fullChannelId).mgmask", default: 0)
    }

    /// Force unmute (0 or 1)
    public func forceUnmutePublisher() -> AnyPublisher<Int, Never> {
        store.select(path: "\(fullChannelId).forceunmute", default: 0)
    }

    /// Assigned subgroup (-1 = none, 0-5 = subgroup index)
    public func subgroupPublisher() -> AnyPublisher<Int, Never> {
        store.select(path: "\(fullChannelId).subgroup", default: -1)
    }

    /// Assigned VCA (-1 = none, 0-5 = VCA index)
    public func vcaAssignmentPublisher() -> AnyPublisher<Int, Never> {
        store.select(path: "\(fullChannelId).vca", default: -1)
    }

    // MARK: - Channel Property Setters

    public func setInvert(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).invert^\(value)")
    }

    public func setSafe(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).safe^\(value)")
    }

    public func setMgmask(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).mgmask^\(value)")
    }

    public func setForceUnmute(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).forceunmute^\(value)")
    }

    public func setSubgroup(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).subgroup^\(value)")
    }

    public func setVcaAssignment(_ value: Int) {
        conn.sendMessage("SETD^\(fullChannelId).vca^\(value)")
    }
}

// MARK: - Input-Only DSP Processors

/// Additional DSP processors available only on input channels.
extension MasterChannel {

    /// De-esser for this input channel (input channels only)
    public func deesser() -> Deesser? {
        guard channelType == .input else { return nil }
        let storeId = "deesser_\(channel)"
        if let cached: Deesser = store.objectStore.get(storeId) {
            return cached
        }
        let instance = Deesser(conn: conn, store: store, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }

    /// Digitech amp modeler for this input channel (input channels only)
    public func digitech() -> Digitech? {
        guard channelType == .input else { return nil }
        let storeId = "digitech_\(channel)"
        if let cached: Digitech = store.objectStore.get(storeId) {
            return cached
        }
        let instance = Digitech(conn: conn, store: store, channel: channel)
        store.objectStore.set(storeId, instance)
        return instance
    }
}

// MARK: - Input-Only Channel Properties

/// Additional properties available only on input channels.
extension HwChannel {

    /// Channel color index (input channels only)
    public func color() -> AnyPublisher<Int, Never> {
        store.select(path: "i.\(channel - 1).color", default: 0)
    }

    /// Hi-Z mode (input channels 1-2 only, 0 or 1)
    public func hiz() -> AnyPublisher<Int, Never> {
        store.select(path: "i.\(channel - 1).hiz", default: 0)
    }

    /// Input source routing
    public func src() -> AnyPublisher<Int, Never> {
        store.select(path: "i.\(channel - 1).src", default: 0)
    }

    /// Soundcheck source routing
    public func scsrc() -> AnyPublisher<Int, Never> {
        store.select(path: "i.\(channel - 1).scsrc", default: 0)
    }

    public func setColor(_ value: Int) {
        conn.sendMessage("SETD^i.\(channel - 1).color^\(value)")
    }

    public func setHiz(_ value: Int) {
        conn.sendMessage("SETD^i.\(channel - 1).hiz^\(value)")
    }

    public func setSrc(_ value: Int) {
        conn.sendMessage("SETD^i.\(channel - 1).src^\(value)")
    }

    public func setScsrc(_ value: Int) {
        conn.sendMessage("SETD^i.\(channel - 1).scsrc^\(value)")
    }
}
