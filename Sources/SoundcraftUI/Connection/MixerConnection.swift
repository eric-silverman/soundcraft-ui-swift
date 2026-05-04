import Combine
import Foundation

/// Protocol for WebSocket transport (enables testing with mock)
public protocol WebSocketTransport: AnyObject {
    func connect(to url: URL)
    func disconnect()
    func send(_ message: String)
    var onMessage: ((String) -> Void)? { get set }
    var onOpen: (() -> Void)? { get set }
    var onClose: (() -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

/// Production WebSocket transport using URLSession
public final class URLSessionWebSocketTransport: WebSocketTransport {
    private var task: URLSessionWebSocketTask?
    private let session: URLSession

    public var onMessage: ((String) -> Void)?
    public var onOpen: (() -> Void)?
    public var onClose: (() -> Void)?
    public var onError: ((Error) -> Void)?

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func connect(to url: URL) {
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()

        // URLSessionWebSocketTask doesn't have a direct open callback;
        // we fire it after resume and start receiving
        onOpen?()
        receiveLoop()
    }

    public func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        onClose?()
    }

    public func send(_ message: String) {
        task?.send(.string(message)) { [weak self] error in
            if let error { self?.onError?(error) }
        }
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            switch result {
            case .success(.string(let text)):
                self?.onMessage?(text)
                self?.receiveLoop()
            case .success(.data(let data)):
                if let text = String(data: data, encoding: .utf8) {
                    self?.onMessage?(text)
                }
                self?.receiveLoop()
            case .failure(let error):
                self?.onError?(error)
                self?.onClose?()
            default:
                self?.receiveLoop()
            }
        }
    }
}

/// Manages the WebSocket connection to a Soundcraft UI mixer
public final class MixerConnection {
    /// Time to wait before reconnecting after an error
    private let reconnectTime: TimeInterval = 2.0
    /// Period time for keepalive interval messages
    private let keepaliveTime: TimeInterval = 1.0

    private let transport: WebSocketTransport
    private let targetIP: String
    private var cancellables = Set<AnyCancellable>()
    private var keepaliveTimer: AnyCancellable?
    private var reconnectWorkItem: DispatchWorkItem?
    private var shouldReconnect = false

    // MARK: - Publishers

    private let statusSubject = CurrentValueSubject<ConnectionStatus, Never>(.close)
    private let inboundSubject = PassthroughSubject<String, Never>()
    private let outboundSubject = PassthroughSubject<String, Never>()

    /// Connection status stream
    public var status: AnyPublisher<ConnectionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    /// Current connection status (synchronous)
    public var currentStatus: ConnectionStatus {
        statusSubject.value
    }

    /// All inbound messages (from mixer, already unframed and split)
    public var inbound: AnyPublisher<String, Never> {
        inboundSubject.eraseToAnyPublisher()
    }

    /// All outbound messages (from client to mixer)
    public var outbound: AnyPublisher<String, Never> {
        outboundSubject.eraseToAnyPublisher()
    }

    /// Combined stream of inbound and outbound messages
    public var allMessages: AnyPublisher<String, Never> {
        Publishers.Merge(inbound, outbound).eraseToAnyPublisher()
    }

    // MARK: - Init

    public init(ip: String, transport: WebSocketTransport? = nil) {
        self.targetIP = ip
        self.transport = transport ?? URLSessionWebSocketTransport()

        setupTransportCallbacks()
        setupKeepalive()
        setupOutboundForwarding()
    }

    private func setupTransportCallbacks() {
        transport.onOpen = { [weak self] in
            self?.statusSubject.send(.open)
        }

        transport.onClose = { [weak self] in
            guard let self else { return }
            self.stopKeepalive()
            self.statusSubject.send(.close)

            if self.shouldReconnect {
                self.scheduleReconnect()
            }
        }

        transport.onError = { [weak self] _ in
            guard let self else { return }
            self.statusSubject.send(.error)
            self.stopKeepalive()

            if self.shouldReconnect {
                self.scheduleReconnect()
            }
        }

        transport.onMessage = { [weak self] rawMessage in
            guard let self else { return }
            guard let unframed = MessageProtocol.unframe(rawMessage) else { return }
            for line in MessageProtocol.splitLines(unframed) {
                self.inboundSubject.send(line)
            }
        }
    }

    private func setupKeepalive() {
        statusSubject
            .removeDuplicates()
            .sink { [weak self] status in
                guard let self else { return }
                if status == .open {
                    self.startKeepalive()
                } else {
                    self.stopKeepalive()
                }
            }
            .store(in: &cancellables)
    }

    private func setupOutboundForwarding() {
        outboundSubject
            .sink { [weak self] message in
                guard let self else { return }
                let framed = MessageProtocol.frame(message)
                self.transport.send(framed)
            }
            .store(in: &cancellables)
    }

    private func startKeepalive() {
        keepaliveTimer = Timer.publish(every: keepaliveTime, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.outboundSubject.send("ALIVE")
            }
    }

    private func stopKeepalive() {
        keepaliveTimer?.cancel()
        keepaliveTimer = nil
    }

    private func scheduleReconnect() {
        reconnectWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.shouldReconnect else { return }
            self.statusSubject.send(.reconnecting)
            self.performConnect()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectTime, execute: workItem)
    }

    // MARK: - Public API

    /// Connect to the mixer
    public func connect() {
        shouldReconnect = true
        statusSubject.send(.opening)
        performConnect()
    }

    private func performConnect() {
        guard let url = URL(string: "ws://\(targetIP)") else { return }
        transport.connect(to: url)
    }

    /// Disconnect from the mixer
    public func disconnect() {
        shouldReconnect = false
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        statusSubject.send(.closing)
        transport.disconnect()
    }

    /// Reconnect: disconnect, wait 1 second, then reconnect
    public func reconnect() {
        disconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.connect()
        }
    }

    /// Send a command to the mixer (will be framed with 3:::)
    public func sendMessage(_ msg: String) {
        outboundSubject.send(msg)
    }
}
