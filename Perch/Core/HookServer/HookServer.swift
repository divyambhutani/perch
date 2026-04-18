import Foundation
import Network

actor HookServer {
    private let parser = HookRequestParser()
    private let router = HookRouter()
    private var listener: NWListener?
    private var activeConnections: [ObjectIdentifier: HookConnection] = [:]
    private(set) var boundPort: UInt16?

    @discardableResult
    func start(
        preferredPort: UInt16 = HookServerConfiguration.defaultPort,
        handler: @escaping @Sendable (HookEvent) async -> Void
    ) async throws -> UInt16 {
        if let existing = boundPort {
            return existing
        }

        var lastError: Error?
        for offset in 0 ..< HookServerConfiguration.portFallbackAttempts {
            let candidate = preferredPort &+ UInt16(offset)
            guard let endpoint = NWEndpoint.Port(rawValue: candidate) else { continue }
            do {
                let listener = try NWListener(using: .tcp, on: endpoint)
                let parser = parser
                let router = router
                listener.newConnectionHandler = { [weak self] connection in
                    guard let self else { return }
                    Task {
                        let peer = HookConnection(
                            connection: connection,
                            parser: parser,
                            router: router,
                            onEvent: handler,
                            onComplete: { [weak self] conn in
                                await self?.removeConnection(conn)
                            }
                        )
                        await self.trackConnection(peer)
                        await peer.begin()
                    }
                }

                let actualPort = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt16, Error>) in
                    nonisolated(unsafe) var resumed = false
                    listener.stateUpdateHandler = { state in
                        guard !resumed else { return }
                        switch state {
                        case .ready:
                            resumed = true
                            let port = listener.port?.rawValue ?? candidate
                            continuation.resume(returning: port)
                        case .failed(let error):
                            resumed = true
                            continuation.resume(throwing: error)
                        case .cancelled:
                            resumed = true
                            continuation.resume(throwing: HookServerError.bindFailed("listener cancelled"))
                        default:
                            break
                        }
                    }
                    listener.start(queue: .global(qos: .userInitiated))
                }

                self.listener = listener
                self.boundPort = actualPort
                return actualPort
            } catch {
                lastError = error
                continue
            }
        }
        throw HookServerError.bindFailed(String(describing: lastError ?? HookServerError.noAvailablePort))
    }

    func stop() {
        listener?.cancel()
        listener = nil
        activeConnections.removeAll()
        boundPort = nil
    }

    private func trackConnection(_ conn: HookConnection) {
        activeConnections[ObjectIdentifier(conn)] = conn
    }

    private func removeConnection(_ conn: HookConnection) {
        activeConnections.removeValue(forKey: ObjectIdentifier(conn))
    }

    func ingest(data: Data) throws -> HookEvent {
        switch try parser.parse(data) {
        case .complete(let request, _):
            return try router.route(request)
        case .needMoreData:
            throw HookServerError.incompleteRequest
        }
    }
}
