import Foundation
import Network

actor HookServer {
    private let parser = HookRequestParser()
    private let router = HookRouter()
    private var listener: NWListener?
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
                listener.newConnectionHandler = { connection in
                    let peer = HookConnection(
                        connection: connection,
                        parser: parser,
                        router: router,
                        onEvent: handler
                    )
                    Task { await peer.begin() }
                }
                listener.start(queue: .global(qos: .userInitiated))
                self.listener = listener
                self.boundPort = candidate
                return candidate
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
        boundPort = nil
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
