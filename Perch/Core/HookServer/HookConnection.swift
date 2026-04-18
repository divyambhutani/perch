import Foundation
import Network

actor HookConnection {
    private let connection: NWConnection
    private let parser: HookRequestParser
    private let router: HookRouter
    private let onEvent: @Sendable (HookEvent) async -> Void
    private var buffer = Data()
    private static let maxBufferBytes = HookRequestParser.maxBodyBytes + 32_768

    init(
        connection: NWConnection,
        parser: HookRequestParser,
        router: HookRouter,
        onEvent: @escaping @Sendable (HookEvent) async -> Void
    ) {
        self.connection = connection
        self.parser = parser
        self.router = router
        self.onEvent = onEvent
    }

    func begin() {
        connection.start(queue: .global(qos: .userInitiated))
        receiveNext()
    }

    private func receiveNext() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { await self.handle(data: data, isComplete: isComplete, error: error) }
        }
    }

    private func handle(data: Data?, isComplete: Bool, error: NWError?) async {
        if error != nil {
            cancel()
            return
        }
        if let data {
            buffer.append(data)
        }
        if buffer.count > Self.maxBufferBytes {
            await respond(status: "413 Payload Too Large")
            return
        }

        do {
            switch try parser.parse(buffer) {
            case .needMoreData:
                if isComplete {
                    await respond(status: "400 Bad Request")
                } else {
                    receiveNext()
                }
            case .complete(let request, _):
                await dispatch(request)
            }
        } catch {
            await respond(status: "400 Bad Request")
        }
    }

    private func dispatch(_ request: HookRequestParser.ParsedRequest) async {
        guard request.method.uppercased() == "POST" else {
            await respond(status: "405 Method Not Allowed")
            return
        }
        guard request.path == HookServerConfiguration.hooksPath else {
            await respond(status: "404 Not Found")
            return
        }
        do {
            let event = try router.route(request)
            await onEvent(event)
            await respond(status: "202 Accepted")
        } catch {
            await respond(status: "400 Bad Request")
        }
    }

    private func respond(status: String) async {
        let frame = Data("HTTP/1.1 \(status)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            connection.send(content: frame, completion: .contentProcessed { _ in
                continuation.resume()
            })
        }
        cancel()
    }

    private func cancel() {
        connection.cancel()
    }
}
