import Combine
import Foundation

/// Generate discrete fader steps for a fade transition
public func generateTransition(
    sourceValue: Double,
    targetValue: Double,
    fadeTime: Double,
    easing: Easing = .linear,
    fps: Int = 25
) -> AnyPublisher<Double, Never> {
    let adjustedFadeTime = max(fadeTime, Double(fps))
    let stepTime = (1000.0 / Double(fps)).rounded()
    let steps = Int((adjustedFadeTime / stepTime).rounded())

    guard steps > 0 else {
        return Just(targetValue).eraseToAnyPublisher()
    }

    return Timer.publish(every: stepTime / 1000.0, on: .main, in: .common)
        .autoconnect()
        .prefix(steps)
        .scan(0) { count, _ in count + 1 }
        .map { i -> Double in
            let progress = Double(i) / Double(steps)
            return easing.apply(progress) * (targetValue - sourceValue) + sourceValue
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
}
