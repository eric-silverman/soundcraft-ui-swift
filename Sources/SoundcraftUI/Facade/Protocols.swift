import Combine

/// A channel that has a fader and supports fade transitions
public protocol FadeableChannel: AnyObject {
    /// Name of the channel
    var name: AnyPublisher<String, Never> { get }
    /// Linear fader level (0..1)
    var faderLevel: AnyPublisher<Double, Never> { get }
    /// dB fader level (-Inf..+10)
    var faderLevelDB: AnyPublisher<Double, Never> { get }

    func setFaderLevel(_ value: Double)
    func setFaderLevelDB(_ dbValue: Double)
    func changeFaderLevel(_ offset: Double)
    func changeFaderLevelDB(_ offsetDB: Double)
    func fadeTo(_ targetValue: Double, fadeTime: Double, easing: Easing, fps: Int)
    func fadeToDB(_ targetValueDB: Double, fadeTime: Double, easing: Easing, fps: Int)
}

/// A channel that has pan control
public protocol PannableChannel: FadeableChannel {
    /// Pan value (0..1)
    var pan: AnyPublisher<Double, Never> { get }
    func setPan(_ value: Double)
}
