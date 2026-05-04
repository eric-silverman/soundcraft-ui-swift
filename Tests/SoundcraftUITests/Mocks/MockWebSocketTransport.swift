import Foundation
@testable import SoundcraftUI

/// Mock WebSocket transport for testing
final class MockWebSocketTransport: WebSocketTransport {
    var sentMessages: [String] = []
    var onMessage: ((String) -> Void)?
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?
    var onError: ((Error) -> Void)?

    var connectCalled = false
    var disconnectCalled = false
    var lastConnectedURL: URL?

    func connect(to url: URL) {
        connectCalled = true
        lastConnectedURL = url
        onOpen?()
    }

    func disconnect() {
        disconnectCalled = true
        onClose?()
    }

    func send(_ message: String) {
        sentMessages.append(message)
    }

    /// Simulate receiving a raw WebSocket message (with 3::: framing)
    func simulateInbound(_ message: String) {
        onMessage?("3:::\(message)")
    }

    /// Simulate receiving a SETD message
    func simulateSetd(path: String, value: String) {
        simulateInbound("SETD^\(path)^\(value)")
    }

    /// Get sent messages without the 3::: framing prefix
    var sentCommands: [String] {
        sentMessages.compactMap { msg in
            msg.hasPrefix("3:::") ? String(msg.dropFirst(4)) : msg
        }
    }
}
